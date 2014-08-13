let s:CONFIG_FILE_NAME='.dutyl.configFile'

function! dutyl#configFile#new()
    let l:result={}
    let l:result=extend(l:result,s:functions)
    return l:result
endfunction

let s:functions={}

function! s:functions.importPaths() dict
    let l:config=s:readConfigFile()
    return l:config
endfunction

function! s:readConfigFile()
    let l:result={
                \'importPaths':[],
                \}
    if !empty(glob(s:CONFIG_FILE_NAME))
        let l:result=extend(l:result,eval(join(readfile(s:CONFIG_FILE_NAME),"\n")))
    endif

    return l:result
endfunction

function! s:writeConfigFile(config)
    call writefile(split(string(a:config),"\n"),s:CONFIG_FILE_NAME)
endfunction

function! s:editStringListField(stringListFieldName)
    let l:config=s:readConfigFile()
    let l:stringList=l:config[a:stringListFieldName]
    new
    call setline(1,l:stringList)
    let b:stringListFieldName=a:stringListFieldName
    "Not setting &buftype to nofile, since we DO need to be able to save the
    "buffer. BufWriteCmd prevents it from being saved to the system
    setlocal bufhidden=wipe
    setlocal nonumber
    setlocal norelativenumber
    execute 'silent file :dutyl:configFile:'.a:stringListFieldName
    autocmd BufWriteCmd <buffer> call s:writeStringListField(b:stringListFieldName)
endfunction

function! s:writeStringListField(stringListFieldName)
    let l:config=s:readConfigFile()
    let l:config[a:stringListFieldName]=filter(getline(1,'$'),'!empty(v:val)')
    call s:writeConfigFile(l:config)
    setlocal nomodified
endfunction

function! dutyl#configFile#editImportPaths()
    call s:editStringListField('importPaths')
endfunction
