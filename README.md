# openai-codex-reasoning

Source AUR packaging repo for the OneNoted Codex fork that shows inline
reasoning traces in the TUI.

## Package contract

- package name: `openai-codex-reasoning`
- installs the standard commands:
  `codex`, `codex-exec`, `codex-linux-sandbox`
- drop-in replacement for:
  `openai-codex`, `openai-codex-bin`

## Source strategy

This package is pinned to a fixed fork tag instead of tracking a branch:

- upstream base: `rust-v0.124.0`
- fork tag: `aur-v0.124.0-reasoning.1`

The fork tag is expected to point at the rebased reasoning-trace change on top
of the upstream release tag.

## Release flow

- `validate.yml` checks packaging metadata on push and pull requests
- `release.yml` polls the fork for the latest `aur-v*-reasoning.*` tag
- when the fork tag changes:
  `PKGBUILD` and `.SRCINFO` are updated,
  the packaging repo is committed on `main`,
  and the flat AUR snapshot is pushed to `master`

The workflow assumes the fork repo already contains the rebased reasoning
change and that the only packaging input is the published fork tag.

## Validation

```bash
./scripts/validate.sh
makepkg --printsrcinfo > .SRCINFO
```

`makepkg --verifysource` will only succeed after the fork tag has been pushed to
GitHub.

## Maintainer

Jonatan Jonasson `<notes@madeingotland.com>`
