"The D completion function
function! dutyl#dComplete(findstart,base) abort
    if a:findstart
        "Vim temporarily deletes the current identifier from the file
        let b:currentLineText=getline('.')

        "We might need it for paren completion:
        let b:closingParenExists=getline('.')[col('.')-1:-1]=~'^\s*)'

        let prePos=searchpos('\W',"bn")
        let preChar=getline(prePos[0])[prePos[1]-1]
        if '.'==preChar
            let b:completionColumn=prePos[1]-1
            return prePos[1]
        endif
        "If we can't find a dot, we look for a paren.
        let parenPos=searchpos("(","bn",line('.'))
        if parenPos[0]
            if getline('.')[parenPos[1]:col('.')-2]=~'^\s*\w*$'
                let b:completionColumn=parenPos[1]-1
                return parenPos[1]
            endif
        endif
        "If we can't find any of the above - just look for the begining of
        "the identifier
        let wordStartPos=searchpos('\w\+',"bn")
        if line('.')==wordStartPos[0]
            let b:completionColumn=wordStartPos[1]
            return wordStartPos[1]-1
        endif

        return -2
    else
        try
            let l:dutyl=dutyl#core#requireFunctions('importPaths','complete')
        catch
            echoerr 'Unable to complete: '.v:exception
            return
        endtry
        let l:args=dutyl#core#gatherCommonArguments(l:dutyl)
        let l:args.bufferLines[line('.')-1]=b:currentLineText
        let l:args.base=a:base
        return l:dutyl.complete(l:args)
    endif
endfunction

"Exactly what it says on the tin
function! dutyl#displayDDocForSymbolUnderCursor() abort
    try
        let l:dutyl=dutyl#core#requireFunctions('importPaths','ddocForSymobolInBuffer')
    catch
        echoerr 'Unable to display DDoc: '.v:exception
        return
    endtry
    let l:args=dutyl#core#gatherCommonArguments(l:dutyl)
    let l:args.symbol=expand('<cword>')
    let l:ddocs=l:dutyl.ddocForSymobolInBuffer(l:args)
    for l:i in range(len(l:ddocs))
        if 0<l:i
            "Print a vertical line:
            echo repeat('_',&columns-1)
            echo ' '
        endif
        echo l:ddocs[l:i]
    endfor
endfunction

"If symbol is a string - jump to the declaration of that string. If symbol is
"an empty non-string - jump to the symbol under the cursor. If symbol is
"non-empty non-string - jump to the symbol under the cursor using text
"search(ignoring it's context).
"Set splitType to '', 's' or 'v' to determine if and how the window will split
"before jumping.
function! dutyl#jumpToDeclarationOfSymbol(symbol,splitType) abort
    try
        if type(a:symbol)==type('')
            let l:dutyl=dutyl#core#requireFunctions('importPaths','declarationsOfSymbol')
            let l:args=dutyl#core#gatherCommonArguments(l:dutyl)
            let l:args.symbol=a:symbol
            let l:declarationLocations=l:dutyl.declarationsOfSymbol(l:args)
        else
            if empty(a:symbol)
                let l:dutyl=dutyl#core#requireFunctions('importPaths','declarationsOfSymbolInBuffer')
                let l:args=dutyl#core#gatherCommonArguments(l:dutyl)
                let l:args.symbol=expand('<cword>')
                let l:declarationLocations=l:dutyl.declarationsOfSymbolInBuffer(l:args)
            else
                let l:dutyl=dutyl#core#requireFunctions('importPaths','declarationsOfSymbol')
                let l:args=dutyl#core#gatherCommonArguments(l:dutyl)
                let l:args.symbol=expand('<cword>')
                let l:declarationLocations=l:dutyl.declarationsOfSymbol(l:args)
            endif
        endif
    catch
        echoerr 'Unable to find declaration: '.v:exception
        return
    endtry

    if empty(l:declarationLocations)
        echo 'Unable to find declaration for symbol `'.l:args.symbol.'`'
    elseif 1==len(l:declarationLocations)
        call dutyl#util#splitWindowBasedOnArgument(a:splitType)
        call dutyl#core#jumpToPositionPushToTagStack(l:declarationLocations[0])
    else
        let l:options=['Multiple declarations found:']
        for l:i in range(len(l:declarationLocations))
            call add(l:options,printf('%i) %s(%s:%s)',
                        \l:i+1,
                        \get(l:declarationLocations[i],'file','current file'),
                        \l:declarationLocations[i].line,
                        \l:declarationLocations[i].column))
        endfor
        let l:selectedLocationIndex=inputlist(l:options)
        if 0<l:selectedLocationIndex && l:selectedLocationIndex<=len(l:declarationLocations)
            call dutyl#util#splitWindowBasedOnArgument(a:splitType)
            call dutyl#core#jumpToPositionPushToTagStack(l:declarationLocations[l:selectedLocationIndex-1])
        endif
    endif
