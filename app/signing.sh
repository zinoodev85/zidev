#!/bin/sh
# One-time: a self-signed code signing identity "zidev local" in its own keychain (~/Library/Keychains/zidev.keychain-db).
# build.sh signs with it when it is there: the app keeps one identity across builds, so macOS keeps its
# Input Monitoring permission (cmd-cmd); ad-hoc signing makes every build a new app to macOS.
set -e
KC="$HOME/Library/Keychains/zidev.keychain-db"
security find-identity -p codesigning "$KC" 2>/dev/null | grep -q "zidev local" && { echo "zidev local: already there"; exit 0; }
T=$(mktemp -d)
cat > "$T/c.cnf" <<CNF
[req]
distinguished_name=dn
x509_extensions=ext
prompt=no
[dn]
CN=zidev local
[ext]
keyUsage=critical,digitalSignature
extendedKeyUsage=critical,codeSigning
basicConstraints=critical,CA:false
CNF
openssl req -x509 -newkey rsa:2048 -nodes -days 7300 -keyout "$T/k.pem" -out "$T/c.pem" -config "$T/c.cnf" 2>/dev/null
openssl pkcs12 -export -legacy -inkey "$T/k.pem" -in "$T/c.pem" -out "$T/i.p12" -passout pass:zidev 2>/dev/null \
  || openssl pkcs12 -export -inkey "$T/k.pem" -in "$T/c.pem" -out "$T/i.p12" -passout pass:zidev
security create-keychain -p zidev "$KC" 2>/dev/null || true
security unlock-keychain -p zidev "$KC"
security set-keychain-settings "$KC"  # never locks itself
security import "$T/i.p12" -k "$KC" -P zidev -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k zidev "$KC" >/dev/null
security list-keychains -d user -s $(security list-keychains -d user | tr -d '"') "$KC"
rm -rf "$T"
echo "zidev local: made"
