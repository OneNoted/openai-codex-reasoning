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

## Validation

```bash
./scripts/validate.sh
makepkg --printsrcinfo > .SRCINFO
```

`makepkg --verifysource` will only succeed after the fork tag has been pushed to
GitHub.

## Maintainer

Jonatan Jonasson `<notes@madeingotland.com>`
