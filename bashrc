PROMPT_COMMAND=.prompt # Func to gen PS1 after CMDs


#echo -ne "\033]0;${USER}@${HOSTNAME}\007"

.title(){
   # change the title of the current window or tab
 echo -ne "\033]0;${USER}@${HOSTNAME}\007" 
}

.title

ssh()
{
   /usr/bin/ssh "$@"
   # revert the window title after the ssh command
   title $USER@$HOST
}

su()
{
   /bin/su "$@"
   # revert the window title after the su command
   title $USER@$HOST
}



##################################################

# Check last command result
# if last command executed correctly prints a green 'V'
# otherwise, in case of error, a red 'X'
.last_command(){ 
    
    local FancyX='\342\234\227'
    local Checkmark='\342\234\223'

    local Red='\[\e[0;31m\]'
    local Gre='\[\e[0;32m\]'

    if [ $EXIT != 0 ]; then
        # red X if exit code not 0
        last_command="$Red$FancyX " 
    else
        #green V is exit cod is 0 
        last_command="$Gre$Checkmark "
    fi

    echo $last_command
}    
###############################################################
# is a git repo
.is_git() {
inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"

    if [ "$inside_git_repo" ]; then
          echo "1"
    else
        echo "0"
    fi

}
###############################################################
# return git banch 
.git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
 }
#####################################################
# return git project 
.git_project(){
    git_project=$(git rev-parse --show-toplevel)
    git_project=$(basename $git_project)

    echo $git_project
}
#####################################################
# return git info
.git_info(){
    is_git=$(.is_git)
    if [ $is_git == "1" ]; then 
        git_project=$(.git_project)
        git_branch=$(.git_branch)
        git_info="[$git_project-$git_branch] "
    else
        git_info=" "
    fi    
   echo $git_info 
}
#####################################################
# set prompt 
.prompt() {
    ###################################################
    # Checks last command result
    # needs to be first
    local EXIT="$?"            
    ###################################################
    # Colors
    local  nocol='\033[0m'
    local  black='\033[0;30m'    
    local  red='\033[0;31m'    
    local  green='\033[0;32m'     
    local  brown='\033[0;33m'    
    local  blue='\033[0;34m'    
    local  purple='\033[0;35m'    
    local  cyan='\033[0;36m'     
    local  lightgray='\033[0;37m'     
    local  darkgray='\033[1;30m'
    local  lightred='\033[1;31m'
    local  lightgreen='\033[1;32m'
    local  yellow='\033[1;33m'
    local  lightblue='\033[1;34m'
    local  lightpurple='\033[1;35m'
    local  lightcyan='\033[1;36m'
    local  white='\033[1;37m'
    ####################################################
    # Check last command result
    last_command=$(.last_command)
    ####################################################
    # Check user
    # Does not work when changing user .bashrc is not read anymore
    #if [[ $USER == 0 ]]; then
    #    UCol="$Red"
    #else 
    #    UCol="$BBlu"
    #fi    
    ####################################################
    # check git
    git_info=$(.git_info)
    ####################################################
    # simple prompt 
    #PS1="${green}@\h ${red}\\w: ${blue}[\$(git branch 2>/dev/null | grep '^*' | colrm 1 2)] \n$last_command \[\e[m\]"
    #PS1="${green}\u@\h ${red}\\w ${blue} $git_info  \n$last_command \[\e[m\]"
    PS1="${red}\\w ${blue} $git_info  \n$last_command \[\e[m\]"



}
####################################################
# set git user and email
git config --global user.email andrea.spano@quantide.com
git config --global user.name andreaspano
###################################################
# Envir variables
export VISUAL=vim
export EDITOR=vim
####################################################
# bash_aliases
if [ -f $HOME/.bash_aliases ]; then
. $HOME/.bash_aliases
fi
####################################################
# Hosts
export HOSTALIASES=~/.hosts
####################################################
# PATH
PATH=$PATH:~/.local/bin
PATH=$PATH:~/gdrive/personal/bin
####################################################
# server aliases 
if [ -f $HOME/.hosts ]; then
. $HOME/.hosts
fi
####################################################
# set the text scolr to brown 
#echo -ne "\033]10;#ffa500\007"



# avoid WARN when ssh -X
export NO_AT_BRIDGE=1
