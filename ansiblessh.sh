ansiblessh::memoize() {
    PROG="$(basename $0)"
    DIR="${HOME}/.cache/${PROG}"
    mkdir -p "${DIR}"
    EXPIRY=600 # default to 10 minutes
    EXPIRY=3
    # check if first argument is a number, if so use it as expiration (seconds)
    [ "$1" -eq "$1" ] 2>/dev/null && EXPIRY=$1 && shift
    [ "$VERBOSE" = true ] && echo "Using expiration $EXPIRY seconds"
    CMD="$@"
    HASH=$(echo "$CMD" | md5sum | awk '{print $1}')
    CACHE="$DIR/$HASH"
    test -f "${CACHE}" && [ $(expr $(date +%s) - $(date -r "$CACHE" +%s)) -le $EXPIRY ] || eval "$CMD" > "${CACHE}"
    cat "${CACHE}"
}
 
ansiblessh::source::ansible-inventory-command() {
  declare -a CANDIDATE=(${INVENTORIES:-inventory hosts})
  local inventories=$(echo "${CANDIDATE[@]}" | xargs ls -d 2>/dev/null | xargs -n1 -I{} echo "-i {}" | xargs echo)
  ansible-inventory $inventories --list \
  | jq -r '
    ._meta.hostvars as $hostvars
    | .[] | select(has("hosts")) | .[][] | . as $host
    | {
        ansible_host:                 $hostvars[$host].ansible_host?,
        ansible_ssh_host:             $hostvars[$host].ansible_ssh_host?,
        ansible_port:                 $hostvars[$host].ansible_port?,
        ansible_ssh_port:             $hostvars[$host].ansible_ssh_port?,
        ansible_user:                 $hostvars[$host].ansible_user?,
        ansible_ssh_user:             $hostvars[$host].ansible_ssh_user?,
        ansible_ssh_private_key_file: $hostvars[$host].ansible_ssh_private_key_file?,
        ansible_ssh_common_args:      $hostvars[$host].ansible_ssh_common_args?,
        ansible_ssh_extra_args:       $hostvars[$host].ansible_ssh_extra_args?,
      }
    | {
        ansible_host:                 (.ansible_host? // .ansible_ssh_host? // null),
        ansible_port:                 (.ansible_port? // .ansible_ssh_port? // null),
        ansible_user:                 (.ansible_user? // .ansible_ssh_user? // null),
        ansible_ssh_private_key_file: (.ansible_ssh_private_key_file? // null | @sh),
        ansible_ssh_common_args:      (.ansible_ssh_common_args? // null | @sh),
        ansible_ssh_extra_args:       (.ansible_ssh_extra_args? // null | @sh),
    }
    | with_entries(select(.value != null and .value != "null"))
    | to_entries | [$host, (map("\(.key)=\(.value)") | .[])] | join("  ")
   '
}

ansiblessh::source::inventory() {
  declare -a CANDIDATE=(${INVENTORIES:-inventory hosts})
  local inventories=($(echo "${CANDIDATE[@]}" | xargs ls -d 2>/dev/null))
  cat "${inventories[@]}" | fgrep -v "["
}

ansiblessh::selector::fzf-tmux() {
  if [[ $# -gt 0 ]]; then
    ${fzf_tmux_path:-fzf-tmux} --query "$@"
  else
    ${fzf_tmux_path:-fzf-tmux}
  fi
}
ansiblessh::selector::fzf() {
  if [[ $# -gt 0 ]]; then
    ${fzf_path:-fzf} --query "$@"
  else
    ${fzf_path:-fzf}
  fi
}
ansiblessh::selector::peco() {
  if [[ $# -gt 0 ]]; then
    ${peco_path:-peco} --query "$@"
  else
    ${peco_path:-peco}
  fi
}
ansiblessh::selector::percol() {
  if [[ $# -gt 0 ]]; then
    ${percol_path:-percol} --query "$@"
  else
    ${percol_path:-percol}
  fi
}
ansiblessh::selector::gof() {
  if [[ $# -gt 0 ]]; then
    ${gof_path:-gof} --query "$@"
  else
    ${gof_path:-gof}
  fi
}
ansiblessh::selector::auto() {
  local filter=
  if [[ -z "${selector_mode}" ]]; then
    local filters="fzf-tmux:fzf:peco:percol:gof"
    while [[ -n $filters ]]; do
      filter=${filters%%:*}
      if type "$filter" >/dev/null 2>&1; then
        filter=($filter)
        break
      else
        filters="${filters#*:}"
      fi
    done
    if [[ -z "${filter}" ]]; then
      echo "ansiblessh: not found any of gof, percol, peco, fzf, or fzf-tmux" 1>&2
      return 1
    fi
  else
    filter="${selector_mode}"
  fi
  ansiblessh::selector::${filter} "$@"
}

abc() {
  set -x
  cat > /dev/null
  echo 4
}

ansiblessh::builder::build_ssh_cmd() {
    local selected_item
    selected_item="$(cat)"
    if [[ -z "$selected_item" ]]; then
      return 1
    fi
    host=$(echo "${selected_item}" | sed -nE 's/([^\t $#]+).*/\1/p')
    ansible_host=$(echo "${selected_item}" | sed -nE 's/.*ansible_host=([^\t $#]+).*/\1/p')
    ansible_port=$(echo "${selected_item}" | sed -nE 's/.*ansible_port=([^\t $#]+).*/\1/p')
    ansible_user=$(echo "${selected_item}" | sed -nE 's/.*ansible_user=([^\t $#]+).*/\1/p')
    ansible_ssh_private_key_file=$(echo "${selected_item}" | sed -nE $'s/.*ansible_ssh_private_key_file=(["\']*)(.*?)\\1([ \t]*|[ \t]+ansible.*|[ \t]*#.*)$/\\2/p')
    ansible_ssh_common_args=$(echo "${selected_item}" | sed -nE $'s/.*ansible_ssh_common_args=(["\']*)(.*?)\\1([ \t]*|[ \t]+ansible.*|[ \t]*#.*)$/\\2/p')
    ansible_ssh_extra_args=$(echo "${selected_item}" | sed -nE $'s/.*ansible_ssh_extra_args=(["\']*)(.*?)\\1([ \t]*|[ \t]+ansible.*|[ \t]*#.*)$/\\2/p')

    cmd="ssh"
    [[ -n "${ansible_port}" ]]                 && cmd+=" -p ${ansible_port}"
    [[ -n "${ansible_user}" ]]                 && cmd+=" -l ${ansible_user}"
    [[ -n "${ansible_ssh_private_key_file}" ]] && cmd+=' -i '$(eval echo "'${ansible_ssh_private_key_file}'")
    [[ -n "${ansible_ssh_common_args}" ]]      && cmd+=' '$(eval echo "'${ansible_ssh_common_args}'")
    [[ -n "${ansible_ssh_extra_args}" ]]       && cmd+=' '$(eval echo "'${ansible_ssh_extra_args}'")
    cmd+=" ${ansible_host:-$host}"
    echo "$cmd"
}

ansiblessh::interactiveprompt() {
  local l="$1"
  if [[ `readlink /proc/$$/exe` == *bash ]]; then
    READLINE_LINE="$l"
    READLINE_POINT=${#l}
  elif [[ `readlink /proc/$$/exe` == *zsh ]]; then
    BUFFER="$l"
    CURSOR=$#BUFFER
    zle reset-prompt
  fi
}

ansiblessh::action::interactiveprompt() {
  local str=$(cat)
  ansiblessh::interactiveprompt "$str"
}

ansiblessh::action::execute() {
  local cmd=$(cat)
  echo "$cmd" "$@"
}

ansiblessh::zsh() {
    ansiblessh::source::inventory \
      | ansiblessh::selector::auto \
      | ansiblessh::builder::build_ssh_cmd \
      | ansiblessh::action::interactiveprompt
}
ansiblessh::bash::ansible-inventory-command() {
    cmd=$(
      ansiblessh::source::ansible-inventory-command \
        | ansiblessh::selector::auto \
        | ansiblessh::builder::build_ssh_cmd \
    )    
    ansiblessh::interactiveprompt "$cmd"
}

ansiblessh::bash() {
    cmd=$(
      ansiblessh::source::inventory \
        | ansiblessh::selector::auto \
        | ansiblessh::builder::build_ssh_cmd \
    )    
    ansiblessh::interactiveprompt "$cmd"
}

ansiblessh::run() {
  local selected_item
  if [ $# -eq 1 ]; then
    host=$1
    shift
    selected_item=$(
      ansiblessh::source::inventory \
      | grep -E "^${host}\s" \
      | head -n 1 \
    )
    if [ -z "${selected_item}" ]; then
      echo "ERROR: Host not found in inventory"
      exit 1
    fi
  else
    selected_item=$(
      ansiblessh::source::inventory \
      | ansiblessh::selector::auto \
    )
  fi

  echo "${selected_item}" | tee /dev/stderr \
    | ansiblessh::builder::build_ssh_cmd \
    | ansiblessh::action::execute "$@"
}

# https://stackoverflow.com/a/28776166
sourced=0
if [ -n "$ZSH_EVAL_CONTEXT" ]; then 
  case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
  [ "$(cd $(dirname -- $0) && pwd -P)/$(basename -- $0)" != "$(cd $(dirname -- ${.sh.file}) && pwd -P)/$(basename -- ${.sh.file})" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
  (return 0 2>/dev/null) && sourced=1 
else # All other shells: examine $0 for known shell binary filenames
  # Detects `sh` and `dash`; add additional shell filenames as needed.
  case ${0##*/} in sh|dash) sourced=1;; esac
fi

if [ $sourced -eq 0 ]; then
  ansiblessh::run "$@"
else
  if [[ `readlink /proc/$$/exe` == *bash ]]; then
    bind -x '"\C-x\C-s": ansiblessh::bash'
    bind -x '"\C-x\C-x": ansiblessh::bash::ansible-inventory-command'
  fi
  if [[ `readlink /proc/$$/exe` == *zsh ]]; then
    zle -N ansiblessh::zsh
    bindkey '^x^s' ansiblessh::zsh
  fi
fi



