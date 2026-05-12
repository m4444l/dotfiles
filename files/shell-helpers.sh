source_if_exists() {
  if [ -f "$1" ]; then
    . "$1"
  fi
}

select_editor() {
  if type code > /dev/null 2>&1 && [ -z "$SSH_CONNECTION" ]; then
    export EDITOR="code --wait"
  elif type nvim > /dev/null 2>&1; then
    export EDITOR="nvim"
  elif type vim > /dev/null 2>&1; then
    export EDITOR="vim"
  else
    echo "Warning: no suitable editor found (code, nvim, vim)"
  fi
}

path_prepend_if_exists() {
  if [ -d "$1" ]; then
    case ":$PATH:" in
      *":$1:"*) ;;
      *) export PATH="$1:$PATH" ;;
    esac
  fi
}

add_common_dirs_to_path() {
  path_prepend_if_exists "/opt/homebrew/bin"
  path_prepend_if_exists "/opt/homebrew/opt/postgresql@18/bin"
  path_prepend_if_exists "/opt/homebrew/opt/sqlite/bin"
  path_prepend_if_exists "$HOME/.lmstudio/bin"
  path_prepend_if_exists "$HOME/.local/bin"
}

activate_brew() {
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv "$@")"
  elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv "$@")"
  elif type brew > /dev/null 2>&1; then
    eval "$(brew shellenv "$@")"
  fi
}
