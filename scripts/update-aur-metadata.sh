#!/usr/bin/env bash
set -euo pipefail

pkgver=${1:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <upstream_tag> <upstream_commit>}
pkgrel=${2:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <upstream_tag> <upstream_commit>}
upstream_tag=${3:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <upstream_tag> <upstream_commit>}
upstream_commit=${4:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <upstream_tag> <upstream_commit>}

[[ "$pkgver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "unexpected pkgver: $pkgver" >&2
  exit 1
}
[[ "$pkgrel" =~ ^[1-9][0-9]*$ ]] || {
  echo "unexpected pkgrel: $pkgrel" >&2
  exit 1
}
[[ "$upstream_tag" =~ ^rust-v[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "unexpected upstream tag: $upstream_tag" >&2
  exit 1
}
[[ "$upstream_commit" =~ ^[0-9a-f]{40}$ ]] || {
  echo "unexpected upstream commit: $upstream_commit" >&2
  exit 1
}

perl -0pi -e "s/^pkgver=.*/pkgver=${pkgver}/m; s/^pkgrel=.*/pkgrel=${pkgrel}/m; s/^_upstream_tag=\"[^\"]*\"/_upstream_tag=\"rust-v\\\${pkgver}\"/m; s/^_upstream_commit='[^']*'/_upstream_commit='${upstream_commit}'/m" PKGBUILD

print_srcinfo() {
  if [[ ${EUID} -ne 0 ]]; then
    makepkg --printsrcinfo
    return
  fi

  local temp_home
  temp_home=$(mktemp -d)
  trap 'rm -rf "$temp_home"' RETURN
  mkdir -p "$temp_home"/build "$temp_home"/log "$temp_home"/pkg "$temp_home"/src "$temp_home"/srcpkg
  chown -R 65534:65534 "$temp_home"
  HOME="$temp_home" \
  BUILDDIR="$temp_home/build" \
  LOGDEST="$temp_home/log" \
  PKGDEST="$temp_home/pkg" \
  SRCDEST="$temp_home/src" \
  SRCPKGDEST="$temp_home/srcpkg" \
    setpriv --reuid 65534 --regid 65534 --clear-groups makepkg --printsrcinfo
}

print_srcinfo > .SRCINFO

printf 'Updated PKGBUILD and .SRCINFO for %s-%s (%s)\n' "$pkgver" "$pkgrel" "$upstream_tag"
