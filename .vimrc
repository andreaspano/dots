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
"execute "set <M-a>=\ea"
"imap <M-a> <- 

" function(){}  
execute "set <M-f>=\ef"
imap <M-f> function() {  } 


" execute "set <a-cr>=\<esc>\<cr>"
"nnoremap <a-cr> something
"nmap <a-cr> <Plug>RDSendLine

nmap <cr> <Plug>RDSendLine
vmap <cr> <Plug>REDSendSelection

" map  start R to  localheader R
nmap <LocalLeader>R <Plug>RStart
imap <LocalLeader>R <Plug>RStart
vmap <LocalLeader>R <Plug>RStart

" Map clear console to localheader L
nmap <LocalLeader>L <Plug>RClearConsole
imap <LocalLeader>L <Plug>RClearConsole
vmap <LocalLeader>L <Plug>RClearConsole

" Map comment to localheader C
nmap <LocalLeader>c <Plug>RSimpleComment
imap <LocalLeader>c <Plug>RSimpleComment
vmap <LocalLeader>c <Plug>RSimpleComment

nmap <LocalLeader>u <Plug>RSimpleUnComment
imap <LocalLeader>u <Plug>RSimpleUnComment
vmap <LocalLeader>u <Plug>RSimpleUnComment

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Radian 
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let R_app = "radian"
let R_cmd = "R"
let R_hl_term = 0
let R_args = []  " if you had set any
let R_bracketed_paste = 1


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Buffer Navigation
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap  <C-w>e :e 
nmap  <C-w>l :ls<cr>
nmap  <C-w><Right> :bn<cr>
nmap  <C-w><Left>  :bp<cr>
nmap  <C-w>1 :b1<cr>
nmap  <C-w>2 :b2<cr>
nmap  <C-w>3 :b3<cr>
nmap  <C-w>v :ls<cr>:vertical sb 
nmap  <C-w>h :ls<cr>:sb 
nmap  <C-w>d :bd<cr>
nmap  <C-w>t :ter<cr>




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

" Disable _ mapping to <- 
let R_assign = 0

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

"Plug 'roxma/nvim-completion-manager'
Plug 'gaalcaras/ncm-R'

Plug 'ncm2/ncm2'
Plug 'roxma/nvim-yarp'

" markdown plugin
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'

" Initialize plugin system
call plug#end()



