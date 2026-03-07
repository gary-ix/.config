#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

. "$LIB_DIR/logging.sh"

create_black_background_image() {
  local image_path='/System/Library/Desktop Pictures/Solid Colors/Black.png'

  if [[ ! -f "$image_path" ]]; then
    log_error "Missing built-in black wallpaper: $image_path"
    exit 1
  fi

  printf '%s\n' "$image_path"
}

set_black_wallpaper() {
  local image_path="$1"

  osascript <<EOF
tell application "System Events"
  tell every desktop
    set picture to POSIX file "$image_path"
  end tell
end tell
EOF

  log_info "Wallpaper set to black: $image_path"
}

set_black_screensaver() {
  local image_path="$1"
  local image_dir='/System/Library/Desktop Pictures/Solid Colors'

  defaults -currentHost write com.apple.screensaver moduleDict -dict \
    moduleName 'iLifeSlideShows' \
    path '/System/Library/Frameworks/ScreenSaver.framework/PlugIns/iLifeSlideshows.saver' \
    type -int 0

  defaults -currentHost write com.apple.ScreenSaverPhotoChooser SelectedSource -int 3
  defaults -currentHost write com.apple.ScreenSaverPhotoChooser SelectedFolderPath -string "$image_dir"
  defaults -currentHost write com.apple.ScreenSaverPhotoChooser LastViewedPhotoPath -string "$image_path"
  defaults -currentHost write com.apple.ScreenSaverPhotoChooser ShufflesPhotos -bool false

  log_info 'Screen saver configured to use black image folder.'
}

mac_file_associations() {
  local script_path="$SCRIPT_DIR/mac-file-associations.sh"

  if [[ ! -f "$script_path" ]]; then
    log_error "Missing file associations script: $script_path"
    exit 1
  fi

  bash "$script_path"
}

configure_remote_access() {
  local ard_kickstart='/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart'

  if ! sudo -v; then
    log_error 'Unable to acquire sudo privileges for remote access setup.'
    exit 1
  fi

  if ! sudo launchctl enable system/com.openssh.sshd; then
    log_error 'Failed to enable sshd service.'
    log_error 'Enable Remote Login manually in System Settings > General > Sharing.'
    exit 1
  fi

  sudo launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist >/dev/null 2>&1 || true
  sudo launchctl kickstart -k system/com.openssh.sshd >/dev/null 2>&1 || true

  if ! sudo launchctl print system/com.openssh.sshd >/dev/null 2>&1; then
    log_error 'Remote Login (SSH) could not be verified as enabled.'
    log_error 'Enable it manually in System Settings > General > Sharing > Remote Login.'
    exit 1
  fi

  if ! sudo /usr/sbin/systemsetup -setremotelogin on >/dev/null 2>&1; then
    log_error 'Failed to set Remote Login to on via systemsetup.'
    log_error 'Enable it manually in System Settings > General > Sharing > Remote Login.'
    exit 1
  fi

  sudo /usr/sbin/dseditgroup -o delete com.apple.access_ssh >/dev/null 2>&1 || true

  if ! sudo launchctl enable system/com.apple.screensharing; then
    log_error 'Failed to enable Screen Sharing service.'
    exit 1
  fi

  sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist >/dev/null 2>&1 || true
  sudo launchctl kickstart -k system/com.apple.screensharing >/dev/null 2>&1 || true

  if ! sudo launchctl print system/com.apple.screensharing >/dev/null 2>&1; then
    log_error 'Screen Sharing service could not be verified as loaded.'
    log_error 'Enable it manually in System Settings > General > Sharing > Screen Sharing.'
    exit 1
  fi

  if [[ -x "$ard_kickstart" ]]; then
    sudo "$ard_kickstart" -activate -configure -allowAccessFor -allUsers >/dev/null 2>&1 || true

    if sudo "$ard_kickstart" -configure -clientopts -setreqperm -reqperm yes -setvnclegacy -vnclegacy no >/dev/null 2>&1; then
      log_info 'Screen Sharing set to request permission for control with no VNC password mode.'
    else
      log_info 'Could not enforce Screen Sharing control-request/no-password options via kickstart on this macOS version.'
      log_info 'Set this manually in System Settings > General > Sharing > Screen Sharing > i.'
    fi
  else
    log_info "Skipping Screen Sharing option tuning; missing tool: $ard_kickstart"
  fi

  sudo /usr/sbin/dseditgroup -o delete com.apple.access_screensharing >/dev/null 2>&1 || true

  log_info 'Remote Login (SSH) enabled.'
  log_info 'Remote Login access set to all users.'
  log_info 'Screen Sharing (VNC) enabled.'
  log_info 'Screen Sharing access set to all users.'
  log_info 'If needed, enable "Allow full disk access for remote users" in System Settings > General > Sharing > Remote Login > i.'

  if [[ -d '/Applications/Tailscale.app' ]]; then
    log_info 'Tailscale app detected. Sign in to attach this Mac to your tailnet.'
  else
    log_error 'Tailscale.app not found in /Applications.'
    log_error 'Install tailscale-app first to use private-network VNC/SSH access.'
    exit 1
  fi
}

