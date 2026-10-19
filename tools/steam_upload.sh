#!/usr/bin/env bash
# Upload a Windows export as a Steam depot. See docs/STEAM.md.
# With none of the four settings present this exits 0, so a tag can still
# publish itch before the Steam app exists. STEAM_REQUIRED=1 makes that
# same gap a failure. Any setting without the other three always fails.
# STEAM_CONFIG_VDF is never printed.
set -euo pipefail

CONTENT="${1:-build/win}"

names=(STEAM_USERNAME STEAM_CONFIG_VDF STEAM_APP_ID STEAM_DEPOT_ID)
present=()
missing=()
for name in "${names[@]}"; do
	if [ -n "${!name:-}" ]; then
		present+=("$name")
	else
		missing+=("$name")
	fi
done

if [ "${#present[@]}" -eq 0 ]; then
	echo "Steam upload is not configured."
	echo "The Windows export is the depot content. See docs/STEAM.md."
	if [ "${STEAM_REQUIRED:-}" = "1" ]; then
		exit 1
	fi
	exit 0
fi

if [ "${#missing[@]}" -gt 0 ]; then
	echo "Steam upload is only partly configured (missing: ${missing[*]})."
	echo "Refusing to upload nothing and call it done. See docs/STEAM.md."
	exit 1
fi

if ! [[ "${STEAM_APP_ID}" =~ ^[0-9]+$ && "${STEAM_DEPOT_ID}" =~ ^[0-9]+$ ]]; then
	echo "STEAM_APP_ID and STEAM_DEPOT_ID must be numbers."
	exit 1
fi

if [ ! -f "${CONTENT}/PathOfLeashResistance.exe" ]; then
	echo "No PathOfLeashResistance.exe in ${CONTENT}."
	exit 1
fi

DESC="${GITHUB_REF_NAME:-local}"
case "${DESC}" in
	*\"*|*[$'\n']*)
		echo "The ref name cannot be written into the depot description."
		exit 1
		;;
esac

ROOT="$(mktemp -d)"
cleanup() {
	rm -rf "${ROOT}"
}
trap cleanup EXIT

CONTENT_ABS="$(cd "${CONTENT}" && pwd)"
mkdir -p "${ROOT}/output"
cat > "${ROOT}/app_build.vdf" <<EOF
"AppBuild"
{
	"AppID" "${STEAM_APP_ID}"
	"Desc" "${DESC}"
	"ContentRoot" "${CONTENT_ABS}"
	"BuildOutput" "${ROOT}/output"
	"Depots"
	{
		"${STEAM_DEPOT_ID}"
		{
			"FileMapping"
			{
				"LocalPath" "*"
				"DepotPath" "."
				"recursive" "1"
			}
		}
	}
}
EOF

# A one-time steamcmd login's config.vdf, base64, from the STEAM_CONFIG_VDF
# secret. It holds the saved login. It stays in this temp home.
export HOME="${ROOT}/home"
mkdir -p "${HOME}/Steam/config" "${HOME}/.steam/steam/config" "${HOME}/.local/share/Steam/config"
umask 077
printf '%s' "${STEAM_CONFIG_VDF}" | base64 -d > "${HOME}/Steam/config/config.vdf"
cp "${HOME}/Steam/config/config.vdf" "${HOME}/.steam/steam/config/config.vdf"
cp "${HOME}/Steam/config/config.vdf" "${HOME}/.local/share/Steam/config/config.vdf"
umask 022

mkdir -p "${ROOT}/steamcmd"
curl -fsSL -o "${ROOT}/steamcmd.tar.gz" https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzf "${ROOT}/steamcmd.tar.gz" -C "${ROOT}/steamcmd"

set +e
"${ROOT}/steamcmd/steamcmd.sh" +login "${STEAM_USERNAME}" +run_app_build "${ROOT}/app_build.vdf" +quit | tee "${ROOT}/steamcmd.log"
code="${PIPESTATUS[0]}"
set -e
if [ "${code}" -ne 0 ] || ! grep -q "Successfully finished AppID" "${ROOT}/steamcmd.log"; then
	echo "Steam did not finish the depot build."
	exit 1
fi
echo "Steam depot build finished for app ${STEAM_APP_ID}."
