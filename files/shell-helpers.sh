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

# Add an existing directory to the front of PATH, moving it if it is already present.
path_prepend_if_exists() {
  if [ -d "$1" ]; then
    path_dir=$1
    path_rest=$PATH
    path_new=

    while :; do
      case "$path_rest" in
        *:*)
          path_part=${path_rest%%:*}
          path_rest=${path_rest#*:}
          ;;
        *)
          path_part=$path_rest
          path_rest=
          ;;
      esac

      if [ "$path_part" != "$path_dir" ] && [ -n "$path_part" ]; then
        if [ -n "$path_new" ]; then
          path_new="$path_new:$path_part"
        else
          path_new=$path_part
        fi
      fi

      if [ -z "$path_rest" ]; then
        break
      fi
    done

    export PATH="$path_dir${path_new:+:$path_new}"
    unset path_dir path_rest path_new path_part
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

activate_mise_shims() {
  if type mise > /dev/null 2>&1; then
    eval "$(mise activate "$1" --shims)"
    path_prepend_if_exists "${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims"
  fi
}
