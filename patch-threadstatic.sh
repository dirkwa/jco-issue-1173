#!/bin/bash
# Patch wit-bindgen output for WASI compatibility
# 1. Remove [ThreadStatic] attribute (not available in single-threaded WASI)
# 2. Add missing using System; directive

for FILE in "$@"; do
    if [ -f "$FILE" ]; then
        # Remove [ThreadStatic] lines
        sed -i 's/\[ThreadStatic\]//g' "$FILE"

        # Add 'using System;' after the auto-generated comment if not present
        if ! grep -q "^using System;" "$FILE"; then
            sed -i 's/#nullable enable/#nullable enable\nusing System;/' "$FILE"
        fi

        echo "Patched $FILE"
    fi
done
