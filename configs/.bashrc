export DOTFILES_PATH=$HOME/.local/share/dotfiles

for config in $DOTFILES_PATH/*; do source $config; done