function! dutyl#dcd#new() abort
    if !dutyl#register#toolExecutable('dcd-client')
                \|| !dutyl#register#toolExecutable('dcd-server')
        return {}
    endif

    let l:result={}
    let l:result=extend(l:result,s:functions)
    return l:result
endfunction

"Register the import paths to the running dcd server
function! s:registerImportPaths(importPaths) abort
    let l:args=[]
    for l:path in a:importPaths
        call add(l:args,'-I')
        call add(l:args,l:path)
    endfor
    call dutyl#core#runTool('dcd-client',l:args)
endfunction

function! dutyl#dcd#startServer() abort
    let l:args=[]
    try
        for l:path in dutyl#core#requireFunctions('importPaths').importPaths()
            call add(l:args,'-I')
            call add(l:args,l:path)
        endfor
    catch
        "Ignore errors and simply don't use import paths
    endtry
    call dutyl#core#runToolInBackground('dcd-server',l:args)
endfunction

function! dutyl#dcd#stopServer() abort
    call dutyl#core#runToolInBackground('dcd-client','--shutdown')
endfunction

function! dutyl#dcd#clearCache() abort
    call dutyl#core#runToolInBackground('dcd-client','--clearCache')
endfunction

let s:functions={}

"DCD's checkFunction should also check if the DCD server is running
function! s:functions.checkFunction(functionName) dict abort
    if !has_key(self,a:functionName)
        return 1
    endif
    call dutyl#core#runTool('dcd-client','--query')
    if 0!=dutyl#core#shellReturnCode()
        return 'DCD server not running'
    endif
    return 0
endfunction

"Retrieve autocompletions from DCD
function! s:functions.complete(args) abort
    "Register the import paths:
    call s:registerImportPaths(a:args.importPaths)

    "Run DCD
    let l:scanResult=s:runDCDToGetAutocompletion(a:args.bufferLines,a:args.bytePos)

    "Split the result text to lines.
    let l:resultLines=dutyl#util#splitLines(l:scanResult)

    "if we have less than one line - something wen wrong
    if empty(l:resultLines)
        echoerr 'bad...'
        return
    endif
    "identify completion type via the first line.
    if l:resultLines[0]=='identifiers'
        return s:parsePairs(a:args.base,l:resultLines[1:],'','')
    elseif l:resultLines[0]=='calltips'
        return s:parseCalltips(a:args.base,l:resultLines[1:])
    endif
    return []
endfunction

"Retrieve ddoc from DCD
function! s:functions.ddocForSymobolInBuffer(args) abort
    "Register the import paths:
    call s:registerImportPaths(a:args.importPaths)

    "Run DCD
    let l:scanResult=s:runDCDOnBufferBytePosition(a:args.bufferLines,a:args.bytePos,['--doc'])
    let l:result=[]
    for l:ddoc in dutyl#util#splitLines(l:scanResult)
        let l:ddoc=substitute(l:ddoc,'\\n',"\n",'g')
        let l:ddoc=substitute(l:ddoc,'\\\\',"\\",'g')
        call add(l:result,l:ddoc)
    endfor
    return l:result
endfunction

