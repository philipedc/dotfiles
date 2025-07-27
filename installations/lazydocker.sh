if command -v lazydocker >/dev/null 2>&1; then
  echo "Lazy Docker already installed, skipping..."
  exit 0
fi

# install lazydocker to ~/.local/bin/
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
