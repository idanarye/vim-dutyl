
function! dutyl#core#create()
    let l:result={}

    let l:modules=[]
    for l:moduleDefinition in dutyl#register#list()
        let l:module=function(l:moduleDefinition.constructor)()
        if !empty(l:module) "Empty module = can not be used
            let l:module.name=l:moduleDefinition.name
            if !has_key(l:module,'supportsFunction')
                let l:module.supportsFunction=function('dutyl#core#supportsFunction')
            endif
            call add(l:modules,l:module)
        endif
    endfor

    let l:result.modules=l:modules
    let l:result.requireFunctions=function('s:requireFunctions')

    return l:result
endfunction

function! dutyl#core#supportsFunction(functionName) dict
    return has_key(self,a:functionName)
endfunction

function! s:requireFunctions(...) dict
    let l:result={'obj':self}
    for l:functionName in a:000
        for l:module in self.modules
            if l:module.supportsFunction(l:functionName)
                let l:result[l:functionName]=l:module[l:functionName]
                break
            endif
            throw 'Function `'.l:functionName.'` is not supported by currently loaded Dutyl modules'
        endfor
    endfor
    return l:result
endfunction
