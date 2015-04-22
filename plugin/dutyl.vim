command! DUreinit call dutyl#core#instance(1)

command! -nargs=1 -bang DUexecute call dutyl#runInProjectRoot('<bang>'.<q-args>)

command! DUConfigFileEditImportPaths call dutyl#configFile#editImportPaths()

command! DUDCDstartServer call dutyl#dcd#startServer()
command! DUDCDstopServer call dutyl#dcd#stopServer()
command! DUDCDclearCache call dutyl#dcd#clearCache()
command! DUDCDrestartServer call dutyl#dcd#stopServer() | call dutyl#dcd#startServer()

command! DUddoc call dutyl#displayDDocForSymbolUnderCursor()
command! -bang -nargs=? DUjump call dutyl#jumpToDeclarationOfSymbol(empty(<q-args>) ? <bang>0 : <q-args>,'')
command! -bang -nargs=? DUsjump call dutyl#jumpToDeclarationOfSymbol(empty(<q-args>) ? <bang>0 : <q-args>,'s')
command! -bang -nargs=? DUvjump call dutyl#jumpToDeclarationOfSymbol(empty(<q-args>) ? <bang>0 : <q-args>,'v')

command! -nargs=* -bang -complete=file DUsyntaxCheck call dutyl#syntaxCheck([<f-args>],'c',<bang>1)
command! -nargs=* -bang -complete=file DUlsyntaxCheck call dutyl#syntaxCheck([<f-args>],'l',<bang>1)
command! -nargs=* -bang -complete=file DUstyleCheck call dutyl#styleCheck([<f-args>],'c',<bang>1)
command! -nargs=* -bang -complete=file DUlstyleCheck call dutyl#styleCheck([<f-args>],'l',<bang>1)

command! -nargs=* -complete=file DUupdateCTags call dutyl#updateCTags([<f-args>])

call dutyl#register#module('dub','dutyl#dub#new',0)
call dutyl#register#module('dcd','dutyl#dcd#new',20)
call dutyl#register#module('dfmt','dutyl#dfmt#new',30)
call dutyl#register#module('dscanner','dutyl#dscanner#new',60)
call dutyl#register#module('configFile','dutyl#configFile#new',100)
