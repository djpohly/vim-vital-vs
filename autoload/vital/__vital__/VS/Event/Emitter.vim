"
" new
"
function! s:new() abort
  return s:Emitter.new()
endfunction

"
" Emitter
"
let s:Emitter = {}

"
" new
"
function! s:Emitter.new() abort
  return extend(deepcopy(s:Emitter), {
  \   'events': {}
  \ })
endfunction

"
" emit
"
function! s:Emitter.emit(event_name, ...) abort
  for l:Listener in get(self.events, a:event_name, [])
    call call(l:Listener, a:000)
  endfor
endfunction

"
" on
"
function! s:Emitter.on(event_name, Listener) abort
  let self.events[a:event_name] = get(self.events, a:event_name, [])
  call add(self.events[a:event_name], a:Listener)
endfunction

"
" listener_count
"
function! s:Emitter.listener_count(event_name) abort
  return len(get(self.events, a:event_name, []))
endfunction

"
" off
"
function! s:Emitter.off(event_name, ...) abort
  let self.events[a:event_name] = get(self.events, a:event_name, [])

  let l:Listener = get(a:000, 0, v:null)

  let l:i = len(self.events[a:event_name]) - 1
  while l:i >= 0
    if self.events[a:event_name][l:i] is# l:Listener || l:Listener is# v:null
      call remove(self.events[a:event_name], l:i)
    endif
    let l:i -= 1
  endwhile
endfunction
