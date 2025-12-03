#!/bin/bash

# =============================================================================
# Agent OS Caching Functions
# Content-based caching for template compilation
# =============================================================================

# Cache directory structure:
# $HOME/.cache/agent-os/
#   ├── compilation/
#   │   ├── <cache-key>.content    # Compiled content
#   │   └── <cache-key>.meta       # Metadata (timestamp, source path)
#   └── version                     # Cache version file

CACHE_DIR="${CACHE_DIR:-$HOME/.cache/agent-os}"
CACHE_VERSION="2.1.0"

# -----------------------------------------------------------------------------
# Cache Initialization
# -----------------------------------------------------------------------------

# Initialize cache directory
init_cache() {
    mkdir -p "$CACHE_DIR/compilation"

    # Check cache version and clear if mismatched
    if [[ -f "$CACHE_DIR/version" ]]; then
        local stored_version=$(cat "$CACHE_DIR/version")
        if [[ "$stored_version" != "$CACHE_VERSION" ]]; then
            print_verbose "Cache version mismatch, clearing cache"
            clear_cache
        fi
    fi

    # Write current version
    echo "$CACHE_VERSION" > "$CACHE_DIR/version"
}

# -----------------------------------------------------------------------------
# Cache Key Generation
# -----------------------------------------------------------------------------

# Generate cache key from compilation inputs
# Uses MD5 hash of combined inputs for fast lookup
generate_cache_key() {
    local source_file=$1
    local profile=$2
    local phase_mode=$3
    local use_subagents=$4
    local standards_as_skills=$5

    # Combine all inputs that affect compilation
    local cache_input=""

    # Add source file content hash
    if [[ -f "$source_file" ]]; then
        local source_hash=$(md5sum "$source_file" 2>/dev/null | cut -d' ' -f1 || echo "no-hash")
        cache_input="${cache_input}source:${source_hash}|"
    else
        # Source doesn't exist, return empty (no cache)
        echo ""
        return
    fi

    # Add configuration parameters
    cache_input="${cache_input}profile:${profile}|"
    cache_input="${cache_input}phase:${phase_mode}|"
    cache_input="${cache_input}subagents:${use_subagents}|"
    cache_input="${cache_input}skills:${standards_as_skills}|"
    cache_input="${cache_input}version:${CACHE_VERSION}"

    # Generate final cache key
    local cache_key=$(echo -n "$cache_input" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "no-key")
    echo "$cache_key"
}

# -----------------------------------------------------------------------------
# Cache Operations
# -----------------------------------------------------------------------------

# Retrieve content from cache
# Returns 0 if found, 1 if not found
get_from_cache() {
    local cache_key=$1
    local output_var=$2  # Variable name to store result

    if [[ -z "$cache_key" ]]; then
        return 1
    fi

    local cache_file="$CACHE_DIR/compilation/${cache_key}.content"

    if [[ -f "$cache_file" ]]; then
        # Read cached content
        local cached_content=$(cat "$cache_file")

        # Return via variable reference
        eval "$output_var=\$cached_content"

        print_verbose "Cache hit: $cache_key"
        return 0
    else
        print_verbose "Cache miss: $cache_key"
        return 1
    fi
}

# Store content in cache
put_in_cache() {
    local cache_key=$1
    local content=$2
    local source_file=$3

    if [[ -z "$cache_key" ]]; then
        return 1
    fi

    init_cache

    local cache_file="$CACHE_DIR/compilation/${cache_key}.content"
    local meta_file="$CACHE_DIR/compilation/${cache_key}.meta"

    # Write content
    echo "$content" > "$cache_file"

    # Write metadata
    cat > "$meta_file" << EOF
source: $source_file
timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
cache_key: $cache_key
EOF

    print_verbose "Cached: $cache_key"
    return 0
}

# -----------------------------------------------------------------------------
# Cache Management
# -----------------------------------------------------------------------------

# Clear entire cache
clear_cache() {
    if [[ -d "$CACHE_DIR" ]]; then
        rm -rf "$CACHE_DIR"
        print_verbose "Cache cleared"
    fi
}

# Clear cache for specific profile
clear_cache_for_profile() {
    local profile=$1

    # Find all cache entries with this profile in metadata
    if [[ -d "$CACHE_DIR/compilation" ]]; then
        while IFS= read -r meta_file; do
            if grep -q "profile:${profile}" "$meta_file" 2>/dev/null; then
                local cache_key=$(basename "$meta_file" .meta)
                rm -f "$CACHE_DIR/compilation/${cache_key}."*
                print_verbose "Cleared cache for profile: $profile"
            fi
        done < <(find "$CACHE_DIR/compilation" -name "*.meta" 2>/dev/null)
    fi
}

# Get cache statistics
get_cache_stats() {
    if [[ ! -d "$CACHE_DIR/compilation" ]]; then
        echo "Cache empty (0 entries, 0 bytes)"
        return
    fi

    local entry_count=$(find "$CACHE_DIR/compilation" -name "*.content" 2>/dev/null | wc -l)
    local cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)

    echo "Cache: $entry_count entries, $cache_size"
}
