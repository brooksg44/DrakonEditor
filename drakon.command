#!/bin/zsh
# Launcher for DRAKON Editor 1.31.
# Uses Anaconda's wish (Tcl/Tk 8.6) explicitly: Homebrew's wish is Tk 9.x,
# and the Img package is installed only in /opt/anaconda3/lib/Img2.1.1.

WISH=/opt/anaconda3/bin/wish
SCRIPT_DIR="${0:A:h}"

if [[ ! -x $WISH ]]; then
    echo "Error: $WISH not found. Install Anaconda Tcl/Tk 8.6 or edit WISH in this script." >&2
    exit 1
fi

exec "$WISH" "$SCRIPT_DIR/drakon_editor.tcl" "$@"
