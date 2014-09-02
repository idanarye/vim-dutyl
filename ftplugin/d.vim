setlocal omnifunc=dutyl#dComplete

command! -buffer DUddoc call dutyl#displayDDocForSymbolUnderCursor()
command! -buffer DUjump call dutyl#jumpToDeclarationOfSymbolUnderCursor()
