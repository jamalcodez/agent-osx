# Agent OS Template Language Reference

Agent OS uses a custom template language for composing commands, agents, workflows, and standards. Templates are processed during installation/update to generate the final files used by Claude Code and other AI coding tools.

## Table of Contents

1. [Workflow Inclusion](#workflow-inclusion)
2. [Standards References](#standards-references)
3. [Conditional Compilation](#conditional-compilation)
4. [PHASE Tag Embedding](#phase-tag-embedding)
5. [Processing Order](#processing-order)
6. [Best Practices](#best-practices)
7. [Common Patterns](#common-patterns)
8. [Troubleshooting](#troubleshooting)

---

## Workflow Inclusion

### Syntax

```markdown
{{workflows/path/to/workflow}}
```

### Description

Includes the content of a workflow file from `profiles/{profile}/workflows/`. Workflows can recursively include other workflows. The `.md` extension is automatically added.

### Examples

**Basic inclusion:**
```markdown
## Implementation Process

{{workflows/implementation/implement-tasks}}
```

**Multiple workflows:**
```markdown
## Planning Phase

{{workflows/planning/gather-product-info}}
{{workflows/planning/create-product-roadmap}}
```

**Nested workflows:**
Workflows can reference other workflows. For example, `implement-tasks.md` might contain:
```markdown
Step 1: Prepare
{{workflows/implementation/verify-prerequisites}}

Step 2: Execute
{{workflows/implementation/run-implementation}}
```

### Features

- **Recursive processing**: Workflows can include other workflows up to a reasonable depth
- **Circular detection**: The system detects and prevents infinite loops
- **Profile inheritance**: Workflows are resolved through the profile inheritance chain
- **Error handling**: Missing workflows generate warning messages in output

### Path Resolution

Paths are relative to `profiles/{profile}/workflows/`:
- `{{workflows/planning/roadmap}}` → `profiles/default/workflows/planning/roadmap.md`
- `{{workflows/implementation/test}}` → `profiles/default/workflows/implementation/test.md`

---

## Standards References

### Syntax

```markdown
{{standards/pattern}}
```

### Description

Generates references to standards files. Supports wildcards for including multiple standards. The output depends on the `standards_as_claude_code_skills` configuration:

- **When false** (default): Generates `@agent-os/standards/...` file references
- **When true**: Standards are converted to Skills, and references are omitted

### Examples

**All standards:**
```markdown
{{standards/*}}
```
Output (when skills disabled):
```
@agent-os/standards/global/conventions.md
@agent-os/standards/global/error-handling.md
@agent-os/standards/backend/api.md
@agent-os/standards/frontend/components.md
...
```

**Category wildcard:**
```markdown
{{standards/backend/*}}
```
Output:
```
@agent-os/standards/backend/api.md
@agent-os/standards/backend/models.md
@agent-os/standards/backend/queries.md
```

**Specific file:**
```markdown
{{standards/global/conventions.md}}
```
Output:
```
@agent-os/standards/global/conventions.md
```

**Multiple categories:**
```markdown
{{standards/global/*}}
{{standards/backend/*}}
{{standards/testing/*}}
```

### Wildcard Patterns

- `{{standards/*}}` - All standards files
- `{{standards/global/*}}` - All files in global/
- `{{standards/backend/*}}` - All files in backend/
- `{{standards/frontend/*}}` - All files in frontend/
- `{{standards/testing/*}}` - All files in testing/
- `{{standards/backend/api.md}}` - Specific file (no wildcard)

### Path Resolution

Paths are relative to `profiles/{profile}/standards/`:
- `{{standards/backend/api.md}}` → `profiles/default/standards/backend/api.md`

### Conditional Behavior

Standards references are typically wrapped in conditionals:
```markdown
{{UNLESS standards_as_claude_code_skills}}
## Standards Compliance

Follow these standards:
{{standards/*}}
{{ENDUNLESS standards_as_claude_code_skills}}
```

---

## Conditional Compilation

### Syntax

**If block (include when true):**
```markdown
{{IF flag_name}}
Content shown when flag is true
{{ENDIF flag_name}}
```

**Unless block (include when false):**
```markdown
{{UNLESS flag_name}}
Content shown when flag is false
{{ENDUNLESS flag_name}}
```

### Description

Conditionally includes or excludes content based on configuration flags. Content inside conditional blocks is only included in the final output if the condition matches.

### Available Flags

| Flag | Type | Description |
|------|------|-------------|
| `use_claude_code_subagents` | boolean | True when using Claude Code with subagents |
| `standards_as_claude_code_skills` | boolean | True when standards are converted to Skills |
| `compiled_single_command` | boolean | True when compiling embedded PHASE content (internal) |

### Examples

**Delegate to subagent or do inline:**
```markdown
{{IF use_claude_code_subagents}}
Use the **implementer** subagent to implement the tasks.
{{ENDIF use_claude_code_subagents}}

{{UNLESS use_claude_code_subagents}}
Follow these steps to implement:
1. Read the spec
2. Write the code
3. Test the implementation
{{ENDUNLESS use_claude_code_subagents}}
```

**Standards handling:**
```markdown
{{UNLESS standards_as_claude_code_skills}}
## Coding Standards

Ensure compliance with:
{{standards/*}}
{{ENDUNLESS standards_as_claude_code_skills}}
```

**Nested conditionals:**
```markdown
{{IF use_claude_code_subagents}}
  Use subagents for implementation.

  {{IF standards_as_claude_code_skills}}
  Subagents will use Skills for standards.
  {{ENDIF standards_as_claude_code_skills}}

  {{UNLESS standards_as_claude_code_skills}}
  Provide standards references to subagents.
  {{ENDUNLESS standards_as_claude_code_skills}}
{{ENDIF use_claude_code_subagents}}
```

### Nesting

- Conditionals can be nested up to reasonable depth
- The system tracks nesting level and detects unclosed blocks
- Both opening and closing tags must include the flag name
- Nesting level is reset at the start of each file

### Important Rules

1. **Matching tags**: Opening and closing tags must use the same flag name
2. **No mixing**: Don't mix IF with ENDUNLESS or vice versa
3. **Case sensitive**: Flag names are case-sensitive
4. **Whitespace**: Extra spaces around flag names are ignored
5. **Validation**: Unclosed blocks generate warnings but don't fail compilation

---

## PHASE Tag Embedding

### Syntax

```markdown
{{PHASE N: @agent-os/path/to/file.md}}
```

### Description

Used in single-agent mode commands to embed sub-command files with automatic header generation. Only processed when compilation mode is "embed".

### Examples

**Sequential phases:**
```markdown
Now implement the feature in these phases:

{{PHASE 1: @agent-os/commands/implement-tasks/1-determine-tasks.md}}

{{PHASE 2: @agent-os/commands/implement-tasks/2-implement-tasks.md}}

{{PHASE 3: @agent-os/commands/implement-tasks/3-verify-implementation.md}}
```

**Compiled output:**
```markdown
Now implement the feature in these phases:

# PHASE 1: Determine Tasks

[Content of 1-determine-tasks.md with all templates processed]

# PHASE 2: Implement Tasks

[Content of 2-implement-tasks.md with all templates processed]

# PHASE 3: Verify Implementation

[Content of 3-verify-implementation.md with all templates processed]
```

### Features

- **Automatic headers**: Each phase gets an H1 header with the phase number and title
- **Title extraction**: Title is extracted from the first H1 in the embedded file
- **Recursive processing**: Embedded files are fully processed (conditionals, workflows, standards)
- **Mode-dependent**: Only active when compile mode is "embed", ignored otherwise

### Usage Context

PHASE tags are used in:
- Single-agent mode commands (when `use_claude_code_subagents: false`)
- Main command files that orchestrate multiple steps
- Commands in `profiles/default/commands/*/single-agent/` directories

PHASE tags are **not** used in:
- Multi-agent mode commands (delegated to subagents instead)
- Agent definition files
- Workflow files (use workflow inclusion instead)

### Path Format

- Must start with `@agent-os/`
- Path is relative to profile root: `@agent-os/commands/...` → `profiles/default/commands/...`
- File must exist or compilation will show warning
- Must include `.md` extension

---

## Processing Order

Template compilation happens in this order:

### 1. Role Replacements (Deprecated)
`{{role.key}}` → Replaced with role-specific data (legacy feature)

### 2. Conditional Compilation
`{{IF ...}}` and `{{UNLESS ...}}` blocks are evaluated and included/excluded

### 3. Workflow Inclusion
`{{workflows/path}}` → Content recursively included

### 4. Standards References
`{{standards/pattern}}` → File references generated (or skipped if using Skills)

### 5. PHASE Tag Embedding (if mode="embed")
`{{PHASE N: ...}}` → Files embedded with headers

### 6. Special Tool Expansion
`Playwright` → Expanded to full tool list in agent files

### 7. File Writing
Final processed content written to destination

### Example Processing

**Input template:**
```markdown
{{IF use_claude_code_subagents}}
Use **implementer** subagent
{{ENDIF use_claude_code_subagents}}

{{workflows/implementation/implement-tasks}}

{{UNLESS standards_as_claude_code_skills}}
Standards: {{standards/global/*}}
{{ENDUNLESS standards_as_claude_code_skills}}
```

**Step 1 - After conditionals** (assume subagents=true, skills=false):
```markdown
Use **implementer** subagent

{{workflows/implementation/implement-tasks}}

Standards: {{standards/global/*}}
```

**Step 2 - After workflow inclusion:**
```markdown
Use **implementer** subagent

[Content of implement-tasks.md workflow]

Standards: {{standards/global/*}}
```

**Step 3 - After standards:**
```markdown
Use **implementer** subagent

[Content of implement-tasks.md workflow]

Standards: @agent-os/standards/global/conventions.md
@agent-os/standards/global/error-handling.md
```

---

## Best Practices

### 1. Use Descriptive Workflow Names

❌ **Bad:**
```markdown
{{workflows/impl}}
{{workflows/step1}}
```

✅ **Good:**
```markdown
{{workflows/implementation/implement-tasks}}
{{workflows/planning/create-product-roadmap}}
```

### 2. Always Close Conditional Blocks

❌ **Bad:**
```markdown
{{IF use_claude_code_subagents}}
Some content
```

✅ **Good:**
```markdown
{{IF use_claude_code_subagents}}
Some content
{{ENDIF use_claude_code_subagents}}
```

### 3. Use Standards Conditionals

❌ **Bad:**
```markdown
Follow these standards:
{{standards/*}}
```

✅ **Good:**
```markdown
{{UNLESS standards_as_claude_code_skills}}
Follow these standards:
{{standards/*}}
{{ENDUNLESS standards_as_claude_code_skills}}
```

### 4. Organize Workflows by Domain

✅ **Good structure:**
```
workflows/
├── planning/
│   ├── gather-requirements.md
│   └── create-roadmap.md
├── specification/
│   └── write-spec.md
└── implementation/
    ├── implement-tasks.md
    └── verify-implementation.md
```

### 5. Document Template Usage in Comments

```markdown
<!-- This command uses subagent delegation when enabled -->
{{IF use_claude_code_subagents}}
...
{{ENDIF use_claude_code_subagents}}
```

---

## Common Patterns

### Pattern 1: Dual-Mode Command

Support both with and without subagents:

```markdown
# Feature Implementation

{{IF use_claude_code_subagents}}
Use the **implementer** subagent with these instructions:
- Read spec from agent-os/specs/current/
- Implement all tasks
{{ENDIF use_claude_code_subagents}}

{{UNLESS use_claude_code_subagents}}
Follow these steps:

{{PHASE 1: @agent-os/commands/implement/1-prepare.md}}
{{PHASE 2: @agent-os/commands/implement/2-execute.md}}
{{PHASE 3: @agent-os/commands/implement/3-verify.md}}
{{ENDUNLESS use_claude_code_subagents}}
```

### Pattern 2: Reusable Workflow Components

Create small, focused workflows:

```markdown
<!-- workflows/implementation/verify-prerequisites.md -->
## Verify Prerequisites

Before implementing:
- [ ] Spec exists and is complete
- [ ] Tests are configured
- [ ] Dependencies are installed
```

Then include it in multiple places:

```markdown
<!-- In various command files -->
{{workflows/implementation/verify-prerequisites}}
```

### Pattern 3: Scoped Standards

Include only relevant standards:

```markdown
# Backend Implementation

{{UNLESS standards_as_claude_code_skills}}
Backend coding standards:
{{standards/backend/*}}
{{standards/global/error-handling.md}}
{{ENDUNLESS standards_as_claude_code_skills}}
```

### Pattern 4: Progressive Disclosure

```markdown
## Quick Start

{{workflows/quickstart/minimal-steps}}

## Advanced Usage

{{IF use_claude_code_subagents}}
{{workflows/advanced/subagent-orchestration}}
{{ENDIF use_claude_code_subagents}}

## Full Reference

{{workflows/reference/all-options}}
```

---

## Troubleshooting

### Problem: Workflow Not Found

**Error message:**
```
⚠️ This workflow file was not found in your Agent OS base installation at ~/agent-os/profiles/default/workflows/path/to/workflow.md
```

**Solutions:**
1. Check the workflow path is correct
2. Verify the workflow file exists in the profile
3. Ensure `.md` extension is not included in the reference
4. Check profile inheritance if using a custom profile

### Problem: Unclosed Conditional Block

**Warning:**
```
Unclosed conditional block detected (nesting level: 1)
```

**Solutions:**
1. Add missing `{{ENDIF flag}}` or `{{ENDUNLESS flag}}`
2. Ensure opening and closing tags use the same flag name
3. Check for typos in flag names
4. Verify proper nesting (inner blocks close before outer blocks)

### Problem: Standards Not Showing Up

**Possible causes:**
1. `standards_as_claude_code_skills` is `true` (standards injected as Skills instead)
2. Missing `{{UNLESS standards_as_claude_code_skills}}` wrapper
3. Standards pattern doesn't match any files
4. Standards files don't exist in the profile

**Solution:**
```markdown
{{UNLESS standards_as_claude_code_skills}}
Standards to follow:
{{standards/*}}
{{ENDUNLESS standards_as_claude_code_skills}}
```

### Problem: PHASE Tags Not Embedding

**Possible causes:**
1. Compilation mode is not "embed" (multi-agent mode)
2. PHASE tag syntax is incorrect
3. Referenced file doesn't exist
4. Path doesn't start with `@agent-os/`

**Verification:**
- Check `use_claude_code_subagents` setting (should be `false` for embedding)
- Verify file path: `@agent-os/commands/...` maps to `profiles/default/commands/...`
- Ensure file has `.md` extension in the PHASE tag

### Problem: Circular Workflow Reference

**Error message:**
```
Circular workflow reference detected: implementation/main
```

**Solution:**
Restructure workflows to avoid cycles:

❌ **Bad:**
```
main.md includes step1.md
step1.md includes step2.md
step2.md includes main.md  ← Circular!
```

✅ **Good:**
```
main.md includes common-setup.md
main.md includes step1.md
main.md includes step2.md
```

---

## Validation Tools

### Manual Validation

Check template syntax in a file:

```bash
# Look for unclosed tags
grep -n "{{IF\|{{UNLESS\|{{ENDIF\|{{ENDUNLESS}}" file.md

# Check workflow references exist
grep -o "{{workflows/[^}]*}}" file.md | while read ref; do
  path=$(echo "$ref" | sed 's/{{workflows\///' | sed 's/}}//')
  [ -f "profiles/default/workflows/${path}.md" ] || echo "Missing: $path"
done
```

### Future: Automated Validator

A template validator tool is planned:

```bash
./scripts/validate-template.sh profiles/default/commands/write-spec/write-spec.md
✓ Syntax valid
✓ All workflow refs resolve
✓ Conditional blocks properly closed
⚠ Warning: standards/deprecated/* pattern matches 0 files
```

---

## Version History

- **v2.1.0**: Added `standards_as_claude_code_skills` flag support
- **v2.0.0**: Retired role replacement system, added PHASE tags
- **v1.x**: Initial template system with workflows, standards, conditionals

---

## Related Documentation

- [Profile System](../../../README.md#profiles)
- [Configuration Options](../../../config.yml)
- [Workflow Directory](../workflows/)
- [Standards Directory](../standards/)

---

**Questions or issues?** See the main [Agent OS documentation](https://buildermethods.com/agent-os) or open an issue on GitHub.
