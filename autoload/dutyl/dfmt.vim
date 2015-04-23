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

function! s:functions.calcIndentForLastLineOfCode(code) abort
    if empty(a:code)
        return -1
    endif
    if type(a:code) == type('')
        let l:code = dutyl#util#splitLines(a:code)
    else
        let l:code = a:code
    endif

    let l:markBeforeLastLine = 'dutylmark'.localtime()
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
    let l:lineIndex = len(l:formattedCode) - 1
    while 0 <= l:lineIndex
        let l:line = l:formattedCode[l:lineIndex]
        if len(l:markBeforeLastLine) < len(l:line)
            if l:line[-len(l:markBeforeLastLine) : -1] == l:markBeforeLastLine
                break
            endif
        endif
        let l:lineIndex -= 1
    endwhile
    if l:lineIndex < 0
        return -1
    endif
    let l:lineIndex += 1
    if empty(l:formattedCode[l:lineIndex])
        let l:lineIndex += 1
    endif

    return strwidth(s:getIndentFrom(l:code)) - strwidth(s:getIndentFrom(l:formattedCode)) + strwidth(matchstr(l:formattedCode[l:lineIndex], '\v^\_s*\ze\S'))
endfunction
