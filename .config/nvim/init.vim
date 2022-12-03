" Basic
filetype plugin indent on
set title
set nocompatible
set autoindent expandtab shiftwidth=2 softtabstop=2 tabstop=2
set ai
set backspace=indent,eol,start
set clipboard=unnamed,unnamedplus
set encoding=utf8
set hlsearch ignorecase incsearch smartcase
set lazyredraw nocursorline ttyfast
set listchars=eol:¶,trail:•,tab:▸\  showbreak=¬\
set virtualedit=block
set mouse=a
set nobackup noswapfile nowritebackup undofile undodir=~/.vim/undo undolevels=99999
set nowrap
set number relativenumber
set ruler
set colorcolumn=80
set cursorline
set scrolloff=999
set showmode
set showcmd
set showmatch
set path+=**
set wildmenu wildmode=longest:full,full wildcharm=<Tab>


" Copy to clipboard
vnoremap  <leader>y  "+y
nnoremap  <leader>Y  "+yg_
nnoremap  <leader>y  "+y
nnoremap  <leader>yy  "+yy

" Paste from clipboard
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P

" Statusline
set laststatus=2
set statusline=
set statusline+=%#Status#
set statusline+=%=
set statusline+=\[%n]
set statusline+=\ %f
set statusline+=%m\
set statusline+=\ %y
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}
set statusline+=\ [%{&fileformat}\]
set statusline+=\ row:%l/%L\ (%03p%%)
set statusline+=\ col:%03c

" Colors
syntax on
set background=dark
hi CursorLineNr ctermfg=lightgreen ctermbg=NONE cterm=NONE
hi CursorLine ctermfg=NONE ctermbg=237 cterm=NONE
hi LineNr ctermfg=243 ctermbg=NONE cterm=NONE
hi Status ctermfg=7 ctermbg=NONE cterm=NONE
highlight Comment ctermfg=green

" Key Mappings
let mapleader=','
nnoremap <leader>, :let @/=''<CR>:noh<CR>
nnoremap <leader># :g/\v^(#\|$)/d_<CR>
nnoremap <leader>l :set list! list?<CR>
nnoremap <leader>n :set number! number?<CR>
nnoremap <leader>p :set invpaste paste?<CR>
nnoremap <leader>r :retab<CR>
nnoremap <leader>s :source $MYVIMRC<CR>
nnoremap <leader>t :%s/\s\+$//e<CR>
nnoremap <leader>w :set wrap! wrap?<CR>
nnoremap <leader>b :bnext<CR>
nnoremap <silent><leader>d "_d
nnoremap <silent><leader>i gg=G``<CR>
cnoreabbrev w!! w !sudo tee > /dev/null %|
vnoremap . :normal .<CR>

" Autocomplete Settings
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS

autocmd FileType python set omnifunc=pythoncomplete#Complete
let python_highlight_all = 1
