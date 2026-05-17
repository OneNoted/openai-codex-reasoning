#!/usr/bin/env bash
set -euo pipefail

current_pkgver=$(awk -F= '/^pkgver=/{print $2; exit}' PKGBUILD)
current_pkgrel=$(awk -F= '/^pkgrel=/{print $2; exit}' PKGBUILD)
current_upstream_tag="rust-v${current_pkgver}"
current_upstream_commit=$(awk -F"'" '/^_upstream_commit=/{print $2; exit}' PKGBUILD)

force_release=${FORCE_RELEASE:-false}
upstream_tag_override=${UPSTREAM_TAG_OVERRIDE:-}
pkgrel_override=${PKGREL_OVERRIDE:-}
source_repo="https://github.com/openai/codex.git"

latest_upstream_tag() {
  git ls-remote --refs --tags "$source_repo" 'rust-v*' |
    awk '{sub("refs/tags/","",$2); print $2}' |
    grep -E '^rust-v[0-9]+\.[0-9]+\.[0-9]+$' |
    sort -V |
    tail -n 1
}

resolve_upstream_commit() {
  local tag=${1:?tag required}
  local commit

  commit=$(git ls-remote "$source_repo" "refs/tags/${tag}^{}" | awk '{print $1}')
  if [[ -z "$commit" ]]; then
    commit=$(git ls-remote "$source_repo" "refs/tags/${tag}" | awk '{print $1}')
  fi

  printf '%s\n' "$commit"
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

if [[ -n "$pkgrel_override" && ! "$pkgrel_override" =~ ^[1-9][0-9]*$ ]]; then
  echo "unexpected pkgrel override: $pkgrel_override" >&2
  exit 1
fi

upstream_commit=$(resolve_upstream_commit "$upstream_tag")
if [[ ! "$upstream_commit" =~ ^[0-9a-f]{40}$ ]]; then
  echo "failed to resolve upstream commit for $upstream_tag" >&2
  exit 1
fi

should_release=false
reason="already at desired upstream tag"

if [[ "$upstream_tag" != "$current_upstream_tag" || "$upstream_commit" != "$current_upstream_commit" ]]; then
  should_release=true
  if [[ "$pkgver" == "$current_pkgver" ]]; then
    pkgrel=${pkgrel_override:-$((10#$current_pkgrel + 1))}
    reason="upstream source changed within same package version"
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
upstream_commit=$upstream_commit
should_release=$should_release
reason=$reason
EOF
