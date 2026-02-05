<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-02-05 | Updated: 2026-02-05 -->

# skills

## Purpose

Skills system framework for extensible workflows. Skills combine multiple tools into reusable patterns. Infrastructure is in place; pre-built skills coming in future releases.

## Key Files

| File | Description |
|------|-------------|
| `skills.dart` | Skills registry and exports |
| `skill.dart` | Skill base class/interface |
| `skill_loader.dart` | Load skills from file system |

## For AI Agents

### Working In This Directory

- Skills framework is implemented
- Pre-built skills not yet included (v0.1.0)
- Future: endpoint_creator, test_generator, etc.

### Skill Structure

Skills are workflows that:
1. Combine multiple tools
2. Can be invoked by name
3. Return structured results

## Dependencies

### Internal

- `lib/tools/` - Skills use tools

<!-- MANUAL: -->
