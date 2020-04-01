function! dutyl#dfmt#new() abort
    if !dutyl#register#toolExecutable('dfmt')
        return {}
    endif

    let l:result={}
    let l:result=extend(l:result,s:functions)
    return l:result
endfunction

let s:functions={}

function! s:getIndentFrom(code) abort
    let l:firstLine = ''
    if type(a:code) == type([])
        for l:line in a:code
            if l:line =~ '\S'
                let l:firstLine = l:line
                break
            endif
        endfor
    else
        let l:firstLine = a:code
    endif
    if empty(l:firstLine)
        return ''
    else
        let l:beforeCodeStarts = matchstr(l:firstLine, '\v^\_s*\ze\S')
        if empty(l:beforeCodeStarts)
            return ''
        else
            return dutyl#util#splitLines(l:beforeCodeStarts)[-1]
        endif
    endif
endfunction

function! s:functions.formatCode(code) abort
    let l:result = dutyl#util#splitLines(dutyl#core#runToolIgnoreStderr('dfmt', [], a:code))
    if !empty(l:result)
        let l:sourceIndent = s:getIndentFrom(a:code)
        let l:resultIndent = s:getIndentFrom(l:result)
        let l:targetDisplayWidth = strdisplaywidth(l:sourceIndent) - strdisplaywidth(l:resultIndent)
        if 0 < l:targetDisplayWidth

            if strridx(l:sourceIndent, l:resultIndent) == len(l:sourceIndent) - len(l:resultIndent)
                "If the result is a suffix of the source indent, simply remove it:
                let l:actualIndent = l:sourceIndent[0 :  -len(l:resultIndent) - 1]
            else
                "If it isn't, we are going to need to cut the actualIndent we
                "add until the indent of the first line is right.
                let l:actualIndent = 0
                let l:actualIndent = l:sourceIndent
                while l:targetDisplayWidth < strdisplaywidth(l:actualIndent . l:resultIndent)
                    let l:actualIndent = l:actualIndent[0 : -2]
                endwhile
                "In case we cut too much, we need only add spaces to mach
                let l:actualIndent = l:actualIndent . repeat(' ', l:targetDisplayWidth - strdisplaywidth(l:actualIndent))
            endif

            let l:result = map(l:result, 'l:actualIndent . v:val')
        endif
    endif
    return l:result
endfunction

function! s:findLineIndexAfterMarker(marker, lines) abort
    let l:lineIndex = len(a:lines) - 1
    while 0 <= l:lineIndex
        let l:line = a:lines[l:lineIndex]
        if len(a:marker) < len(l:line)
            if l:line[-len(a:marker) : -1] == a:marker
                break
            endif
        endif
        let l:lineIndex -= 1
    endwhile
    if l:lineIndex < 0
        return -1
    endif
    let l:lineIndex += 1
    if a:lines[l:lineIndex] =~ '\v^\s*$'
        let l:lineIndex += 1
    endif
    return l:lineIndex
endfunction

function! s:functions.calcIndentForLastLineOfCode(code) abort
    if empty(a:code)
        return -1
    endif
    if type(a:code) == type('')
        let l:code = dutyl#util#splitLines(a:code)
    else
        let l:code = a:code
    endif

    if l:code[-1] =~ '\v^\s*$'
        return 0
    endif

    let l:origLineBeforeIndex = len(l:code) - 2
    while 0 <= l:origLineBeforeIndex && l:code[l:origLineBeforeIndex] =~ '\v^\s*$'
        let l:origLineBeforeIndex -= 1
    endwhile
    if 0 <= l:origLineBeforeIndex
        let l:origIndentOfLineBefore = strwidth(s:getIndentFrom(l:code[l:origLineBeforeIndex]))

        let l:markBeforeLineBeforeLast = 'dutylmarkLineBefore-'.localtime()
        call insert(l:code, '//', l:origLineBeforeIndex)
        call insert(l:code, '// '.l:markBeforeLineBeforeLast, l:origLineBeforeIndex)
    endif

    let l:markBeforeLastLine = 'dutylmark-'.localtime()
    call insert(l:code, '//', -1)
    call insert(l:code, '// '.l:markBeforeLastLine, -1)
    call add(l:code, '//')
    call add(l:code, 'foo();')
    let l:lastLineLength = len(l:code[-1])

    "This will not actually affect the brace style, we are only indenting here
    "and can't break lines, but if the bracing style is allman and dfmt is
    "configured to use one of the other bracing styles the opening brace will
    "be indented weirdly.
    let l:dfmtArgs = [
                \'--brace_style', 'allman',
                \]


    let l:formattedCode = dutyl#util#splitLines(dutyl#core#runToolIgnoreStderr('dfmt', l:dfmtArgs, l:code))

    "Find the mark we placed:
    let l:lineIndex = s:findLineIndexAfterMarker(l:markBeforeLastLine, l:formattedCode)
    let l:formattedLine = l:formattedCode[l:lineIndex]
    let l:formattedIndent = strwidth(s:getIndentFrom(l:formattedLine))

    if l:origLineBeforeIndex < 0
        return l:formattedIndent
    else
        let l:lineBeforeIndex = s:findLineIndexAfterMarker(l:markBeforeLineBeforeLast, l:formattedCode)
        let l:formattedLineBefore = l:formattedCode[l:lineBeforeIndex]
        let l:formattedIndentBefore = strwidth(s:getIndentFrom(l:formattedLineBefore))

        let l:result = l:formattedIndent - l:formattedIndentBefore + l:origIndentOfLineBefore
        if l:result < 0
            return 0
        else
            return l:result
        endif
    endif
endfunction
