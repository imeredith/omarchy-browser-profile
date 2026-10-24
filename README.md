# Browser profile picker

Asks which browser profile to use when a link is opened from outside the
browser (from Slack, a terminal, `xdg-open`, the desktop portal, ...). Links
clicked inside the browser stay where they are.

Works with Chromium-based browsers: Chrome, Chromium, Brave, Edge and Vivaldi.
With only one profile, or when the shell isn't running, links open straight in
the browser as before.

## How it works

Omarchy sends links through `omarchy-browser.desktop` to
`omarchy-launch-browser`, which hands them to the default browser.
`install.sh` makes `bin/browser-profile-open` the default browser, through a
`<browser>-choose-profile.desktop` entry, and remembers the real browser in
`~/.config/direkiwi.browser-profile/browser`.

When `browser-profile-open` gets bare links it reads the profiles from the
browser's `Local State` and summons this overlay. Choosing a profile runs it
again with `--profile-directory=<dir>`, which passes the links to the real
browser. Anything else, such as `--app=` from web apps, `--incognito` or a
launch with no link, goes to the real browser straight away.

## Install

```bash
ln -s ~/omarchy-plugins/direkiwi.browser-profile ~/.config/omarchy/plugins/direkiwi.browser-profile
omarchy-shell shell rescanPlugins
omarchy plugin enable direkiwi.browser-profile
~/.config/omarchy/plugins/direkiwi.browser-profile/install.sh   # or: install.sh brave-browser.desktop
```

`install.sh --uninstall` puts the previous default browser back. Re-run
`install.sh` after switching browsers with `omarchy default browser`.

## Keys

| Key                  | Action                         |
|----------------------|--------------------------------|
| `1`–`9`              | Open in that profile           |
| `↑`/`↓`, `j`/`k`, Tab | Move the selection             |
| `Enter`              | Open in the selected profile   |
| `Esc`                | Don't open the link            |

The last used profile is selected when the picker opens.
