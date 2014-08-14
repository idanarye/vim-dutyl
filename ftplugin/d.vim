setlocal omnifunc=dutyl#dComplete

command! -buffer DUddoc call dutyl#displayDDocForSymbolUnderCursor()
