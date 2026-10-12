#!/bin/sh
# Releases the VERSION in zidev: tag + push, then the brew tap points at it.
set -e
cd "$(dirname "$0")"
v=$(sed -n 's/^VERSION = "\(.*\)"/\1/p' zidev)
app/build.sh zip  # the app, ready built: brew installs it without Swift
git tag "v$v" 2>/dev/null || true
git push origin main "v$v"
gh release create "v$v" app/build/zidev-app.zip --title "zidev $v" --notes "brew upgrade zidev && zidev app"
url="https://github.com/zinoodev85/zidev/archive/refs/tags/v$v.tar.gz"
sha=$(curl -fsL "$url" | shasum -a 256 | cut -d' ' -f1)
app_url="https://github.com/zinoodev85/zidev/releases/download/v$v/zidev-app.zip"
app_sha=$(shasum -a 256 app/build/zidev-app.zip | cut -d' ' -f1)
tap=../homebrew-zidev
git -C "$tap" pull -q
sed -i '' -e "s|^  url \".*\"|  url \"$url\"|" -e "s|^  sha256 \".*\"|  sha256 \"$sha\"|" \
  -e "s|^    url \".*\"|    url \"$app_url\"|" -e "s|^    sha256 \".*\"|    sha256 \"$app_sha\"|" \
  "$tap/Formula/zidev.rb"
git -C "$tap" commit -qam "zidev $v"
git -C "$tap" push
echo "released zidev $v: brew upgrade zidev"
