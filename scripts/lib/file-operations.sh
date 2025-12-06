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

    # Don't convert to staging if path already contains staging directory
    # (caller may have already converted it)
    if [[ "$STAGING_ACTIVE" == "true" ]] && [[ "$dir" != *"$STAGING_DIR"* ]]; then
        dir=$(get_staging_path "$dir" "$PROJECT_DIR")
    fi

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

    # Use staging path if staging is active
    local actual_dest="$dest"
    if [[ "$STAGING_ACTIVE" == "true" ]]; then
        actual_dest=$(get_staging_path "$dest" "$PROJECT_DIR")
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        # Show diff if destination exists
        if [[ -f "$dest" ]]; then
            local old_content=$(cat "$dest")
            local new_content=$(cat "$source")
            show_diff_preview "$old_content" "$new_content" "$dest"
        fi
        echo "$dest"
    else
        ensure_dir "$(dirname "$actual_dest")"
        cp "$source" "$actual_dest"
        print_verbose "Copied: $source -> $actual_dest"
        echo "$dest"
    fi
}

# Write content to file with dry-run support
write_file() {
    local content=$1
    local dest=$2

    # Use staging path if staging is active
    local actual_dest="$dest"
    if [[ "$STAGING_ACTIVE" == "true" ]]; then
        actual_dest=$(get_staging_path "$dest" "$PROJECT_DIR")
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        # Show diff if destination exists
        if [[ -f "$dest" ]]; then
            local old_content=$(cat "$dest")
            show_diff_preview "$old_content" "$content" "$dest"
        fi
        echo "$dest"
    else
        ensure_dir "$(dirname "$actual_dest")"
        echo "$content" > "$actual_dest"
        print_verbose "Wrote file: $actual_dest"
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

# -----------------------------------------------------------------------------
# Transactional Staging
# -----------------------------------------------------------------------------

# Global staging directory variable
STAGING_DIR=""
STAGING_ACTIVE="false"

# Initialize staging directory for transactional operations
# Usage: init_staging "$PROJECT_DIR"
init_staging() {
    local project_dir=$1

    # Create unique staging directory
    STAGING_DIR="$project_dir/.agent-os-staging-$$"

    if [[ -d "$STAGING_DIR" ]]; then
        print_warning "Staging directory already exists, cleaning up..."
        rm -rf "$STAGING_DIR"
    fi

    mkdir -p "$STAGING_DIR"
    STAGING_ACTIVE="true"

    print_verbose "Initialized staging directory: $STAGING_DIR"
}

# Convert target path to staging path
# Usage: staging_path=$(get_staging_path "$target_path" "$project_dir")
get_staging_path() {
    local target_path=$1
    local project_dir=$2

    if [[ "$STAGING_ACTIVE" != "true" ]]; then
        # No staging - return original path
        echo "$target_path"
        return
    fi

    # Replace project directory with staging directory
    local staging_path="${target_path/#$project_dir/$STAGING_DIR}"
    echo "$staging_path"
}

# Commit staged files to final destination
# Usage: commit_staging "$PROJECT_DIR"
commit_staging() {
    local project_dir=$1

    if [[ "$STAGING_ACTIVE" != "true" ]] || [[ ! -d "$STAGING_DIR" ]]; then
        print_verbose "No staging directory to commit"
        return 0
    fi

    print_status "Committing installation..."

    # Verify staging directory has content
    if [[ ! "$(ls -A "$STAGING_DIR" 2>/dev/null)" ]]; then
        print_verbose "Staging directory is empty, nothing to commit"
        rm -rf "$STAGING_DIR"
        STAGING_ACTIVE="false"
        return 0
    fi

    # Move files from staging to target (atomic operation)
    # Using rsync for atomic directory moves with progress
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --remove-source-files "$STAGING_DIR/" "$project_dir/"
        # Remove empty directories from staging
        find "$STAGING_DIR" -type d -empty -delete 2>/dev/null || true
    else
        # Fallback: use cp + rm
        cp -R "$STAGING_DIR"/* "$project_dir/" 2>/dev/null || true
        rm -rf "$STAGING_DIR"
    fi

    STAGING_ACTIVE="false"
    print_verbose "Staging committed successfully"
    return 0
}

# Rollback staged files (cleanup on failure)
# Usage: rollback_staging
rollback_staging() {
    if [[ "$STAGING_ACTIVE" != "true" ]] || [[ ! -d "$STAGING_DIR" ]]; then
        return 0
    fi

    print_warning "Installation interrupted, rolling back changes..."
    rm -rf "$STAGING_DIR" 2>/dev/null || true
    STAGING_ACTIVE="false"
    print_verbose "Rollback complete"
}

