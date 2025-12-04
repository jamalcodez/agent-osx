#!/bin/bash

# =============================================================================
# Agent OS Project Installation Script
# Installs Agent OS into a project's codebase
# =============================================================================

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$HOME/agent-os"
PROJECT_DIR="$(pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# -----------------------------------------------------------------------------
# Default Values
# -----------------------------------------------------------------------------

DRY_RUN="false"
VERBOSE="false"
USE_CACHE="true"
PRESET=""
PROFILE=""
CLAUDE_CODE_COMMANDS=""
USE_CLAUDE_CODE_SUBAGENTS=""
AGENT_OS_COMMANDS=""
STANDARDS_AS_CLAUDE_CODE_SKILLS=""
RE_INSTALL="false"
OVERWRITE_ALL="false"
OVERWRITE_STANDARDS="false"
OVERWRITE_COMMANDS="false"
OVERWRITE_AGENTS="false"
INSTALLED_FILES=()

# -----------------------------------------------------------------------------
# Help Function
# -----------------------------------------------------------------------------

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Install Agent OS into the current project directory.

Options:
    --preset PRESET                          Use configuration preset (default: from config.yml)
                                             Available: claude-code-full, claude-code-simple,
                                             claude-code-basic, cursor, multi-tool, custom
    --profile PROFILE                        Use specified profile (default: from config.yml)
    --claude-code-commands [BOOL]            Install Claude Code commands (default: from preset/config)
    --use-claude-code-subagents [BOOL]       Use Claude Code subagents (default: from preset/config)
    --agent-os-commands [BOOL]               Install agent-os commands (default: from preset/config)
    --standards-as-claude-code-skills [BOOL] Use Claude Code Skills for standards (default: from preset/config)
    --re-install                             Delete and reinstall Agent OS
    --overwrite-all                          Overwrite all existing files during update
    --overwrite-standards                    Overwrite existing standards during update
    --overwrite-commands                     Overwrite existing commands during update
    --overwrite-agents                       Overwrite existing agents during update
    --dry-run                                Show what would be done without doing it
    --no-cache                               Disable compilation caching
    --verbose                                Show detailed output
    -h, --help                               Show this help message

Note: Flags accept both hyphens and underscores (e.g., --use-claude-code-subagents or --use_claude_code_subagents)

Examples:
    $0                                       # Use preset from config.yml
    $0 --preset claude-code-full             # Override with preset
    $0 --preset cursor                       # Use Cursor preset
    $0 --profile rails                       # Use rails profile
    $0 --preset claude-code-full --agent-os-commands true  # Preset + override
    $0 --dry-run                             # Preview changes

EOF
    exit 0
}

# -----------------------------------------------------------------------------
# Parse Command Line Arguments
# -----------------------------------------------------------------------------

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        # Normalize flag by replacing underscores with hyphens
        local flag="${1//_/-}"

        case $flag in
            --preset)
                PRESET="$2"
                shift 2
                ;;
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --claude-code-commands)
                read CLAUDE_CODE_COMMANDS shift_count <<< "$(parse_bool_flag "$CLAUDE_CODE_COMMANDS" "$2")"
                shift $shift_count
                ;;
            --use-claude-code-subagents)
                read USE_CLAUDE_CODE_SUBAGENTS shift_count <<< "$(parse_bool_flag "$USE_CLAUDE_CODE_SUBAGENTS" "$2")"
                shift $shift_count
                ;;
            --agent-os-commands)
                read AGENT_OS_COMMANDS shift_count <<< "$(parse_bool_flag "$AGENT_OS_COMMANDS" "$2")"
                shift $shift_count
                ;;
            --standards-as-claude-code-skills)
                read STANDARDS_AS_CLAUDE_CODE_SKILLS shift_count <<< "$(parse_bool_flag "$STANDARDS_AS_CLAUDE_CODE_SKILLS" "$2")"
                shift $shift_count
                ;;
            --re-install)
                RE_INSTALL="true"
                shift
                ;;
            --overwrite-all)
                OVERWRITE_ALL="true"
                shift
                ;;
            --overwrite-standards)
                OVERWRITE_STANDARDS="true"
                shift
                ;;
            --overwrite-commands)
                OVERWRITE_COMMANDS="true"
                shift
                ;;
            --overwrite-agents)
                OVERWRITE_AGENTS="true"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --no-cache)
                USE_CACHE="false"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            -h|--help)
                show_help
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# Configuration Functions
# -----------------------------------------------------------------------------

