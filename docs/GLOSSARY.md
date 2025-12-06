# Agent OS Glossary

This glossary defines the terms and concepts used throughout Agent OS. Understanding these terms will help you use the framework more effectively.

## Core Concepts

### Agent OS
A **spec-driven agentic development system** that provides structured workflows to help AI coding agents produce high-quality code. Think of it as a project management system specifically designed for AI development assistants.

### Specification (Spec)
A detailed document that describes what to build, why it's needed, and how it should work. Specifications include requirements, constraints, and acceptance criteria. In Agent OS, specs guide AI agents to build features correctly on the first try.

### Workflow
A predefined sequence of steps that an AI agent follows to complete a task. Workflows ensure consistency and quality by breaking complex processes into manageable steps.

### Profile
A collection of settings, commands, agents, and standards that define how Agent OS behaves in a project. Profiles can be customized for different project types, teams, or preferences.

### Preset
A pre-configured profile optimized for specific tools or workflows. Presets simplify setup by providing sensible defaults for common use cases (e.g., `claude-code-full`, `cursor`).

## Agent Roles

### Spec Shaper
An agent that gathers requirements through targeted questions and analysis. The Spec Shaper helps clarify what needs to be built and why it matters.

### Spec Writer
An agent that creates detailed technical specifications based on gathered requirements. The Spec Writer translates business needs into technical implementation details.

### Product Planner
An agent that creates product documentation, including mission statements, roadmaps, and technical stack decisions. The Product Planner focuses on the big picture and strategic direction.

### Implementer
An agent that builds features according to specifications and task lists. The Implementer follows the detailed instructions to write actual code.

### Implementation Verifier
An agent that tests and validates implemented features. The Verifier ensures the implementation meets the specification requirements and quality standards.

### Task List Creator
An agent that breaks down specifications into actionable development tasks. The Task Creator organizes work into logical, implementable steps.

## Configuration

### config.yml
The main configuration file for Agent OS. It controls which preset to use, profile settings, and other project-specific configurations.

### Standards
Coding standards, conventions, and best practices that agents should follow. Standards can be provided inline or as Claude Code Skills.

### Skills (Claude Code)
A feature in Claude Code that allows reusable knowledge and behaviors to be injected into conversations. Agent OS can provide standards as Skills for easy access.

### Subagents
In Claude Code, subagents are specialized agents that can be delegated specific tasks. This allows complex workflows to be broken down and handled by agents with appropriate expertise.

## Commands and Operations

### Slash Commands
Commands that start with `/` (e.g., `/shape-spec`, `/implement-tasks`) that trigger specific Agent OS workflows. In Claude Code, these are typed directly. In other tools, they correspond to markdown files.

### Dry Run Mode
A preview mode that shows what changes will be made without actually applying them. Useful for reviewing updates before installation.

### Caching
A performance optimization that stores compiled templates and configurations. Cache allows reinstallation in seconds instead of minutes.

### Rollback
Automatic restoration of the previous state if an installation fails or is interrupted. Rollback ensures your project isn't left in a broken state.

## File Structure

### .claude/
Directory where Claude Code stores commands, agents, and Skills. This is where Agent OS installs Claude Code-compatible files.

### agent-os/
Directory where Agent OS stores commands for non-Claude Code tools. This allows compatibility with Cursor, Windsurf, and other AI coding assistants.

### profiles/
Directory containing profile definitions, including workflows, agents, standards, and commands. Each profile is a complete configuration package.

### commands/
Directory containing command definitions (markdown files) that define Agent OS workflows. Commands are the entry points for different operations.

## Workflow Phases

### Plan Product
The initial phase where product vision, mission, roadmap, and technical stack are defined. This phase sets the strategic direction for the project.

### Shape Spec
The requirements gathering phase where feature details are collected through questions and analysis. This phase ensures all stakeholders' needs are understood.

### Write Spec
The technical specification phase where requirements are translated into detailed implementation plans. This phase creates the blueprint for development.

### Create Tasks
The task breakdown phase where specifications are converted into actionable development steps. This phase organizes the work for implementation.

### Implement Tasks
The development phase where features are built according to specifications and tasks. This phase involves actual coding.

### Orchestrate Tasks
The coordination phase where multiple agents work together on complex features. This phase manages collaboration between specialized agents.

## Technical Terms

### Template Syntax
The syntax used in Agent OS configurations (e.g., `{{variable}}`, `{{PHASE: @path/to/file.md}}`) for dynamic content injection and workflow sequencing.

### Staging Directory
A temporary directory used during installation to prepare files before moving them to their final locations. This enables atomic operations and rollback capability.

### Content-based Caching
A caching mechanism that uses file content hashes to determine when cache entries are invalid. This ensures efficient updates while maintaining consistency.

### YAML
A human-readable data serialization format used for Agent OS configuration files. YAML is used for `config.yml` and other configuration files.

### Markdown
The format used for Agent OS commands, workflows, and documentation. Markdown files define workflows, agent behaviors, and command instructions.

## Common Patterns

### Progressive Disclosure
A documentation approach that starts with simple concepts and gradually introduces complexity. This helps new users get started quickly without being overwhelmed.

### Single-Agent Mode
A workflow execution mode where all steps are handled by one agent. This is simpler and faster for straightforward tasks.

### Multi-Agent Mode
A workflow execution mode where tasks are delegated to specialized agents. This is more efficient for complex projects that require different expertise.

### Atomic Operations
Operations that either complete fully or not at all, with no intermediate states. Agent OS uses atomic operations to ensure installations don't leave projects in a broken state.

## Quality and Testing

### Validation
The process of checking that configurations, profiles, and commands are correct before use. Agent OS includes pre-flight validation to catch issues early.

### Verification
The process of testing that implemented features meet specifications and quality standards. Verification ensures the built feature works as expected.

### Contextual Errors
Error messages that include specific information about what went wrong and how to fix it. Agent OS provides helpful error messages to guide users to solutions.

---

Still have questions? Check the [FAQ](FAQ.md) or open an issue on GitHub.