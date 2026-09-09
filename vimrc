

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Terminal title to file name
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set title
set titlestring=%t%m

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Buffer Navigation
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <C-Left> gt
nnoremap <C-Right> gT

" Tab labels: file name only, never the path (vim's default tabline falls
" back to showing path segments when two open tabs share a basename).
function! MyTabLine()
  let s = ''
  for i in range(tabpagenr('$'))
    let tabnr = i + 1
    let winnr = tabpagewinnr(tabnr)
    let bufnr = tabpagebuflist(tabnr)[winnr - 1]
    let bufname = bufname(bufnr)
    let label = bufname ==# '' ? '[No Name]' : fnamemodify(bufname, ':t')
    let modified = getbufvar(bufnr, '&modified') ? ' [+]' : ''

    let s .= '%' . tabnr . 'T'
    let s .= (tabnr == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#')
    let s .= ' ' . label . modified . ' '
  endfor
  let s .= '%#TabLineFill#%T'
  return s
endfunction

set tabline=%!MyTabLine()

" Send the visually selected lines to the MyClaude console pane (tmux,
" see fun-test.sh) with q. Uses tmux's own buffer instead of piping through
" the shell, so no escaping worries. Afterwards, re-enters visual mode on
" the next non-blank line so a repeated q walks through the file.
function! s:SendSelectionToTmux() range
  if empty($TMUX) || empty($MYCLAUDE_CONSOLE_PANE)
    echom 'MYCLAUDE_CONSOLE_PANE not set: not inside a MyClaude tmux session'
    return
  endif
  let text = join(getline(a:firstline, a:lastline), "\n")
  call system('tmux load-buffer -', text)
  call system('tmux paste-buffer -d -p -t ' . shellescape($MYCLAUDE_CONSOLE_PANE))
  call system('tmux send-keys -t ' . shellescape($MYCLAUDE_CONSOLE_PANE) . ' Enter')

  let next = a:lastline + 1
  let last = line('$')
  while next <= last && getline(next) =~ '^\s*$'
    let next += 1
  endwhile
  if next <= last
    call cursor(next, 1)
    normal! V
  endif
endfunction

xnoremap <silent> q :call <SID>SendSelectionToTmux()<CR>

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

" Keep the terminal/tmux pane's own background instead of the dark grey
" desert forces on Normal/NonText, so opening vim doesn't shift the bg color.
highlight Normal ctermbg=NONE guibg=NONE
highlight NonText ctermbg=NONE guibg=NONE

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
set wrap "Wrap lines



set term=xterm-256color
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins via Vim-Plug 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""



" To install any plugin just type vim command PlugInstall

" Specify a directory for plugins
" Make sure you use single quotes
" call plug#begin('~/.vim/plugged')

" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
"Plug 'junegunn/vim-easy-align'

" R Vim plugin
"Plug 'jalvesaq/Nvim-R'

"Plug 'roxma/nvim-completion-manager'
"Plug 'gaalcaras/ncm-R'

"Plug 'ncm2/ncm2'
"Plug 'roxma/nvim-yarp'

" markdown plugin
"Plug 'godlygeek/tabular'
"Plug 'plasticboy/vim-markdown'

" Initialize plugin system
"call plug#end()



