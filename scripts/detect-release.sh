#!/usr/bin/env bash
set -euo pipefail

current_pkgver=$(awk -F= '/^pkgver=/{print $2; exit}' PKGBUILD)
current_pkgrel=$(awk -F= '/^pkgrel=/{print $2; exit}' PKGBUILD)
current_fork_tag=$(awk -F"'" '/^_fork_tag=/{print $2; exit}' PKGBUILD)

force_release=${FORCE_RELEASE:-false}
fork_tag_override=${FORK_TAG_OVERRIDE:-}
pkgrel_override=${PKGREL_OVERRIDE:-}

latest_fork_tag() {
  git ls-remote --refs --tags https://github.com/OneNoted/codex.git 'aur-v*' |
    awk '{sub("refs/tags/","",$2); print $2}' |
    sort -V |
    tail -n 1
}

if [[ -n "$fork_tag_override" ]]; then
  fork_tag=$fork_tag_override
else
  fork_tag=$(latest_fork_tag)
fi

if [[ -z "$fork_tag" ]]; then
  echo "failed to determine fork tag" >&2
  exit 1
fi

if [[ ! "$fork_tag" =~ ^aur-v([0-9]+\.[0-9]+\.[0-9]+)-reasoning\.([0-9]+)$ ]]; then
  echo "unexpected fork tag format: $fork_tag" >&2
  exit 1
fi

pkgver=${BASH_REMATCH[1]}
should_release=false
reason="already at desired fork tag"

if [[ "$fork_tag" != "$current_fork_tag" ]]; then
  should_release=true
  if [[ "$pkgver" == "$current_pkgver" ]]; then
    pkgrel=${pkgrel_override:-$((10#$current_pkgrel + 1))}
    reason="fork tag changed within same upstream release"
  else
    pkgrel=${pkgrel_override:-1}
    reason="fork tag moved to a new upstream release"
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
fork_tag=$fork_tag
should_release=$should_release
reason=$reason
EOF
