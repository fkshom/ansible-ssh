# ansible-ssh

## Usage
```sh
$ cat <<'EOF' >> .bashrc
bind -x '"\C-x\C-s": ansiblessh::bash'
bind -x '"\C-x\C-x": ansiblessh::bash::ansible-inventory-command'
export INVENTORIES=(your inventory files from current directory)

export ANSIBLESSH_USE_SOURCE=ini
# or 
export ANSIBLESSH_USE_SOURCE=command

export ANSIBLESSH_SHOW_HOST_VARS=0
# or
export ANSIBLESSH_SHOW_HOST_VARS=1
EOF
```
