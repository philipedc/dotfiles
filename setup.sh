#!/bin/bash -e
# exit if any command returns non-zero status

export DOTFILES_PATH=$HOME/.local/share/dotfiles

mkdir -p $DOTFILES_PATH

# Check if script is running with sudo privileges
if [ "$EUID" -eq 0 ]; then
    sudo apt update -y
	sudo apt upgrade -y
	sudo apt install -y curl git unzip

	for installer in ./installations/*.sh; do source $installer; done
fi

cp -r ./configs/bashrc.d/* $DOTFILES_PATH/

cat configs/.bashrc > $HOME/.bashrc

cat ./configs/.gitconfig > $HOME/.gitconfig
