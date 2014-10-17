INTRODUCTION
============

Dutyl operates various Dlang tools to help you program D in Vim. Instead of
having a separate plugin for each tool, Dutyl can use multiple plugins and
use them together - for example, use DUB to get a list of import paths the
project is using and pass that list to DCD to get autocompleting for symbols
that come from libraries. Dutyl has a module(/plugin) system that allows tools
to back up each other - so for example if a project doesn't use DUB, Dutyl can
back up reading the import paths from a static configuration file.

Currently supported features:

* Getting the imports list from DUB or from a configuration file
* Autocompletion using DCD
* Finding DDoc using DCD
* Finding declarations using DCD or Dscanner
* Syntax and style checks using Dscanner
* Updating the tags file using Dscanner
* Recognizing the project's root and running commands there


REQUIREMENTS
============

Dutyl requires the tools that it uses. If you want it to use DUB to get info
about the project, you need [DUB](http://code.dlang.org/download). If you want
it to use DCD for autocompletion, you need
[DCD](https://github.com/Hackerpilot/DCD)(currently tested with version 0.4.0).
If you want it to use Dscanner, you need
[Dscanner](https://github.com/Hackerpilot/Dscanner).


CONFIGURATION
=============

Use `g:dutyl_stdImportPaths` to specify the standard library import paths.
```vim
let g:dutyl_stdImportPaths=['/usr/include/dlang/dmd']
```
You must either set `g:dutyl_stdImportPaths` or configure these paths in DCD
itself, or else DCD won't be able to recognize standard library symbols.

If you want to never add the closing paren in calltips completions, set
`g:dutyl_neverAddClosingParen` to 1:
```vim
let g:dutyl_neverAddClosingParen=1
```

Dutyl will assume that tools are in the system's PATH. If they are not, you'll
have to supply the path for them using `dutyl#register#tool` like so:
```vim
call dutyl#register#tool('dcd-client','/path/to/DCD/dcd-client')
call dutyl#register#tool('dcd-server','/path/to/DCD/dcd-server')
```
**Note**: If you are using a plugin manager(like Pathogen or Vundle), make sure
that you only call `dutyl#register#tool` after you run the plugin manager's
command for updating the runtime path(`pathogen#infect` in case of Pathogen,
`vundle#end` in case of Vundle, or whatever the command is for whatever the
tool you are using).

Under Windows, Dutyl uses [VimProc](https://github.com/Shougo/vimproc.vim) when
available to prevent opening a console windows every time a command needs to be
ran. To prevent using VimProc, set `g:dutyl_dontUseVimProc` to 1:
```vim
let g:dutyl_dontUseVimProc=1
```

Dutyl will use a local file named "tags" for tags. If you want to everride
this, set `g:dutyl_tagsFileName` to the name of the new tags file:
```vim
let g:dutyl_tagsFileName='newnamefortagsfile'
```
Note that the new tags file name will still have to be in `tags` in order
for Vim to recognize it.
