<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-02-05 | Updated: 2026-02-05 -->

# cli

## Purpose

CLI infrastructure for the boost command. Handles argument parsing, command routing, and output formatting.

## Key Files

| File | Description |
|------|-------------|
| `cli.dart` | Main CLI coordinator |
| `command_runner.dart` | Command routing |

## For AI Agents

### Working In This Directory

- Uses `args` package for parsing
- Delegates to `lib/commands/` for handlers
- Supports subcommands (install, skill:list, skill:show, info)

<!-- MANUAL: -->
