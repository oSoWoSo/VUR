#!/usr/bin/env bash

# Script to ease packaging more apps together

#TODO: Dont bump template twice in one run
#TODO: Add options to adopt/orphan groups (Use existing git credentials)
#TODO: optionaly set XBPS_TARGET_ARCH otherwise build for x86_64

readonly XBPS_DISTDIR="${XBPS_DISTDIR:-${HOME}/void}"
sourceDir="${sourceDir:-$XBPS_DISTDIR/srcpkgs}"
destinationDir="${destinationDir:-/home/z/Projekty/oco/srcpkgs}"

# Track results for summary
declare -a SUCCEEDED=()
declare -a FAILED=()
declare -a SKIPPED=()

_g() {
	if command -v gum &>/dev/null; then
		gum style --border rounded --border-foreground "#14a113" --padding "0 1" "$@"
	else
		echo "[OK] $*"
	fi
}
_y() {
	if command -v gum &>/dev/null; then
		gum style --border rounded --border-foreground "#fdde13" --padding "0 1" "$@"
	else
		echo "[WARN] $*"
	fi
}
_r() {
	if command -v gum &>/dev/null; then
		gum style --border rounded --border-foreground "#e50203" --padding "0 1" "$@"
	else
		echo "[ERROR] $*"
	fi
}

