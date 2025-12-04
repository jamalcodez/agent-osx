# Creating Custom Profiles

This guide shows you how to create custom agent-os profiles tailored to your project needs.

## Quick Start

```bash
# 1. Create a new profile
cd ~/agent-os
./scripts/create-profile.sh my-custom-profile

# 2. Add your content to the profile
cd profiles/my-custom-profile
# Edit commands/, agents/, standards/, workflows/

# 3. Install your profile
cd ~/my-project
~/agent-os/scripts/project-install.sh \
  --profile my-custom-profile \
  --preset claude-code-full
```

## Profile Structure

A profile contains these directories:

```
profiles/my-custom-profile/
├── commands/          # Slash commands for Claude Code or other tools
│   ├── my-command/
│   │   ├── single-agent/   # For embedded agent mode
│   │   │   └── my-command.md
│   │   └── multi-agent/    # For subagent delegation mode
│   │       └── my-command.md
│   └── another-command/
│       └── ...
├── agents/            # Agent definitions (for subagent mode)
│   ├── my-agent.md
│   └── another-agent.md
├── standards/         # Coding standards and guidelines
│   ├── coding/
│   │   ├── style.md
│   │   └── naming.md
│   ├── testing/
│   │   └── unit-tests.md
│   └── security/
│       └── auth.md
└── workflows/         # Reusable workflow snippets
    ├── planning/
    │   └── gather-requirements.md
    └── implementation/
        └── write-tests.md
```

## Template Syntax

Agent-os templates support powerful features for dynamic content:

### 1. Workflow Inclusion

Include reusable workflow snippets:

```markdown
## Step 1: Gather Requirements

{{workflows/planning/gather-requirements}}
```

### 2. Standards Inclusion

Include coding standards:

```markdown
## Standards to Follow

{{standards/coding/*.md}}        # Include all coding standards
{{standards/testing/unit-tests.md}}  # Include specific standard
```

### 3. Conditional Compilation

Show content based on configuration:

```markdown
IF{{use_claude_code_subagents}}
Use the **my-agent** subagent to handle this task.
ENDIF{{use_claude_code_subagents}}

UNLESS{{use_claude_code_subagents}}
Handle this task inline with the following steps:
1. Step one
2. Step two
ENDUNLESS{{use_claude_code_subagents}}
```

### 4. Phase Embedding

Embed numbered phases for structured workflows:

```markdown
{{PHASE}}1. Initial Setup
- Create project structure
- Initialize configuration

{{PHASE}}2. Implementation
- Write core functionality
- Add error handling

{{PHASE}}3. Testing
- Write unit tests
- Run test suite
```

When compiled in single-agent mode, this becomes:
```markdown
### Phase 1: Initial Setup
- Create project structure
- Initialize configuration

### Phase 2: Implementation
...
```

## Example: Simple Custom Profile

Let's create a profile for React development:

### Step 1: Create Profile Structure

```bash
cd ~/agent-os
./scripts/create-profile.sh react-dev
cd profiles/react-dev
```

### Step 2: Create a Command

```bash
# Create directory
mkdir -p commands/create-component/single-agent

# Create the command file
cat > commands/create-component/single-agent/create-component.md << 'EOF'
---
name: create-component
description: Create a new React component with tests
---

# Create React Component

You will create a new React component following our standards.

## Standards

{{standards/react/*.md}}
{{standards/testing/*.md}}

## Workflow

{{PHASE}}1. Component Structure
- Create component file in `src/components/`
- Use TypeScript with proper types
- Follow functional component pattern

{{PHASE}}2. Component Implementation
- Implement the component logic
- Add PropTypes or TypeScript interfaces
- Include JSDoc comments

{{PHASE}}3. Styling
- Create corresponding CSS/SCSS file
- Use CSS modules or styled-components
- Follow responsive design principles

{{PHASE}}4. Testing
- Create test file: `ComponentName.test.tsx`
- Write unit tests for all props
- Test edge cases and error states

{{PHASE}}5. Documentation
- Add usage examples in comments
- Document all props
- Include Storybook story if applicable

## Ask the User

Before starting, ask the user:
1. Component name
2. Component purpose/functionality
3. Required props
4. Any specific requirements
EOF
```

### Step 3: Create Standards

```bash
mkdir -p standards/react

cat > standards/react/component-standards.md << 'EOF'
# React Component Standards

## Naming
- Use PascalCase for component names
- File name should match component name
- Use descriptive names (e.g., `UserProfileCard`, not `Card`)

## Structure
```typescript
// Imports
import React from 'react';
import styles from './ComponentName.module.css';

