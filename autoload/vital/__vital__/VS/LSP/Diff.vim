"
" compute
"
function! s:compute(old, new) abort
  let l:old = a:old
  let l:new = a:new

  let l:old_len = len(l:old)
  let l:new_len = len(l:new)
  let l:min_len = min([l:old_len, l:new_len])

  " empty -> empty
  if l:old_len == 0 && l:new_len == 0
    return {
    \   'range': {
    \     'start': {
    \       'line': 0,
    \       'character': 0,
    \     },
    \     'end': {
    \       'line': 0,
    \       'character': 0,
    \     }
    \   },
    \   'text': '',
    \   'rangeLength': 0
    \ }
  " not empty -> empty
  elseif l:old_len != 0 && l:new_len == 0
    return {
    \   'range': {
    \     'start': {
    \       'line': 0,
    \       'character': 0,
    \     },
    \     'end': {
    \       'line': l:old_len - 1,
    \       'character': strchars(l:old[-1]),
    \     }
    \   },
    \   'text': '',
    \   'rangeLength': strchars(join(l:old, "\n"))
    \ }
  " empty -> not empty
  elseif l:old_len == 0 && l:new_len != 0
    return {
    \   'range': {
    \     'start': {
    \       'line': 0,
    \       'character': 0,
    \     },
    \     'end': {
    \       'line': 0,
    \       'character': 0,
    \     }
    \   },
    \   'text': join(l:new, "\n"),
    \   'rangeLength': 0
    \ }
  endif

  if s:is_lua_enabled
    let [l:first_line, l:last_line] = luaeval('vital_vs_lsp_diff_search_line_region(_A[1], _A[2])', [l:old, l:new])
  else
    let l:first_line = 0
    while l:first_line < l:min_len - 1
      if l:old[l:first_line] !=# l:new[l:first_line]
        break
      endif
      let l:first_line += 1
    endwhile

    let l:last_line = -1
    while l:last_line > -l:min_len + l:first_line
      if l:old[l:last_line] !=# l:new[l:last_line]
        break
      endif
      let l:last_line -= 1
    endwhile
  endif

  let l:old_lines = l:old[l:first_line : l:last_line]
  let l:new_lines = l:new[l:first_line : l:last_line]
  let l:old_text = join(l:old_lines, "\n") . "\n"
  let l:new_text = join(l:new_lines, "\n") . "\n"
  let l:old_text_len = strchars(l:old_text)
  let l:new_text_len = strchars(l:new_text)
  let l:min_text_len = min([l:old_text_len, l:new_text_len])

  let l:first_char = 0
  for l:first_char in range(0, l:min_text_len - 1)
    if strgetchar(l:old_text, l:first_char) != strgetchar(l:new_text, l:first_char)
      break
    endif
  endfor

  let l:last_char = 0
  for l:last_char in range(0, -l:min_text_len + l:first_char, -1)
    if strgetchar(l:old_text, l:old_text_len + l:last_char - 1) != strgetchar(l:new_text, l:new_text_len + l:last_char - 1)
      break
    endif
  endfor

  return {
  \   'range': {
  \     'start': {
  \       'line': l:first_line,
  \       'character': l:first_char,
  \     },
  \     'end': {
  \       'line': l:old_len + l:last_line,
  \       'character': strchars(l:old_lines[-1]) + l:last_char + 1,
  \     }
  \   },
  \   'text': strcharpart(l:new_text, l:first_char, l:new_text_len + l:last_char - l:first_char),
  \   'rangeLength': l:old_text_len + l:last_char - l:first_char
  \ }
endfunction

function! s:try_enable_lua() abort
lua <<EOF
function vital_vs_lsp_diff_search_line_region(old, new)
  local old_len = #old
  local new_len = #new
  local min_len = math.min(#old, #new)

  local first_line = 0
  while first_line < min_len - 1 do
    if old[first_line + 1] ~= new[first_line + 1] then
      break
    end
    first_line = first_line + 1
  end

  local last_line = -1
  while last_line > -min_len + first_line do
    if old[(old_len + last_line) + 1] ~= new[(new_len + last_line) + 1] then
      break
    end
    last_line = last_line - 1
  end
  return { first_line, last_line }
end
EOF
endfunction

let s:is_lua_enabled = v:false
if has('nvim')
  try
    call s:try_enable_lua()
    let s:is_lua_enabled = v:true
  catch /.*/
  endtry
endif

