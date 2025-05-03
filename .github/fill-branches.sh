#!/usr/bin/env bash

generate_syncBranch_yml() {
	[ -f "$BRANCH" ] || fatal "not found: ${BRANCH}"
	[ -f "$BRANCH_LIST" ] || fatal "not found: ${BRANCH_LIST}"

	mkdir -p "$(dirname "$WORKFLOW")"

	_opts=$(mktemp)
	while IFS= read -r _pkg; do
		[ -z "$_pkg" ] && continue
		[ -L "${SCRIPT_DIR}/${SRCPKGS}/${_pkg}" ] && continue
		printf '        - %s\n' "$_pkg"
	done < "$BRANCH_LIST" > "$_opts"

	awk -v opts="$_opts" '
		/^[[:space:]]*__BRANCH_OPTIONS__[[:space:]]*$/ {
			while ((getline ln < opts) > 0) print ln
			close(opts)
			next
		}
		{ print }
	' "$BRANCH" > "$WORKFLOW"

	rm -f "$_opts"
	echo 'syncBranch.yml: updated'
}
