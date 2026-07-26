# TASKS.md

Roadmap for the next development pass.

## In Progress

- [ ] DMG packaging validation outside Codex sandbox
  - `build_dmg.sh` is implemented and executable.
  - Xcode build succeeds.
  - Codex shell cannot run `swift build` here because `.build/build.db` is read-only under sandbox restrictions.
  - Run `./build_dmg.sh` from a normal Terminal session to produce `dist/Translator.dmg`.

## Planned

## Done

- [x] Panel size modes
  - Added compact, standard, and wide panel modes.
  - Stored the selected mode in `UserDefaults`.
  - Applied the mode to the main translator panel.

- [x] Privacy engine indicator
  - Shows when text is sent to Google online translation.
  - Shows when Apple on-device translation is used.
  - Shows offline-only state before translation.

- [x] Offline-only mode
  - Added a setting that disables Google translation completely.
  - Uses only Apple Translation when enabled.
  - Shows a clear error if the required offline languages are not installed.

- [x] DMG packaging
  - Added `build_dmg.sh`.
  - The script includes `Translator.app`, `README.md`, and `LICENSE`.
  - Generated artifacts are ignored through `.gitignore`.

- [x] App update checks
  - Added a lightweight manual update check.
  - Uses `TranslatorLatestReleaseURL` from `Info.plist` when configured.
  - Keeps update checks optional and transparent.

- [x] First-run setup
  - Added a first-launch setup window.
  - Checks Accessibility permission.
  - Explains hotkeys.
  - Offers opening offline language downloads.
  - Offers theme selection.

- [x] GitHub-ready README.
- [x] MIT License.
- [x] Public-safe project documentation.
- [x] Glass themes: Neon Glass and Frost Glass.