endfunction

"Runs a syntax check and sets the quickfix or the location list to it's
"results. Arguments:
" - files: a list of files to include in the syntax check. Send an empty list
"   to let the tool decide which files to take
" - targetList: 'c'/'q' for the quickfix list, 'l' for the location list
" - jump: nonzero value to automatically jump to the first entry
function! dutyl#syntaxCheck(files,targetList,jump)
    try
        let l:dutyl=dutyl#core#requireFunctions('syntaxCheck')
    catch
        echoerr 'Unable to check syntax: '.v:exception
        return
    endtry
    let l:args=dutyl#core#gatherCommonArguments(l:dutyl)
    let l:args.files=a:files
    let l:checkResult=l:dutyl.syntaxCheck(l:args)
    call dutyl#util#setQuickfixOrLocationList(l:checkResult,a:targetList,a:jump)
endfunction

"Runs a style check and sets the quickfix or the location list to it's
"results. Arguments:
" - files: a list of files to include in the style check. Send an empty list
"   to let the tool decide which files to take
" - targetList: 'c'/'q' for the quickfix list, 'l' for the location list
" - jump: nonzero value to automatically jump to the first entry
function! dutyl#styleCheck(files,targetList,jump)
    try
        let l:dutyl=dutyl#core#requireFunctions('styleCheck')
    catch
        echoerr 'Unable to check style: '.v:exception
        return
    endtry
    let l:args=dutyl#core#gatherCommonArguments(l:dutyl)
    let l:args.files=a:files
    let l:checkResult=l:dutyl.styleCheck(l:args)
    call dutyl#util#setQuickfixOrLocationList(l:checkResult,a:targetList,a:jump)
endfunction


"Update the CTags file.
function! dutyl#updateCTags(paths) abort
    try
        let l:dutyl=dutyl#core#requireFunctions('generateCTags')
    catch
        echoerr 'Unable to update CTags: '.v:exception
        return
    endtry
    let l:args=dutyl#core#gatherCommonArguments(l:dutyl)
    if !empty(a:paths)
        let l:args.files=a:paths
    endif
    let l:tagList=l:dutyl.generateCTags(l:args)
    let l:tagsFile='tags'
    if exists('g:dutyl_tagsFileName')
        let l:tagsFile=g:dutyl_tagsFileName
    endif
    call writefile(l:tagList,l:tagsFile)
endfunction

"Return the project's root
function! dutyl#projectRoot() abort
    try
        let l:dutyl=dutyl#core#requireFunctions('projectRoot')
    catch
        echoerr 'Unable to find project root: '.v:exception
        return
    endtry
    return l:dutyl.projectRoot()
endfunction

"Runs a command in the project's root
function! dutyl#runInProjectRoot(command) abort
    try
        let l:dutyl=dutyl#core#requireFunctions('projectRoot')
    catch
        echoerr 'Unable to find project root: '.v:exception
        return
    endtry
    call dutyl#util#runInDirectory(l:dutyl.projectRoot(),a:command)
endfunction
