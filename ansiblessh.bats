#!/usr/bin/env bats

@test "without ansible_host" {
  source ansiblessh.sh
  selected_item='host12'
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == 'ssh host12' ]
}
@test "with ansible_host" {
  source ansiblessh.sh
  selected_item='host12 ansible_host=1.1.1.2'
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == 'ssh 1.1.1.2' ]
}

@test "ansible_port" {
  source ansiblessh.sh
  selected_item='host12 ansible_host=1.1.1.2 ansible_port=5555'
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == 'ssh -p 5555 1.1.1.2' ]
}
@test "ansible_user" {
  source ansiblessh.sh
  selected_item='host12 ansible_host=1.1.1.2 ansible_user=user'
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == 'ssh -l user 1.1.1.2' ]
}

@test "ansible_ssh_private_key_file without quote" {
  source ansiblessh.sh
  selected_item="host12 ansible_host=1.1.1.2 ansible_ssh_private_key_file=~/.ssh/id_rsa"
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == "ssh -i ~/.ssh/id_rsa 1.1.1.2" ]
}
@test "ansible_ssh_private_key_file including single quote" {
  skip
  source ansiblessh.sh
  selected_item="host12 ansible_host=1.1.1.2 ansible_ssh_private_key_file='~/.ssh/id_rsa test'"
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == "ssh -i '~/.ssh/id_rsa test' 1.1.1.2" ]
}
@test "ansible_ssh_private_key_file including double quote" {
  skip
  source ansiblessh.sh
  selected_item='host12 ansible_host=1.1.1.2 ansible_ssh_private_key_file="~/.ssh/id_rsa test"'
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == 'ssh -i "~/.ssh/id_rsa test" 1.1.1.2' ]
}

@test "ansible_ssh_common_args without quote" {
  source ansiblessh.sh
  selected_item="host12 ansible_host=1.1.1.2 ansible_ssh_common_args=-4"
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == "ssh -4 1.1.1.2" ]
}
@test "ansible_ssh_common_args including single quote" {
  source ansiblessh.sh
  selected_item="host12 ansible_host=1.1.1.2 ansible_ssh_common_args='-o ProxyCommand='\''ssh -W %h:%p host'\'''"
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == "ssh -o ProxyCommand='ssh -W %h:%p host' 1.1.1.2" ]
}
@test "ansible_ssh_common_args including double quote" {
  source ansiblessh.sh
  selected_item='host12 ansible_host=1.1.1.2 ansible_ssh_common_args='\''-o ProxyCommand="ssh -W %h:%p host"'\'''
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == 'ssh -o ProxyCommand="ssh -W %h:%p host" 1.1.1.2' ]
}

@test "ansible_ssh_extra_args without quote" {
  source ansiblessh.sh
  selected_item="host12 ansible_host=1.1.1.2 ansible_ssh_extra_args=-4"
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == "ssh -4 1.1.1.2" ]
}
@test "ansible_ssh_extra_args including single quote" {
  source ansiblessh.sh
  selected_item="host12 ansible_host=1.1.1.2 ansible_ssh_extra_args='-o ProxyCommand='\''ssh -W %h:%p host'\'''"
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == "ssh -o ProxyCommand='ssh -W %h:%p host' 1.1.1.2" ]
}
@test "ansible_ssh_extra_args including double quote" {
  source ansiblessh.sh
  selected_item='host12 ansible_host=1.1.1.2 ansible_ssh_extra_args='\''-o ProxyCommand="ssh -W %h:%p host"'\'''
  output=$(echo "${selected_item}" | ansiblessh::builder::build_ssh_cmd)
  [ "$output" == 'ssh -o ProxyCommand="ssh -W %h:%p host" 1.1.1.2' ]
}
