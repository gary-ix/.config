#!/usr/bin/env bash

# Present a numbered list of options and return the selected index (1-based).
# Usage:
#   choice="$(interactive_select "What do you want?" "Option A" "Option B" "Option C")"
#   case "$choice" in
#     1) echo "Chose A" ;;
#     2) echo "Chose B" ;;
#     3) echo "Chose C" ;;
#   esac
interactive_select() {
  local question="$1"
  shift
  local options=("$@")
  local choice

  if ((${#options[@]} == 0)); then
    log_error 'interactive_select: no options provided.'
    return 1
  fi

  printf '%s\n' "$question" >/dev/tty
  local i=1
  for option in "${options[@]}"; do
    printf '  %d) %s\n' "$i" "$option" >/dev/tty
    ((i++))
  done

  while true; do
    printf 'Enter choice (1-%d): ' "${#options[@]}" >/dev/tty
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#options[@]})); then
      printf '%s\n' "$choice"
      return 0
    fi
    log_error "Invalid choice. Please enter a number between 1 and ${#options[@]}."
  done
}
