# Browser profile picker

Asks which browser profile to use when a link is opened from outside the
browser (from Slack, a terminal, `xdg-open`, the desktop portal, ...). Links
clicked inside the browser stay where they are.

Works with Chromium-based browsers: Chrome, Chromium, Brave, Edge and Vivaldi.
With only one profile, or when the shell isn't running, links open straight in
the browser as before.

## Requirements

- Omarchy with `omarchy-shell`
- A Chromium-based browser
- `jq`, `xdg-utils` and `desktop-file-utils`, which come with Omarchy

`install.sh` changes your default web browser, so it's a separate step you run
yourself. It writes only `~/.config/imeredith.browser-profile/` and one
`<browser>-choose-profile.desktop` entry in `~/.local/share/applications/`, and
`install.sh --uninstall` removes both.

## How it works

Omarchy sends links through `omarchy-browser.desktop` to
`omarchy-launch-browser`, which hands them to the default browser.
`install.sh` makes `bin/browser-profile-open` the default browser, through a
`<browser>-choose-profile.desktop` entry, and remembers the real browser in
`~/.config/imeredith.browser-profile/browser`.

When `browser-profile-open` gets bare links it reads the profiles from the
browser's `Local State` and summons this overlay. Choosing a profile runs it
again with `--profile-directory=<dir>`, which passes the links to the real
browser. Anything else, such as `--app=` from web apps, `--incognito` or a
launch with no link, goes to the real browser straight away.

## Install

```bash
omarchy plugin add https://github.com/imeredith/omarchy-browser-profile.git --enable
~/.config/omarchy/plugins/imeredith.browser-profile/install.sh   # or: install.sh brave-browser.desktop
```

`omarchy plugin add` doesn't run `install.sh` for you. To work on the plugin
from a local checkout, symlink it in instead:

```bash
ln -s ~/personal/omarchy-browser-profile ~/.config/omarchy/plugins/imeredith.browser-profile
omarchy-shell shell rescanPlugins
omarchy plugin enable imeredith.browser-profile
```

Re-run `install.sh` after switching browsers with `omarchy default browser`.

## Keys

| Key                  | Action                         |
|----------------------|--------------------------------|
| `1`–`9`              | Open in that profile           |
| `↑`/`↓`, `j`/`k`, Tab | Move the selection             |
| `Enter`              | Open in the selected profile   |
| `Esc`                | Don't open the link            |

The last used profile is selected when the picker opens.

## Remove

```bash
~/.config/omarchy/plugins/imeredith.browser-profile/install.sh --uninstall
omarchy plugin remove imeredith.browser-profile
```

`install.sh --uninstall` puts the previous default browser back. Run it before
removing the plugin, as otherwise links are sent to a launcher that no longer
exists.

## License

MIT. See [LICENSE](LICENSE).
