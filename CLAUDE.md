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
- `id` must stay `direkiwi.browser-profile`. `omarchy plugin add` installs the repo into
  `~/.config/omarchy/plugins/<id>/`, so renaming it breaks updates for anyone
  who has it installed.
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
ln -s ~/personal/direkiwi.browser-profile ~/.config/omarchy/plugins/direkiwi.browser-profile   # once
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

## Git

Commit as the repo's configured git user. This repo was split out of
`~/omarchy-plugins`, which holds the history from before the split.