load_configuration() {
    # Set preset override if provided via command line
    if [[ -n "$PRESET" ]]; then
        export PRESET_OVERRIDE="$PRESET"
    fi

    # Load base configuration using common function
    load_base_config

    # Set effective values (command line overrides base config)
    EFFECTIVE_PROFILE="${PROFILE:-$BASE_PROFILE}"
    EFFECTIVE_CLAUDE_CODE_COMMANDS="${CLAUDE_CODE_COMMANDS:-$BASE_CLAUDE_CODE_COMMANDS}"
    EFFECTIVE_USE_CLAUDE_CODE_SUBAGENTS="${USE_CLAUDE_CODE_SUBAGENTS:-$BASE_USE_CLAUDE_CODE_SUBAGENTS}"
    EFFECTIVE_AGENT_OS_COMMANDS="${AGENT_OS_COMMANDS:-$BASE_AGENT_OS_COMMANDS}"
    EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS="${STANDARDS_AS_CLAUDE_CODE_SKILLS:-$BASE_STANDARDS_AS_CLAUDE_CODE_SKILLS}"
    EFFECTIVE_VERSION="$BASE_VERSION"

    # Validate configuration using common function (may override EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS if dependency not met)
    validate_config "$EFFECTIVE_CLAUDE_CODE_COMMANDS" "$EFFECTIVE_USE_CLAUDE_CODE_SUBAGENTS" "$EFFECTIVE_AGENT_OS_COMMANDS" "$EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS" "$EFFECTIVE_PROFILE"

    print_verbose "Configuration loaded:"
    print_verbose "  Profile: $EFFECTIVE_PROFILE"
    print_verbose "  Claude Code commands: $EFFECTIVE_CLAUDE_CODE_COMMANDS"
    print_verbose "  Use Claude Code subagents: $EFFECTIVE_USE_CLAUDE_CODE_SUBAGENTS"
    print_verbose "  Agent OS commands: $EFFECTIVE_AGENT_OS_COMMANDS"
    print_verbose "  Standards as Claude Code Skills: $EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS"
}

# -----------------------------------------------------------------------------
# Installation Functions
# -----------------------------------------------------------------------------