first_existing_path() {
  local path

  for path in "$@"; do
    if [[ -d "$path" ]]; then
      printf '%s\n' "$path"
      return 0
    fi
  done

  return 1
}

resolve_required_app_path() {
  local app_name="$1"
  shift

  local resolved_path
  if ! resolved_path="$(first_existing_path "$@")"; then
    log_error "Unable to find ${app_name}. Checked: $*"
    exit 1
  fi

  printf '%s\n' "$resolved_path"
}

add_dock_app() {
  local app_path="$1"
  local entry

  entry="<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>${app_path}</string><key>_CFURLStringType</key><integer>0</integer></dict></dict><key>tile-type</key><string>file-tile</string></dict>"
  defaults write com.apple.dock persistent-apps -array-add "$entry"
}

configure_dock() {
  local safari_app
  local notes_app
  local ghostty_app
  local system_settings_app
  local iphone_mirroring_app

  safari_app="$(resolve_required_app_path 'Safari.app' '/Applications/Safari.app' '/System/Cryptexes/App/System/Applications/Safari.app' '/System/Applications/Safari.app')"
  notes_app="$(resolve_required_app_path 'Notes.app' '/System/Applications/Notes.app' '/Applications/Notes.app')"
  ghostty_app="$(resolve_required_app_path 'Ghostty.app' '/Applications/Ghostty.app')"
  system_settings_app="$(resolve_required_app_path 'System Settings.app' '/System/Applications/System Settings.app')"
  iphone_mirroring_app="$(resolve_required_app_path 'iPhone Mirroring.app' '/System/Applications/iPhone Mirroring.app')"

  defaults write com.apple.dock persistent-apps -array
  add_dock_app "$safari_app"
  add_dock_app "$notes_app"
  add_dock_app "$ghostty_app"
  add_dock_app "$system_settings_app"
  add_dock_app "$iphone_mirroring_app"

  defaults write com.apple.dock persistent-others -array
  defaults write com.apple.dock show-recents -bool false
  killall Dock >/dev/null 2>&1 || true

  log_info 'Dock updated with chosen apps, no downloads stack, and no recent apps section.'
}

set_black_wallpaper_and_screensaver() {
  local image_path

  image_path="$(create_black_background_image)"
  set_black_wallpaper "$image_path"
  set_black_screensaver "$image_path"
}

main() {
  run_step 'Set Black Wallpaper and Screen Saver' set_black_wallpaper_and_screensaver
  run_step 'Install File Associations' mac_file_associations
  run_step 'Configure Remote Access' configure_remote_access
  run_step 'Configure Dock' configure_dock
}

main "$@"
