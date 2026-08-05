# ~/.bash_profile -- login shells.
#
# All real configuration lives in ~/.bashrc; this file only makes login shells
# (tty console, ssh, `bash -l`, "run as login shell" terminals) read it.
#
# Because this file exists, bash IGNORES ~/.profile entirely. That is deliberate:
# it stops installers that rewrite ~/.profile from silently breaking the shell.
# The trade-off: lines an installer appends to ~/.profile will NOT be read --
# if a newly installed tool is missing from PATH, check there first.

ln -s ~/dev/dots/vimrc .vimrc

[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
