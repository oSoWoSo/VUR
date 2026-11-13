#!/bin/sh
# SonicDE namespace transformation helper
sonic_namespace_patch() {
	[ -d "$wrksrc" ] || return 0
	cd "$wrksrc" || return 0

	python3 - "$wrksrc" <<'PY'
import os, sys
root = sys.argv[1]
for dirpath, dirnames, filenames in os.walk(root, topdown=False):
    for name in list(dirnames) + list(filenames):
        path = os.path.join(dirpath, name)
        new = name
        if 'KF6' in new:
            new = new.replace('KF6', 'SF6')
        if name == 'kde' and os.path.basename(dirpath) == 'org':
            new = 'sf'
        if 'org.kde' in name:
            new = new.replace('org.kde', 'org.sf')
        if 'kf6' in name:
            new = new.replace('kf6', 'sf6')
        if 'Kf6' in name:
            new = new.replace('Kf6', 'Sf6')
        if os.path.islink(path):
            target = os.readlink(path)
            newtarget = target.replace('KF6', 'SF6').replace('org.kde', 'org.sf').replace('kf6', 'sf6').replace('Kf6', 'Sf6')
            if newtarget != target:
                os.remove(path)
                os.symlink(newtarget, path)
        if new != name:
            os.rename(path, os.path.join(dirpath, new))
PY

	if grep -rIl 'KF6' . >/dev/null 2>&1; then
		grep -rIl 'KF6' . | while IFS= read -r f; do
			sed -i 's/KF6/SF6/g' "$f"
		done
	fi

	if grep -rIl 'KF\${QT_MAJOR_VERSION}' . >/dev/null 2>&1; then
		grep -rIl 'KF\${QT_MAJOR_VERSION}' . | while IFS= read -r f; do
			sed -i 's/KF\${QT_MAJOR_VERSION}/SF\${QT_MAJOR_VERSION}/g' "$f"
		done
	fi

	if grep -rIl 'Kf6' . >/dev/null 2>&1; then
		grep -rIl 'Kf6' . | while IFS= read -r f; do
			sed -i 's/Kf6/Sf6/g' "$f"
		done
	fi

	if grep -rIl 'kf6' . >/dev/null 2>&1; then
		grep -rIl 'kf6' . | while IFS= read -r f; do
			sed -i 's/kf6/sf6/g' "$f"
		done
	fi

	if grep -rIl 'OrgKde' . >/dev/null 2>&1; then
		grep -rIl 'OrgKde' . | while IFS= read -r f; do
			sed -i 's/OrgKde/OrgSf/g' "$f"
		done
	fi

	if grep -rIl 'org::kde::kdeconnect' . >/dev/null 2>&1; then
		grep -rIl 'org::kde::kdeconnect' . | while IFS= read -r f; do
			sed -i 's/org::kde::kdeconnect/@@KDECONNECT@@/g' "$f"
		done
	fi
	if grep -rIl 'org::kde::KDirNotify' . >/dev/null 2>&1; then
		grep -rIl 'org::kde::KDirNotify' . | while IFS= read -r f; do
			sed -i 's/org::kde::KDirNotify/@@KDIRNOTIFY@@/g' "$f"
		done
	fi
	if grep -rIl 'org::kde::KSSLD' . >/dev/null 2>&1; then
		grep -rIl 'org::kde::KSSLD' . | while IFS= read -r f; do
			sed -i 's/org::kde::KSSLD/@@KSSLD@@/g' "$f"
		done
	fi
	if grep -rIl 'org::kde' . >/dev/null 2>&1; then
		grep -rIl 'org::kde' . | while IFS= read -r f; do
			sed -i 's/org::kde/org::sf/g' "$f"
		done
	fi
	sed -i 's/@@KDECONNECT@@/org::kde::kdeconnect/g; s/@@KDIRNOTIFY@@/org::kde::KDirNotify/g; s/@@KSSLD@@/org::kde::KSSLD/g' $(grep -rIl '@@KDECONNECT@@\|@@KDIRNOTIFY@@\|@@KSSLD@@' . 2>/dev/null) 2>/dev/null || true

	if grep -rIl 'org_kde' . >/dev/null 2>&1; then
		grep -rIl 'org_kde' . | while IFS= read -r f; do
			sed -i 's/org_kde/org_sf/g' "$f"
		done
	fi

	if grep -rIl 'org\.kde\.kdeconnect' . >/dev/null 2>&1; then
		grep -rIl 'org\.kde\.kdeconnect' . | while IFS= read -r f; do
			sed -i 's/org\.kde\.kdeconnect/@@KDECONNECT@@/g' "$f"
		done
	fi
	if grep -rIl 'org\.kde\.KDirNotify' . >/dev/null 2>&1; then
		grep -rIl 'org\.kde\.KDirNotify' . | while IFS= read -r f; do
			sed -i 's/org\.kde\.KDirNotify/@@KDIRNOTIFY@@/g' "$f"
		done
	fi
	if grep -rIl 'org\.kde\.kssld' . >/dev/null 2>&1; then
		grep -rIl 'org\.kde\.kssld' . | while IFS= read -r f; do
			sed -i 's/org\.kde\.kssld/@@KSSLD@@/g' "$f"
		done
	fi
	if grep -rIl 'org\.kde' . >/dev/null 2>&1; then
		grep -rIl 'org\.kde' . | while IFS= read -r f; do
			sed -i 's/org\.kde/org.sf/g' "$f"
		done
	fi
	sed -i 's/@@KDECONNECT@@/org.kde.kdeconnect/g; s/@@KDIRNOTIFY@@/org.kde.KDirNotify/g; s/@@KSSLD@@/org.kde.kssld/g' $(grep -rIl '@@KDECONNECT@@\|@@KDIRNOTIFY@@\|@@KSSLD@@' . 2>/dev/null) 2>/dev/null || true
}
