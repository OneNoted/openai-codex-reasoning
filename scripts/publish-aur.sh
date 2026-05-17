#!/usr/bin/env bash
set -euo pipefail

aur_remote=${1:?usage: publish-aur.sh <aur-remote>}
pkgname=$(awk -F= '/^pkgname=/{print $2; exit}' PKGBUILD)
pkgver=$(awk -F= '/^pkgver=/{print $2; exit}' PKGBUILD)
pkgrel=$(awk -F= '/^pkgrel=/{print $2; exit}' PKGBUILD)
work_dir=$(mktemp -d)
repo_dir="$work_dir/aur"
trap 'rm -rf "$work_dir"' EXIT

git clone --depth 1 "$aur_remote" "$repo_dir"
find "$repo_dir" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp PKGBUILD .SRCINFO "$repo_dir/"

while IFS= read -r source_entry; do
  case "$source_entry" in
    *://*|git+*) continue ;;
  esac

  source_path=${source_entry#*::}
  cp "$source_path" "$repo_dir/"
done < <(awk -F' = ' '/^[[:space:]]*source = /{print $2}' .SRCINFO)

git -C "$repo_dir" config user.name "${GIT_AUTHOR_NAME:-Jonatan Jonasson}"
git -C "$repo_dir" config user.email "${GIT_AUTHOR_EMAIL:-notes@madeingotland.com}"
git -C "$repo_dir" add .

if git -C "$repo_dir" diff --cached --quiet; then
  printf 'AUR metadata already up to date for %s %s-%s\n' "$pkgname" "$pkgver" "$pkgrel"
  exit 0
fi

git -C "$repo_dir" commit -m "update to ${pkgver}-${pkgrel}"
git -C "$repo_dir" push origin HEAD:master
printf 'Published %s %s-%s to AUR\n' "$pkgname" "$pkgver" "$pkgrel"