# Install standards files
install_standards() {
    if [[ "$DRY_RUN" != "true" ]]; then
        print_status "Installing standards"
    fi

    local standards_count=0

    while read file; do
        if [[ "$file" == standards/* ]]; then
            local source=$(get_profile_file "$EFFECTIVE_PROFILE" "$file" "$BASE_DIR")
            local dest="$PROJECT_DIR/agent-os/$file"

            if [[ -f "$source" ]]; then
                local installed_file=$(copy_file "$source" "$dest")
                if [[ -n "$installed_file" ]]; then
                    INSTALLED_FILES+=("$installed_file")
                    ((standards_count++)) || true
                fi
            fi
        fi
    done < <(get_profile_files "$EFFECTIVE_PROFILE" "$BASE_DIR" "standards")

    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ $standards_count -gt 0 ]]; then
            echo "✓ Installed $standards_count standards in agent-os/standards"
        fi
    fi
}

# Install and compile single-agent mode commands
# Install Claude Code commands with delegation (multi-agent files)
install_claude_code_commands_with_delegation() {
    if [[ "$DRY_RUN" != "true" ]]; then
        print_status "Installing Claude Code commands (with delegation to subagents)..."
    fi

    local commands_count=0
    # Determine target directory based on whether agent-os commands are enabled
    local target_dir
    if [[ "$EFFECTIVE_AGENT_OS_COMMANDS" == "true" ]]; then
        target_dir="$PROJECT_DIR/.claude/commands/agent-os"
    else
        target_dir="$PROJECT_DIR/.claude/commands"
    fi

    mkdir -p "$target_dir"

    # Count total files first for progress reporting
    local total_files=0
    while read file; do
        if [[ "$file" == commands/*/multi-agent/* ]] || [[ "$file" == commands/orchestrate-tasks/orchestrate-tasks.md ]]; then
            local source=$(get_profile_file "$EFFECTIVE_PROFILE" "$file" "$BASE_DIR")
            [[ -f "$source" ]] && ((total_files++))
        fi
    done < <(get_profile_files "$EFFECTIVE_PROFILE" "$BASE_DIR" "commands")

    # Process files with progress reporting
    while read file; do
        # Process multi-agent command files OR orchestrate-tasks special case
        if [[ "$file" == commands/*/multi-agent/* ]] || [[ "$file" == commands/orchestrate-tasks/orchestrate-tasks.md ]]; then
            local source=$(get_profile_file "$EFFECTIVE_PROFILE" "$file" "$BASE_DIR")
            if [[ -f "$source" ]]; then
                # Extract command name from path (e.g., commands/create-spec/multi-agent/create-spec.md -> create-spec)
                local cmd_name=$(echo "$file" | cut -d'/' -f2)
                local dest="$target_dir/${cmd_name}.md"

                # Increment counter
                ((commands_count++)) || true

                # Show progress (unless dry-run)
                if [[ "$DRY_RUN" != "true" ]] && [[ $total_files -gt 0 ]]; then
                    show_compilation_progress "$commands_count" "$total_files" "$cmd_name.md"
                fi

                # Compile with workflow and standards injection (includes conditional compilation)
                local compiled=$(compile_command "$source" "$dest" "$BASE_DIR" "$EFFECTIVE_PROFILE")
                if [[ "$DRY_RUN" == "true" ]]; then
                    INSTALLED_FILES+=("$dest")
                fi
            fi
        fi
    done < <(get_profile_files "$EFFECTIVE_PROFILE" "$BASE_DIR" "commands")

    # Clear progress line
    if [[ "$DRY_RUN" != "true" ]] && [[ $total_files -gt 0 ]]; then
        clear_progress
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ $commands_count -gt 0 ]]; then
            echo "✓ Installed $commands_count Claude Code commands (with delegation)"
        fi
    fi
}

# Install Claude Code commands without delegation (single-agent files with injection)
install_claude_code_commands_without_delegation() {
    if [[ "$DRY_RUN" != "true" ]]; then
        print_status "Installing Claude Code commands (without delegation)..."
    fi

    local commands_count=0

    # Count total files first for progress reporting
    local total_files=0
    while read file; do
        if [[ "$file" == commands/*/single-agent/* ]] || [[ "$file" == commands/orchestrate-tasks/orchestrate-tasks.md ]]; then
            local source=$(get_profile_file "$EFFECTIVE_PROFILE" "$file" "$BASE_DIR")
            if [[ -f "$source" ]]; then
                if [[ "$file" == commands/orchestrate-tasks/orchestrate-tasks.md ]]; then
                    ((total_files++))
                else
                    local filename=$(basename "$file")
                    # Only count non-numbered files
                    [[ ! "$filename" =~ ^[0-9]+-.*\.md$ ]] && ((total_files++))
                fi
            fi
        fi
    done < <(get_profile_files "$EFFECTIVE_PROFILE" "$BASE_DIR" "commands")

    # Process files with progress reporting
    while read file; do
        # Process single-agent command files OR orchestrate-tasks special case
        if [[ "$file" == commands/*/single-agent/* ]] || [[ "$file" == commands/orchestrate-tasks/orchestrate-tasks.md ]]; then
            local source=$(get_profile_file "$EFFECTIVE_PROFILE" "$file" "$BASE_DIR")
            if [[ -f "$source" ]]; then
                # Handle orchestrate-tasks specially (flat destination)
                if [[ "$file" == commands/orchestrate-tasks/orchestrate-tasks.md ]]; then
                    ((commands_count++)) || true

                    # Show progress
                    if [[ "$DRY_RUN" != "true" ]] && [[ $total_files -gt 0 ]]; then
                        show_compilation_progress "$commands_count" "$total_files" "orchestrate-tasks.md"
                    fi

                    # Determine target directory
                    local dest
                    if [[ "$EFFECTIVE_AGENT_OS_COMMANDS" == "true" ]]; then
                        dest="$PROJECT_DIR/.claude/commands/agent-os/orchestrate-tasks.md"
                    else
                        dest="$PROJECT_DIR/.claude/commands/orchestrate-tasks.md"
                    fi
                    # Compile without PHASE embedding for orchestrate-tasks
                    local compiled=$(compile_command "$source" "$dest" "$BASE_DIR" "$EFFECTIVE_PROFILE" "")
                    if [[ "$DRY_RUN" == "true" ]]; then
                        INSTALLED_FILES+=("$dest")
                    fi
                else
                    # Only install non-numbered files (e.g., plan-product.md, not 1-product-concept.md)
                    local filename=$(basename "$file")
                    if [[ ! "$filename" =~ ^[0-9]+-.*\.md$ ]]; then
                        ((commands_count++)) || true

                        # Extract command name (e.g., commands/plan-product/single-agent/plan-product.md -> plan-product.md)
                        local cmd_name=$(echo "$file" | sed 's|commands/\([^/]*\)/single-agent/.*|\1|')

                        # Show progress
                        if [[ "$DRY_RUN" != "true" ]] && [[ $total_files -gt 0 ]]; then
                            show_compilation_progress "$commands_count" "$total_files" "$cmd_name.md"
                        fi

                        # Determine target directory
                        local dest
                        if [[ "$EFFECTIVE_AGENT_OS_COMMANDS" == "true" ]]; then
                            dest="$PROJECT_DIR/.claude/commands/agent-os/$cmd_name.md"
                        else
                            dest="$PROJECT_DIR/.claude/commands/$cmd_name.md"
                        fi

                        # Compile with PHASE embedding (mode="embed")
                        local compiled=$(compile_command "$source" "$dest" "$BASE_DIR" "$EFFECTIVE_PROFILE" "embed")
                        if [[ "$DRY_RUN" == "true" ]]; then
                            INSTALLED_FILES+=("$dest")
                        fi
                    fi
                fi
            fi
        fi
    done < <(get_profile_files "$EFFECTIVE_PROFILE" "$BASE_DIR" "commands")

    # Clear progress line
    if [[ "$DRY_RUN" != "true" ]] && [[ $total_files -gt 0 ]]; then
        clear_progress
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ $commands_count -gt 0 ]]; then
            echo "✓ Installed $commands_count Claude Code commands (without delegation)"
        fi
    fi
}

# Install Claude Code static agents
install_claude_code_agents() {
    if [[ "$DRY_RUN" != "true" ]]; then
        print_status "Installing Claude Code agents..."
    fi

    local agents_count=0
    # Determine target directory based on whether agent-os commands are enabled
    local target_dir
    if [[ "$EFFECTIVE_AGENT_OS_COMMANDS" == "true" ]]; then
        target_dir="$PROJECT_DIR/.claude/agents/agent-os"
    else
        target_dir="$PROJECT_DIR/.claude/agents"
    fi

    mkdir -p "$target_dir"

    # Count total files first for progress reporting
    local total_files=0
    while read file; do
        if [[ "$file" == agents/*.md ]] && [[ "$file" != agents/templates/* ]]; then
            local source=$(get_profile_file "$EFFECTIVE_PROFILE" "$file" "$BASE_DIR")
            [[ -f "$source" ]] && ((total_files++))
        fi
    done < <(get_profile_files "$EFFECTIVE_PROFILE" "$BASE_DIR" "agents")

    # Process files with progress reporting
    while read file; do
        # Include all agent files (flatten structure - no subfolders in output)
        if [[ "$file" == agents/*.md ]] && [[ "$file" != agents/templates/* ]]; then
            local source=$(get_profile_file "$EFFECTIVE_PROFILE" "$file" "$BASE_DIR")
            if [[ -f "$source" ]]; then
                ((agents_count++)) || true

                # Get just the filename (flatten directory structure)
                local filename=$(basename "$file")
                local dest="$target_dir/$filename"

                # Show progress
                if [[ "$DRY_RUN" != "true" ]] && [[ $total_files -gt 0 ]]; then
                    show_compilation_progress "$agents_count" "$total_files" "$filename"
                fi

                # Compile with workflow and standards injection
                local compiled=$(compile_agent "$source" "$dest" "$BASE_DIR" "$EFFECTIVE_PROFILE" "")
                if [[ "$DRY_RUN" == "true" ]]; then
                    INSTALLED_FILES+=("$dest")
                fi
            fi
        fi
    done < <(get_profile_files "$EFFECTIVE_PROFILE" "$BASE_DIR" "agents")

    # Clear progress line
    if [[ "$DRY_RUN" != "true" ]] && [[ $total_files -gt 0 ]]; then
        clear_progress
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ $agents_count -gt 0 ]]; then
            echo "✓ Installed $agents_count Claude Code agents"
        fi
    fi
}

# Install agent-os commands (single-agent files with injection)
install_agent_os_commands() {
    if [[ "$DRY_RUN" != "true" ]]; then
        print_status "Installing agent-os commands..."
    fi

    local commands_count=0

    # Count total files first for progress reporting
    local total_files=0
    while read file; do
        if [[ "$file" == commands/*/single-agent/* ]] || [[ "$file" == commands/orchestrate-tasks/orchestrate-tasks.md ]]; then
            local source=$(get_profile_file "$EFFECTIVE_PROFILE" "$file" "$BASE_DIR")
            [[ -f "$source" ]] && ((total_files++))
        fi
    done < <(get_profile_files "$EFFECTIVE_PROFILE" "$BASE_DIR" "commands")

    # Process files with progress reporting
    while read file; do
        # Process single-agent command files OR orchestrate-tasks special case
        if [[ "$file" == commands/*/single-agent/* ]] || [[ "$file" == commands/orchestrate-tasks/orchestrate-tasks.md ]]; then
            local source=$(get_profile_file "$EFFECTIVE_PROFILE" "$file" "$BASE_DIR")
            if [[ -f "$source" ]]; then
                ((commands_count++)) || true

                # Handle orchestrate-tasks specially (preserve folder structure)
                if [[ "$file" == commands/orchestrate-tasks/orchestrate-tasks.md ]]; then
                    local dest="$PROJECT_DIR/agent-os/commands/orchestrate-tasks/orchestrate-tasks.md"
                    local filename="orchestrate-tasks.md"
                else
                    # Extract command name and preserve numbering
                    local cmd_path=$(echo "$file" | sed 's|commands/\([^/]*\)/single-agent/\(.*\)|\1/\2|')
                    local dest="$PROJECT_DIR/agent-os/commands/$cmd_path"
                    local filename=$(basename "$file")
                fi

                # Show progress
                if [[ "$DRY_RUN" != "true" ]] && [[ $total_files -gt 0 ]]; then
                    show_compilation_progress "$commands_count" "$total_files" "$filename"
                fi

                # Compile with workflow and standards injection and PHASE embedding
                local compiled=$(compile_command "$source" "$dest" "$BASE_DIR" "$EFFECTIVE_PROFILE" "embed")
                if [[ "$DRY_RUN" == "true" ]]; then
                    INSTALLED_FILES+=("$dest")
                fi
            fi
        fi
    done < <(get_profile_files "$EFFECTIVE_PROFILE" "$BASE_DIR" "commands")

    # Clear progress line
    if [[ "$DRY_RUN" != "true" ]] && [[ $total_files -gt 0 ]]; then
        clear_progress
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ $commands_count -gt 0 ]]; then
            echo "✓ Installed $commands_count agent-os commands"
        fi
    fi
}

# Create agent-os folder structure
create_agent_os_folder() {
    if [[ "$DRY_RUN" != "true" ]]; then
        print_status "Installing agent-os folder"
    fi

    # Create the main agent-os folder
    ensure_dir "$PROJECT_DIR/agent-os"

    # Create the configuration file
    local config_file=$(write_project_config "$EFFECTIVE_VERSION" "$EFFECTIVE_PROFILE" \
        "$EFFECTIVE_CLAUDE_CODE_COMMANDS" "$EFFECTIVE_USE_CLAUDE_CODE_SUBAGENTS" \
        "$EFFECTIVE_AGENT_OS_COMMANDS" "$EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS")
    if [[ "$DRY_RUN" == "true" && -n "$config_file" ]]; then
        INSTALLED_FILES+=("$config_file")
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        echo "✓ Created agent-os folder"
        echo "✓ Created agent-os project configuration"
    fi
}

# Perform fresh installation
perform_installation() {
    # Initialize transactional staging (unless dry-run)
    if [[ "$DRY_RUN" != "true" ]]; then
        init_staging "$PROJECT_DIR"
        # Set up trap handler for automatic rollback on failure/interrupt
        trap 'rollback_staging; exit 1' EXIT ERR INT TERM
    fi

    # Show dry run warning at the top if applicable
    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "DRY RUN - No files will be actually created"
        echo ""
    fi

    # Display configuration at the top
    echo ""
    print_status "Configuration:"
    echo -e "  Profile: ${YELLOW}$EFFECTIVE_PROFILE${NC}"
    echo -e "  Claude Code commands: ${YELLOW}$EFFECTIVE_CLAUDE_CODE_COMMANDS${NC}"
    echo -e "  Use Claude Code subagents: ${YELLOW}$EFFECTIVE_USE_CLAUDE_CODE_SUBAGENTS${NC}"
    echo -e "  Standards as Claude Code Skills: ${YELLOW}$EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS${NC}"
    echo -e "  Agent OS commands: ${YELLOW}$EFFECTIVE_AGENT_OS_COMMANDS${NC}"
    echo ""

    # In dry run mode, just collect files silently
    if [[ "$DRY_RUN" == "true" ]]; then
        # Collect files without output
        create_agent_os_folder
        install_standards

        # Install Claude Code files if enabled
        if [[ "$EFFECTIVE_CLAUDE_CODE_COMMANDS" == "true" ]]; then
            if [[ "$EFFECTIVE_USE_CLAUDE_CODE_SUBAGENTS" == "true" ]]; then
                install_claude_code_commands_with_delegation
                install_claude_code_agents
            else
                install_claude_code_commands_without_delegation
            fi
            install_claude_code_skills
            install_improve_skills_command
        fi

        # Install agent-os commands if enabled
        if [[ "$EFFECTIVE_AGENT_OS_COMMANDS" == "true" ]]; then
            install_agent_os_commands
        fi

        echo ""
        print_status "The following files would be created:"
        for file in "${INSTALLED_FILES[@]}"; do
            # Make paths relative to project root
            local relative_path="${file#$PROJECT_DIR/}"
            echo "  - $relative_path"
        done
    else
        # Normal installation with output
        create_agent_os_folder
        echo ""

        install_standards
        echo ""

        # Install Claude Code files if enabled
        if [[ "$EFFECTIVE_CLAUDE_CODE_COMMANDS" == "true" ]]; then
            if [[ "$EFFECTIVE_USE_CLAUDE_CODE_SUBAGENTS" == "true" ]]; then
                install_claude_code_commands_with_delegation
                echo ""
                install_claude_code_agents
                echo ""
            else
                install_claude_code_commands_without_delegation
                echo ""
            fi
            install_claude_code_skills
            install_improve_skills_command
            echo ""
        fi

        # Install agent-os commands if enabled
        if [[ "$EFFECTIVE_AGENT_OS_COMMANDS" == "true" ]]; then
            install_agent_os_commands
            echo ""
        fi
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        read -p "Proceed with actual installation? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            DRY_RUN="false"
            INSTALLED_FILES=()
            perform_installation
        fi
    else
        # Commit staged files to final destination
        echo ""
        commit_staging "$PROJECT_DIR"

        # Disable trap (installation succeeded)
        trap - EXIT ERR INT TERM

        print_success "Agent OS has been successfully installed in your project!"
        echo ""
        echo -e "${GREEN}Visit the docs for guides on how to use Agent OS: https://buildermethods.com/agent-os${NC}"
        echo ""
    fi
}

# Handle re-installation
handle_reinstallation() {
    print_section "Re-installation"

    print_warning "This will DELETE your current agent-os/ folder and reinstall from scratch."
    echo ""

    # Check for Claude Code files
    if [[ -d "$PROJECT_DIR/.claude/agents/agent-os" ]] || [[ -d "$PROJECT_DIR/.claude/commands/agent-os" ]]; then
        print_warning "This will also DELETE:"
        [[ -d "$PROJECT_DIR/.claude/agents/agent-os" ]] && echo "  - .claude/agents/agent-os/"
        [[ -d "$PROJECT_DIR/.claude/commands/agent-os" ]] && echo "  - .claude/commands/agent-os/"
        echo ""
    fi

    read -p "Are you sure you want to proceed? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Re-installation cancelled"
        exit 0
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        print_status "Removing existing installation..."
        rm -rf "$PROJECT_DIR/agent-os"
        rm -rf "$PROJECT_DIR/.claude/agents/agent-os"
        rm -rf "$PROJECT_DIR/.claude/commands/agent-os"
        echo "✓ Existing installation removed"
        echo ""
    fi

    perform_installation
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------

main() {
    print_section "Agent OS Project Installation"

    # Parse command line arguments
    parse_arguments "$@"

    # Check if we're trying to install in the base installation directory
    check_not_base_installation

    # Validate base installation using common function
    validate_base_installation

    # Load configuration
    load_configuration

    # Run pre-flight validation (unless dry-run, which validates anyway)
    if ! run_preflight_validation "$EFFECTIVE_PROFILE" "$BASE_DIR" "$PRESET" \
        "$EFFECTIVE_CLAUDE_CODE_COMMANDS" "$EFFECTIVE_USE_CLAUDE_CODE_SUBAGENTS" \
        "$EFFECTIVE_AGENT_OS_COMMANDS" "$EFFECTIVE_STANDARDS_AS_CLAUDE_CODE_SKILLS"; then
        exit 1
    fi

    # Check if Agent OS is already installed
    if is_agent_os_installed "$PROJECT_DIR"; then
        if [[ "$RE_INSTALL" == "true" ]]; then
            handle_reinstallation
        else
            # Delegate to update script
            print_status "Agent OS is already installed. Running update..."
            exec "$BASE_DIR/scripts/project-update.sh" "$@"
        fi
    else
        # Fresh installation
        perform_installation
    fi
}

# Run main function
main "$@"
