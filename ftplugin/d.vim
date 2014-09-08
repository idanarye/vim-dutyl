setlocal omnifunc=dutyl#dComplete

command! -buffer DUddoc call dutyl#displayDDocForSymbolUnderCursor()
command! -bang -buffer -nargs=? DUjump call dutyl#jumpToDeclarationOfSymbol(empty(<q-args>) ? <bang>0 : <q-args>,'')
command! -bang -buffer -nargs=? DUsjump call dutyl#jumpToDeclarationOfSymbol(empty(<q-args>) ? <bang>0 : <q-args>,'s')
command! -bang -buffer -nargs=? DUvjump call dutyl#jumpToDeclarationOfSymbol(empty(<q-args>) ? <bang>0 : <q-args>,'v')
