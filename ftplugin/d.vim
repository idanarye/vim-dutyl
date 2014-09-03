setlocal omnifunc=dutyl#dComplete

command! -buffer DUddoc call dutyl#displayDDocForSymbolUnderCursor()
command! -buffer -nargs=? DUjump 
      \if empty(<q-args>)
      \|call dutyl#jumpToDeclarationOfSymbolUnderCursor()
      \|else
      \|call dutyl#jumpToDeclarationOfSymbol(<q-args>)
      \|endif
