"Checks if the path is an absolute path
function! dutyl#util#isPathAbsolute(path) abort
	if has('win32')
		return a:path=~':' || a:path[0]=='%' "Absolute paths in Windows contain : or start with an environment variable
	else
		return a:path[0]=~'\v^[/~$]' "Absolute paths in Linux start with ~(home),/(root dir) or $(environment variable)
	endif
endfunction

"Exactly what it says on the tin
function! dutyl#util#cleanPathFromLastCharacterIfPathSeparator(path) abort
	let l:lastCharacter=a:path[len(a:path)-1]
	if '/'==l:lastCharacter || '\'==l:lastCharacter
		return a:path[0:-2]
	else
		return a:path
	endif
endfunction
