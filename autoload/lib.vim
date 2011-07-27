" File: lib.vim
" Author: Andrew Radev
" Description: The place for any functions I might decide I need.

" Function to check if the cursor is currently in a php block. Useful for
" autocompletion. Ripped directly from phpcomplete.vim
function! lib#CursorIsInsidePhpMarkup()
  let phpbegin = searchpairpos('<?', '', '?>', 'bWn',
        \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? "string\|comment"')
  let phpend   = searchpairpos('<?', '', '?>', 'Wn',
        \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? "string\|comment"')
  return !(phpbegin == [0,0] && phpend == [0,0])
endfunction

" Toggle between settings:
function! lib#MapToggle(key, opt)
  let cmd = ':set '.a:opt.'! \| set '.a:opt."?\<CR>"
  exec 'nnoremap '.a:key.' '.cmd
endfunction

" Capitalize first letter of argument:
" foo -> Foo
function! lib#Capitalize(word)
  return substitute(a:word, '^\w', '\U\0', 'g')
endfunction

" CamelCase underscored word:
" foo_bar_baz -> fooBarBaz
function! lib#CamelCase(word)
  return substitute(a:word, '_\(.\)', '\U\1', 'g')
endfunction

" CamelCase and Capitalize
" foo_bar_baz -> FooBarBaz
function! lib#CapitalCamelCase(word)
  return lib#Capitalize(lib#CamelCase(a:word))
endfunction

" Underscore CamelCased word:
" FooBarBaz -> foo_bar_baz
function! lib#Underscore(word)
  let result = lib#Lowercase(a:word)
  return substitute(result, '\([A-Z]\)', '_\l\1', 'g')
endfunction

" Lowercase first letter of argument:
" Foo -> foo
function! lib#Lowercase(word)
  return substitute(a:word, '^\w', '\l\0', 'g')
endfunction

" Ripped directly from haskellmode.vim
function! lib#UrlEncode(string)
  let pat  = '\([^[:alnum:]]\)'
  let code = '\=printf("%%%02X",char2nr(submatch(1)))'
  let url  = substitute(a:string,pat,code,'g')
  return url
endfunction

" Ripped directly from unimpaired.vim
function! lib#UrlDecode(str)
  let str = substitute(substitute(substitute(a:str,'%0[Aa]\n$','%0A',''),'%0[Aa]','\n','g'),'+',' ','g')
  return substitute(str,'%\(\x\x\)','\=nr2char("0x".submatch(1))','g')
endfunction

" Join the list of items given with the current path separator, escaping the
" backslash in Windows for use in regular expressions.
function! lib#RxPath(...)
  let ps = has('win32') ? '\\' : '/'
  return join(a:000, ps)
endfunction

" Checks to see if {needle} is in {haystack}.
function! lib#InString(haystack, needle)
  return (stridx(a:haystack, a:needle) != -1)
endfunction

" Trimming functions. Should be obvious.
function! lib#Ltrim(s)
  return substitute(a:s, '^\s\+', '', '')
endfunction
function! lib#Rtrim(s)
  return substitute(a:s, '\s\+$', '', '')
endfunction
function! lib#Trim(s)
  return lib#Rtrim(lib#Ltrim(a:s))
endfunction

" Wraps a string with another string if string is not empty, in which case
" returns the empty string
" ('/', 'foo') ->  '/foo/'
" ('/', '') ->  ''
function! lib#Wrap(surrounding, string)
  if a:string == ''
    return ''
  else
    return a:surrounding.a:string.a:surrounding
  endif
endfunction

" Extract a regex match from a string.
function! lib#ExtractRx(expr, pat, sub)
  let rx = a:pat

  if stridx(a:pat, '^') != 0
    let rx = '^.*'.rx
  endif

  if strridx(a:pat, '$') + 1 != strlen(a:pat)
    let rx = rx.'.*$'
  endif

  return substitute(a:expr, rx, a:sub, '')
endfunction

" Create an outline of buffer by folding according to pattern
function! lib#Outline(pattern)
  if exists('b:outlined') " Un-outline it
    FoldEndFolding
    unlet b:outlined
  else
    exe "FoldMatching ".a:pattern." -1"
    let b:outlined = 1
    setlocal foldenable
  endif
endfunction

" Execute a command, leaving the cursor on the current line
function! lib#InPlace(command)
  let save_cursor = getpos(".")
  exe a:command
  call setpos('.', save_cursor)
endfunction

" Highlighting custom stuff
function! lib#HiArea(syn, from, to)
  let line_to   = a:to[0] + 1
  let col_to    = a:to[1] + 1
  let line_from = a:from[0] - 1
  let col_from  = a:from[1] - 1

  let line_from = line_from >= 0 ? line_from : 0
  let col_from  = col_from  >= 0 ? col_from  : 0

  let pattern = ''
  let pattern .= '\%>'.line_from.'l'
  let pattern .= '\%<'.line_to.'l'
  let pattern .= '\%>'.col_from.'c'
  let pattern .= '\%<'.col_to.'c'

  call matchadd(a:syn, pattern)
endfunction

function! lib#HiCword(syn)
  normal! "zyiw
  let from = searchpos(@z, 'bWcn')
  let to   = searchpos(@z, 'eWcn')

  call lib#HiArea(a:syn, from, to)

  return [from, to]
endfunction

function! lib#HiCwordOrBrace(syn)
  normal! v"zy

  if @z =~ '[{\[()\]}]'
    let [_, line, col, _] = getpos('.')
    let pos = [line, col]

    call lib#HiArea(a:syn, pos, pos)
    return [pos, pos]
  else
    return lib#HiCword(a:syn)
  end
endfunction

function! lib#MarkMatches(syn)
  call clearmatches()
  let save_cursor = getpos('.')

  let b:match_positions = []

  " Get the first position to highlight
  let pos = lib#HiCwordOrBrace(a:syn)
  while index(b:match_positions, pos) == -1
    call add(b:match_positions, pos)
    normal %

    " Get the next position
    let pos = lib#HiCword(a:syn)
  endwhile

  call setpos('.', save_cursor)
endfunction

" The vim includeexpr
function! lib#VimIncludeExpression(fname)
  if getline('.') =~ '^runtime'
    for dir in split(&rtp, ',')
      let fname = dir.'/'.a:fname

      if(filereadable(fname))
        return fname
      endif
    endfor
  endif

  return a:fname
endfunction
