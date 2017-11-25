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
function! dutyl#util#normalizePaths(paths) abort
    let l:result=dutyl#util#globPaths(a:paths)
    let l:result=map(l:result,'fnamemodify(v:val,":p")')
    let l:result=map(l:result,'dutyl#util#cleanPathFromLastCharacterIfPathSeparator(v:val)')
    let l:result=dutyl#util#unique(l:result)
    return l:result
endfunction

"Use with argument 's' to split the window horizontally or with 'v' to split
"vertically.
function! dutyl#util#splitWindowBasedOnArgument(splitType)
    if 's'==a:splitType
        split
    elseif 'v'==a:splitType
        vsplit
    endif
endfunction

"Split based on any newline character.
function! dutyl#util#splitLines(text) abort
    if type([])==type(a:text)
        return a:text
    elseif type('')==type(a:text)
        return split(a:text,'\v\r\n|\n|\r')
    endif
endfunction

"Exactly what it says on the tin. Arguments:
" - newItems: a list in the same format as the one you send to
"   setqflist/setloclist
" - targetList: 'c'/'q' for the quickfix list, 'l' for the location list
" - jump: nonzero value to automatically jump to the first entry
function! dutyl#util#setQuickfixOrLocationList(newItems,targetList,jump) abort
    if 'c'==a:targetList || 'q'==a:targetList
        call setqflist(a:newItems)
    elseif 'l'==a:targetList
        call setloclist(0,a:newItems)
    endif
    if a:jump && !empty(a:newItems)
        if 'c'==a:targetList || 'q'==a:targetList
            cc 1
        elseif 'l'==a:targetList
            ll 1
        endif
    endif
endfunction

"Exactly what it says on the tin
function! dutyl#util#unique(list) abort
    if exists('*uniq') "Use built-in uniq if possible
        return uniq(sort(a:list))
    endif
    if empty(a:list)
        return []
    endif
    let l:sorted=sort(a:list)
    let l:result=[l:sorted[0]]
    for l:entry in l:sorted[1:]
        if l:entry!=l:result[-1]
            call add(l:result,l:entry)
        endif
    endfor
    return l:result
endfunction

"Look for glob patterns up in the directory tree
function! dutyl#util#globInParentDirectories(patterns) abort
    let l:path=getcwd()
    if type([])==type(a:patterns)
        let l:patterns=a:patterns
    else
        let l:patterns=[a:patterns]
    endif
    while 1
        let l:matches=filter(map(copy(l:patterns),'dutyl#util#splitLines(globpath(l:path,v:val,1))'),'!empty(v:val)')
        if !empty(l:matches)
            let l:result=[]
            for l:match in l:matches
                let l:result+=l:match
            endfor
            return l:result
        endif
        let l:newPath=fnamemodify(l:path,':h')
        if len(l:path)<=len(l:newPath)
            return []
        endif
        let l:path=l:newPath
    endwhile
    return l:path
endfunction

"lcd to the directory, run the function or command, and return to the current
"directory
function! dutyl#util#runInDirectory(directory,action,...) abort
    let l:cwd=fnameescape(getcwd())
    try 
        let l:directory=fnameescape(a:directory)
        execute 'lcd '.l:directory
        if type(function('tr'))==type(a:action)
            return call(a:action,a:000)
        elseif type('')==type(a:action)
            execute a:action
        endif
    finally
        execute 'lcd '.l:cwd
    endtry
endfunction

"Similar to Vim's inputlist, but adds numbers and a 'more' option for huge
"lists. If no options selected, returns -1(not 0 like inputlist!)
function! dutyl#util#inputList(prompt, options, morePrompt) abort
    let l:takeFrom=0
    while l:takeFrom<len(a:options)
        let l:takeThisTime=&lines-2
        if l:takeFrom+l:takeThisTime<len(a:options)
            let l:more=l:takeThisTime
            let l:takeThisTime-=1
        else
            let l:more=0
        endif

        let l:options=[a:prompt]

        for l:i in range(min([l:takeThisTime,len(a:options)-l:takeFrom]))
            call add(l:options,printf('%i) %s',1+l:i,a:options[l:takeFrom+l:i]))
        endfor
        if l:more
            call add(l:options,printf('%i) %s',l:more,a:morePrompt))
        endif
        let l:selected=inputlist(l:options)
        if l:selected<=0 || len(l:options)<=l:selected
            return -1
        elseif l:more && l:selected<l:more
            return l:takeFrom+l:selected-1
        elseif !l:more && l:selected<len(l:options)
            return l:takeFrom+l:selected-1
        endif

        "Create a new line for the next inputlist's prompt
        echo ' '

        let l:takeFrom+=l:takeThisTime
    endwhile
endfunction
