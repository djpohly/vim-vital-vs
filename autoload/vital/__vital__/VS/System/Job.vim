"
" _vital_loaded
"
function! s:_vital_loaded(V) abort
  let s:Emitter = a:V.import('VS.Event.Emitter')
endfunction

"
" _vital_depends
"
function! s:_vital_depends() abort
  return ['VS.Event.Emitter']
endfunction

"
" new
"
function! s:new() abort
  return s:Job.new()
endfunction

let s:chunk_size = 2048

let s:Job = {}

"
" new
"
function! s:Job.new() abort
  let l:job = extend(deepcopy(s:Job), {
  \   'events': s:Emitter.new(),
  \   'write_buffer': '',
  \   'write_timer': -1,
  \   'job': v:null,
  \ })
  let l:job.write = function(l:job.write, [], l:job)
  return l:job
endfunction

"
" start
"
function! s:Job.start(args) abort
  if self.is_running()
    return
  endif

  let l:option = {}
  for l:key in ['cwd', 'env']
    if has_key(a:args, l:key)
      let l:option[l:key] = a:args[l:key]
    endif
  endfor

  if has_key(l:option, 'cwd') && !isdirectory(l:option.cwd)
    unlet! l:option.cwd
  endif

  let self.job = s:_create(
  \   a:args.cmd,
  \   l:option,
  \   function(self.on_stdout, [], self),
  \   function(self.on_stderr, [], self),
  \   function(self.on_exit, [], self)
  \ )
endfunction

"
" stop
"
function! s:Job.stop() abort
  if !self.is_running()
    return
  endif
  call self.job.stop()
  let self.job = v:null
endfunction

"
" is_running
"
function! s:Job.is_running() abort
  return !empty(self.job)
endfunction

"
" send
"
function! s:Job.send(data) abort
  if !self.is_running()
    return
  endif
  let self.write_buffer .= a:data
  if self.write_timer != -1
    return
  endif
  call self.write()
endfunction

"
" write
"
function! s:Job.write(...) abort
  let self.write_timer = -1
  if self.write_buffer ==# ''
    return
  endif
  call self.job.send(strpart(self.write_buffer, 0, s:chunk_size))
  let self.write_buffer = strpart(self.write_buffer, s:chunk_size)
  if self.write_buffer !=# ''
    let self.write_timer = timer_start(0, self.write)
  endif
endfunction

"
" on_stdout
"
function! s:Job.on_stdout(data) abort
  call self.events.emit('stdout', a:data)
endfunction

"
" on_stderr
"
function! s:Job.on_stderr(data) abort
  call self.events.emit('stderr', a:data)
endfunction

"
" on_exit
"
function! s:Job.on_exit(code) abort
  call self.events.emit('exit', a:code)
endfunction

"
" create job instance
"
if has('nvim')
  function! s:_create(cmd, option, out, err, exit) abort
    let a:option.on_stdout = { id, data, event -> a:out(join(data, "\n")) }
    let a:option.on_stderr = { id, data, event -> a:err(join(data, "\n")) }
    let a:option.on_exit = { id, data, code -> a:exit(code) }
    let l:job = jobstart(a:cmd, a:option)
    return {
    \   'stop': { -> jobstop(l:job) },
    \   'send': { data -> jobsend(l:job, data) }
    \ }
  endfunction
else
  function! s:_create(cmd, option, out, err, exit) abort
    let a:option.noblock = v:true
    let a:option.in_io = 'pipe'
    let a:option.in_mode = 'raw'
    let a:option.out_io = 'pipe'
    let a:option.out_mode = 'raw'
    let a:option.err_io = 'pipe'
    let a:option.err_mode = 'raw'
    let a:option.out_cb = { job, data -> a:out(data) }
    let a:option.err_cb = { job, data -> a:err(data) }
    let a:option.exit_cb = { job, code -> a:exit(code) }
    let l:job = job_start(a:cmd, a:option)
    return {
    \   'stop': { ->  ch_close(l:job) },
    \   'send': { data -> ch_sendraw(l:job, data) }
    \ }
  endfunction
endif

