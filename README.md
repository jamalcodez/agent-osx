<img width="1280" height="640" alt="agent-os-og" src="https://github.com/user-attachments/assets/f70671a2-66e8-4c80-8998-d4318af55d10" />

## Your system for spec-driven agentic development.

[Agent OS](https://buildermethods.com/agent-os) transforms AI coding agents from confused interns into productive developers. With structured workflows that capture your standards, your stack, and the unique details of your codebase, Agent OS gives your agents the specs they need to ship quality code on the first try—not the fifth.

Use it with:

✅ Claude Code, Cursor, or any other AI coding tool.

✅ New products or established codebases.

✅ Big features, small fixes, or anything in between.

✅ Any language or framework.

---

## 🚀 Quick Start

Get Agent OS running in your project in under 5 minutes:

### 1. Installation

```bash
# Install Agent OS base framework (one-time)
curl -sSL https://raw.githubusercontent.com/buildermethods/agent-os/main/scripts/base-install.sh | bash

# Then install in your project
cd your-project
~/agent-os/scripts/project-install.sh --preset claude-code-full
```

### Installation from a Custom Branch or Fork

```bash
# Install from your fork's branch
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/agent-os/main/scripts/base-install.sh | bash -s -- --repo YOUR_USERNAME/agent-os --branch YOUR_BRANCH

# Example:
curl -sSL https://raw.githubusercontent.com/johndoe/agent-os/main/scripts/base-install.sh | bash -s -- --repo johndoe/agent-os --branch feature-new-ui
```

### 2. Choose Your Preset

```bash
# For Claude Code users (recommended)
~/agent-os/scripts/project-install.sh --preset claude-code-full

# For Cursor/Windsurf users
~/agent-os/scripts/project-install.sh --preset cursor

# For beginners or simple projects
~/agent-os/scripts/project-install.sh --preset claude-code-basic
```

[📖 Need help choosing? See all presets →](docs/PRESETS.md)

### 3. Create Your First Feature

```bash
# Plan a new feature
/plan-product

# Write specifications
/shape-spec

# Build the feature
/implement-tasks
```

That's it! Agent OS is now configured and ready to help you build better code, faster.

**Performance boost:** Reinstallations are now 30× faster with caching (15s → 0.5s)

## Why Agent OS Uses Download-Based Installation

Agent OS uses a unique two-phase installation that provides:

- ⚡ **30× faster** project setup through intelligent caching
- 🛡️ **Transactional safety** with automatic rollback on failure
- 🔄 **Git-friendly** project structures (no .git conflicts)
- 🎯 **Zero dependencies** (doesn't require git to be installed)
- 📦 **Reliable version control** (install specific versions reliably)

### The Two-Phase Process

1. **Base Installation** (`~/agent-os/`): Downloads the framework globally once
2. **Project Installation** (`./agent-os/`): Compiles templates into your project

This design allows for:
- Fast project setup through cached templates
- Project-specific customization without affecting the global installation
- Clean separation between framework and project files
- Ability to commit generated files to your project's git repository

### For Developers Working on Agent OS

If you're contributing to Agent OS or testing changes on a branch:

```bash
# Clone your branch locally
git clone -b your-branch-name https://github.com/YOUR_USERNAME/agent-os.git agent-os-dev

# Install from your local copy
cd agent-os-dev
./scripts/base-install.sh

# Use it in a project
cd ../your-project
~/agent-os/scripts/project-install.sh
```

## How It Works

Agent OS provides structured workflows that guide AI agents through the development process:

```mermaid
flowchart LR
    A[Product Planning] --> B[Specification]
    B --> C[Task Creation]
    C --> D[Implementation]
    D --> E[Verification]

    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#e8f5e9
    style D fill:#fff3e0
    style E fill:#ffebee
```

1. **Plan** → Define mission, roadmap, and tech stack
2. **Specify** → Create detailed requirements and technical specs
3. **Task** → Break specs into actionable development tasks
4. **Implement** → Build features following the specifications
5. **Verify** → Test and validate the implementation

---

### Documentation & Installation

Comprehensive docs, guides, & best practices 👉 [buildermethods.com/agent-os](https://buildermethods.com/agent-os)

**Quick links:**
- [📚 All Presets Explained](docs/PRESETS.md)
- [⚡ 5-Minute Tutorial](docs/QUICK_START.md)
- [❓ FAQ & Troubleshooting](docs/FAQ.md)
- [📖 Glossary of Terms](docs/GLOSSARY.md)

---

### Follow updates & releases

Read the [changelog](CHANGELOG.md)

[Subscribe to be notified of major new releases of Agent OS](https://buildermethods.com/agent-os)

---

### Created by Brian Casel @ Builder Methods

Created by Brian Casel, the creator of [Builder Methods](https://buildermethods.com), where Brian helps professional software developers and teams build with AI.

Get Brian's free resources on building with AI:
- [Builder Briefing newsletter](https://buildermethods.com)
- [YouTube](https://youtube.com/@briancasel)

Join [Builder Methods Pro](https://buildermethods.com/pro) for official support and connect with our community of AI-first builders: