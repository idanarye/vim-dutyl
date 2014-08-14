function! dutyl#register#resetModules() abort
    let s:registeredModules={}
endfunction

function! dutyl#register#resetTools() abort
    let s:registeredTools={}
endfunction

function! dutyl#register#module(name,constructor,priority) abort
    if !exists('s:registeredModules')
        let s:registeredModules={}
    end

    let s:registeredModules[a:name]={'name':a:name,'constructor':a:constructor,'priority':a:priority}
endfunction

function! dutyl#register#tool(name,path) abort
    if !exists('s:registeredTools')
        let s:registeredTools={}
    end

    let s:registeredTools[a:name]=a:path
endfunction

function! dutyl#register#getToolPath(name) abort
    if !exists('s:registeredTools')
        return a:name
    end

    return get(s:registeredTools,a:name,a:name)
endfunction

function! s:sortModulesByPriority(module1,module2) abort
    if a:module1.priority==a:module2.priority
        return 0
    elseif a:module1.priority<a:module2.priority
        return -1
    else
        return 1
    endif
endfunction

function! dutyl#register#list() abort
    if !exists('s:registeredModules')
        return []
    endif
    let l:result=values(s:registeredModules)
    let l:result=sort(l:result,function('s:sortModulesByPriority'))
    return l:result
endfunction
