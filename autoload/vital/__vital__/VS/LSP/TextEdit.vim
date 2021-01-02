"
" _vital_loaded
"
function! s:_vital_loaded(V) abort
  let s:Text = a:V.import('VS.LSP.Text')
  let s:Position = a:V.import('VS.LSP.Position')
endfunction

"
" _vital_depends
"
function! s:_vital_depends() abort
  return ['VS.LSP.Text']
endfunction

"
" fixeol
"
let s:_fixeol = v:false
function! s:fixeol(bool) abort
  let s:_fixeol = a:bool
endfunction

"
" apply
"
function! s:apply(path, text_edits) abort
  let l:current_bufname = bufname('%')
  let l:target_bufname = a:path
  let l:cursor_position = s:Position.cursor()

  let l:old_virtualedit = &virtualedit
  let l:old_whichwrap = &whichwrap
  let l:old_winview = winsaveview()
  let l:old_reg = getreg('x')

  let &virtualedit = 'onemore'
  let &whichwrap = 'h'

  let l:fix_cursor = v:false
  call s:_switch(l:target_bufname)
  for l:text_edit in s:_normalize(a:text_edits)
    call setreg('x', l:text_edit.newText, 'c')
    let l:fix_cursor = l:fix_cursor || s:_apply(bufnr(l:target_bufname), l:text_edit, l:cursor_position)
  endfor
  call s:_switch(l:current_bufname)

  let &virtualedit = l:old_virtualedit
  let &whichwrap = l:old_whichwrap
  call winrestview(l:old_winview)
  call setreg('x', l:old_reg)

  if l:fix_cursor && bufnr(l:current_bufname) == bufnr(l:target_bufname)
    call cursor(s:Position.lsp_to_vim('%', l:cursor_position))
  endif
endfunction

"
" _apply
"
function! s:_apply(bufnr, text_edit, cursor_position) abort
  " prepare.
  let l:start = s:Position.lsp_to_vim(a:bufnr, a:text_edit.range.start)
  let l:end = s:Position.lsp_to_vim(a:bufnr, a:text_edit.range.end)
  let l:lines = s:Text.split_by_eol(a:text_edit.newText)
  let l:lines_len = len(l:lines)
  let l:range_len = (l:end[0] - l:start[0]) + 1

  " apply edit.
  let l:old_reg = getreg('x')
  if l:start[0] == l:end[0] && l:start[1] == l:end[1]
    execute printf("keepjumps noautocmd silent! normal! %sG%s|\"xP", l:start[0], l:start[1])
  else
    execute printf("keepjumps noautocmd silent! normal! %sG%s|v%sG%s|h\"_d\"xP", l:start[0], l:start[1], l:end[0], l:end[1])
  endif

  " fix cursor.
  if a:text_edit.range.end.line < a:cursor_position.line
    let a:cursor_position.line += l:lines_len - l:range_len
    return v:true
  elseif a:text_edit.range.end.line == a:cursor_position.line && a:text_edit.range.end.character <= a:cursor_position.character
    let a:cursor_position.line += l:lines_len - l:range_len
    let a:cursor_position.character += strchars(l:lines[-1]) - a:text_edit.range.end.character
    return v:true
  endif
  return v:false
endfunction

"
" _normalize
"
function! s:_normalize(text_edits) abort
  let l:text_edits = type(a:text_edits) == type([]) ? a:text_edits : [a:text_edits]
  let l:text_edits = s:_range(l:text_edits)
  let l:text_edits = sort(copy(l:text_edits), function('s:_compare', [], {}))
  let l:text_edits = s:_check(l:text_edits)
  return reverse(l:text_edits)
endfunction

"
" _range
"
function! s:_range(text_edits) abort
  for l:text_edit in a:text_edits
    if l:text_edit.range.start.line > l:text_edit.range.end.line || (
    \   l:text_edit.range.start.line == l:text_edit.range.end.line &&
    \   l:text_edit.range.start.character > l:text_edit.range.end.character
    \ )
      let l:text_edit.range = { 'start': l:text_edit.range.end, 'end': l:text_edit.range.start }
    endif
  endfor
  return a:text_edits
endfunction

"
" _check
"
function! s:_check(text_edits) abort
  if len(a:text_edits) > 1
    let l:range = a:text_edits[0].range
    for l:text_edit in a:text_edits[1 : -1]
      if l:range.end.line > l:text_edit.range.start.line || (
      \   l:range.end.line == l:text_edit.range.start.line &&
      \   l:range.end.character > l:text_edit.range.start.character
      \ )
        throw 'VS.LSP.TextEdit: range overlapped.'
      endif
      let l:range = l:text_edit.range
    endfor
  endif
  return a:text_edits
endfunction

"
" _compare
"
function! s:_compare(text_edit1, text_edit2) abort
  let l:diff = a:text_edit1.range.start.line - a:text_edit2.range.start.line
  if l:diff == 0
    return a:text_edit1.range.start.character - a:text_edit2.range.start.character
  endif
  return l:diff
endfunction

"
" _switch
"
function! s:_switch(path) abort
  if bufnr(a:path) >= 0
    execute printf('keepalt keepjumps %sbuffer!', bufnr(a:path))
  else
    execute printf('keepalt keepjumps edit! %s', fnameescape(a:path))
  endif
endfunction

