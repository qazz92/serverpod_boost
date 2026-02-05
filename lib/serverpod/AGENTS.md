<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-02-05 | Updated: 2026-02-05 -->

# serverpod

## Purpose

ServerPod project detection, validation, and metadata extraction. Identifies monorepo structure (server, client, flutter) and provides project access.

## Key Files

| File | Description |
|------|-------------|
| `serverpod_locator.dart` | Central service locator for project access |
| `project_detector.dart` | Detects ServerPod v3 monorepo structure |
| `endpoint_parser.dart` | Parses endpoint method signatures |
| `model_parser.dart` | Parses .spy.yaml model definitions |
| `yaml_parser.dart` | YAML file parsing utilities |

## For AI Agents

### Working In This Directory

- Project detection is critical - all tools depend on this
- Supports ServerPod v3 monorepo only
- Structure: server (source), client (generated), flutter (app)

### Project Structure Detected

```
project_root/
├── project_server/    # Source of truth
├── project_client/    # Generated
└── project_flutter/   # Flutter app
```

## Dependencies

### External

- `serverpod: ^3.2.3` - Framework types
- `yaml: ^3.1.2` - YAML parsing

<!-- MANUAL: -->
