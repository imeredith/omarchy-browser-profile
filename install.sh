#!/bin/bash

# Makes the profile picker the default web browser, standing in for the
# current one, which it hands every link to once a profile is chosen.
#
#   install.sh [browser.desktop]   install (defaults to the current browser)
#   install.sh --uninstall         put the previous default browser back

set -e

plugin_id=imeredith.browser-profile
config="${XDG_CONFIG_HOME:-$HOME/.config}"
apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
state_dir="$config/$plugin_id"
entry_pattern='*-choose-profile.desktop'

# Same as omarchy-default-browser: xdg-settings must only see mimeapps.list,
# where the browser itself is kept, not the desktop-specific list that routes
# links through omarchy-browser.desktop.
set_default_browser() {
  env -u BROWSER XDG_CURRENT_DESKTOP= xdg-settings set default-web-browser "$1"
}

remove_entries() {
  find "$apps" -maxdepth 1 -name "$entry_pattern" -exec grep -l browser-profile-open {} + 2>/dev/null |
    xargs -r rm -f
}

if [[ ${1:-} == --uninstall ]]; then
  browser=$(cat "$state_dir/browser" 2>/dev/null || true)
  if [[ -n $browser ]]; then
    set_default_browser "$browser"
    echo "Default browser restored to $browser"
  fi
  remove_entries
  rm -rf "$state_dir"
  update-desktop-database "$apps" 2>/dev/null || true
  exit 0
fi

# Run the launcher from where the shell loads the plugin when it is there, so
# a symlinked checkout and a copied one both keep working.
if [[ -x $config/omarchy/plugins/$plugin_id/bin/browser-profile-open ]]; then
  launcher="$config/omarchy/plugins/$plugin_id/bin/browser-profile-open"
else
  launcher="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/bin/browser-profile-open"
fi
if [[ $launcher == *[[:space:]]* ]]; then
  echo "The launcher path can't contain spaces: $launcher" >&2
  exit 1
fi

browser=${1:-$(omarchy-cmd-default-browser)}
if [[ $browser == $entry_pattern ]]; then
  browser=$(cat "$state_dir/browser" 2>/dev/null || true)
fi
if [[ -z $browser ]]; then
  echo "No default browser found. Pass its desktop entry, e.g. install.sh google-chrome.desktop" >&2
  exit 1
fi

source_entry=""
IFS=: read -ra data_dirs <<<"${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
for data_dir in "${data_dirs[@]}"; do
  if [[ -r $data_dir/applications/$browser ]]; then
    source_entry="$data_dir/applications/$browser"
    break
  fi
done
if [[ -z $source_entry ]]; then
  echo "No desktop entry named $browser" >&2
  exit 1
fi

# The entry is named after the browser's own (google-chrome-choose-profile.desktop)
# so omarchy-launch-webapp still recognises it as a Chromium-based browser and
# keeps opening web apps with --app, which the launcher passes straight through.
entry="${browser%.desktop}-choose-profile.desktop"
name=$(sed -n 's/^Name=//p' "$source_entry" | head -1)
icon=$(sed -n 's/^Icon=//p' "$source_entry" | head -1)

remove_entries
mkdir -p "$apps" "$state_dir"
echo "$browser" >"$state_dir/browser"
cat >"$apps/$entry" <<EOF
[Desktop Entry]
Version=1.0
Name=${name:-Browser} (choose profile)
Comment=Ask which profile to open links in
Exec=$launcher %U
Icon=${icon:-web-browser}
Terminal=false
Type=Application
NoDisplay=true
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
EOF
update-desktop-database "$apps" 2>/dev/null || true

set_default_browser "$entry"
echo "Links now open through the profile picker, then $browser"
