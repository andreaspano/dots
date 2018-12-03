"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Row number 
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable row number 
set number 

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Short cuts  
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search text  
"map f / 

" Split Vertical
"map v :split<enter>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => R short cuts   
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


" %>%
execute "set <M-m>=\em"
imap <M-m> %>% 

" <-  
execute "set <M-a>=\ea"
imap <M-a> <- 

" function(){}  
execute "set <M-f>=\ef"
imap <M-f> function() {  } 


" execute "set <a-cr>=\<esc>\<cr>"
"nnoremap <a-cr> something
"nmap <a-cr> <Plug>RDSendLine

nmap <cr> <Plug>RDSendLine
vmap <cr> <Plug>REDSendSelection
  
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Colors and Fonts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable syntax highlighting
syntax enable 

" Enable 256 colors palette in Gnome Terminal
if $COLORTERM == 'gnome-terminal'
    set t_Co=256
endif

try
    colorscheme desert
catch
endtry

set background=dark

" Set extra options when running in GUI mode
if has("gui_running")
    set guioptions-=T
    set guioptions-=e
    set t_Co=256
    set guitablabel=%M\ %t
endif

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Files, backups and undo
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Turn backup off, since most stuff is in SVN, git et.c anyway...
set nobackup
set nowb
set noswapfile


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Text, tab and indent related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 4 spaces
set shiftwidth=2
set tabstop=2

" Linebreak on 500 characters
set lbr
set tw=500

set ai "Auto indent
set si "Smart indent
set nowrap "Wrap lines


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins via Vim-Plug 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" To install any plugin just type vim command PlugInstall

" Specify a directory for plugins
" Make sure you use single quotes
call plug#begin('~/.vim/plugged')

" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align'

" R Vim plugin
Plug 'jalvesaq/Nvim-R'

" Initialize plugin system
call plug#end()
