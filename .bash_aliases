# terminal

function get-term-height () {
  stty -a | awk 'match($0, "\\<rows +([0-9]+)", m) {print m[1]}'
}



# Cursor Styles
## https://superuser.com/a/1302503
export VTE_CURSOR_STYLE_TERMINAL_DEFAULT=0
export VTE_CURSOR_STYLE_BLINK_BLOCK=1
export VTE_CURSOR_STYLE_STEADY_BLOCK=2
export VTE_CURSOR_STYLE_BLINK_UNDERLINE=3
export VTE_CURSOR_STYLE_STEADY_UNDERLINE=4
### *_IBEAMarextermextensions
export VTE_CURSOR_STYLE_BLINK_IBEAM=5
export VTE_CURSOR_STYLE_STEADY_IBEAM=6
function cursor-style () {
  if [ $# -gt 0 ]
  then
    printf '\033[%d q' $1
  else
    echo Usage: 'cursor-style <style-number>' >&2
    echo Style numbers: >&2
    env | grep --color=never VTE_CURSOR_STYLE_ | sort >&2
    return -1
  fi
}



# Colours
## https://stackoverflow.com/a/28938235

## Reset
export CLR_Normal='\033[0m'          # Text Reset

## Regular Colors
export CLR_Black='\033[0;30m'        # Black
export CLR_Red='\033[0;31m'          # Red
export CLR_Green='\033[0;32m'        # Green
export CLR_Yellow='\033[0;33m'       # Yellow
export CLR_Blue='\033[0;34m'         # Blue
export CLR_Purple='\033[0;35m'       # Purple
export CLR_Cyan='\033[0;36m'         # Cyan
export CLR_White='\033[0;37m'        # White

## Bold
export CLR_BBlack='\033[1;30m'       # Black
export CLR_BRed='\033[1;31m'         # Red
export CLR_BGreen='\033[1;32m'       # Green
export CLR_BYellow='\033[1;33m'      # Yellow
export CLR_BBlue='\033[1;34m'        # Blue
export CLR_BPurple='\033[1;35m'      # Purple
export CLR_BCyan='\033[1;36m'        # Cyan
export CLR_BWhite='\033[1;37m'       # White

## Underline
export CLR_UBlack='\033[4;30m'       # Black
export CLR_URed='\033[4;31m'         # Red
export CLR_UGreen='\033[4;32m'       # Green
export CLR_UYellow='\033[4;33m'      # Yellow
export CLR_UBlue='\033[4;34m'        # Blue
export CLR_UPurple='\033[4;35m'      # Purple
export CLR_UCyan='\033[4;36m'        # Cyan
export CLR_UWhite='\033[4;37m'       # White

## Background
export CLR_On_Black='\033[40m'       # Black
export CLR_On_Red='\033[41m'         # Red
export CLR_On_Green='\033[42m'       # Green
export CLR_On_Yellow='\033[43m'      # Yellow
export CLR_On_Blue='\033[44m'        # Blue
export CLR_On_Purple='\033[45m'      # Purple
export CLR_On_Cyan='\033[46m'        # Cyan
export CLR_On_White='\033[47m'       # White

## High Intensity
export CLR_IBlack='\033[0;90m'       # Black
export CLR_IRed='\033[0;91m'         # Red



# Unicode

export vvert=‖
export vvvert=⦀



# ls

## enable colour support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    export autocolour=' --color=auto'
fi

alias ll="'ls'$autocolour -alF"
alias la="'ls'$autocolour -A"
alias  l="'ls'$autocolour -CF"
alias ld="ll -d"
alias lt="ll -tr"
alias ltree="tree -C | sed -e's/└/╰/'" # -e's/├──/╞╾─/'



# grep

alias  grep="grep $autocolour"
alias cgrep="grep --color=always"
alias egrep="egrep$autocolour"
alias fgrep="fgrep$autocolour"
alias pgrep="grep $autocolour -P"



# watching

function watch () {
  sleep="$1"
  shift

  (
    trap 'tput rmcup; tput cnorm' EXIT # restore terminal on exit
    tput smcup # alternatve buffer
    tput civis # hide cursor
    clear="$(tput clear)"
    cursor_home="$(tput cup 0 0)"
    clear_eol="$(tput el)" # clear cursor to end of line
    clear_eos="$(tput ed)" # clear cursor to end of screen
    while true; do
      n=$(get-term-height)
      buf=$(eval "$@" 2>&1 | head -n$n)
      echo -n "$cursor_home${buf//$'\n'/$clear_eol$'\n'}$clear_eos"
      sleep "$sleep"
    done
  )
}

clock () {
  # Continuously displays the time.  Takes on optional variable to set the total
  # width of the displayed right-aligned string.  This defaults to 0 (i.e.,
  # left-aligned).
  watch 0.9 printf '"$CLR_BCyan%*s$CLR_Normal"' ${1:-0} '"$(date)"'
}

## "alert" alias for long running commands.  Use like so:
##   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'



# tmux

tmux-pane-id () {
  tmux display-message -p '#{pane_id}'
}



# terraform

alias tffmt='type terraform >/dev/null && terraform fmt -recursive $(git rev-parse --show-toplevel) || true'
alias tfdoc='find $(git rev-parse --show-toplevel) -type d -exec test -e {}/README.md \; -exec terraform-docs {} \;' # Only update existing README files



# git

.brh-stack-file () {
  stack=$(git rev-parse --show-toplevel)/.git/branch-stack
  touch -a $stack
  echo $stack
}

brh-current () {
    git rev-parse --abbrev-ref HEAD
}

brh-stack () {
  stack=$(.brh-stack-file)
  grep --color=always -n '^' $stack
  printf '\033[0;32m->\033[0m'; brh-current
}

brh-pop () {
  stack=$(.brh-stack-file)
  old_branch=$(brh-current)
  if ( [ -s "$stack" ] )
  then
    git checkout "$(tail -1 "$stack")"
    new_branch=$(brh-current)
    if ( [ "$new_branch" != "$old_branch" ] )
    then
      sed -i '$ d' "$stack"
    fi
  fi
  brh-stack
}

brh-push () {
  stack=$(.brh-stack-file)
  old_branch=$(brh-current)
  git switch "$1"
  new_branch=$(brh-current)
  if ( [ "$new_branch" != "$old_branch" ] )
  then
    printf '%s\n' "$old_branch" >>"$stack"
  fi
  brh-stack
}

brh-create () {
  git switch -C "$@" &&
    {
      brh-push "${@: -1}" 2>&1 1>&3 3>&- |
        grep -v '^Already on ';
    } 3>&1 1>&2
}

brh-create-with-reference-to-azure-devops-board-ticket () {
  ado_num="AB#$(tmux display-message -p '#S' | sed 's/[^0-9]//g')"
  dscrptn=$(tr ' ' - <<<"$@" | tr A-Z a-z)
  brh-create $ado_num/$dscrptn
}

git-list-custom-aliases () {
  local _git_aliases=(git)
  while true
  do
    local _git_aliases_cnt=${#_git_aliases[*]}
    local _git_alias
    for _git_alias in ${_git_aliases[@]}
    do
      local _this_alias
      for _this_alias in $(
          alias -p |
            grep -E "\<$_git_alias\>" |
            cut -d= -f1 |
            cut -d\  -f2
        )
      do
        <<<"${_git_aliases[*]}" grep -qE "\<$_this_alias\>" ||
          _git_aliases+=($_this_alias)
      done
    done
    if [ $_git_aliases_cnt -eq ${#_git_aliases[*]} ]
    then
      break
    fi
  done
  alias -p |
    grep -E "($(<<<"${_git_aliases[*]}" tr \  \|))" |
    grep -P '(?<=^alias )[^=]*' # This is just for colouring
}

. <(git-alias-factory)

## map x-y to x.y
for a in $(alias -p | perl -nle '/^alias (g\w+(?:\.\w+)+)=/ and print $1')
do
  alias $(tr . - <<<$a)=$a
done


git-continuous-status-and-diff () {
  watch 3                                                                     \
    brh-stack                                                              \; \
    echo                                                                   \; \
    gss                                                                    \; \
    printf "'$CLR_Cyan%*s-$CLR_Normal\\n'" \$COLUMNS \| sed "'s/  / -/g'"  \; \
    gdf --color                                                            \| \
    grep -Ev '[+-]\{3\}\ [ab]\\/'
}

git-continuous-fetch-and-diff () {
  cached=""
  if [ "$1" == "--cached" ]; then cached=" --cached"; shift; fi
  diff_range="${1:-origin/main}"
  watch 9                                                                         \
    printf "'diff%s $CLR_BPurple%s$CLR_Normal\\n'" "'$cached'" "'$diff_range'" \; \
    git fetch \>/dev/null                                                      \; \
    gdf.no$cached  "'$diff_range'"                                             \; \
    gdf$cached --color "'$diff_range'"                                         \| \
    grep -Ev '[+-]\{3\}\ [ab]\\/'
}

# git-tmux

git-tmux-status-pane ()
{
  right_pane_width=${1:-72} # Optional, defaults to 72
  lower_pane_height=$2      # Optional, defaults to half of available height
  total_pane_height=$(tmux display-message -p '#{pane_height}')
  clock_pane_height=1
  : ${lower_pane_height:=$(( ($total_pane_height - $clock_pane_height) / 2 ))}
  middle_pane_height=$(( $total_pane_height - $lower_pane_height ))

  current_directory=$(pwd)
  original_pane_id=$(tmux-pane-id)                       # get pane id

  # Create the panes
  ## Clock pane
  tmux split-pane -h \; resize-pane -x$right_pane_width  # create pane
  clock_pane_id=$(tmux-pane-id)                          # get pane id
  tmux select-pane -T clock                              # name pane
  ## Git status pane
  tmux split-pane -v                                     # create pane
  git_status_id=$(tmux-pane-id)                          # get pane id
  tmux select-pane -T git_status                         # name pane
  ## Git diff-from-origin pane
  tmux split-pane -v                                     # create pane
  git_ogdiff_id=$(tmux-pane-id)                          # get pane id
  tmux select-pane -T git_ogdiff                         # name pane

  # Set pane heights
  tmux resize-pane -t$clock_pane_id -y$clock_pane_height
  tmux resize-pane -t$git_status_id -y$middle_pane_height
  tmux resize-pane -t$git_ogdiff_id -y$lower_pane_height

  # Send commands to the panes
  tmux select-pane -t$clock_pane_id \; send-keys                              \
    " clock $right_pane_width                                             ; " \
    Enter
  tmux select-pane -t$git_status_id \; send-keys                              \
    " cd '$current_directory'                                             ; " \
    " setterm -linewrap off                                               ; " \
    " git-continuous-status-and-diff                                      ; " \
    Enter
  tmux select-pane -t$git_ogdiff_id \; send-keys                              \
    " cd '$current_directory'                                             ; " \
    " setterm -linewrap off                                               ; " \
    " git-continuous-fetch-and-diff                                       ; " \
    Enter

  tmux select-pane -t$original_pane_id
}