// Types/Interfaces
interface ComponentNameProps {
  title: string;
  onAction?: () => void;
}

// Component
export const ComponentName: React.FC<ComponentNameProps> = ({
  title,
  onAction
}) => {
  return (
    <div className={styles.container}>
      {/* Component JSX */}
    </div>
  );
};
```

## Best Practices
- Keep components small and focused
- Extract reusable logic into hooks
- Use TypeScript for type safety
- Always handle loading and error states
EOF

mkdir -p standards/testing

cat > standards/testing/react-testing.md << 'EOF'
# React Testing Standards

## Testing Library
Use React Testing Library with Jest.

## What to Test
- Component renders without errors
- Props are used correctly
- User interactions work as expected
- Conditional rendering works
- Error boundaries catch errors

## Example Test
```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { ComponentName } from './ComponentName';

describe('ComponentName', () => {
  it('renders with required props', () => {
    render(<ComponentName title="Test" />);
    expect(screen.getByText('Test')).toBeInTheDocument();
  });

  it('handles user interaction', () => {
    const onAction = jest.fn();
    render(<ComponentName title="Test" onAction={onAction} />);
    fireEvent.click(screen.getByRole('button'));
    expect(onAction).toHaveBeenCalled();
  });
});
```
EOF
```

### Step 4: Create Workflows

```bash
mkdir -p workflows/react

cat > workflows/react/component-checklist.md << 'EOF'
## Component Checklist

Before completing, verify:
- [ ] Component follows naming conventions
- [ ] TypeScript types are defined
- [ ] PropTypes or interfaces documented
- [ ] Responsive design implemented
- [ ] Accessibility attributes added (ARIA labels, roles)
- [ ] Unit tests written and passing
- [ ] Error states handled
- [ ] Loading states handled
- [ ] Component is exported from index
EOF
```

### Step 5: Install and Test

```bash
cd ~/my-react-project
~/agent-os/scripts/project-install.sh \
  --profile react-dev \
  --preset claude-code-simple

# Check the installed command
cat .claude/commands/create-component.md
```

## Example: Multi-Agent Profile

For complex workflows with subagents:

```bash
mkdir -p profiles/fullstack/commands/build-feature/multi-agent
mkdir -p profiles/fullstack/agents

# Main command (delegates to subagents)
cat > profiles/fullstack/commands/build-feature/multi-agent/build-feature.md << 'EOF'
---
name: build-feature
description: Build a full-stack feature with frontend, backend, and tests
---

# Build Full-Stack Feature

This command orchestrates building a complete feature.

## Standards
{{standards/architecture/*.md}}

## Process

### Phase 1: Planning
Use the **feature-planner** agent to:
- Analyze requirements
- Create technical spec
- Identify dependencies

### Phase 2: Backend Development
Use the **backend-developer** agent to:
- Create API endpoints
- Implement business logic
- Add database migrations

### Phase 3: Frontend Development
Use the **frontend-developer** agent to:
- Create UI components
- Integrate with backend
- Add client-side validation

### Phase 4: Testing
Use the **test-engineer** agent to:
- Write integration tests
- Write E2E tests
- Verify all functionality
EOF

# Create subagents
cat > profiles/fullstack/agents/feature-planner.md << 'EOF'
---
name: feature-planner
description: Plans feature architecture and creates technical specs
tools: Write, Read, Bash
---

# Feature Planning Agent

You are a technical architect who creates detailed feature specifications.

## Your Process

{{workflows/planning/technical-spec}}

## Standards

{{standards/architecture/*.md}}
{{standards/api-design/*.md}}

## Deliverables

Create these files:
1. `docs/specs/[feature-name].md` - Technical specification
2. `docs/api/[feature-name].md` - API design
3. `docs/db/[feature-name].sql` - Database schema
EOF
```

## Configuration Presets

When installing a profile, use presets to control behavior:

### claude-code-full
Best for comprehensive Claude Code usage:
```bash
~/agent-os/scripts/project-install.sh \
  --profile my-profile \
  --preset claude-code-full
```
- Claude Code commands: ✓
- Subagents: ✓
- Standards as Skills: ✓
- Agent-os commands: ✗

### claude-code-simple
For simpler single-agent mode:
```bash
~/agent-os/scripts/project-install.sh \
  --profile my-profile \
  --preset claude-code-simple
```
- Claude Code commands: ✓
- Subagents: ✗
- Standards as Skills: ✓
- Agent-os commands: ✗

