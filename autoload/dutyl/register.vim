function! dutyl#register#reset()
    let s:registeredModules={}
endfunction

function! dutyl#register#register(name,constructor,priority)
    if !exists('s:registeredModules')
        let s:registeredModules={}
    end

    let s:registeredModules[a:name]={'name':a:name,'constructor':a:constructor,'priority':a:priority}
endfunction

function! s:sortModulesByPriority(module1,module2)
    if a:module1.priority==a:module2.priority
        return 0
    elseif a:module1.priority<a:module2.priority
        return -1
    else
        return 1
    endif
endfunction

function! dutyl#register#list()
    let l:result=values(s:registeredModules)
    let l:result=sort(l:result,function('s:sortModulesByPriority'))
    return l:result
endfunction
