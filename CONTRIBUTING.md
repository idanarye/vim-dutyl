# Contributing

* Please keep the scope of this project in mind. Dutyl is about tool integration
- if your contribution is not using D tools, and can be run on a machine that
doesn't have any of the D tools installed, it's probably not a good fit for
Dutyl, and you should try sending it to
[the d.vim plugin](https://github.com/JesseKPhillips/d.vim) instead.
For example, syntax highlighting based on Vim regular syntax highlighting
facilities doesn't belong here, but syntax highlighting based on some tool that
uses libdparse or something it might be a good fit.

* At the beginning of `doc/dutyl.txt` there is a line that specifies the
  current version of Dutyl. When there are changes in the code but a new
  version is not yet released, there should be a `+` after the version - e.g.
  `Version: 1.2.3+` - to indicate that this is a different, mid-version. If
  that `+` is not there already, please add it as part of the PR.
