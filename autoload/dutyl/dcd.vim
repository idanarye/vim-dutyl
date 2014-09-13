function! dutyl#dcd#new() abort
    if !dutyl#core#toolExecutable('dcd-client')
                \|| !dutyl#core#toolExecutable('dcd-server')
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
    try
	let l:args=map(dutyl#core#requireFunctions('importPaths').importPaths(),
		    \'"-I".v:val')
    catch "Ignore errors and simply don't use them
	let l:args=[]
    endtry
    call dutyl#core#runToolInBackground('dcd-server',l:args)
endfunction

function! dutyl#dcd#stopServer() abort
    call dutyl#core#runToolInBackground('dcd-client','--shutdown')
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
    let resultLines=dutyl#util#splitLines(l:scanResult)

    "if we have less than one line - something wen wrong
    if empty(resultLines)
        return 'bad...'
    endif
    "identify completion type via the first line.
    if resultLines[0]=='identifiers'
        return s:parsePairs(a:args.base,resultLines[1:],'','')
    elseif resultLines[0]=='calltips'
        return s:parseCalltips(a:args.base,resultLines[1:])
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
    "call s:registerImportPaths(a:args.importPaths)

    "Run DCD
    let l:scanResult=s:runDCDOnBufferBytePosition(a:args.bufferLines,a:args.bytePos,['--symbolLocation'])
    if l:scanResult=~'\v^Not found'
	return []
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
    return l:result
endfunction


"Run DCD to get autocompletion results
function! s:runDCDToGetAutocompletion(bufferLines,bytePos) abort
	return s:runDCDOnBufferBytePosition(a:bufferLines,a:bytePos,[])
endfunction

"Run DCD on the current buffer with the supplied position
function! s:runDCDOnBufferBytePosition(bufferLines,bytePosition,args) abort
    let l:scanResult=dutyl#core#runTool('dcd-client',a:args+['--cursorPos='.a:bytePosition],join(a:bufferLines,"\n"))
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
