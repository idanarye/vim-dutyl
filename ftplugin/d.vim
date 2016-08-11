setlocal omnifunc=dutyl#dComplete

if dutyl#register#toolExecutable('dfmt')
    if !get(g:, 'dutyl_dontHandleFormat')
        setlocal formatexpr=dutyl#formatExpressionInvoked()
    endif
    if !get(g:, 'dutyl_dontHandleIndent')
        setlocal indentexpr=dutyl#indentExpressionInvoked()
    endif
endif
