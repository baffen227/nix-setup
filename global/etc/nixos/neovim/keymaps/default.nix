''
  " Set leader key
  let mapleader = " "

  " Clear search highlight
  nnoremap <leader>h :nohlsearch<CR>

  " Better window navigation
  nnoremap <C-h> <C-w>h
  nnoremap <C-j> <C-w>j
  nnoremap <C-k> <C-w>k
  nnoremap <C-l> <C-w>l

  " Better indentation in visual mode
  vnoremap < <gv
  vnoremap > >gv

  " Move lines up/down
  nnoremap <A-j> :m .+1<CR>==
  nnoremap <A-k> :m .-2<CR>==
  vnoremap <A-j> :m '>+1<CR>gv=gv
  vnoremap <A-k> :m '<-2<CR>gv=gv

  " Plugin keymaps
  nnoremap <leader>e :NvimTreeToggle<CR>
  nnoremap <leader>f :Telescope find_files<CR>
  nnoremap <leader>g :Telescope live_grep<CR>
  nnoremap <leader>b :Telescope buffers<CR>

  " TODO: Claude Code keymaps
  " nnoremap <leader>cc :ClaudeCode<CR>
''