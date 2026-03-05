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

set_black_wallpaper_and_screensaver() {
  local image_path

  image_path="$(create_black_background_image)"
  set_black_wallpaper "$image_path"
  set_black_screensaver "$image_path"
}

main() {
  run_step 'Set Black Wallpaper and Screen Saver' set_black_wallpaper_and_screensaver
  run_step 'Install File Associations' mac_file_associations
}

main "$@"
