<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-02-05 | Updated: 2026-02-05 -->

# commands

## Purpose

Command handlers for all boost CLI commands. Each file implements a specific command (install, skill:list, skill:show, info, endpoints, models).

## Key Files

| File | Description |
|------|-------------|
| `install_command.dart` | boost install - Setup Boost in project |
| `skill_command.dart` | boost skill:list, boost skill:show |
| `info_command.dart` | boost info - Show project info |
| `endpoints_command.dart` | boost endpoints - List endpoints |
| `models_command.dart` | boost models - List models |

## For AI Agents

### Working In This Directory

- Each command file = one handler
- Commands use tools from `lib/tools/`
- Output formatted for terminal display

<!-- MANUAL: -->
