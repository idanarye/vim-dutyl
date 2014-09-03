function! dutyl#dscanner#new() abort
    if !dutyl#core#toolExecutable('dscanner')
        return {}
    endif

    let l:result={}
    let l:result=extend(l:result,s:functions)
    return l:result
endfunction

let s:functions={}


"Retrieve declaration location using Dscanner
function! s:functions.declarationsOfSymbol(args) abort
    "Register the import paths:
    "call s:registerImportPaths(a:args.importPaths)

    "Run Dscanner
    let l:scanResult=dutyl#core#runTool('dscanner',['-d',a:args.symbol])

    "Try looking at the import paths. Don't do it if we can find the symbol
    "here - scanning all the import paths takes a very long time!
    if 0!=dutyl#core#shellReturnCode() || empty(l:scanResult)
	let l:scanResult=dutyl#core#runTool('dscanner',['-d',a:args.symbol]+a:args.importPaths)
    endif

    if 0!=dutyl#core#shellReturnCode()
	return []
    endif

    let l:result=[]
    for l:resultLine in split(l:scanResult,"\n")
	let l:parsedLine=matchlist(l:resultLine,'\v^(.*)\((\d+)\:(\d+)\)$')
	if 3<len(l:parsedLine)
	    call add(l:result,{
			\'file':fnamemodify(l:parsedLine[1],':p'),
			\'line':l:parsedLine[2],
			\'column':l:parsedLine[3]
			\})
	endif
    endfor

    return l:result
endfunction

"The implementation is identical, but we need two separate functions so we can
"always use Dscanner for manually written symbols even if DCD is running.
let s:functions.declarationsOfSymbolInBuffer=s:functions.declarationsOfSymbol
