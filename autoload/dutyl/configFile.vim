let s:CONFIG_FILE_NAME='.dutyl.configFile'

function! dutyl#configFile#new() abort
    let l:result={}
    let l:result=extend(l:result,s:functions)
    return l:result
endfunction

let s:functions={}

function! s:functions.projectRoot() abort
    let l:configFileMatches=dutyl#util#globInParentDirectories(s:CONFIG_FILE_NAME)
    if empty(l:configFileMatches)
        return ''
    else
        return fnamemodify(l:configFileMatches[0],':h')
    endif
endfunction

function! s:functions.importPaths() abort
    let l:result=exists('g:dutyl_stdImportPaths') ? copy(g:dutyl_stdImportPaths) : []
    let l:result=extend(l:result,s:readConfigFile().importPaths)
    let l:result=dutyl#util#normalizePaths(l:result)
    return l:result
endfunction

function! s:configFilePath(emptyIfNotExist) abort
    let l:configFileMatches=dutyl#util#globInParentDirectories(s:CONFIG_FILE_NAME)
    if empty(l:configFileMatches)
        if a:emptyIfNotExist
            return ''
        else
            return s:CONFIG_FILE_NAME
        endif
    else
        return l:configFileMatches[0]
    endif
endfunction

"Return a Vim Dictionary of the configuration in the configuration file
function! s:readConfigFile() abort
    let l:result={
                \'importPaths':[],
                \}
    if !empty(s:configFilePath(1))
        let l:result=extend(l:result,eval(join(readfile(s:configFilePath(1)),"\n")))
    endif

    return l:result
endfunction

"Write a Vim Dictionary to the configuration file
function! s:writeConfigFile(config) abort
    call writefile(split(string(a:config),"\n"),s:configFilePath(0))
endfunction

"Open a buffer for editing a single configuration field
function! s:editStringListField(stringListFieldName) abort
    let l:config=s:readConfigFile()
    let l:stringList=l:config[a:stringListFieldName]
    new
    call setline(1,l:stringList)
    let b:stringListFieldName=a:stringListFieldName
    "Not setting &buftype to nofile, since we DO need to be able to save the
    "buffer. BufWriteCmd prevents it from being saved to the system
    setlocal bufhidden=wipe
    "Disabling swapfile for this buffer since it's filename can have illegal
    "characters (e.g. on Windows)
    setlocal noswapfile
    setlocal nonumber
    setlocal norelativenumber
    execute 'silent file :dutyl:configFile:'.a:stringListFieldName
    autocmd BufWriteCmd <buffer> call s:writeStringListField(b:stringListFieldName)
    setlocal nomodified
endfunction

"Handle saving the buffer opened by s:editStringListField
function! s:writeStringListField(stringListFieldName) abort
    let l:config=s:readConfigFile()
    let l:config[a:stringListFieldName]=filter(getline(1,'$'),'!empty(v:val)')
    call s:writeConfigFile(l:config)
    setlocal nomodified
endfunction

"Open a buffer for editing the import paths
function! dutyl#configFile#editImportPaths() abort
    call s:editStringListField('importPaths')
endfunction
