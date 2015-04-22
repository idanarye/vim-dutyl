function! dutyl#dfmt#new() abort
    if !dutyl#core#toolExecutable('dfmt')
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
