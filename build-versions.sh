#!/usr/bin/env bash
# Génère versions.json à partir des fichiers corbuilder-x.y.z.zip présents dans ce dossier.
# Usage : ./build-versions.sh   (à lancer dans le dossier, après avoir ajouté ou retiré un zip)
#
# Pour chaque corbuilder-x.y.z.zip : numéro, nom du fichier, date (celle du fichier), empreinte SHA-256.
# Notes de version (facultatif) : un fichier notes/x.y.z.txt, une ligne par note.
# Les noms de zips sont relatifs : le dossier peut être déplacé d'un serveur à l'autre sans rien changer.
set -euo pipefail
cd "$(dirname "$0")"

sha() { if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi; }
esc() { sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/ /g'; }
fdate() { date -r "$1" +%F 2>/dev/null || stat -f %Sm -t %F "$1"; }

files=$(ls corbuilder-*.zip 2>/dev/null | grep -E '^corbuilder-[0-9]+\.[0-9]+\.[0-9]+\.zip$' | sort -t- -k2 -V -r || true)
if [ -z "$files" ]; then echo "Aucun fichier corbuilder-x.y.z.zip trouvé." >&2; exit 1; fi

out="versions.json.tmp"
{
  printf '{\n  "name": "Corbuilder",\n  "versions": [\n'
  first=1
  for f in $files; do
    v=${f#corbuilder-}; v=${v%.zip}
    [ $first -eq 1 ] || printf ',\n'
    first=0
    printf '    {\n      "version": "%s",\n      "file": "%s",\n      "sha256": "%s",\n      "date": "%s",\n      "notes": [' "$v" "$f" "$(sha "$f")" "$(fdate "$f")"
    if [ -f "notes/$v.txt" ]; then
      n=0
      while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        [ $n -eq 0 ] || printf ','
        printf '\n        "%s"' "$(printf '%s' "$line" | esc)"
        n=$((n+1))
      done < "notes/$v.txt"
      [ $n -eq 0 ] || printf '\n      '
    fi
    printf ']\n    }'
  done
  printf '\n  ]\n}\n'
} > "$out"
mv "$out" versions.json
echo "versions.json généré : $(echo "$files" | wc -l | tr -d ' ') version(s)."

git add .
git commit -m "Added new version"
git push
