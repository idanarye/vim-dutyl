setlocal omnifunc=dutyl#dComplete

if dutyl#register#toolExecutable('dfmt')
    setlocal formatexpr=dutyl#formatExpressionInvoked()
    setlocal indentexpr=dutyl#indentExpressionInvoked()
endif
