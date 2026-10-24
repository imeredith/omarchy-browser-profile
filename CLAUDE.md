# CLAUDE.md

This repo is one Omarchy shell plugin, `direkiwi.browser-profile`. It's QML
loaded by `omarchy-shell`, a long-running Quickshell process. See README.md for
the user-facing overview.

## Layout

- `manifest.json`: the plugin manifest, at the repo root so
  `omarchy plugin add <git-url>` can install the repo directly.
- `ProfilePicker.qml`: the overlay (`keepLoaded`). It's summoned over IPC with
  the links and the browser's profiles.
- `bin/browser-profile-open`: stands in for the default browser. It sends bare
  links to the picker and everything else straight to the real browser.
- `install.sh`: makes `browser-profile-open` the default browser and remembers
  the real one in `~/.config/direkiwi.browser-profile/browser`.
  `install.sh --uninstall` reverses it. `omarchy plugin add` never runs it,
  so users run it themselves after installing.

Keep the IPC payload (`{ launcher, lastUsed, urls, profiles }`) in step
between `bin/browser-profile-open` and `ProfilePicker.qml`.

## Manifest rules (enforced by `omarchy plugin validate`)

- `"schemaVersion": 1` must be the number 1, not the string `"1"`.
- Required fields: `id`, `name`, `version`, `kinds` (a non-empty array) and
  `entryPoints` (an object).
- `id` must stay `direkiwi.browser-profile`. The repo is named
  `omarchy-browser-profile`, like other Omarchy plugin repos, but
  `omarchy plugin add` installs it into `~/.config/omarchy/plugins/<id>/`.
  Renaming the id breaks updates for anyone who has it installed. Ids can't
  use `omarchy.*`, which is reserved for Omarchy's built-in plugins.
- Every kind needs its entry point: `bar-widget`→`barWidget`, `panel`→`panel`,
  `overlay`→`overlay`, `menu`→`menu`, `service`→`service`, `bar`→`bar`.
- Entry points must be relative paths, with no `..`, to files that exist.
- No symlinks anywhere in the repo.

Run `omarchy plugin validate .` after every manifest change. Bump `version`
when releasing a change.

## Reference material

- `/usr/share/omarchy/shell/README.md`: manifest schema, kinds, host-injected
  properties (`omarchyPath`, `shell`, `manifest`, `pluginRegistry`,
  `barWidgetRegistry`), IPC contract and `keepLoaded`.
- `/usr/share/omarchy/shell/plugins/`: built-in plugin source. Copy its idioms
  (theme singletons, widget structure) instead of inventing new ones.
- `/usr/share/omarchy/shell/services/PluginRegistry.qml`: the authoritative
  loader and validation logic.
- `/usr/share/omarchy/bin/`: the `omarchy-*` commands this plugin calls.
- `/usr/share/omarchy/default/agents/skills/omarchy/`: Omarchy's own agent
  skill docs.

Never edit anything under `/usr/share/omarchy`. It is the system install and is
overwritten on update.

## Testing

```bash
ln -s ~/personal/omarchy-browser-profile ~/.config/omarchy/plugins/direkiwi.browser-profile   # once
omarchy-shell shell rescanPlugins
omarchy plugin enable direkiwi.browser-profile
omarchy plugin list --json          # confirm it was discovered
omarchy restart shell               # needed for keepLoaded plugins
```

Edits made through the symlink may not trigger the shell's file watcher, so run
`rescanPlugins` if a change doesn't show up. QML load errors appear on the
shell's console/journal rather than in the CLI.

Third-party plugins get capability-scoped facades instead of the trusted host
objects. Don't rely on reaching into other plugins' services or auth state.

## Publishing

The plugin is listed at [plugins.omarchy.org](https://plugins.omarchy.org).
Its submission rules are in `SUBMISSION.md` and `SECURITY.md` of
`omacom/omarchy-plugin-marketplace`. Keep these true:

- `manifest.json`, `README.md` and `LICENSE` at the repo root. The README needs
  install and removal steps and lists every dependency.
- `omarchy plugin validate .` passes, and
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell <file>.qml` exits 0 for
  each QML file.
- Nothing changes user configuration without the user choosing it.
- The marketplace's security scan sends a plugin for maintainer review if any
  file, docs included, mentions privilege escalation, package installs or
  systemd service control, or if the repo has an install script. Don't add
  these without need. The scan's patterns are listed in the marketplace's
  `SECURITY.md`. Don't copy them into this repo, as quoting them counts too.
- An optional `preview.png` (or `.jpg`/`.webp`) at the root is used as the
  listing image.

After a change is published, request re-verification of the new commit with
the marketplace's "Plugin verification" issue form.

## Git

Commit as the repo's configured git user. This repo was split out of
`~/omarchy-plugins`, which holds the history from before the split.
