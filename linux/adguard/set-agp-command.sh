# Install a helper command `agp` that auto-sources the script:
if ! grep -q 'agp()' ~/.bashrc 2>/dev/null; then
  printf '\n# AdGuard proxy helper\nagp(){ source "$HOME/bin/ag-proxy.sh" "$@"; }\n' >> ~/.bashrc
fi

# For zsh:
if [ -n "$ZSH_VERSION" ] && ! grep -q 'agp()' ~/.zshrc 2>/dev/null; then
  printf '\n# AdGuard proxy helper\nagp(){ source "$HOME/bin/ag-proxy.sh" "$@"; }\n' >> ~/.zshrc
fi

# Load it now in the current shell:
agp() { source "$HOME/bin/ag-proxy.sh" "$@"; }

# Now use as:
# `agp` -> auto detect & apply (default mode)
# `agp --on` -> start + apply
# `agp --off` -> stop + clear
