#!/usr/bin/env sh

# Actively discover the home directory for the windows user through looking in
# the PATH variable, assuming there will be pointers to locally installed
# applications (as in locally to the account).
OIFS=$IFS
IFS=:
for p in $PATH; do
    if [ -z "$SSHPATH" ] && printf %s\\n "$p" | grep -q '/mnt/[a-z]/Users'; then
        SSHPATH=$(printf %s\\n "$p" | sed -E 's;^(/mnt/[a-z]/Users/[^/]+)/.*;\1;')
    fi
done
IFS=$OIFS

if [ -n "$SSHPATH" ]; then
    # Create SSH directory if it does not exist yet.
    if ! [ -d "${HOME}/.ssh" ]; then
        echo "Creating ${HOME}/.ssh"
        mkdir -p "${HOME}/.ssh"
        chmod og-rwx "${HOME}/.ssh"
    fi

    # Copies Windows keys into the local Linux installation, arrange for proper,
    # restrictive rights.
    if [ -d "${SSHPATH}/.ssh" ] && [ -d "${HOME}/.ssh" ]; then
        for f in $(find "${SSHPATH}/.ssh" -name 'id_*' -o -name 'config'); do
            b=$(basename "$f")
            echo "Copying ${SSHPATH}/.ssh/$b -> ${HOME}/.ssh/$b"
            cp -f "${SSHPATH}/.ssh/$b" "${HOME}/.ssh/$b"
            if [ "${b##*.}" = "pub" ]; then
                chmod a+r,og-wx,u+w,u-x "${HOME}/.ssh/$b"
            else
                chmod og-rwx,u-x,u+rw "${HOME}/.ssh/$b"
            fi
        done
    fi
fi