### cursor
Optimized for Cursor IDE:
```bash
~/agent-os/scripts/project-install.sh \
  --profile my-profile \
  --preset cursor
```
- Claude Code commands: ✗
- Subagents: ✗
- Standards as Skills: ✗
- Agent-os commands: ✓

### multi-tool
Use both Claude Code and agent-os:
```bash
~/agent-os/scripts/project-install.sh \
  --profile my-profile \
  --preset multi-tool
```
- Claude Code commands: ✓
- Subagents: ✓
- Standards as Skills: ✓
- Agent-os commands: ✓

## Best Practices

### 1. Keep Commands Focused
Each command should do one thing well:
- ✓ Good: `create-component`, `write-tests`, `refactor-code`
- ✗ Bad: `do-everything`

### 2. Use Workflows for Reusability
Extract common patterns into workflows:
```markdown
workflows/
├── planning/
│   ├── gather-requirements.md
│   └── create-spec.md
├── implementation/
│   ├── write-code.md
│   └── add-tests.md
└── review/
    └── code-review-checklist.md
```

### 3. Organize Standards by Category
```markdown
standards/
├── language/
│   ├── typescript.md
│   └── python.md
├── framework/
│   ├── react.md
│   └── django.md
├── testing/
│   └── unit-tests.md
└── security/
    └── auth.md
```

### 4. Version Your Profile
```bash
# Tag profile versions
git tag -a profile-v1.0 -m "React dev profile v1.0"
git push --tags
```

### 5. Test Your Profile
Always test after changes:
```bash
# Test in a scratch project
mkdir -p /tmp/test-profile
cd /tmp/test-profile
git init
~/agent-os/scripts/project-install.sh \
  --profile my-profile \
  --preset claude-code-full \
  --dry-run

# Check the output
cat .claude/commands/my-command.md
```

## Sharing Profiles

### Option 1: Separate Repository
```bash
# Create profile repo
git init my-profile
cd my-profile
# Copy profile structure
cp -r ~/agent-os/profiles/my-profile/* .
git add .
git commit -m "Initial profile"
git push

# Others can install
git clone https://github.com/you/my-profile
mv my-profile ~/agent-os/profiles/
```

### Option 2: Fork agent-os
1. Fork the agent-os repository
2. Add your profile to `profiles/`
3. Submit a pull request to share with community

## Troubleshooting

### Profile Not Found
```bash
# Check profile exists
ls ~/agent-os/profiles/my-profile

# Use full path if needed
~/agent-os/scripts/project-install.sh \
  --profile /full/path/to/my-profile
```

### Template Not Compiling
```bash
# Validate template syntax
~/agent-os/scripts/validate-template.sh \
  ~/agent-os/profiles/my-profile/commands/my-command.md

# Check for common issues:
# - Unclosed IF/ENDIF blocks
# - Invalid workflow paths
# - Syntax errors in frontmatter
```

### Standards Not Included
```bash
# Check standards exist
ls ~/agent-os/profiles/my-profile/standards/

# Verify glob patterns
{{standards/coding/*.md}}     # Matches all .md in coding/
{{standards/coding/style.md}} # Matches specific file
```

## Advanced Features

### Conditional Content by Preset

Use configuration flags in templates:

```markdown
IF{{use_claude_code_subagents}}
## Using Subagents
Delegate to specialized agents:
- **planner** for architecture
- **coder** for implementation
- **tester** for validation
ENDIF{{use_claude_code_subagents}}

UNLESS{{use_claude_code_subagents}}
## Single-Agent Mode
Follow these steps yourself:
1. Plan the architecture
2. Implement the code
3. Write tests
ENDUNLESS{{use_claude_code_subagents}}
```

### Dynamic Workflows

Create workflow templates that adapt:

```markdown
{{workflows/planning/create-spec}}

IF{{standards_as_claude_code_skills}}
Your coding standards are available as Claude Code Skills.
Reference them during implementation.
ENDIF{{standards_as_claude_code_skills}}

UNLESS{{standards_as_claude_code_skills}}
Follow these coding standards:
{{standards/coding/*.md}}
ENDUNLESS{{standards_as_claude_code_skills}}
```

## Related Documentation

- [Template Syntax Reference](../profiles/default/TEMPLATE_SYNTAX.md)
- [Systems Thinking Analysis](../ANALYSIS.md)
- [Testing Guide](../tests/README.md)

## Examples

See example profiles in:
- `profiles/default/` - The default agent-os profile
- Community profiles: https://github.com/topics/agent-os-profile
