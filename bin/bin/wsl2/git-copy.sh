#!/usr/bin/env sh

# Copy git configuration from Windows into the WSL2 area so there is only one
# place of truth.
OIFS=$IFS
IFS=:
for p in $PATH; do
    if [ -z "$WINPATH" ] && printf %s\\n "$p" | grep -q '/mnt/[a-z]/Users'; then
        WINPATH=$(printf %s\\n "$p" | sed -E 's;^(/mnt/[a-z]/Users/[^/]+)/.*;\1;')
    fi
done
IFS=$OIFS

if [ -n "$WINPATH" ]; then
    # Create SSH directory if it does not exist yet.
    if ! [ -d "${HOME}/.git" ]; then
        echo "Creating ${HOME}/.git"
        mkdir -p "${HOME}/.git"
        chmod og-rwx "${HOME}/.git"
    fi

    # Copies git global configurations into the WSL2 area.
    if [ -d "${WINPATH}/.git" ] && [ -d "${HOME}/.git" ]; then
        for f in $(find "${WINPATH}/.git" -name 'config'); do
            b=$(basename "$f")
            echo "Copying ${WINPATH}/.git/$b -> ${HOME}/.git/$b"
            cp -f "${WINPATH}/.git/$b" "${HOME}/.git/$b"
            chmod og-rwx,u-x,u+rw "${HOME}/.git/$b"
        done
    fi
fi
