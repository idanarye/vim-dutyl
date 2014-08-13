
function! dutyl#dub#new()
    let l:result={}
    let l:result.test=function('s:test')
    return l:result
endfunction

function! s:test() dict
    echo 'test function from dub module'
endfunction
