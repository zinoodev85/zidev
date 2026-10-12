#!/bin/sh
# Releases the VERSION in zidev: tag + push, then the brew tap points at it.
set -e
cd "$(dirname "$0")"
v=$(sed -n 's/^VERSION = "\(.*\)"/\1/p' zidev)
git tag "v$v" 2>/dev/null || true
git push origin main "v$v"
url="https://github.com/zinoodev85/zidev/archive/refs/tags/v$v.tar.gz"
sha=$(curl -fsL "$url" | shasum -a 256 | cut -d' ' -f1)
tap=../homebrew-zidev
sed -i '' -e "s|^  url \".*\"|  url \"$url\"|" -e "s|^  sha256 \".*\"|  sha256 \"$sha\"|" "$tap/Formula/zidev.rb"
git -C "$tap" commit -qam "zidev $v"
git -C "$tap" push
echo "released zidev $v: brew upgrade zidev"
