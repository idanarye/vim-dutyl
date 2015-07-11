" Vim syntax file
" Language:     dcov (dlang coverage testing output)
" Maintainer:   Joakim Brannstrom <joakim.brannstrom@gmx.com>
" Last Change:  2015-07-10

" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" Source lines
syn match dcovNoCode            "^\s*|.*"
syn match dcovNotExecuted       "^\s*0\+|.*"
syn match dcovExecuted          "^\s*[1-9]\d*|.*"

" Coverage statistic
syn match dcovFile              contained "^.\{-}\s\+\( is \)\@!"
syn match dcovPartial           contained "\d\+% cov\w*"
syn match dcovFull              contained "100% cov\w*"
syn match dcovLow               contained "[1-3]\=\d\=% cov\w*"
syn match dcovNone              contained "0% cov\w*"
syn match dcovStat              "^\(.\{0,7}|\)\@!.*$" contains=dcovFull,dcovPartial,dcovNone,dcovFile,dcovLow

" Define the default highlighting.
" Only used when an item doesn't have highlighting yet
hi def link dcovNotExecuted             Constant
hi def link dcovExecuted                Type
hi def link dcovNoCode                  Comment
hi def link dcovFull                    PreProc
hi def link dcovFile                    Identifier
hi def link dcovNone                    Error
hi def link dcovLow                     Operator
hi def link dcovPartial                 Structure

let b:current_syntax = "dcov"
