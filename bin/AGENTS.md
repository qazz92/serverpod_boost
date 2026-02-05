<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-02-05 | Updated: 2026-02-05 -->

# bin

## Purpose

Executable entry points for ServerPod Boost CLI. Contains the main `boost` command that users run to install, configure, and interact with Boost.

## Key Files

| File | Description |
|------|-------------|
| `boost.dart` | Main CLI entry point - handles all boost commands |
| `boost_command.dart` | Boost-specific command implementations |

## For AI Agents

### Working In This Directory

- `boost.dart` is the executable declared in `pubspec.yaml`
- Commands are delegated to `lib/commands/` handlers
- Uses `args` package for argument parsing

### Executable Commands

- `boost install` - Install Boost in a ServerPod project
- `boost skill:list` - List available skills
- `boost skill:show <name>` - Show skill details
- `boost info` - Show project information
- `boost endpoints` - List endpoints
- `boost models` - List models

## Dependencies

### Internal

- `lib/cli/` - CLI infrastructure
- `lib/commands/` - Command handlers

<!-- MANUAL: -->
