# Quick Start Guide

Get Agent OS installed and running in your project in 5 minutes. This guide assumes you have a basic understanding of command-line tools and Git.

## Prerequisites

Before you start, make sure you have:
- A code project (Git repository)
- Command line / terminal access
- An AI coding tool (Claude Code, Cursor, etc.)

## Step 1: Install Agent OS

First, navigate to your project directory:

```bash
cd /path/to/your/project
```

Then install Agent OS with the appropriate preset:

### For Claude Code Users

```bash
# Recommended for most users
./scripts/project-install.sh --preset claude-code-full
```

### For Cursor/Windsurf Users

```bash
./scripts/project-install.sh --preset cursor
```

### For Beginners or Simple Projects

```bash
./scripts/project-install.sh --preset claude-code-basic
```

**What just happened?**
Agent OS has been installed in your project with the preset configuration. It created a `config.yml` file and set up all the necessary commands and workflows.

*💡 Don't know which preset to choose? See the [Presets Guide](PRESETS.md) for detailed comparisons.*

## Step 2: Verify Installation

Check that Agent OS is installed correctly:

```bash
ls -la
```

You should see:
- `.claude/` directory (for Claude Code users) or `agent-os/` directory
- `config.yml` file
- `profiles/` directory

## Step 3: Create Your First Specification

Let's create a simple feature specification to see Agent OS in action.

```bash
# For Claude Code users, run this in Claude Code
/shape-spec
```

For non-Claude Code users:
```bash
# Find the shape-spec command in your agent-os directory
./agent-os/commands/shape-spec.md
```

### Example: Adding a Login Feature

When prompted, describe the feature you want to build:

> "I need to add user login functionality with email and password authentication, including a login form, password validation, and session management."

Agent OS will guide you through questions to gather all the requirements.

**What just happened?**
The `shape-spec` command helped you create detailed requirements for your feature. This specification will guide the AI agent when implementing the feature.

## Step 4: Create Implementation Tasks

Now let's turn the specification into actionable tasks:

```bash
# In Claude Code
/create-tasks
```

Agent OS will analyze your specification and create a list of implementation tasks.

**What just happened?**
Agent OS broke down your feature specification into specific, actionable development tasks that an AI agent can implement step by step.

## Step 5: Implement the Feature

Finally, let's implement the feature:

```bash
# In Claude Code
/implement-tasks
```

Agent OS will now implement the feature following the tasks it created.

**What just happened?**
Agent OS is using the specification and task list to implement your feature with all the details and requirements you specified.

## Step 6: Review and Iterate

After implementation, review the changes:

```bash
git status
git diff
```

Make any adjustments needed, then commit your changes:

```bash
git add .
git commit -m "Add user login feature"
```

## Common Commands

Here are the most common commands you'll use:

| Command | What it does | When to use |
|---------|--------------|-------------|
| `/plan-product` | Creates product mission, roadmap, and tech stack | Starting a new project |
| `/shape-spec` | Gathers requirements for a feature | Planning a new feature |
| `/write-spec` | Creates technical specifications | After gathering requirements |
| `/create-tasks` | Breaks specs into development tasks | Before implementation |
| `/implement-tasks` | Builds the feature | When ready to code |
| `/orchestrate-tasks` | Manages complex multi-agent projects | For large features |

## Troubleshooting

### "Command not found" error

Make sure you're using the command in the right context:
- Claude Code users: Type commands directly in Claude Code
- Other tools: Run the markdown files from your `agent-os/commands/` directory

### Installation fails

Check that:
1. You're in a Git repository
2. You have write permissions in the project directory
3. The scripts folder exists and is executable

### Can't decide on a preset?

Start with `claude-code-basic` - you can always change it later by editing `config.yml` and running:
```bash
./scripts/project-update.sh
```

## What's Next?

- 📚 **Learn about presets** - [Presets Guide](PRESETS.md)
- 📖 **Understand key concepts** - [Glossary](GLOSSARY.md)
- 🎯 **Create custom profiles** - [Custom Profiles Guide](CUSTOM_PROFILES.md)
- ❓ **Get answers** - [FAQ](FAQ.md)

## Need Help?

- Check our [FAQ](FAQ.md) for common questions
- Open an issue on GitHub
- Join the [Builder Methods Pro](https://buildermethods.com/pro) community for support

Congratulations! You've successfully installed and used Agent OS. You're on your way to building better code with AI assistance.