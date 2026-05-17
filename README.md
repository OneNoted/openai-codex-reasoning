# openai-codex-reasoning

Source AUR packaging repo for OpenAI Codex with raw reasoning traces enabled
by default.

## Package contract

- package name: `openai-codex-reasoning`
- installs the standard commands:
  `codex`, `codex-exec`, `codex-linux-sandbox`
- drop-in replacement for:
  `openai-codex`, `openai-codex-bin`

## Source strategy

This package is pinned to a fixed upstream release tag instead of tracking a
branch:

- upstream source: `openai/codex`
- upstream tag format: `rust-v<version>`
- downstream patch: `default-raw-reasoning.patch`

The downstream patch flips the default for `show_raw_agent_reasoning` to
`true`. If upstream changes that config path, the patch should fail during
package preparation rather than silently drifting.

## Release flow

- `validate.yml` checks packaging metadata on push and pull requests
- `release.yml` polls upstream for the latest stable `rust-v*` tag
- when the upstream tag changes:
  `PKGBUILD` and `.SRCINFO` are updated,
  the packaging repo is committed on `main`,
  and the flat AUR snapshot is pushed to `master`

The workflow applies the package-owned downstream patch during `prepare()`.

## Validation

```bash
./scripts/validate.sh
makepkg --printsrcinfo > .SRCINFO
```

`makepkg --verifysource` verifies the upstream tag source and the local
downstream patch.

## Maintainer

Jonatan Jonasson `<notes@madeingotland.com>`
