#!/bin/bash

# =============================================================================
# Agent OS YAML Parsing Functions
# Robust YAML parsing utilities for configuration files
# =============================================================================

# -----------------------------------------------------------------------------
# String Normalization
# -----------------------------------------------------------------------------

# Normalize input to lowercase, replace spaces/underscores with hyphens, remove punctuation
normalize_name() {
    local input=$1
    echo "$input" | tr '[:upper:]' '[:lower:]' | sed 's/[ _]/-/g' | sed 's/[^a-z0-9-]//g'
}

# Normalize YAML line (handle tabs, trim spaces, etc.)
normalize_yaml_line() {
    echo "$1" | sed 's/\t/    /g' | sed 's/[[:space:]]*$//'
}

# Get indentation level (counts spaces/tabs at beginning)
get_indent_level() {
    local line="$1"
    local normalized=$(echo "$line" | sed 's/\t/    /g')
    local spaces=$(echo "$normalized" | sed 's/[^ ].*//')
    echo "${#spaces}"
}

# -----------------------------------------------------------------------------
# YAML Value Extraction
# -----------------------------------------------------------------------------

# Get a simple value from YAML (handles key: value format)
# More robust: handles quotes, different spacing, tabs
get_yaml_value() {
    local file=$1
    local key=$2
    local default=$3

    if [[ ! -f "$file" ]]; then
        echo "$default"
        return
    fi

    # Look for the key with flexible spacing and handle quotes
    local value=$(awk -v key="$key" '
        BEGIN { found=0 }
        {
            # Normalize tabs to spaces
            gsub(/\t/, "    ")
            # Remove leading/trailing spaces
            gsub(/^[[:space:]]+/, "")
            gsub(/[[:space:]]+$/, "")
        }
        # Match key: value (with or without spaces around colon)
        $0 ~ "^" key "[[:space:]]*:" {
            # Extract value after colon
            sub("^" key "[[:space:]]*:[[:space:]]*", "")
            # Remove quotes if present
            gsub(/^["'\'']/, "")
            gsub(/["'\'']$/, "")
            # Handle empty value
            if (length($0) > 0) {
                print $0
                found=1
                exit
            }
        }
        END { if (!found) exit 1 }
    ' "$file" 2>/dev/null)

    if [[ $? -eq 0 && -n "$value" ]]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# Get array values from YAML (handles - item format under a key)
# More robust: handles variable indentation
get_yaml_array() {
    local file=$1
    local key=$2

    if [[ ! -f "$file" ]]; then
        return
    fi

    awk -v key="$key" '
        BEGIN {
            found=0
            key_indent=-1
            array_indent=-1
        }
        {
            # Normalize tabs to spaces
            gsub(/\t/, "    ")

            # Get current line indentation
            indent = match($0, /[^ ]/)
            if (indent == 0) indent = length($0) + 1
            indent = indent - 1

            # Store original line for processing
            line = $0
            # Remove leading spaces for pattern matching
            gsub(/^[[:space:]]+/, "")
        }

        # Found the key
        !found && $0 ~ "^" key "[[:space:]]*:" {
            found = 1
            key_indent = indent
            next
        }

        # Process array items under the key
        found {
            # If we hit a line with same or less indentation as key, stop
            if (indent <= key_indent && $0 != "" && $0 !~ /^[[:space:]]*$/) {
                exit
            }

            # Look for array items (- item)
            if ($0 ~ /^-[[:space:]]/) {
                # Set array indent from first item
                if (array_indent == -1) {
                    array_indent = indent
                }

                # Only process items at the expected indentation
                if (indent == array_indent) {
                    sub(/^-[[:space:]]*/, "")
                    # Remove quotes if present
                    gsub(/^["'\'']/, "")
                    gsub(/["'\'']$/, "")
                    print
                }
            }
        }
    ' "$file"
}
