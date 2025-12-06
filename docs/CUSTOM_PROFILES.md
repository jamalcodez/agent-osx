# Creating Custom Profiles

Custom profiles let you tailor Agent OS to your specific project needs, team preferences, and development workflow. This guide will help you create your own profile from scratch or by modifying an existing one.

## Why Create a Custom Profile?

You might want a custom profile to:
- **Add your own commands** for specific workflows
- **Include team-specific coding standards**
- **Add project-specific agent behaviors**
- **Create workflows for your tech stack**
- **Integrate with your existing tools**

## Quick Start: Create Your First Profile

### Option 1: Copy the Default Profile (Recommended)

The easiest way to start is by copying the default profile:

```bash
# 1. Copy the default profile
cp -r profiles/default profiles/my-profile

# 2. Use your custom profile
~/agent-osx/scripts/project-install.sh --profile my-profile --preset claude-code-full
```

### Option 2: Create from Scratch

```bash
# 1. Create a new empty profile
mkdir -p profiles/my-profile/{commands,agents,standards,workflows}

# 2. Create the minimal required files
touch profiles/my-profile/commands/.keep
touch profiles/my-profile/agents/.keep
touch profiles/my-profile/standards/.keep
touch profiles/my-profile/workflows/.keep

# 3. Use your profile
~/agent-osx/scripts/project-install.sh --profile my-profile --preset claude-code-simple
```

## Understanding Profile Structure

A profile contains four main directories:

### 📁 commands/
Slash commands that trigger workflows. Each command has:
- `single-agent/` - For simple, single-agent workflows
- `multi-agent/` - For complex workflows using subagents

### 📁 agents/
Agent definitions for subagent mode. Define specialized agents for different tasks.

### 📁 standards/
Your coding standards and guidelines. Organized by category:
- `coding/` - Style guides, naming conventions
- `testing/` - Testing standards and practices
- `security/` - Security guidelines
- `frontend/` - UI/UX standards
- `backend/` - API and server standards

### 📁 workflows/
Reusable workflow snippets that can be included in commands.

## Simple Customization Examples

### Adding Your Own Standards

1. Create a standards file:
```bash
mkdir -p profiles/my-profile/standards/coding
cat > profiles/my-profile/standards/coding/my-rules.md << 'EOF'
# My Team's Coding Rules

1. Always use TypeScript
2. Function names must be verbs
3. No hardcoded magic numbers
4. Add JSDoc comments to all public functions
EOF
```

2. Reference it in commands:
```markdown
{{standards/coding/my-rules.md}}
```

### Creating a Simple Command

1. Create the command structure:
```bash
mkdir -p profiles/my-profile/commands/my-cool-command/single-agent
```

2. Create the command file:
```bash
cat > profiles/my-profile/commands/my-cool-command/single-agent/my-cool-command.md << 'EOF'
# My Cool Command

This command does something cool for my project.

## Steps to Follow

1. First, do this
2. Then, do that
3. Finally, verify it works

{{standards/coding/my-rules.md}}
EOF
```

3. Use your command:
```bash
/my-cool-command
```

## Template Syntax (The Easy Parts)

You don't need to know everything about template syntax to start. Here are the most useful patterns:

### Including Standards

```markdown
## Standards to Follow

{{standards/coding/*.md}}  # Include all coding standards
{{standards/testing/unit-tests.md}}  # Include one specific file
```

### Including Workflows

```markdown
## Planning Phase

{{workflows/planning/gather-requirements.md}}
```

### Conditional Content (Advanced)

Show different content based on your configuration:

```markdown
IF{{use_claude_code_subagents}}
Use specialized agents for this task
ELSE
Handle it yourself with these steps:
1. Step one
2. Step two
ENDIF{{use_claude_code_subagents}}
```

## Real-World Example: React Profile

Here's how to create a profile optimized for React development:

### Step 1: Create the Profile

```bash
# Copy default profile as a starting point
cp -r profiles/default profiles/react-dev
```

### Step 2: Add React-Specific Standards

```bash
cat > profiles/react-dev/standards/react/components.md << 'EOF'
# React Component Standards

## Structure
- Use functional components with TypeScript
- File name matches component name (PascalCase)
- Co-locate styles: ComponentName.module.css
- Always export components with named exports

## Example
```typescript
import React from 'react';
import styles from './Button.module.css';

interface ButtonProps {
  children: React.ReactNode;
  onClick: () => void;
  variant?: 'primary' | 'secondary';
}

export const Button: React.FC<ButtonProps> = ({
  children,
  onClick,
  variant = 'primary'
}) => {
  return (
    <button
      className={`${styles.button} ${styles[variant]}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
};
```
EOF
```

### Step 3: Create a React-Specific Command

```bash
mkdir -p profiles/react-dev/commands/create-component/single-agent

cat > profiles/react-dev/commands/create-component/single-agent/create-component.md << 'EOF'
---
name: create-component
description: Create a new React component with TypeScript and styles
---

# Create React Component

I'll help you create a new React component following our standards.

{{standards/react/components.md}}

## What I need from you:

1. **Component name** (PascalCase, e.g., UserCard)
2. **What does it do?** (brief description)
3. **Any props it needs?** (list them with types)

## Once you provide those details, I will:

{{PHASE}}1. Create the component file
- Generate TypeScript interface for props
- Create the functional component
- Add JSDoc documentation

{{PHASE}}2. Add styling
- Create CSS module file
- Add base styles
- Include responsive design

{{PHASE}}3. Add tests
- Create test file with React Testing Library
- Write tests for all props
- Test user interactions

{{PHASE}}4. Add story (optional)
- Create Storybook story
- Document all variants

Ready to create your component!
EOF
```

### Step 4: Use Your Profile

```bash
~/agent-osx/scripts/project-install.sh --profile react-dev --preset claude-code-full
```

Now you can use your custom command:
```bash
/create-component
```
EOF
```

## Best Practices for Custom Profiles

### 1. Start Small
Don't try to customize everything at once. Start with:
- One custom command
- A few key standards
- Basic workflow adjustments

### 2. Copy and Modify
Always start by copying the default profile. It has all the basic structure you need.

### 3. Test Incrementally
After each change:
```bash
~/agent-osx/scripts/project-install.sh --profile my-profile --preset claude-code-basic --dry-run
```

### 4. Keep It Organized
- Use clear, descriptive names
- Group related files
- Add comments explaining complex parts

### 5. Document Your Profile
Create a README.md in your profile directory explaining:
- What the profile is for
- What customizations it includes
- How to use it

## Need More Help?

- Check the [Template Syntax Reference](../profiles/default/TEMPLATE_SYNTAX.md) for advanced features
- Look at the [default profile](../profiles/default/) for examples
- See [community profiles](https://github.com/topics/agent-os-profile) for inspiration
- Ask questions in GitHub issues

Remember: Custom profiles are powerful, but start simple and build up complexity as you need it!
