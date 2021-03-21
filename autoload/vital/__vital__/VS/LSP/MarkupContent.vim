"
" _vital_loaded
"
function! s:_vital_loaded(V) abort
  let s:Text = a:V.import('VS.LSP.Text')
endfunction

"
" _vital_depends
"
function! s:_vital_depends() abort
  return ['VS.LSP.Text']
endfunction

"
" normalize
"
function! s:normalize(markup_content) abort
  if type(a:markup_content) == type('')
    return s:_compact(a:markup_content)
  elseif type(a:markup_content) == type([])
    return s:_compact(join(a:markup_content, "\n"))
  elseif type(a:markup_content) == type({})
    let l:string = a:markup_content.value
    if has_key(a:markup_content, 'language')
      let l:string = '```' . a:markup_content.language . ' ' . l:string . ' ```'
    elseif get(a:markup_content, 'kind', 'plaintext') ==# 'plaintext'
      let l:string = '```plaintext ' . l:string . ' ```'
    endif
    return s:_compact(l:string)
  endif
endfunction

let s:_compact_fenced_start = '\%(^\|' . "\n" . '\)\s*'
let s:_compact_fenced_end = '\s*\%($\|' . "\n" . '\)'
let s:_compact_fenced_empty = '\s*\%(\s\|' . "\n" . '\)\s*'

"
" _compact
"
function! s:_compact(string) abort
  " normalize eol.
  let l:string = s:Text.normalize_eol(a:string)

  " compact fenced code block start.
  let l:string = substitute(l:string, s:_compact_fenced_start . '```\s*\w\+\s*\zs' . s:_compact_fenced_empty, ' ', 'g')

  " compact fenced code block end.
  let l:string = substitute(l:string, s:_compact_fenced_empty . '\ze```' . s:_compact_fenced_end, ' ', 'g')

  " trim first/last whitespace.
  let l:string = substitute(l:string, '^' . s:_compact_fenced_empty . '\|' . s:_compact_fenced_empty . '$', '', 'g')

  return l:string
endfunction

