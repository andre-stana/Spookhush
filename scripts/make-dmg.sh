#!/bin/zsh
# Packs build/Spookhush.app into dist/Spookhush.dmg with the custom drag-to-Applications window.
set -euo pipefail
cd "$(dirname "$0")/.."

app=${1:-build/Spookhush.app}
out=${2:-dist/Spookhush.dmg}
dmgbuild_version=1.6.7
dmgbuild=.build/dmgbuild/bin/dmgbuild

if [[ ! -d "$app" ]]; then
    ./build.sh
fi

if [[ ! -x "$dmgbuild" ]]; then
    python3 -m venv .build/dmgbuild
    .build/dmgbuild/bin/pip install -q "dmgbuild==$dmgbuild_version"
fi

mkdir -p "$(dirname "$out")"
rm -f "$out"

artwork=$(mktemp -d)
swift scripts/make-dmg-background.swift "$artwork/background.png" 1 >/dev/null
swift scripts/make-dmg-background.swift "$artwork/background@2x.png" 2 >/dev/null
tiffutil -cathidpicheck "$artwork/background.png" "$artwork/background@2x.png" -out "$artwork/background.tiff" 2>/dev/null
"$dmgbuild" -s scripts/dmg-settings.py -D app="$app" -D background="$artwork/background.tiff" Spookhush "$out" 2>/dev/null
rm -rf "$artwork"

codesign --force --sign "${IDENTITY:--}" "$out"
echo "Built $out"
