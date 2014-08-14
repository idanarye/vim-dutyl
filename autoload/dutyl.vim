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
        let l:bufferLines=getline(1,'$')
        let l:bufferLines[line('.')-1]=b:currentLineText
        let l:args={
                    \'base':a:base,
                    \'importPaths':l:dutyl.importPaths(),
                    \'bufferLines':l:bufferLines,
                    \'bytePos':dutyl#core#bytePosition('.',b:completionColumn),
                    \'lineNumber':line('.'),
                    \'columnNumber':b:completionColumn,
                    \}
        return l:dutyl.complete(l:args)
    endif
endfunction

function! dutyl#displayDDocForSymbolUnderCursor() abort
    try
        let l:dutyl=dutyl#core#requireFunctions('importPaths','ddocForSymobolInBuffer')
    catch
        echoerr 'Unable to display DDoc: '.v:exception
        return
    endtry
    let l:args={
                \'importPaths':l:dutyl.importPaths(),
                \'bufferLines':getline(1,'$'),
                \'symbol':expand('<cword>'),
                \'bytePos':dutyl#core#bytePosition(),
                \'lineNumber':line('.'),
                \'columnNumber':col('.'),
                \}
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
