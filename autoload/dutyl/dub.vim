function! dutyl#dub#new() abort
    if !filereadable('dub.json')
        return {}
    endif
    if !dutyl#core#toolExecutable('dub')
        return {}
    endif

    let l:result={}
    let l:result=extend(l:result,s:functions)
    return l:result
endfunction

let s:functions={}

"Return all the import paths DCD knows about, plus the ones in
"g:dutyl_stdImportPaths
function! s:functions.importPaths() dict abort
    let l:result=exists('g:dutyl_stdImportPaths') ? copy(g:dutyl_stdImportPaths) : []

    let l:info=s:dubDescribe()
    for l:package in l:info.packages
        for l:importPath in l:package.importPaths
            if dutyl#util#isPathAbsolute(l:importPath)
                call add(l:result,l:importPath)
            else
                let l:absoluteImportPath=globpath(l:package.path,l:importPath)
                if !empty(l:absoluteImportPath)
                    call add(l:result,l:absoluteImportPath)
                endif
            endif
        endfor
    endfor

    return l:result
endfunction

"Calls 'dub describe' and turns the result to Vim's data types
function! s:dubDescribe() abort
    "let l:result=system('dub describe')
    let l:result=dutyl#core#runTool('dub','describe')
    "Replace true with 1 and false with 0
    let l:result=substitute(l:result,'\vtrue\,?[\n\r]','1\n','g')
    let l:result=substitute(l:result,'\vfalse\,?[\n\r]','0\n','g')

    "Remove linefeeds
    let l:result=substitute(l:result,'\v[\n\r]',' ','g')
    return eval(l:result)
endfunction
