<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-02-05 | Updated: 2026-02-05 -->

# install

## Purpose

File provisioning system for boost install command. Copies guidelines, skills, MCP config, and generates AGENTS.md/CLAUDE.md documentation.

## Key Files

| File | Description |
|------|-------------|
| `installer.dart` | Main installation coordinator |
| `file_provisioner.dart` | Copy files to .ai/boost/ |
| `config_generator.dart` | Generate MCP config for Claude Desktop |

## For AI Agents

### Working In This Directory

- Creates `.ai/boost/` directory structure
- Generates documentation files
- Configures Claude Desktop automatically

### Installation Creates

```
project_root/
├── .ai/
│   ├── boost/
│   │   ├── bin/
│   │   ├── skills/
│   │   └── config/
│   ├── AGENTS.md
│   └── CLAUDE.md
```

<!-- MANUAL: -->
