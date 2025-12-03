#!/bin/bash

# =============================================================================
# Agent OS File Operations
# File manipulation utilities with dry-run support
# =============================================================================

# -----------------------------------------------------------------------------
# Directory Management
# -----------------------------------------------------------------------------

# Create directory if it doesn't exist (unless in dry-run mode)
ensure_dir() {
    local dir=$1

    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ ! -d "$dir" ]]; then
            print_verbose "Would create directory: $dir"
        fi
    else
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_verbose "Created directory: $dir"
        fi
    fi
}

# -----------------------------------------------------------------------------
# File Copying and Writing
# -----------------------------------------------------------------------------

# Copy file with dry-run support
copy_file() {
    local source=$1
    local dest=$2

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "$dest"
    else
        ensure_dir "$(dirname "$dest")"
        cp "$source" "$dest"
        print_verbose "Copied: $source -> $dest"
        echo "$dest"
    fi
}

# Write content to file with dry-run support
write_file() {
    local content=$1
    local dest=$2

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "$dest"
    else
        ensure_dir "$(dirname "$dest")"
        echo "$content" > "$dest"
        print_verbose "Wrote file: $dest"
    fi
}

# -----------------------------------------------------------------------------
# File Update Logic
# -----------------------------------------------------------------------------

# Check if file should be skipped during update
should_skip_file() {
    local file=$1
    local overwrite_all=$2
    local overwrite_type=$3
    local file_type=$4

    if [[ "$overwrite_all" == "true" ]]; then
        return 1  # Don't skip
    fi

    if [[ ! -f "$file" ]]; then
        return 1  # Don't skip - file doesn't exist
    fi

    # Check specific overwrite flags
    case "$file_type" in
        "agent")
            [[ "$overwrite_type" == "true" ]] && return 1
            ;;
        "command")
            [[ "$overwrite_type" == "true" ]] && return 1
            ;;
        "standard")
            [[ "$overwrite_type" == "true" ]] && return 1
            ;;
    esac

    return 0  # Skip file
}
