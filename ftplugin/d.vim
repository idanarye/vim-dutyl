setlocal omnifunc=dutyl#dComplete

command! -buffer DutylDDoc call dutyl#displayDDocForSymbolUnderCursor()
