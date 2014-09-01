"Checks if the path is an absolute path
function! dutyl#util#isPathAbsolute(path) abort
    if has('win32')
        return a:path=~':' || a:path[0]=='%' "Absolute paths in Windows contain : or start with an environment variable
    else
        return a:path[0]=~'\v^[/~$]' "Absolute paths in Linux start with ~(home),/(root dir) or $(environment variable)
    endif
endfunction

"Exactly what it says on the tin
function! dutyl#util#cleanPathFromLastCharacterIfPathSeparator(path) abort
    let l:lastCharacter=a:path[len(a:path)-1]
    if '/'==l:lastCharacter || '\'==l:lastCharacter
        return a:path[0:-2]
    else
        return a:path
    endif
endfunction

"Glob a list of paths
function! dutyl#util#globPaths(paths) abort
    let l:result=[]
    for l:path in a:paths
        let l:result+=glob(l:path,1,1)
    endfor
    return l:result
endfunction

"Convert a list of paths and path patterns to a list of absolute, concrete
"paths without the last path separator.
function! dutyl#util#normalizeImportPaths(paths) abort
    let l:result=dutyl#util#globPaths(a:paths)
    let l:result=map(l:result,'fnamemodify(v:val,":p")')
    let l:result=map(l:result,'dutyl#util#cleanPathFromLastCharacterIfPathSeparator(v:val)')
    let l:result=uniq(l:result)
    return l:result
endfunction
