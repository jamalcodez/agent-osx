# Frequently Asked Questions

Find answers to common questions about Agent OS. Can't find what you're looking for? [Open an issue](https://github.com/builderio/agent-os/issues) on GitHub.

## Installation

### Q: Why doesn't Agent OS use `git clone` for installation?

**A:** Agent OS uses a download-based installation approach for several important reasons:

1. **No Git Required**: Many users don't have git installed or don't want to clone repositories just to use a tool
2. **Clean Project Structure**: Downloading avoids creating .git directories in your projects
3. **Reliable Versioning**: Installing from a specific tag/branch ensures consistent versions
4. **Transactional Safety**: The installation can roll back on failure, which is harder with partial git clones
5. **Performance**: The system uses intelligent caching to make subsequent installations 30× faster

### Q: Can I still use git if I want to?

**A:** Yes! While the default installation uses curl, you can:

1. **Clone and install locally**:
   ```bash
   git clone https://github.com/buildermethods/agent-os.git
   cd agent-os
   ./scripts/base-install.sh
   ```

2. **Install from your fork**:
   ```bash
   curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/agent-os/main/scripts/base-install.sh | bash -s -- --repo YOUR_USERNAME/agent-os
   ```

3. **Work with branches**:
   ```bash
   ./scripts/base-install.sh --repo YOUR_USERNAME/agent-os --branch feature-xyz
   ```

### Q: How do the two-phase installations work?

**A:** Agent OS uses a two-phase architecture:

1. **Base Installation** (Phase 1): Installs the framework to `~/agent-os/`
   - Downloads profiles, scripts, and templates
   - Sets up global configuration
   - Done once per system

2. **Project Installation** (Phase 2): Installs into your project directory
   - Compiles templates with project-specific context
   - Creates `./agent-os/` directory with your standards
   - Generates commands/agents for your AI coding tool

This separation allows:
- Fast project setup (cached templates)
- Project customization without affecting global installation
- Ability to commit generated files to your project's git

### Q: What if I need to test changes on a development branch?

**A:** You have several options:

1. **Use branch parameters**:
   ```bash
   ./scripts/base-install.sh --repo YOUR_USERNAME/agent-os --branch your-branch-name
   ```

2. **Clone and install locally**:
   ```bash
   git clone -b your-branch https://github.com/YOUR_USERNAME/agent-os.git agent-os-dev
   cd agent-os-dev
   ./scripts/base-install.sh
   ```

3. **Use the development mode** (coming soon):
   ```bash
   ./scripts/dev-install.sh your-branch-name
   ```

### Q: Does the download approach work offline?

**A:** Yes, Agent OS has a caching system:

1. **First installation**: Downloads and caches files
2. **Subsequent installations**: Uses cached files (30× faster)
3. **Offline mode**: Can install from cache without internet

### Q: How do I update Agent OS?

**A:** Updates are simple:

```bash
# Update base installation
~/agent-os/scripts/base-install.sh

# Update project installation
~/agent-os/scripts/project-update.sh
```

The update system will:
- Check for newer versions
- Show what will change
- Allow selective updates (profiles, scripts, etc.)
- Create backups before updating

### Q: Can I customize the installation?

**A:** Yes! Agent OS supports:

1. **Custom profiles**: Create your own profiles in `~/agent-os/profiles/`
2. **Custom standards**: Modify `~/agent-os/profiles/default/standards/`
3. **Custom presets**: Edit `~/agent-os/config.yml`
4. **Project-specific overrides**: Each project can customize its installation

### Q: What gets installed in my project?

**A:** The project installation creates:

- `agent-os/standards/`: Your coding standards and conventions
- `.claude/commands/`: Claude Code commands (if enabled)
- `.claude/agents/`: Claude Code agents (if enabled)
- `.claude/skills/`: Claude Code Skills (if enabled)

All generated files are designed to be:
- Human-readable and editable
- Committed to your project's git repository
- Customizable for your project's needs

### Q: Is my data sent anywhere?

**A:** No. Agent OS:

1. Only downloads from GitHub during installation
2. Does not send any of your code or data externally
3. Runs entirely on your local machine
4. Only uses the GitHub API to fetch file lists during installation

### Q: How do I uninstall Agent OS?

**A:** Removal is straightforward:

```bash
# Remove base installation
rm -rf ~/agent-os

# Remove from a specific project
rm -rf project-folder/agent-os
rm -rf project-folder/.claude/commands/agent-os
```

There are no system-wide changes or hidden files outside these directories.

## Getting Started

### What is Agent OS?

Agent OS is a spec-driven agentic development system that transforms AI coding agents from confused interns into productive developers. It provides structured workflows that capture your standards, tech stack, and codebase details to help AI agents ship quality code on the first try.

### Is Agent OS for me?

Agent OS is for you if you:
- Use AI coding assistants (Claude Code, Cursor, Windsurf, etc.)
- Want more consistent, reliable output from your AI assistants
- Work on projects that require understanding complex codebases
- Need to maintain consistent coding standards across AI-generated code
- Want to accelerate feature development while maintaining quality

### What AI tools does Agent OS work with?

Agent OS works with any AI coding tool, including:
- Claude Code (full integration with Skills and subagents)
- Cursor
- Windsurf
- Continue.dev
- Any other AI coding assistant

## Installation and Setup

### How do I install Agent OS?

```bash
# Navigate to your project
cd /path/to/your-project

# Install with a preset
~/agent-os/scripts/project-install.sh --preset claude-code-full
```

See the [Quick Start Guide](QUICK_START.md) for detailed instructions.

### Which preset should I choose?

- **claude-code-full**: Best for Claude Code users with complex projects
- **claude-code-simple**: For simpler projects where speed is important
- **claude-code-basic**: Perfect for beginners or learning Agent OS
- **cursor**: Optimized for Cursor and other non-Claude tools
- **multi-tool**: If you switch between multiple AI tools

See the [Presets Guide](PRESETS.md) for detailed comparisons.

### Can I change presets later?

Yes! Edit your `config.yml` file to change the preset, then run:
```bash
~/agent-os/scripts/project-update.sh
```

### Installation failed. What should I do?

1. Check you're in a Git repository
2. Ensure you have write permissions
3. Verify the scripts directory exists:
   ```bash
   ls ~/agent-os/scripts/
   ```
4. Try with verbose output:
   ```bash
   ~/agent-os/scripts/project-install.sh --preset claude-code-basic -v
   ```

## Usage

### How do I use Agent OS commands?

For Claude Code users, type commands directly:
```
/shape-spec
/implement-tasks
```

For other tools, find commands in your `agent-os/commands/` directory and follow the instructions in the markdown files.

### What's the typical workflow?

1. `/plan-product` - Define your product's mission and roadmap
2. `/shape-spec` - Gather requirements for a feature
3. `/write-spec` - Create technical specifications
4. `/create-tasks` - Break specs into implementation tasks
5. `/implement-tasks` - Build the feature
6. Run tests and verification

### Can I use Agent OS for bug fixes?

Yes! While Agent OS is optimized for feature development, you can use it for bug fixes by:
1. Using `/shape-spec` to describe the bug and expected behavior
2. Following the normal workflow to implement the fix

## Configuration

### What's the difference between a preset and a profile?

- **Preset**: A pre-configured setup optimized for specific tools/workflows
- **Profile**: A complete collection of settings, commands, agents, and standards

Presets are like choosing a pre-built house plan, while profiles are like customizing every detail of your house.

### Can I customize Agent OS?

Absolutely! You can:
- Create custom profiles
- Modify existing workflows
- Add your own standards
- Create new commands
- Adjust agent behaviors

See the [Custom Profiles Guide](CUSTOM_PROFILES.md) to learn how.

### Where are my configurations stored?

- Main config: `config.yml`
- Profiles: `profiles/` directory
- Claude Code files: `.claude/` directory
- Agent OS files: `agent-os/` directory

## Troubleshooting

### Commands aren't working in Claude Code

1. Ensure you've installed with a claude-code preset
2. Check that commands are in `.claude/commands/`
3. Restart Claude Code
4. Verify `config.yml` has `claude_code_commands: true`

### Agent OS seems slow

Agent OS includes caching for faster reinstallation:
- First install: ~15 seconds
- With cache: ~0.5 seconds

If it's still slow, check:
- Disk space (cache needs space to work)
- Antivirus software scanning files
- Network connectivity (for initial downloads)

### My AI agent isn't following the specification

1. Ensure the specification is clear and complete
2. Check that standards are properly loaded
3. Verify you're using the correct command for your task
4. Try being more specific in your requirements

### I see errors about missing files

Run the update script to refresh your installation:
```bash
~/agent-os/scripts/project-update.sh
```

If errors persist, try a clean reinstall:
```bash
# Backup your config.yml
cp config.yml config.yml.backup

# Remove Agent OS files
rm -rf .claude/ agent-os/ profiles/

# Reinstall
~/agent-os/scripts/project-install.sh --preset [your-preset]
```

## Advanced

### Can I use Agent OS with multiple projects?

Yes! Each project gets its own Agent OS installation. You can have different presets and profiles for different projects.

### How do I create my own preset?

1. Choose a base preset as a template
2. Create a custom profile with your settings
3. Set `preset: custom` in `config.yml`
4. Configure everything manually

### Can I contribute to Agent OS?

Absolutely! See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines. Areas where help is especially welcome:
- Documentation improvements
- Bug reports
- Feature suggestions
- Community support

### Where can I get help?

- 📖 Check this FAQ and other documentation
- 🐛 [Open an issue](https://github.com/builderio/agent-os/issues) on GitHub
- 👥 Join [Builder Methods Pro](https://buildermethods.com/pro) for community support
- 📧 Email support for Pro members

## Performance

### How much disk space does Agent OS use?

- Fresh install: ~2-5 MB
- With cache: ~10-20 MB
- Cache grows with project size but has automatic cleanup

### Is Agent OS safe for production projects?

Yes! Agent OS includes:
- Automatic rollback on failure
- Dry-run mode for previewing changes
- Atomic operations to prevent broken states
- Extensive testing

However, always:
- Commit your code before major changes
- Test in a staging environment first
- Review AI-generated code before deploying

### Can I use Agent OS in CI/CD?

Yes! Agent OS can be integrated into CI/CD pipelines for:
- Automated testing
- Documentation generation
- Code review assistance
- Deployment preparations

---

Still have questions? We're here to help! Check the [Glossary](GLOSSARY.md) for term definitions or see the [Quick Start Guide](QUICK_START.md) for hands-on tutorials.