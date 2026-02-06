# ServerPod Boost CLI 레퍼런스

ServerPod Boost CLI는 ServerPod 개발을 위한 AI 가속 도구입니다. 이 문서는 모든 CLI 명령어의 상세 레퍼런스를 제공합니다.

## 목차

- [개요](#개요)
- [설치 명령어](#설치-명령어)
- [스킬 관리 명령어](#스킬-관리-명령어)
- [설정 명령어](#설정-명령어)
- [MCP 서버 모드](#mcp-서버-모드)
- [공통 옵션](#공통-옵션)
- [종료 코드](#종료-코드)

---

## 개요

ServerPod Boost는 두 가지 모드로 실행됩니다:

1. **MCP 서버 모드 (기본값)**: AI 에디터와 통합하기 위한 Model Context Protocol 서버
2. **CLI 명령 모드**: 스킬 관리, 파일 생성, 설정 등을 위한 대화형 명령어

### 기본 사용법

```bash
# MCP 서버로 실행 (기본)
dart run serverpod_boost:boost

# CLI 명령어 실행
dart run serverpod_boost:boost <command> [options]

# 또는 설치된 별칭 사용
boost <command> [options]
```

### 프로젝트 요구사항

ServerPod Boost는 유효한 ServerPod 프로젝트 내에서 실행해야 합니다:

```
monorepo_root/
├── project_server/   (필수)
├── project_client/   (선택)
└── project_flutter/  (선택)
```

---

## 설치 명령어

### `boost install`

ServerPod Boost의 대화형 설치를 실행합니다. 모든 기능(가이드라인, 스킬, MCP 설정)을 한 번에 설치합니다.

#### 사용법

```bash
boost install [options]
```

#### 옵션

| 옵션 | 설명 |
|------|------|
| `--non-interactive`, `-y` | 대화형 프롬프트 건너뛰기 |
| `--overwrite` | 기존 파일 덮어쓰기 |

#### 예시

```bash
# 대화형 설치 (모든 기능)
boost install

# 비대화형 설치
boost install --non-interactive

# 기존 파일 덮어쓰기
boost install --overwrite
```

#### 예상 출력

```
╔═══════════════════════════════════════╗
║   ServerPod Boost Installation       ║
║               v0.1.0                 ║
╚═══════════════════════════════════════╝

Project: /path/to/project
Server: /path/to/project/server

─────────────────────────────────────
  Installing All Features
─────────────────────────────────────

Installing:
  ✓ Guidelines (AGENTS.md, CLAUDE.md)
  ✓ Skills (8 built-in skills)
  ✓ MCP Configuration

Proceed with installation? (y/n): y

═══════════════════════════════════════
Installing Guidelines
═══════════════════════════════════════

Generating AGENTS.md and CLAUDE.md...
  Using 8 skill(s)
Writing AGENTS.md...
  ✓ AGENTS.md - Created
Writing CLAUDE.md...
  ✓ CLAUDE.md - Created

═══════════════════════════════════════
Installing Skills
═══════════════════════════════════════

Copying 8 built-in skills...
  ✓ core
  ✓ endpoints
  ✓ models
  ✓ migrations
  ✓ testing
  ✓ authentication
  ✓ webhooks
  ✓ redis

═══════════════════════════════════════
Configuring MCP
═══════════════════════════════════════

Detected AI editors:
  ✓ Claude Desktop
  ✓ Cursor

═══════════════════════════════════════
All installations completed successfully! 🚀

https://github.com/serverpod/serverpod_boost
```

---

## 스킬 관리 명령어

### `boost skill:list`

사용 가능한 모든 스킬을 나열합니다.

#### 사용법

```bash
boost skill:list [--skills-path=<path>]
```

#### 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--skills-path=<path>` | 스킬 디렉토리 경로 | `.ai/skills` |

#### 예시

```bash
# 기본 스킬 경로에서 스킬 목록 표시
boost skill:list

# 사용자 정의 스킬 경로 지정
boost skill:list --skills-path=/custom/path/to/skills
```

#### 예상 출력

```
Available Skills (5):

  create-endpoint
    Create a new endpoint with method signatures
    Tags: endpoint, crud, api

  create-model
    Generate a ServerPod model with fields and types
    Tags: model, database, schema

  database-migration
    Create and manage database migrations
    Depends on: create-model
    Tags: database, migration

  endpoint-testing
    Generate unit tests for endpoints
    Tags: testing, unit-test

  code-optimization
    Analyze and optimize ServerPod code
    Requires ServerPod: >=3.2.0
    Tags: optimization, performance
```

---

### `boost skill:show`

특정 스킬의 상세 정보를 표시합니다.

#### 사용법

```bash
boost skill:show <skill-name> [--skills-path=<path>]
```

#### 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--skills-path=<path>` | 스킬 디렉토리 경로 | `.ai/skills` |

#### 인자

| 인자 | 설명 | 필수 |
|------|------|------|
| `skill-name` | 표시할 스킬 이름 | 예 |

#### 예시

```bash
# 스킬 상세 정보 표시
boost skill:show create-endpoint

# 사용자 정의 스킬 경로에서 스킬 표시
boost skill:show create-endpoint --skills-path=/custom/path
```

#### 예상 출력

```
Skill: create-endpoint
=====================

Description:
  Create a new endpoint with method signatures, parameters, and return types

Metadata:
  Version: 1.0.0
  Min ServerPod Version: 3.2.0
  Dependencies:
    - model-inspector
  Tags: endpoint, crud, api
  Source: serverpod

Template:
---
# Create Endpoint: {{endpointName}}

You are tasked with creating a new endpoint in ServerPod.

## Endpoint Information

- **Name**: {{endpointName}}
- **Description**: {{description}}
...
---
```

---

### `boost skill:render`

스킬 템플릿을 현재 프로젝트 컨텍스트로 렌더링합니다.

#### 사용법

```bash
boost skill:render <skill-name> [output-file] [--skills-path=<path>]
```

#### 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--skills-path=<path>` | 스킬 디렉토리 경로 | `.ai/skills` |

#### 인자

| 인자 | 설명 | 필수 |
|------|------|------|
| `skill-name` | 렌더링할 스킬 이름 | 예 |
| `output-file` | 출력 파일 경로 (생략 시 stdout) | 아니오 |

#### 예시

```bash
# 표준 출력으로 렌더링
boost skill:render create-endpoint

# 파일로 저장
boost skill:render create-endpoint output.md

# 사용자 정의 경로 지정
boost skill:render create-model /path/to/model-guide.md
```

#### 예상 출력

```bash
# stdout 출력
# Create Endpoint: UserService

You are tasked with creating a new endpoint in ServerPod.

## Endpoint Information

- **Name**: UserService
- **Project**: my_project
- **ServerPod Version**: 3.2.3

## Implementation Steps

...

# 파일 저장 시
Rendered skill written to: output.md
```

---

### `boost skill:add`

GitHub 저장소에서 스킬을 추가합니다.

#### 사용법

```bash
boost skill:add <repo> [skill-name] [--skills-path=<path>] [--force]
```

#### 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--skills-path=<path>` | 스킬 디렉토리 경로 | `.ai/skills` |
| `--force` | 확인 없이 강제 설치 | false |

#### 인자

| 인자 | 설명 | 필수 |
|------|------|------|
| `repo` | GitHub 저장소 (owner/repo 형식) | 예 |
| `skill-name` | 추가할 특정 스킬 이름 (생략 시 목록 표시) | 아니오 |

#### 예시

```bash
# 저장소의 스킬 목록 표시
boost skill:add username/serverpod-skills

# 특정 스킬 추가
boost skill:add username/serverpod-skills create-endpoint

# 강제로 스킬 추가 (확인 건너뛰기)
boost skill:add username/repo skill-name --force
```

#### 예상 출력

```bash
# 목록 조회
Fetching skills from username/serverpod-skills...

Available Skills (3):
  • create-endpoint
  • create-model
  • database-migration

To add a skill, run:
  boost skill:add username/serverpod-skills <skill-name>

# 스킬 추가
Adding create-endpoint from username/serverpod-skills...
✓ Skill installed successfully

Location: .ai/skills/remote/username/serverpod-skills/create-endpoint

You can now use this skill:
  boost skill:show create-endpoint
  boost skill:render create-endpoint
  boost install --with-skill create-endpoint

Tags: endpoint, crud, api
```

---

### `boost skill:remove`

로컬 스킬 디렉토리에서 스킬을 제거합니다.

#### 사용법

```bash
boost skill:remove <skill-name> [--skills-path=<path>] [--force]
```

#### 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--skills-path=<path>` | 스킬 디렉토리 경로 | `.ai/skills` |
| `--force` | 확인 없이 강제 삭제 | false |

#### 인자

| 인자 | 설명 | 필수 |
|------|------|------|
| `skill-name` | 제거할 스킬 이름 | 예 |

#### 예시

```bash
# 제거 전 확인 표시
boost skill:remove my-skill

# 강제 제거 (확인 없음)
boost skill:remove my-skill --force
```

#### 예상 출력

```bash
# 확인 모드
Removing skill: my-skill
Location: .ai/skills/remote/username/repo/my-skill

This will permanently delete the skill directory.
Use --force to skip this confirmation.

To confirm, run with --force flag:
  boost skill:remove my-skill --force

# 강제 제거
✓ Skill removed: my-skill

Location: .ai/skills/remote/username/repo/my-skill
```

---

## MCP 서버 모드

ServerPod Boost는 기본적으로 MCP (Model Context Protocol) 서버로 실행됩니다. AI 에디터와 직접 통합하여 다음과 같은 도구를 제공합니다:

### 사용 가능한 MCP 도구

| 도구 | 설명 |
|------|------|
| `list_endpoints` | 모든 엔드포인트 나열 |
| `endpoint_methods` | 특정 엔드포인트의 메서드 나열 |
| `list_models` | 모든 모델 나열 |
| `model_inspector` | 모델 상세 정보 보기 |
| `call_endpoint` | 엔드포인트 메서드 호출 |
| `database_schema` | 데이터베이스 스키마 보기 |
| `migration_scanner` | 마이그레이션 파일 스캔 |
| `read_file` | 파일 읽기 |
| `find_files` | 파일 검색 |
| `search_code` | 코드 검색 |
| `project_structure` | 프로젝트 구조 보기 |
| `application_info` | 애플리케이션 정보 보기 |
| `service_config` | 서비스 설정 보기 |

### 사용법

```bash
# 기본 모드로 MCP 서버 실행
dart run serverpod_boost:boost

# 상세 로깅 활성화
dart run serverpod_boost:boost --verbose

--path=<project_path>    Path to ServerPod project root
                          (useful when .mcp.json is in project root)

# 프로젝트 루트를 지정하여 실행 (프로젝트 루트에서 실행하는 경우 유용)
dart run serverpod_boost:boost --path=/path/to/project

# 환경 변수로 프로젝트 루트 지정
SERVERPOD_BOOST_PROJECT_ROOT=/path/to/project dart run serverpod_boost:boost
```

#### 시작 시 출력 예시

```
[INFO] ServerPod Boost v0.1.0
[INFO] Project: /path/to/project
[INFO] Server: /path/to/project/server
[INFO] Tools: 13
[INFO]
[INFO] MCP server ready, listening for requests...
```

---

## 공통 옵션

### 전역 옵션

모든 명령어에서 사용 가능한 옵션:

| 옵션 | 설명 |
|------|------|
| `-h`, `--help` | 도움말 메시지 표시 |
| `-v`, `--verbose` | 상세 로깅 활성화 |
| `--skills-path=<path>` | 스킬 디렉토리 경로 지정 |

### 환경 변수

| 변수 | 설명 |
|------|------|
| `SERVERPOD_BOOST_VERBOSE` | 상세 로깅 활성화 (true/false) |
| `SERVERPOD_BOOST_PROJECT_ROOT` | 프로젝트 루트 경로 강제 지정 |
| `GITHUB_TOKEN` | GitHub API 인증을 위한 토큰 |

---

## 종료 코드

| 코드 | 설명 |
|------|------|
| `0` | 성공 |
| `1` | 일반 오류 |
| `2` | 사용자 입력 오류 (잘못된 인자 등) |

### 일반 오류 시나리오

#### 유효하지 않은 ServerPod 프로젝트

```bash
Error: Not a valid ServerPod project!
ServerPod Boost must be run from within a ServerPod project.

Project structure should be:
  monorepo_root/
  ├── project_server/   (required)
  ├── project_client/   (optional)
  └── project_flutter/  (optional)

Set SERVERPOD_BOOST_PROJECT_ROOT environment variable to override detection.
```

#### 스킬을 찾을 수 없음

```bash
Error: Skill "unknown-skill" not found

Run "boost skill:list" to see available skills.
```

#### 잘못된 저장소 형식

```bash
✗ Invalid repository format: invalid-repo
Expected format: owner/repo
```

---

## 추가 리소스

- [GitHub 저장소](https://github.com/serverpod/serverpod_boost)
- [사용자 가이드](./USER_GUIDE.md)
- [ServerPod 문서](https://serverpod.dev)

---

## 도움말

모든 명령어에 대한 도움말을 보려면:

```bash
boost --help
```

특정 명령어에 대한 도움말:

```bash
boost <command> --help
```
