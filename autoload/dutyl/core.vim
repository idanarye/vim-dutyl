"Create and return the instance object. If there already is an instance object
"don't re-create it - unless the argument reinit is not-empty
function! dutyl#core#instance(reinit) abort
    if !exists('s:instance') || !empty(a:reinit)
        let s:instance=dutyl#core#create()
    endif
    return s:instance
endfunction

function! dutyl#core#requireFunctions(...) abort
    return call(dutyl#core#instance(0).requireFunctions,a:000,s:instance)
endfunction

"Create the base Dutyl object and load all modules to it
function! dutyl#core#create() abort
    let l:result={}

    let l:modules=[]
    for l:moduleDefinition in dutyl#register#list()
        let l:module=function(l:moduleDefinition.constructor)()
        if !empty(l:module) "Empty module = can not be used
            let l:module.name=l:moduleDefinition.name
            if !has_key(l:module,'checkFunction')
                let l:module.checkFunction=function('s:checkFunction')
            endif
            call add(l:modules,l:module)
        endif
    endfor

    let l:result.modules=l:modules
    let l:result.requireFunctions=function('s:requireFunctions')

    return l:result
endfunction

"Base function for testing if a module supports a function
function! s:checkFunction(functionName) dict abort
    return !has_key(self,a:functionName)
endfunction

"Creates an object with the required functions from the modules, based on
"module priority
function! s:requireFunctions(...) dict abort
    let l:result={'obj':self}
    for l:functionName in a:000
        if exists('l:Function')
            unlet l:Function
        endif
        let l:reasons=[]
        for l:module in self.modules
            unlet! l:reason
            let l:reason=l:module.checkFunction(l:functionName)
            if empty(l:reason)
                "let l:result[l:functionName]=l:module[l:functionName]
                let l:Function=l:module[l:functionName]
                break
            elseif type('')==type(l:reason)
                let l:reasons=add(l:reasons,l:reason)
            endif
        endfor
        if exists('l:Function')
            let l:result[l:functionName]=l:Function
        else
            let l:errorMessage='Function `'.l:functionName.'` is not supported by currently loaded Dutyl modules.'
            if !empty(l:reasons)
                let l:errorMessage=l:errorMessage.' Possible reasons: '.join(l:reasons,', ')
            endif
            throw l:errorMessage
        endif
    endfor
    return l:result
endfunction

"Return 1 if it's OK to use VimProc
function! s:useVimProcInWindows()
    if !exists(':VimProcBang')
        return 0
    elseif !exists('g:dutyl_dontUseVimProc')
        return 1
    else
        return empty(g:dutyl_dontUseVimProc)
    endif
endfunction

"Use vimproc if available under windows for escaping characters - because
"that's what the dutyl#core#system command will use!
function! dutyl#core#shellescape(string) abort
    if has('win32') && s:useVimProcInWindows() "We don't need vimproc when we use linux
        return vimproc#shellescape(a:string)
    else
        return shellescape(a:string)
    endif
endfunction

"Use vimproc if available under windows to prevent opening a console window
function! dutyl#core#system(command,...) abort
    if has('win32') && s:useVimProcInWindows() "We don't need vimproc when we use linux
        if empty(a:000)
            return vimproc#system(a:command)
        else
            return vimproc#system(a:command,a:000[0])
        endif
    else
        if empty(a:000)
            return system(a:command)
        else
            return system(a:command,a:000[0])
        endif
    endif
endfunction

"Returns the return code from the last run of dutyl#core#system
function! dutyl#core#shellReturnCode() abort
    if has('win32') && s:useVimProcInWindows() "We don't need vimproc when we use linux
        return vimproc#get_last_status()
    else
        return v:shell_error
    endif
endfunction

"Create the command line for running a tool
function! s:createRunToolCommand(tool,args) abort
    let l:tool=dutyl#register#getToolPath(a:tool)
    if !executable(l:tool)
        throw '`'.l:tool.'` is not executable'
    endif
    let l:result=dutyl#core#shellescape(l:tool)
    if type('')==type(a:args)
        let l:result=l:result.' '.a:args
    elseif type([])==type(a:args)
        for l:arg in a:args
            let l:result=l:result.' '.dutyl#core#shellescape(l:arg)
        endfor
    endif
    return l:result
endfunction

"Like s:createRunToolCommand, but doesn't try to use VimProc even if Dutyl is
"configured to use it. This is used when we want to run things in the
"background.
function! s:createRunToolCommandIgnoreVimproc(tool,args) abort
    let l:tool=dutyl#register#getToolPath(a:tool)
    if !executable(l:tool)
        throw '`'.l:tool.'` is not executable'
    endif
    let l:result=shellescape(l:tool)
    if type('')==type(a:args)
        let l:result=l:result.' '.a:args
    elseif type([])==type(a:args)
        for l:arg in a:args
            let l:result=l:result.' '.shellescape(l:arg)
        endfor
    endif
    return l:result
endfunction

"Run a tool and return the result
function! dutyl#core#runTool(tool,args,...) abort
    return call(function('dutyl#core#system'),[s:createRunToolCommand(a:tool,a:args)]+a:000)
endfunction

"Check if a tool is executable. If not - it can not be used
function! dutyl#core#toolExecutable(tool) abort
    return executable(dutyl#register#getToolPath(a:tool))
endfunction

"Run a tool in the background
function! dutyl#core#runToolInBackground(tool,args) abort
    if has('win32')
        silent execute '!start '.s:createRunToolCommandIgnoreVimproc(a:tool,a:args)
    else
        silent execute '!'.s:createRunToolCommand(a:tool,a:args).' > /dev/null &'
    endif
endfunction

"Return the byte position. The arguments are the line and the column:
" - Use current line if line argument not supplied. Can be string
" - Use current column if column argument not supplied. Must be numeric
" Always uses unix file format.
function! dutyl#core#bytePosition(...) abort
    let l:line=get(a:000,0,'.')
    let l:column=get(a:000,1,col('.'))

    let l:oldFileFormat=&fileformat
    try
        set fileformat=unix
        return line2byte(l:line)+l:column-1
    finally
        let &fileformat=l:oldFileFormat
    endtry
endfunction

"Convert byte position in the current buffer to row and column.
" Always uses unix file format.
function! dutyl#core#bytePosition2rowAndColumnCurrentBuffer(bytePos) abort
    let l:oldFileFormat=&fileformat
    try
        set fileformat=unix
	    let l:line=byte2line(a:bytePos)
        let l:lineStart=line2byte(l:line)
        let l:column=a:bytePos-l:lineStart+2
        return {'bytePos':a:bytePos,'line':l:line,'column':l:column}
    finally
        let &fileformat=l:oldFileFormat
    endtry
endfunction

"Convert byte position from another file to row and column.
function! dutyl#core#bytePosition2rowAndColumnAnotherFile(fileName,bytePos) abort
    let l:column=a:bytePos
    let l:lineNumber=1
    for l:line in readfile(a:fileName,1)
        let l:lineLength=strlen(l:line)
        if l:column <= l:lineLength
            return {
                        \'file':a:fileName,
                        \'bytePos':a:bytePos,
                        \'line':l:lineNumber,
                        \'column':l:column+1
                        \}
        endif
        let l:lineNumber+=1
        let l:column-=l:lineLength+1 "The +1 is for the linefeed character!
    endfor
    throw 'Byte position '.a:bytePos.' is larger than file '.a:fileName
endfunction

"Jump to a position supplied in the arguments. Expected keys of args:
" - file: Leave false for current buffer
" - line, column: Exactly what it says on the tin
" - bytePos: Only used if line is not supplied
function! dutyl#core#jumpToPosition(args) abort
    if has_key(a:args,'file')
        let l:bufnr=bufnr(a:args.file)
        if 0<=l:bufnr
            execute 'buffer '.l:bufnr
        else
            execute 'edit '.a:args.file
        endif
    endif
    if has_key(a:args,'line')
        execute ':'.a:args.line
        if has_key(a:args,'column')
            execute 'normal! '.strdisplaywidth(getline('.')[0:a:args.column-1]).'|'
        endif
    elseif
        "We'd rather not use this option - it has some problems with tabs...
        execute 'goto '.a:args.bytePos
    endif
endfunction

"Like dutyl#core#jumpToPosition, but also pushes to the tag stack
function! dutyl#core#jumpToPositionPushToTagStack(args) abort
    "based on http://vim.1045645.n5.nabble.com/Modifying-the-tag-stack-tp1158229p1158240.html
    let l:tmpTagsFile=tempname()
    let l:tagName='dutyl_tag_'.localtime()
    let l:file=fnamemodify(get(a:args,'file',expand('%')),':p')
    let l:oldTags=&tags
    try
        call writefile([l:tagName."\t".l:file."\t0"],l:tmpTagsFile)
        let &tags=l:tmpTagsFile
        execute 'tag '.l:tagName
        call dutyl#core#jumpToPosition(a:args)
    finally
        let &tags=l:oldTags
        call delete(l:tmpTagsFile)
    endtry
endfunction

"Gather the arguments commonly used by the various operations. Extract as many
"common arguments as possible from the supplied dutyl object.
function! dutyl#core#gatherCommonArguments(dutyl) abort
    let l:result={
                \'bufferLines':getline(1,'$'),
                \'bytePos':dutyl#core#bytePosition(),
                \'lineNumber':line('.'),
                \'columnNumber':col('.'),
                \}
    if has_key(a:dutyl,'importPaths')
        let l:result['importPaths']=a:dutyl.importPaths()
    endif

    return l:result
endfunction
