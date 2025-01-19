XDG_DATA_HOME=${XDG_DATA_HOME:-${HOME}/.local/share}
GNOME_EXTENSIONS_INDEX=${GNOME_EXTENSIONS_INDEX:-${XDG_DATA_HOME}/gnome-shell/extensions/.unforge}

if ps -e | grep -Fq gnome-shell; then
    if [ -f "$GNOME_EXTENSIONS_INDEX" ]; then
        while IFS= read -r line || [ -n "${line:-}" ]; do
            # Skip leading comments and empty lines.
            if [ "${line#\#}" != "$line" ]; then
                continue
            fi
            if [ -n "$line" ]; then
                extension=$(printf %s\\n "$line" | awk '{print $1}')
                if [ -d "$(dirname "$GNOME_EXTENSIONS_INDEX")/$extension" ]; then
                    # Recompile extensions schemas
                    if [ -d "$(dirname "$GNOME_EXTENSIONS_INDEX")/${extension}/schemas" ]; then
                        if gnome-extensions list --inactive --user | grep -Fq "$extension"; then
                            glib-compile-schemas "$(dirname "$GNOME_EXTENSIONS_INDEX")/${extension}/schemas"
                        fi
                    fi
                    # And enable the extension
                    if gnome-extensions list --disabled --user | grep -Fq "$extension"; then
                        gnome-extensions enable --quiet "$extension"
                    fi
                fi
            fi
        done < "$GNOME_EXTENSIONS_INDEX"
    fi
else
    (
        sleep 5 && $HOME/.bashrc.d/gnome.sh
    ) &
fi
