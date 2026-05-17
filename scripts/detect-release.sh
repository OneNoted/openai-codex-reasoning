#!/usr/bin/env bash
set -euo pipefail

current_pkgver=$(awk -F= '/^pkgver=/{print $2; exit}' PKGBUILD)
current_pkgrel=$(awk -F= '/^pkgrel=/{print $2; exit}' PKGBUILD)
current_upstream_tag="rust-v${current_pkgver}"

force_release=${FORCE_RELEASE:-false}
upstream_tag_override=${UPSTREAM_TAG_OVERRIDE:-}
pkgrel_override=${PKGREL_OVERRIDE:-}

latest_upstream_tag() {
  git ls-remote --refs --tags https://github.com/openai/codex.git 'rust-v*' |
    awk '{sub("refs/tags/","",$2); print $2}' |
    grep -E '^rust-v[0-9]+\.[0-9]+\.[0-9]+$' |
    sort -V |
    tail -n 1
}

if [[ -n "$upstream_tag_override" ]]; then
  upstream_tag=$upstream_tag_override
else
  upstream_tag=$(latest_upstream_tag)
fi

if [[ -z "$upstream_tag" ]]; then
  echo "failed to determine upstream tag" >&2
  exit 1
fi

if [[ ! "$upstream_tag" =~ ^rust-v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  echo "unexpected upstream tag format: $upstream_tag" >&2
  exit 1
fi

pkgver=${BASH_REMATCH[1]}
should_release=false
reason="already at desired upstream tag"

if [[ "$upstream_tag" != "$current_upstream_tag" ]]; then
  should_release=true
  if [[ "$pkgver" == "$current_pkgver" ]]; then
    pkgrel=${pkgrel_override:-$((10#$current_pkgrel + 1))}
    reason="upstream tag changed within same package version"
  else
    pkgrel=${pkgrel_override:-1}
    reason="new upstream release"
  fi
elif [[ -n "$pkgrel_override" && "$pkgrel_override" != "$current_pkgrel" ]]; then
  should_release=true
  pkgrel=$pkgrel_override
  reason="pkgrel override requested"
elif [[ "$force_release" == "true" ]]; then
  should_release=true
  pkgrel=${pkgrel_override:-$((10#$current_pkgrel + 1))}
  reason="forced release requested"
else
  pkgrel=$current_pkgrel
fi

cat <<EOF
pkgver=$pkgver
pkgrel=$pkgrel
upstream_tag=$upstream_tag
should_release=$should_release
reason=$reason
EOF
