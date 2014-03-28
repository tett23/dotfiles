function UniteNewBufferAndSeekFile()
  new
  Unite file
endfunction
noremap <Plug>(unite_new_buffer_and_seek_file) :<C-u>call UniteNewBufferAndSeekFile()<CR>
map q <Plug>(unite_new_buffer_and_seek_file)