_summary() {
	echo ""
	echo "=========================================="
	echo "SUMMARY"
	echo "=========================================="
	if ((${#SUCCEEDED[@]})); then
		_g "Succeeded: ${#SUCCEEDED[@]}"
		printf '  - %s\n' "${SUCCEEDED[@]}"
	fi
	if ((${#FAILED[@]})); then
		_r "Failed: ${#FAILED[@]}"
		printf '  - %s\n' "${FAILED[@]}"
	fi
	if ((${#SKIPPED[@]})); then
		_y "Skipped: ${#SKIPPED[@]}"
		printf '  - %s\n' "${SKIPPED[@]}"
	fi
	echo "=========================================="
}

cd "$XBPS_DISTDIR" || _r "XBPS_DISTDIR not exist!"

_build_one() {
	local package="$1"
	local soname soName soOLD soNEW so output
	local failed=0
	_y "Building $package"
	output=$(mktemp) || {
		_r "Error creating temporary file"
		FAILED+=("$package")
		return 1
	}
	if ! (
		set -o pipefail
		./xbps-src pkg -Q "$package" 2>&1 | tee "$output"
	); then
		_r "Error building $package"
		rm -f "$output"
		FAILED+=("$package")
		return 1
	fi
	if grep -q 'SONAME bump detected' "$output"; then
		soname=$(grep 'SONAME bump detected' "$output" | cut -d':' -f2,4)
		soName=$(echo "$soname" | cut -d' ' -f2 | cut -d':' -f1)
		soOLD=$(echo "$soname" | cut -d' ' -f3)
		soNEW=$(echo "$soname" | cut -d' ' -f5)
		echo "package name: $soName"
		echo "OLD so: $soOLD"
		echo "NEW so: $soNEW"
		if grep -q "$soOLD" common/shlibs; then
			sed -i "s|^.*${soOLD}.*$|${soNEW} ${soName}|" common/shlibs
			echo "Updated shlibs entry for $package"
		fi
	elif grep -q 'SONAME ' "$output"; then
		soname=$(grep 'SONAME ' "$output" | head -n1)
		so=$(echo "$soname" | cut -d' ' -f2)
		soName=$(echo "$soname" | cut -d' ' -f4 | rev | cut -d'/' -f1 | rev)
		echo "package name: $soName"
		echo "SO name: $so"
		if grep -q "$package" common/shlibs; then
			sed -i "s|^.*${so}.*$|${soName} ${so}|" common/shlibs
			echo "Updated shlibs entry for $package"
		fi
	fi
	rm -f "$output"
	_g "$package built successfully"
	SUCCEEDED+=("$package")
	return 0
}

_bump() {
	local package revdeps dep new output failed=0
	for package in "${packageList[@]}"; do
		if [[ -f "$package" ]]; then
			continue
		fi
		new=''
		output=$(mktemp) || {
			_r "Error creating temporary file"
			FAILED+=("$package")
			return 1
		}
		echo -e "\n================================"
		echo "📦 Processing: $package"
		echo "================================"
		echo "Finding reverse dependencies..."
		revdeps=$(xrevshlib "$package" 2>/dev/null | awk '{print $1}' | sort -u)
		if [[ -n "$revdeps" ]]; then
			echo "Reverse dependencies found:"
			while IFS= read -r dep; do
				echo "  - $dep"
			done <<<"$revdeps"
		else
			echo "No reverse dependencies found"
		fi
		echo "Bumping $package..."
		if (
			set -o pipefail
			xxautobump "$package" 2>&1 | tee "$output"
		); then
			new=$(awk '/Updating package/ {print $(NF-1)}' "$output")
			if [[ -n "$new" ]]; then
				_g "$package bumped to $new"
				SUCCEEDED+=("$package (bumped to $new)")
				if [[ "$build" = 1 ]]; then
					if _build_one "$package"; then
						if git add . &&
							git commit -m "$package: update to $new"; then
							_g "$package committed successfully"
						else
							_r "Error committing $package"
							FAILED+=("$package (commit)")
							failed=$((failed + 1))
						fi
					else
						_r "Error building $package"
						FAILED+=("$package (build)")
						failed=$((failed + 1))
					fi
				fi
			else
				_y "No updated version found for $package"
				SKIPPED+=("$package")
			fi
			rm -f "$output"
		else
			_r "Error bumping $package"
			cat "$output"
			rm -f "$output"
			FAILED+=("$package")
			failed=$((failed + 1))
			continue
		fi
		if [[ -n "$revdeps" && -n "$new" ]]; then
			echo "Bumping reverse dependencies..."
			while IFS= read -r dep; do
				[[ -z "$dep" ]] && continue
				echo "  Bumping $dep..."
				if xrevbump "revbump for $package" "$dep" "version"; then
					_g "$dep: rebuild for $package update"
				else
					_r "Error bumping $dep"
					FAILED+=("$dep (revbump)")
					failed=$((failed + 1))
				fi
			done <<<"$revdeps"
		fi
	done
	_summary
	if ((failed)); then
		_r "Bumping done with $failed error(s)"
		return 1
	fi
	_g "Bumping done"
}

_lint() {
	local failed=0
	for package in "${packageList[@]}"; do
		if xlint "$package"; then
			_g "$package linted successfully"
			SUCCEEDED+=("$package (lint)")
		else
			_r "Lint error: $package"
			FAILED+=("$package (lint)")
			((failed++))
		fi
	done
	_summary
	if ((failed)); then
		_r "Linting done: $failed package(s) failed"
		return 1
	fi
	_g "Linting done: all packages passed"
}

_build() {
	rm -f "build-${group}"
	if [[ "${recordOrder:-0}" = 1 || "${RECORD_BUILD_ORDER:-0}" = 1 ]]; then
		: >"build-${group}.order"
	fi
	for package in "${packageList[@]}"; do
		_y "Building $package"
		if (
			set -o pipefail
			./xbps-src pkg -Q "$package" 2>&1 | tee -a "build-${group}.log"
		); then
			_g "$package built successfully"
			SUCCEEDED+=("$package (build)")
			if [[ "${recordOrder:-0}" = 1 || "${RECORD_BUILD_ORDER:-0}" = 1 ]]; then
				printf '%s\n' "$package" >>"build-${group}.order"
			fi
		else
			_r "Error building $package"
			FAILED+=("$package (build)")
			#exit 1
			return 1
		fi
	done
	_summary
	_g "Building done"
}

_install() {
	_y "Installing Hyprland"
	local failed=0
	for package in "${packageList[@]}"; do
		_y "Installing $package"
		if xi -f "$package"; then
			_g "$package installed successfully"
			SUCCEEDED+=("$package (install)")
		else
			_r "Error installing $package"
			FAILED+=("$package (install)")
			failed=$((failed + 1))
		fi
	done
	_summary
	if ((failed)); then
		_r "Installation completed with $failed error(s)"
		return 1
	fi
	_g "Installation completed"
}

# Subpackages of $1 are discovered, never hardcoded:
#   - <sub>_package() functions declared in the template (authoritative)
#   - symlinks in $sourceDir pointing at $1 (catches subpackages whose
#     _package() function was dropped but whose symlink still exists)
# Printed as "<name> <parent>", deduplicated.
declare -A _linksByTarget=()

_collect_links() {
	local link name target
	_linksByTarget=()
	while IFS= read -r link; do
		[[ -z "$link" ]] && continue
		name=${link##*/}
		target=$(readlink "$link") || continue
		target=${target#./}
		[[ -z "$target" ]] && continue
		_linksByTarget[$target]="${_linksByTarget[$target]:-} $name"
	done < <(find "$sourceDir" -maxdepth 1 -type l 2>/dev/null)
}

_subpackages() {
	local pkg="$1" name
	if [[ -f "$sourceDir/$pkg/template" ]]; then
		while IFS= read -r name; do
			[[ -n "$name" && "$name" != "$pkg" ]] && printf '%s %s\n' "$name" "$pkg"
		done < <(
			grep -oE '^[[:alnum:]][[:alnum:]_+.-]*_package\(\)' "$sourceDir/$pkg/template" 2>/dev/null |
				sed 's/_package()$//'
		)
	fi
	for name in ${_linksByTarget[$pkg]:-}; do
		printf '%s %s\n' "$name" "$pkg"
	done
}

# Every <sub>_package() needs a srcpkgs/<sub> symlink to <parent>, otherwise
# xbps-src never builds the subpackage. Create it even when sourceDir lacks it.
_copy_symlink() {
	local entry="$1" parent="$2" target="${3:-}"
	[[ -n "$target" ]] || target="$parent"
	if [[ ! -d "$destinationDir/$parent" ]]; then
		_r "Error creating symlink $entry: parent $parent not copied"
		FAILED+=("$entry (copy symlink)")
		return 1
	fi
	_y "Copying $entry symlink ($target)"
	if ! rm -f "$destinationDir/$entry" ||
		! ln -s "$target" "$destinationDir/$entry"; then
		_r "Error copying symlink $entry"
		FAILED+=("$entry (copy symlink)")
		return 1
	fi
	_g "$entry symlink copied successfully"
	SUCCEEDED+=("$entry (copy symlink)")
	return 0
}

_copy_one() {
	local entry="$1" parent="$2" target="${3:-}"
	if [[ -n "$parent" ]]; then
		if [[ -L "$sourceDir/$entry" ]]; then
			target=$(readlink "$sourceDir/$entry")
			target=${target#./}
		fi
		_copy_symlink "$entry" "$parent" "$target"
		return $?
	fi
	if [[ -L "$sourceDir/$entry" ]]; then
		_copy_symlink "$entry" "$(readlink "$sourceDir/$entry")" "$(readlink "$sourceDir/$entry")"
		return $?
	fi
	_y "Removing and copying newer $entry template"
	if ! rm -rf "$destinationDir/$entry"; then
		_r "Error removing $entry"
		FAILED+=("$entry (copy)")
		return 1
	fi
	if ! cp -r "$sourceDir/$entry" "$destinationDir/"; then
		_r "Error copying $entry"
		FAILED+=("$entry (copy)")
		return 1
	fi
	_g "$entry copied successfully"
	SUCCEEDED+=("$entry (copy)")
	return 0
}

# Sync common/shlibs entries for a package into oco/shlibs_append.
# For each SONAME line in source common/shlibs whose package field belongs
# to $1, update the matching (soname + same package) line in shlibs_append
# or append it if missing. Duplicate exact lines are never created.
_sync_shlibs() {
	local pkg="$1"
	local srcShlibs="$XBPS_DISTDIR/common/shlibs"
	local destAppend="${destinationDir%/*}/shlibs_append"
	[[ -f "$srcShlibs" ]] || return 0
	local -A seen=()
	local -a srcLines=()
	local line sname pname
	while IFS= read -r line; do
		[[ -z "$line" || "$line" == \#* ]] && continue
		read -r sname pname _ <<<"$line"
		[[ -z "$sname" || -z "$pname" ]] && continue
		if [[ "$pname" == "$pkg"-* ]]; then
			if [[ -z "${seen[$line]:-}" ]]; then
				seen[$line]=1
				srcLines+=("$line")
			fi
		fi
	done <"$srcShlibs"
	((${#srcLines[@]} == 0)) && return 0
	[[ -f "$destAppend" ]] || : >"$destAppend"
	local tmp l ss pn tmp2 existing es ep
	tmp=$(mktemp) || return 1
	cp "$destAppend" "$tmp"
	for l in "${srcLines[@]}"; do
		read -r ss pn _ <<<"$l"
		tmp2=$(mktemp) || {
			rm -f "$tmp"
			return 1
		}
		while IFS= read -r existing; do
			[[ -z "$existing" ]] && {
				printf '%s\n' "$existing" >>"$tmp2"
				continue
			}
			read -r es ep _ <<<"$existing"
			if [[ "$es" == "$ss" && "$ep" == "$pkg"-* ]]; then
				continue
			fi
			printf '%s\n' "$existing" >>"$tmp2"
		done <"$tmp"
		if ! grep -Fxq -- "$l" "$tmp2"; then
			printf '%s\n' "$l" >>"$tmp2"
		fi
		mv "$tmp2" "$tmp"
	done
	mv "$tmp" "$destAppend"
	_g "shlibs synced for $pkg (${#srcLines[@]} line(s))"
	return 0
}

_copy() {
	local failed=0 dir sub parent
	local -A copied=()
	_collect_links
	for dir in "${packageList[@]}"; do
		copied[$dir]=1
	done
	for dir in "${packageList[@]}"; do
		_copy_one "$dir" || failed=$((failed + 1))
		_sync_shlibs "$dir" || true
		while read -r sub parent; do
			[[ -z "$sub" || -n "${copied[$sub]:-}" ]] && continue
			copied[$sub]=1
			_copy_one "$sub" "$parent" || failed=$((failed + 1))
			_sync_shlibs "$sub" || true
		done < <(_subpackages "$dir" | sort -u)
	done
	_summary
	if ((failed)); then
		_r "Copying done with $failed error(s)"
		return 1
	fi
	_g "Copying done"
}

_show_order() {
	echo "Build order for $group:"
	local i=1
	for package in "${packageList[@]}"; do
		echo "  $i. $package"
		((i++))
	done
}

_help() {
	if command -v gum &>/dev/null; then
		gum style --border rounded --border-foreground "#14a113" --padding "2 5 2 2" "
		$(gum style --foreground '#14a113' 'Script to help with group packaging')

		Possible arguments are:
		u OR --bump     Bump all group packages
		l OR --lint     Lint all group packages
		b OR --build    Build all group packages
		c OR --copy     Copy templates + their subpackages (symlinks)
		i OR --install  Install all group packages
		o OR --order    Show build order only
		h OR --help     Show this help message
		a OR --all      bump, build, copy and install

		$(gum style --foreground '#14a113' 'You must take care of Shlibs yourself!')
		To set sourceDir and destinationDir yourself
		Just export them before running script

		shlibs Must be handled manually for now!"
	else
		cat <<'HELP'
Script to help with group packaging

Possible arguments are:
  u OR --bump     Bump all group packages
  l OR --lint     Lint all group packages
  b OR --build    Build all group packages
  c OR --copy     Copy templates + their subpackages (symlinks)
  i OR --install  Install all group packages
  o OR --order    Show build order only
  r OR --record-order  Record successful build order to build-<group>.order
  h OR --help     Show this help message
  a OR --all      bump, build, copy and install

You must take care of Shlibs yourself outside of copy!
To set sourceDir and destinationDir yourself
Just export them before running script

Shlibs are synced automatically during copy (common/shlibs -> oco/shlibs_append).
HELP
	fi
}

if [ -z "$1" ]; then
	echo 'Pick group as first argument:'
	echo 'cosmic'
	echo 'hypr'
	echo 'nwg'
	echo 'sonic'
	echo 'Then pick second argument'
	_help
	exit 1
else
	# Save group name for masterdir
	group="$1"
fi

case "${1}" in
	cosmic)
		shift
		packageList=(
			xdg-desktop-portal-cosmic
			cosmic-osk
			cosmic-viewer
			cosmic-applibrary
			cosmic-applets
			cosmic-bg
			cosmic-edit
			cosmic-idle
			cosmic-monitor
			cosmic-notifications
			cosmic-osd
			cosmic-panel
			cosmic-player
			cosmic-screenshot
			cosmic-settings-daemon
			cosmic-sound-theme
			cosmic-term
			cosmic-wallpapers
			cosmic-workspaces-epoch
			blocaled
			pop-launcher
			cosmic-icons
			default-cursors
			cosmic-randr
			cosmic-comp
			cosmic-initial-setup # blocaled
			cosmic-launcher      # pop-launcher
			cosmic-files         # icons
			cosmic-store         # icons
			cosmic-session       # icons default-cursors
			cosmic-settings      # icons randr
			cosmic-greeter       # comp session
			cosmic-desktop-minimal
			cosmic-desktop-full
			# TODO:
			# libcosmic
			# cosmic
		) ;;
	dux)
		shift
		packageList=(
			dux-qml-common
			dux-gop
			dux-calendar
			dux-search
			dux-files
			dux-greeter
			dux-shell
		) ;;
	hypr)
		shift
		packageList=(
			hyprland-protocols
			hyprwayland-scanner
			hyprutils
			libspng
			hyprgraphics
			hyprlang
			hyprcursor
			aquamarine
			xdg-desktop-portal-hyprland
			hyprwire
			hyprtoolkit
			hyprland
			hyprland-qt-support
			glaze
			hyprsysteminfo
			hyprsunset
			hyprpolkitagent
			hyprpicker
			hyprpaper
			hyprlock
			hyprland-guiutils
			hypridle
		) ;;
	nwg)
		shift
		packageList=(
			python3-dasbus
			python3-geographiclib
			python3-geopy
			nwg-bar
			nwg-clipman
			nwg-displays
			nwg-dock
			nwg-dock-hyprland
			nwg-drawer
			nwg-hello
			nwg-icon-picker
			nwg-look
			nwg-menu
			nwg-panel
			nwg-readme-browser
			nwg-shell
			nwg-shell-config
			nwg-shell-wallpapers
		) ;;
	sonic)
		shift
		packageList=(
			sonic-namespace
			sf-cmake-modules
			sf-settings
			sf-text-codec
			sf-gui-addons
			sf-internationalization
			sf-color-scheme
			sf-core-addons
			sf-widgets-addons
			sf-settings-ui
			sf-archive
			sf-doctools
			sonic-polkit
			sf-windowsystem
			sf-auth
			sf-bookmarks
			sf-autocomplete
			sf-crash-handler
			sf-dbus
			#??? nestihl jsem zapsat, nevim kolik sablon
			sf-silver-icons
			sf-icon-themes
			sf-data-views
			sf-notifications
			sf-progress-ui
			sf-app-info
			sf-keyring
			sonic-daemon
			sf-device-integration
			sf-io
			sf-keybind
			sf-xml-gui
			sf-quick-ui
			#??
			sonic-silver
			sonic-silver-gtk
			sonic-activity-manager-daemon
			sf-pseudo-terminal
			sf-root-shell
			sf-ui-components
			sf-qml-bridge
			sf-holidays
			sf-idle-tracker
			sf-quick-desktop-style
			sf-data-models
			sf-spell-check
			sf-quick-ui-addons
			sonic-pipewire
			sf-quick-charts
			sf-status-notification
			sf-syntax-highlighting
			sf-text-widgets
			sf-text-editor
			sf-user-feedback
			sonic-exiv2-library
			sonic-activities-stats
			sf-barcode
			sf-file-metadata
			sf-file-search
			sf-notification-settings
			sf-unit-conversion
			sf-networkmanager
			sonic-system-monitor-library
			sonic-plasma5-support-library
			sf-runner
			sonic-keybind-daemon
			sonic-screen-library
			sonic-night-light
			sonic-win
			sf-io-fuse
			sonic-system-stats
			sonic-qt-theme-bridge
			sf-zeroconf
			sf-io-extras
			sonic-workspace
			#??
			sonic-screen
			sonic-pulseaudio-library
			sonic-audio-applet-pulse
			sonic-desktop-interface
			sonic-system-info
			sonic-workspace-addons
			xdg-desktop-portal-sonicde
			sonicde-meta
			#
			#sonic-activities # ← sf-cmake-modules (shortened to 'scfm')
			#sonic-activities-stats # ← sfcm sf-settings
			#sonic-activity-manager-daemon # ← sfcm sf-settings
			#sf-data-models # ← sfcm
			#sf-quick-ui # ← sfcm
			#sonic-audio-applet-pulse # ← sfcm sf-data-models sf-quick-ui
			#sonic-bluetooth-runtime # ← sfcm sf-quick-ui
			#sf-silver-icons # ← sfcm
			#sonic-breeze # ← sfcm sf-silver-icons
			#sonic-breeze-sddm # ← sfcm
			#sonic-browser-integration # ← sfcm
			#sonic-crypto-library
			#sonic-daemon # ← sfcm
			#sonic-decoration # ← sfcm
			#sonic-launcher-menu-edit # ← sfcm
			#sonic-polkit-agent # ← sfcm
			#sf-quick-desktop-style # ← sfcm
			#sonic-desktop-interface # ← sf-quick-desktop-style sonic-launcher-menu-edit sonic-polkit-agent
			#sonic-disks # ← sfcm
			#sonic-dr-robotnik # ← sfcm sf-data-models sf-quick-ui
			#sonic-drawing-tablet # ← sfcm
			#sf-io-extras # ← sfcm sf-core-addons sf-doctools
			#sonic-ecco # ← sfcm sf-io-extras
			#sonic-exiv2-library # ← sfcm
			#sonic-firewall # ← sfcm
			#sf-addons-downloader # ← sfcm
			#sf-app-info # ← sfcm
			#sf-barcode # ← sfcm
			#sf-bluetooth # ← sfcm
			#sf-data-views # ← sfcm
			#sf-device-integration # ← sfcm
			#sf-feeds # ← sfcm
			#sf-file-metadata # ← sfcm
			#sf-holidays # ← sfcm
			#sf-icon-themes # ← sfcm
			#sf-idle-tracker # ← sfcm
			#sf-image-formats # ← sfcm
			#sf-io # ← sfcm
			#sf-io-fuse # ← sfcm
			#sf-keybind # ← sfcm
			#sf-keyring # ← sfcm
			#sf-keyring-pam # ← sfcm
			#sf-modemmanager # ← sfcm
			#sf-notifications # ← sfcm
			#sf-open-collab # ← sfcm
			#sf-package # ← sfcm sf-doctools
			#sf-progress-ui # ← sfcm
			#sf-pseudo-terminal # ← sfcm
			#sf-qml-bridge # ← sfcm
			#sf-purpose # ← sf-barcode sfcm sf-data-models sf-qml-bridge
			#sf-qt-integration # ← sfcm
			#sf-quick-charts # ← sfcm
			#sf-quick-ui-addons # ← sfcm sf-core-addons sf-quick-desktop-style sf-quick-ui sf-settings
			#sf-root-shell # ← sfcm
			#sf-settings-utils # ← sfcm
			#sf-spell-check # ← sfcm
			#sf-sso
			#sf-status-notification # ← sfcm
			#sf-svg # ← sfcm
			#sf-syntax-highlighting # ← sfcm
			#sf-text-editor # ← sfcm
			#sf-text-widgets # ← sfcm
			#sf-ui-components # ← sfcm
			#sf-user-feedback # ← sfcm
			#sf-xml-gui # ← sfcm sf-settings
			#sf-zeroconf # ← sfcm
			#sonic-terminal-tools # ← sfcm
			#sonic-gtk-theme-bridge # ← sfcm sonic-terminal-tools
			#sonic-interface-libraries # ← sf-quick-ui sf-settings
			#sonic-login-manager # ← sfcm
			#sonic-network-manager # ← sf-barcode sfcm sf-quick-ui
			#sonic-night-light # ← sfcm sf-settings
			#sonic-oxygen # ← sfcm
			#sonic-oxygen-icons # ← sfcm
			#sonic-oxygen-sounds # ← sfcm
			#sonic-partition-manager # ← sf-doctools sf-settings
			#sonic-pipewire # ← sfcm
			#sonic-pulseaudio-library # ← sfcm
			#sonic-qt-accounts-library
			#sonic-silver # ← sfcm sf-qt-integration sf-silver-icons
			#sonic-qt-theme-bridge # ← sfcm sf-quick-desktop-style sonic-silver
			#sonic-quick-image-editor # ← sfcm sf-settings
			#sonic-rdp # ← sfcm
			#sonic-screen # ← sfcm sf-image-formats
			#sonic-screenies # ← sfcm
			#sonic-screenlocker # ← sfcm
			#sonic-silver-gtk # ← sfcm sonic-silver
			#sonic-system-stats # ← sfcm sf-settings
			#sonic-workspace # ← sonic-activity-manager-daemon sf-io-fuse sonic-qt-theme-bridge sonic-system-stats
			#sonic-silver-sddm # ← sonic-workspace
			#sonic-ssh-password-prompt # ← sfcm sf-doctools
			#sonic-system-info # ← sfcm
			#sonic-system-log # ← sfcm sf-core-addons sf-doctools sf-settings
			#sonic-system-monitor # ← sfcm sf-package sf-quick-charts sf-quick-desktop-style sf-quick-ui sonic-system-stats
			#sonic-terminal # ← sfcm
			#sonic-thunderbolt # ← sfcm
			#sonic-win # ← sf-quick-ui sonic-silver
			#sonic-tv-interface # ← sonic-audio-applet-pulse sfcm sonic-network-manager sonic-screen sonic-terminal-tools sonic-win
			#sonic-vault # ← sfcm
			#sonic-workspace-addons # ← sfcm
			#sonic-workspace-wallpapers # ← sfcm
			#sonic-write-daemon # ← sfcm
			#sonicde-meta
			#xdg-desktop-portal-sonicde # ← sfcm sonic-workspace

			#sonic-frameworks-cmake-modules
			#sonic-activities # ← sf-cmake-modules (shortened to 'scfm')
			#sonic-frameworks-settings # ← sfcm
			#sonic-activities-stats # ← sfcm sf-settings
			#sonic-activity-manager-daemon # ← sfcm sf-settings
			#sonic-frameworks-data-models # ← sfcm
			#sonic-frameworks-quick-ui # ← sfcm
			#sonic-audio-applet-pulse # ← sfcm sf-data-models sf-quick-ui
			#sonic-bluetooth-runtime # ← sfcm sf-quick-ui
			#sonic-frameworks-silver-icons # ← sfcm
			#sonic-breeze # ← sfcm sf-silver-icons
			#sonic-breeze-sddm # ← sfcm
			#sonic-browser-integration # ← sfcm
			#sonic-crypto-library
			#sonic-daemon # ← sfcm
			#sonic-decoration # ← sfcm
			#sonic-launcher-menu-edit # ← sfcm
			#sonic-polkit-agent # ← sfcm
			#sonic-frameworks-quick-desktop-style # ← sfcm
			#sonic-desktop-interface # ← sf-quick-desktop-style sonic-launcher-menu-edit sonic-polkit-agent
			#sonic-disks # ← sfcm
			#sonic-dr-robotnik # ← sfcm sf-data-models sf-quick-ui
			#sonic-drawing-tablet # ← sfcm
			#sonic-frameworks-doctools # ← sfcm
			#sonic-frameworks-core-addons # ← sfcm
			#sonic-frameworks-io-extras # ← sfcm sf-core-addons sf-doctools
			#sonic-ecco # ← sfcm sf-io-extras
			#sonic-exiv2-library # ← sfcm
			#sonic-firewall # ← sfcm
			#sonic-frameworks-addons-downloader # ← sfcm
			#sonic-frameworks-app-info # ← sfcm
			#sonic-frameworks-archive # ← sfcm
			#sonic-frameworks-auth # ← sfcm
			#sonic-frameworks-autocomplete # ← sfcm sf-settings
			#sonic-frameworks-barcode # ← sfcm
			#sonic-frameworks-bluetooth # ← sfcm
			#sonic-frameworks-bookmarks # ← sfcm sf-settings
			#sonic-frameworks-color-scheme # ← sfcm
			#sonic-frameworks-crash-handler # ← sfcm
			#sonic-frameworks-data-views # ← sfcm
			#sonic-frameworks-dbus # ← sfcm
			#sonic-frameworks-device-integration # ← sfcm
			#sonic-frameworks-feeds # ← sfcm
			#sonic-frameworks-file-metadata # ← sfcm
			#sonic-frameworks-file-search # ← sfcm
			#sonic-frameworks-gui-addons # ← sfcm
			#sonic-frameworks-holidays # ← sfcm
			#sonic-frameworks-icon-themes # ← sfcm
			#sonic-frameworks-idle-tracker # ← sfcm
			#sonic-frameworks-image-formats # ← sfcm
			#sonic-frameworks-internationalization # ← sfcm
			#sonic-frameworks-io # ← sfcm
			#sonic-frameworks-io-fuse # ← sfcm
			#sonic-frameworks-keybind # ← sfcm
			#sonic-frameworks-keyring # ← sfcm
			#sonic-frameworks-keyring-pam # ← sfcm
			#sonic-frameworks-modemmanager # ← sfcm
			#sonic-frameworks-networkmanager # ← sfcm
			#sonic-frameworks-notification-settings # ← sfcm
			#sonic-frameworks-notifications # ← sfcm
			#sonic-frameworks-open-collab # ← sfcm
			#sonic-frameworks-package # ← sfcm sf-doctools
			#sonic-frameworks-progress-ui # ← sfcm
			#sonic-frameworks-pseudo-terminal # ← sfcm
			#sonic-frameworks-qml-bridge # ← sfcm
			#sonic-frameworks-purpose # ← sf-barcode sfcm sf-data-models sf-qml-bridge
			#sonic-frameworks-qt-integration # ← sfcm
			#sonic-frameworks-quick-charts # ← sfcm
			#sonic-frameworks-quick-ui-addons # ← sfcm sf-core-addons sf-quick-desktop-style sf-quick-ui sf-settings
			#sonic-frameworks-root-shell # ← sfcm
			#sonic-frameworks-windowsystem # ← sfcm
			#sonic-frameworks-runner # ← sfcm sf-core-addons sf-doctools sf-windowsystem
			#sonic-frameworks-settings-ui # ← sfcm
			#sonic-frameworks-settings-utils # ← sfcm
			#sonic-frameworks-spell-check # ← sfcm
			#sonic-frameworks-sso
			#sonic-frameworks-status-notification # ← sfcm
			#sonic-frameworks-svg # ← sfcm
			#sonic-frameworks-syntax-highlighting # ← sfcm
			#sonic-frameworks-text-codec # ← sfcm
			#sonic-frameworks-text-editor # ← sfcm
			#sonic-frameworks-text-widgets # ← sfcm
			#sonic-frameworks-ui-components # ← sfcm
			#sonic-frameworks-unit-conversion # ← sfcm
			#sonic-frameworks-user-feedback # ← sfcm
			#sonic-frameworks-widgets-addons # ← sfcm
			#sonic-frameworks-xml-gui # ← sfcm sf-settings
			#sonic-frameworks-zeroconf # ← sfcm
			#sonic-terminal-tools # ← sfcm
			#sonic-gtk-theme-bridge # ← sfcm sonic-terminal-tools
			#sonic-interface-libraries # ← sf-quick-ui sf-settings
			#sonic-keybind-daemon # ← sfcm sf-settings
			#sonic-login-manager # ← sfcm
			#sonic-network-manager # ← sf-barcode sfcm sf-quick-ui
			#sonic-night-light # ← sfcm sf-settings
			#sonic-oxygen # ← sfcm
			#sonic-oxygen-icons # ← sfcm
			#sonic-oxygen-sounds # ← sfcm
			#sonic-partition-manager # ← sf-doctools sf-settings
			#sonic-pipewire # ← sfcm
			#sonic-plasma5-support-library # ← sfcm
			#sonic-polkit
			#sonic-pulseaudio-library # ← sfcm
			#sonic-qt-accounts-library
			#sonic-silver # ← sfcm sf-qt-integration sf-silver-icons
			#sonic-qt-theme-bridge # ← sfcm sf-quick-desktop-style sonic-silver
			#sonic-quick-image-editor # ← sfcm sf-settings
			#sonic-rdp # ← sfcm
			#sonic-screen # ← sfcm sf-image-formats
			#sonic-screen-library # ← sfcm
			#sonic-screenies # ← sfcm
			#sonic-screenlocker # ← sfcm
			#sonic-silver-gtk # ← sfcm sonic-silver
			#sonic-system-stats # ← sfcm sf-settings
			#sonic-workspace # ← sonic-activity-manager-daemon sf-io-fuse sonic-qt-theme-bridge sonic-system-stats
			#sonic-silver-sddm # ← sonic-workspace
			#sonic-ssh-password-prompt # ← sfcm sf-doctools
			#sonic-system-info # ← sfcm
			#sonic-system-log # ← sfcm sf-core-addons sf-doctools sf-settings
			#sonic-system-monitor # ← sfcm sf-package sf-quick-charts sf-quick-desktop-style sf-quick-ui sonic-system-stats
			#sonic-system-monitor-library # ← sfcm
			#sonic-terminal # ← sfcm
			#sonic-thunderbolt # ← sfcm
			#sonic-win # ← sf-quick-ui sonic-silver
			#sonic-tv-interface # ← sonic-audio-applet-pulse sfcm sonic-network-manager sonic-screen sonic-terminal-tools sonic-win
			#sonic-vault # ← sfcm
			#sonic-workspace-addons # ← sfcm
			#sonic-workspace-wallpapers # ← sfcm
			#sonic-write-daemon # ← sfcm
			#sonicde-meta
			#xdg-desktop-portal-sonicde # ← sfcm sonic-workspace
		) ;;
	*)
		echo 'Pick group first:'
		echo 'cosmic'
		echo 'dux'
		echo 'hypr'
		echo 'nwg'
		echo 'sonic'
		exit 1 ;;
esac

if [ -z "$1" ]; then
	echo 'Provide second argument!'
	_help
	exit 1
fi

# Use own masterdir per group
export XBPS_MASTERDIR="${XBPS_DISTDIR}/masterdir_${group}"

if [ "$1" = l ] || [ "$1" = '--lint' ]; then
	shift
	_lint
fi
if [ "$1" = b ] || [ "$1" = '--build' ]; then
	shift
	build=1
fi
if [ "$1" = o ] || [ "$1" = '--order' ]; then
	shift
	_show_order
fi
if [ "$1" = r ] || [ "$1" = '--record-order' ]; then
	shift
	recordOrder=1
fi
if [ "$1" = u ] || [ "$1" = '--bump' ]; then
	shift
	_bump
elif [ "$build" = 1 ]; then
	_build
fi
if [ "$1" = i ] || [ "$1" = '--install' ]; then
	shift
	_install
fi
if [ "$1" = c ] || [ "$1" = '--copy' ]; then
	shift
	_copy
fi
if [ "$1" = a ] || [ "$1" = '--all' ]; then
	shift
	build=1
	_lint
	_bump
	_install
	_copy
	_g "Everything done"
fi
if [ -n "$1" ]; then
	echo 'Another argument?'
	exit 1
fi