"Retrieve declaration location from DCD
function! s:functions.declarationsOfSymbolInBuffer(args) abort
    "Register the import paths:
    call s:registerImportPaths(a:args.importPaths)

    "Run DCD
    let l:scanResult=s:runDCDOnBufferBytePosition(a:args.bufferLines,a:args.bytePos,['--symbolLocation'])
    if l:scanResult=~'\v^Not found'
        return s:functions.declarationsOfSymbol(a:args)
    endif
    let l:result=[]
    for l:resultLine in dutyl#util#splitLines(l:scanResult)
        let l:lineParts=split(l:resultLine,"\t")
        let l:bytePos=str2nr(l:lineParts[1])
        if l:lineParts[0]=='stdin'
            call add(l:result,dutyl#core#bytePosition2rowAndColumnCurrentBuffer(l:bytePos))
        else
            call add(l:result,dutyl#core#bytePosition2rowAndColumnAnotherFile(l:lineParts[0],l:bytePos))
        end
    endfor
    return dutyl#util#unique(l:result)
endfunction

"Retrieve declaration location from DCD based on name only
function! s:functions.declarationsOfSymbol(args) abort
    "Register the import paths:
    call s:registerImportPaths(a:args.importPaths)
    let l:currentFileName = expand('%:p')

    "Run DCD
    let l:scanResult=s:runDCDOnBuffer(a:args.bufferLines,['--search',a:args.symbol])
    if l:scanResult=~'\v^Not found'
        return []
    endif
    let l:result=[]
    for l:resultLine in dutyl#util#splitLines(l:scanResult)
        let l:lineParts=split(l:resultLine,"\t")
        let l:bytePos=str2nr(l:lineParts[2])
        if l:lineParts[0]=='stdin'
            if empty(l:currentFileName)
                call add(l:result,dutyl#core#bytePosition2rowAndColumnCurrentBuffer(l:bytePos))
            else
                call add(l:result,dutyl#core#bytePosition2rowAndColumnAnotherFile(l:currentFileName,l:bytePos))
            endif
        else
            call add(l:result,dutyl#core#bytePosition2rowAndColumnAnotherFile(l:lineParts[0],l:bytePos))
        end
    endfor
    return dutyl#util#unique(l:result)
endfunction

function! s:functions.signaturesForSymobolInBuffer(args) abort
    let l:identifierEnd = match(a:args.bufferLines[a:args.lineNumber - 1], '\W', a:args.columnNumber)
    let l:replaceLineWith = a:args.bufferLines[a:args.lineNumber - 1][: l:identifierEnd - 1]
    let l:bufferLines = a:args.bufferLines[:a:args.lineNumber - 2] + [l:replaceLineWith.'(']
    let l:bytePos = a:args.bytePos + l:identifierEnd - a:args.columnNumber + 1

    let l:scanResult = s:runDCDToGetAutocompletion(l:bufferLines, l:bytePos)
    let l:resultLines = dutyl#util#splitLines(l:scanResult)
    if empty(l:resultLines)
        return []
    elseif 'calltips' != remove(l:resultLines, 0)
        return []
    endif
    call filter(l:resultLines, 'v:val[:4] != "this("')
    return l:resultLines
endfunction


"Run DCD to get autocompletion results
function! s:runDCDToGetAutocompletion(bufferLines,bytePos) abort
    return s:runDCDOnBufferBytePosition(a:bufferLines,a:bytePos,[])
endfunction

"Run DCD on the current buffer with the supplied position
function! s:runDCDOnBufferBytePosition(bufferLines,bytePosition,args) abort
    return s:runDCDOnBuffer(a:bufferLines,a:args+['--cursorPos='.a:bytePosition])
endfunction

"Run DCD on the current buffer
function! s:runDCDOnBuffer(bufferLines, args) abort
    let l:bufferText = join(a:bufferLines, "\n")
    if empty(l:bufferText)
        let l:bufferText = "\n"
    endif

    let l:scanResult = dutyl#core#runTool('dcd-client', a:args, l:bufferText)
    if v:shell_error
        throw l:scanResult
    endif
    return l:scanResult
endfunction

"Parse simple pair results
function! s:parsePairs(base,resultLines,addBefore,addAfter) abort
    let result=[]
    for l:resultLine in a:resultLines
        if len(l:resultLine)
            let lineParts=split(l:resultLine)
            if lineParts[0]=~'^'.a:base && 2==len(lineParts) && 1==len(lineParts[1])
                call add(result,{'word':a:addBefore.lineParts[0].a:addAfter,'kind':lineParts[1]})
            endif
        end
    endfor
    return result
endfunction

"Parse function calltips results
function! s:parseCalltips(base,resultLines) abort
    let result=[a:base]
    for resultLine in a:resultLines
        if 0<=match(resultLine,".*(.*)")
            let funcArgs=[]
            for funcArg in split(resultLine[match(resultLine,'(')+1:-2],', ')
                let argParts=split(funcArg)
                if 1<len(argParts)
                    call add(funcArgs,argParts[-1])
                else
                    call add(funcArgs,'')
                endif
            endfor
            let funcArgsString=join(funcArgs,', ')
            if !b:closingParenExists && !(exists('g:dutyl_neverAddClosingParen') && g:dutyl_neverAddClosingParen)
                let funcArgsString=funcArgsString.')'
            endif
            call add(result,{'word':funcArgsString,'abbr':substitute(resultLine,'\\n\\t','','g'),'dup':1})
        end
    endfor
    return result
endfunction
