#!/usr/bin/env bash
# Export the signed Android App Bundle (for Google Play) and a sideload APK
# into build/android/. Used by release.yml on a tag (with the upload key from
# the google-play environment) and by android.yml (with a throwaway key, to
# prove the build works before a tag needs it).
#
# env: GODOT                  the Godot editor binary (export templates installed)
#      TAG                    v1.76 or v1.76.1: the version name, and the
#                             version code MAJOR*10000 + MINOR*100 + PATCH
#      ANDROID_KEYSTORE_PATH  the keystore file
#      ANDROID_KEY_ALIAS      its key's alias
#      ANDROID_KEY_PASSWORD   the keystore's and the key's password
# ANDROID_HOME and JAVA_HOME must point at the SDK and a JDK 17.
#
# The key reaches Godot through its own GODOT_ANDROID_KEYSTORE_RELEASE_*
# variables, so it is never written into export_presets.cfg. The preset's
# version is edited for the export and put back afterwards.
set -euo pipefail
: "${GODOT:?}" "${TAG:?}" "${ANDROID_KEYSTORE_PATH:?}" "${ANDROID_KEY_ALIAS:?}" "${ANDROID_KEY_PASSWORD:?}"

if [[ ! "$TAG" =~ ^v([0-9]+)\.([0-9]+)(\.([0-9]+))?$ ]]; then
  echo "TAG must look like v1.76 or v1.76.1, got: $TAG"
  exit 1
fi
maj="${BASH_REMATCH[1]}"
min="${BASH_REMATCH[2]}"
pat="${BASH_REMATCH[4]:-0}"
if (( min > 99 || pat > 99 )); then
  echo "MINOR and PATCH must stay under 100 for the version code: $TAG"
  exit 1
fi
name="${TAG#v}"
code=$(( 10#$maj * 10000 + 10#$min * 100 + 10#$pat ))
echo "Android version ${name} (code ${code})"

export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$ANDROID_KEYSTORE_PATH"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$ANDROID_KEY_ALIAS"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$ANDROID_KEY_PASSWORD"

orig="$(mktemp)"
cp export_presets.cfg "$orig"
trap 'cp "$orig" export_presets.cfg; rm -f "$orig"' EXIT

sed -i -E "s/^version\/code=.*/version\/code=${code}/; s/^version\/name=.*/version\/name=\"${name}\"/" export_presets.cfg
grep -q "^version/code=${code}$" export_presets.cfg

# a gradle build exports through the project's android/ template, which is
# not committed: install it from the export templates for this export
if [ ! -d android/build ]; then
  "$GODOT" --headless --path . --install-android-build-template
fi
test -d android/build

mkdir -p build/android
"$GODOT" --headless --path . --export-release "Android" build/android/PathOfLeashResistance.aab
test -s build/android/PathOfLeashResistance.aab
# the same build as an APK, to install by hand
sed -i 's/^gradle_build\/export_format=1/gradle_build\/export_format=0/' export_presets.cfg
"$GODOT" --headless --path . --export-release "Android" build/android/PathOfLeashResistance.apk
test -s build/android/PathOfLeashResistance.apk
ls -l build/android
