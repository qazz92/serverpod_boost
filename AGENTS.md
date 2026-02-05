# ServerPod Boost - AI 가속화 패키지

> **ServerPod v3 전용** | v2는 지원하지 않습니다

## 프로젝트 개요

**ServerPod Boost**는 ServerPod v3 애플리케이션을 위한 AI 가속화 패키지입니다. Laravel Boost에서 영감을 받아, LLM(Claude, GPT 등)이 ServerPod 프로젝트에서 고품질의 코드를 생성할 수 있도록 필수적인 컨텍스트와 도구를 제공합니다.

### 버전 지원

| 버전 | 지원 | 상태 |
|------|------|------|
| **ServerPod v3.x** | ✅ 예 | 완전 지원 |
| ServerPod v2.x | ❌ 아니오 | 지원 안 함 - v3로 마이그레이션 권장

### 핵심 목표

AI 어시스턴트가 다음을 수행할 수 있도록 돕습니다:
- ServerPod 프로젝트 구조와 컨벤션 이해
- 생성된 코드를 프로젝트에 통합
- MCP(Model Context Protocol) 도구로 프로젝트 상태에 접근
- 도메인별 스킬 활용
- 수동 가이드 없이 모범 사례 적용

### 관련 프로젝트

| 프로젝트 | 경로 | 목적 |
|---------|------|---------|
| **Laravel Boost** | `/Users/musinsa/always_summer/boost` | 원본 inspiration |
| **ServerPod** | `/Users/musinsa/always_summer/serverpod` | 확장할 프레임워크 |
| **ServerPod Boost** | `/Users/musinsa/always_summer/serverpod_boost` | 이 프로젝트 |

---

## Laravel Boost 분석

Laravel Boost는 `.ai/` 디렉토리 구조로 가이드라인과 스킬을 조직화합니다:

```
boost/.ai/
├── foundation.blade.php           # 기본 Laravel 컨텍스트
├── enforce-tests.blade.php        # 조건부 테스트 가이드라인
├── php/
│   └── core.blade.php            # PHP 언어 컨벤션
├── livewire/
│   ├── core.blade.php            # Livewire 기초
│   ├── 2/skill/livewire-development/SKILL.blade.php
│   ├── 3/skill/livewire-development/SKILL.blade.php
│   └── 4/skill/livewire-development/SKILL.blade.php
├── pest/
│   ├── core.blade.php            # Pest 테스트 기초
│   └── 3/skill/pest-testing/SKILL.blade.php
└── mcp/
    ├── core.blade.php            # MCP 개발 패턴
    └── skill/mcp-development/SKILL.blade.php
```

### Laravel Boost의 핵심 패턴

1. **Foundation Layer** - 기본 컨텍스트 제공
2. **Package Guidelines** - 에코시스템 패키지별 가이드라인 (`core.blade.php`)
3. **Skills System** - 버전별 스킬 (`3/skill/.../SKILL.blade.php`)
4. **GuidelineComposer** - 컨텍스트 인지적 가이드라인 조립
5. **MCP Tools** - 21개의 Laravel 통합 도구

---

## ServerPod Boost 구조

Laravel Boost의 패턴을 ServerPod/Dart 생태계에 맞게 조정합니다.

### 프로젝트 구조

```
serverpod_boost/
├── .ai/                              # 가이드라인과 스킬
│   ├── foundation.dart               # 기본 ServerPod 컨텍스트
│   ├── dart/
│   │   └── core.dart                # Dart 언어 컨벤션
│   ├── serverpod/
│   │   ├── core.dart                # ServerPod 기초
│   │   └── skill/serverpod-development/SKILL.dart
│   ├── serverpod_auth/
│   │   ├── core.dart
│   │   └── skill/auth-development/SKILL.dart
│   ├── serverpod_chat/
│   │   └── skill/chat-development/SKILL.dart
│   └── mcp/
│       ├── core.dart
│       └── skill/mcp-development/SKILL.dart
├── lib/
│   ├── install/
│   │   ├── guideline_composer.dart   # 가이드라인 조립기
│   │   ├── skill_composer.dart       # 스킬 발견 및 로드
│   │   ├── guideline_writer.dart     # 가이드라인 파일 작성
│   │   └── skill_writer.dart         # 스킬 파일 작성
│   ├── mcp/
│   │   ├── tools/
│   │   │   ├── list_endpoints.dart   # 모든 엔드포인트 나열
│   │   │   ├── list_models.dart      # 모든 모델 나열
│   │   │   ├── get_database_schema.dart
│   │   │   ├── get_config.dart
│   │   │   ├── run_migrations.dart
│   │   │   ├── read_logs.dart
│   │   │   ├── search_docs.dart
│   │   │   └── ...
│   │   ├── tool_registry.dart        # 도구 자동 발견
│   │   └── mcp_server.dart           # MCP 서버
│   ├── skills/
│   │   ├── skill_loader.dart         # 스킬 로더
│   │   └── skill_base.dart           # 스킬 기본 클래스
│   ├── guidelines/
│   │   ├── composers/
│   │   │   ├── endpoint_guideline.dart
│   │   │   ├── model_guideline.dart
│   │   │   ├── migration_guideline.dart
│   │   │   └── flutter_guideline.dart
│   │   └── guideline_composer.dart
│   ├── config/
│   │   ├── boost_config.dart         # boost.yaml 로더
│   │   └── default_config.yaml       # 기본 설정
│   ├── codegen/
│   │   ├── endpoint_generator.dart
│   │   ├── model_generator.dart
│   │   └── migration_generator.dart
│   └── utils/
│       ├── pubspec_parser.dart       # pubspec.yaml 파싱
│       └── file_scanner.dart         # 프로젝트 파일 스캔
├── config/
│   └── boost.yaml                    # ServerPod Boost 설정
├── bin/
│   └── command.dart                  # CLI 진입점
├── test/
│   ├── mcp/
│   ├── skills/
│   └── guidelines/
└── example/
    └── demo_serverpod/               # 예제 ServerPod 프로젝트
```

---

## 핵심 컴포넌트

### 1. MCP 서버

AI 어시스턴트에게 실시간 프로젝트 상태를 제공하는 도구들:

| 도구 | 설명 | 읽기 전용 |
|------|------|-----------|
| `list_endpoints` | 모든 엔드포인트와 메서드 나열 | ✓ |
| `list_models` | 모든 모델과 필드 타입 나열 | ✓ |
| `get_database_schema` | 현재 데이터베이스 스키마 | ✓ |
| `run_migrations` | 마이그레이션 적용 | ✗ |
| `read_logs` | ServerPod 로그 읽기 | ✓ |
| `get_config` | config/ YAML 값 접근 | ✓ |
| `search_docs` | ServerPod 문서 검색 | ✓ |
| `validate_endpoint` | 엔드포인트 유효성 검사 | ✓ |
| `generate_endpoint` | 엔드포인트 스터브 생성 | ✗ |
| `generate_model` | 모델 스터브 생성 | ✗ |
| `list_migrations` | 마이그레이션 기록 | ✓ |

**구현 예시:**
```dart
// lib/mcp/tools/list_endpoints.dart
class ListEndpoints extends Tool {
  @override
  String get description => 'List all ServerPod endpoints with methods and parameters';

  @override
  Map<String, Type> get schema => {
    'module': String,
    'filter': String,
  };

  @override
  Future<Response> handle(Request request) async {
    final endpoints = await _discoverEndpoints();
    return Response.json(endpoints);
  }
}
```

### 2. 스킬 시스템

도메인별 지식을 컨텍스트에 따라 활성화:

**코어 스킬:**
- `serverpod-development` - 엔드포인트, 모델, 서비스
- `flutter-integration` - 클라이언트 코드와 스트리밍
- `database-design` - 마이그레이션과 ORM 패턴
- `auth-implementation` - ServerPod Auth 인증
- `testing-best-practices` - 통합 테스트

**스킬 포맷 (.ai/domain/version/skill/skill-name/SKILL.dart):**
```dart
/// # ServerPod Development Skill
///
/// ## Metadata
/// - Name: serverpod-development
/// - Version: 2.0.0
/// - Description: Develops ServerPod endpoints, models, and services
///
/// ## When to Apply
/// Activate when:
/// - Creating endpoints in `lib/src/endpoints/`
/// - Defining models with serialization
/// - Writing database queries
/// - Implementing authentication
///
/// ## Endpoint Creation
/// ```dart
/// class MyEndpoint extends Endpoint {
///   Future<String> hello(Session session, String name) async {
///     return 'Hello, $name';
///   }
/// }
/// ```
///
/// ## Database Queries
/// ```dart
/// final users = await User.db.find(
///   session,
///   where: (t) => t.isActive.equals(true),
/// );
/// ```
```

### 3. 가이드라인 시스템

컨텍스트 인지적 조합 가능 문서:

**GuidelineComposer 파이프라인:**
```dart
class GuidelineComposer {
  Future<String> compose() async {
    final guidelines = await guidelines();

    final composed = guidelines.values
        .where((g) => g.content.isNotEmpty)
        .map((g) => '\n=== ${g.name} ===\n\n${g.content}')
        .join('\n\n');

    return MarkdownFormatter.format(composed);
  }

  Future<Map<String, Guideline>> guidelines() async {
    return {
      // 코어 가이드라인
      ...await getCoreGuidelines(),
      // 조건부 가이드라인
      ...await getConditionalGuidelines(),
      // 패키지별 (pubspec.yaml에서)
      ...await getPackageGuidelines(),
      // 사용자 정의 (.ai/guidelines/에서)
      ...await getUserGuidelines(),
    };
  }
}
```

**컴포저들:**
- `EndpointGuideline` - 엔드포인트 생성 시 활성화
- `ModelGuideline` - 모델 정의 시 활성화
- `MigrationGuideline` - 마이그레이션 작성 시 활성화
- `FlutterGuideline` - Flutter 코드 작성 시 활성화
- `StreamingGuideline` - 실시간 통신 구현 시 활성화
- `AuthGuideline` - 인증 구현 시 활성화
- `TestingGuideline` - 테스트 작성 시 활성화
- `SecurityGuideline` - 보안 검토 시 활성화

### 4. CLI

```bash
# 가이드라인 설치
dart run serverpod_boost install

# 스킬 관리
dart run serverpod_boost skills:list
dart run serverpod_boost skills:update

# MCP 서버
dart run serverpod_boost mcp:start

# 가이드라인 보기
dart run serverpod_boost guidelines:show
```

---

## 설정

### boost.yaml

```yaml
# config/boost.yaml
boost:
  # 가이드라인 설정
  guidelines:
    output_format: markdown
    include_timestamps: true
    max_tokens: 8000

  # 스킬 설정
  skills:
    auto_discover: true
    remote_sources:
      - url: https://github.com/serverpod-community/skills
        enabled: true

  # MCP 설정
  mcp:
    enabled: true
    port: 8081
    tools:
      include:
        - list_endpoints
        - list_models
        - get_database_schema
      exclude:
        - run_migrations  # 쓰기 작업은 기본 제외

  # 코드 생성 설정
  codegen:
    endpoint_template: .ai/templates/endpoint.dart.tmpl
    model_template: .ai/templates/model.dart.tmpl

  # 프로젝트 설정
  project:
    server_root: .
    test_runner: dart test
    code_gen_command: dart run serverpod generate
```

---

## Laravel Boost와의 주요 차이점

| 측면 | Laravel Boost | ServerPod Boost (v3 전용) |
|------|---------------|-------------------------|
| 언어 | PHP | Dart |
| 템플릿 엔진 | Blade (.blade.php) | 순수 Dart/문자열 |
| 패키지 관리자 | Composer | Pub |
| 버전 소스 | Roster (composer.json) | pubspec.yaml 파싱 |
| 지원 버전 | Laravel 8, 9, 10, 11 | **ServerPod v3.x만** |
| CLI | Artisan | `dart run serverpod` |
| 설정 | PHP 배열 | YAML |
| 데이터베이스 | Eloquent ORM | ServerPod database |
| 라우팅 | routes/web.php | `endpoints/` 디렉토리 |
| 테스팅 | PHPUnit/Pest | `test/` 디렉토리 |
| 스트리밍 | 없음 | WebSocket 지원 |

---

## 개발 단계

### Phase 1: Foundation
- [x] `.ai/foundation.dart` 생성
- [x] `.ai/dart/core.dart` 생성
- [x] `.ai/serverpod/core.dart` 생성
- [ ] `GuidelineComposer` 기본 구현

### Phase 2: Skills System
- [ ] `SkillComposer`와 `Skill` 모델 구현
- [ ] `serverpod-development` 스킬 생성
- [ ] 스킬 활성화를 foundation에 추가

### Phase 3: MCP Tools
- [ ] `ToolRegistry` 패턴 구현
- [ ] 코어 도구 생성 (endpoints, schema, config)
- [ ] MCP 서버 작성기 구현

### Phase 4: Package Detection
- [ ] `pubspec.yaml` 파싱으로 ServerPod 패키지 감지
- [ ] 버전별 가이드라인 로드
- [ ] 서드파티 패키지 가이드라인 지원

### Phase 5: CLI Integration
- [ ] `boost:install` 명령어
- [ ] 에이전트 설정 지원 (Claude Code, Cline 등)
- [ ] 업데이트 명령어

---

## ServerPod v3 3-패키지 아키텍처

**ServerPod v3**는 **3개의 패키지**로 구성된 모노레포 구조입니다. ServerPod Boost는 ServerPod v3의 이 구조를 모두 지원합니다.

> **중요:** ServerPod Boost는 ServerPod v3.x만 지원합니다. v2 프로젝트는 v3로 마이그레이션한 후 사용하세요.

### 패키지 구조

```
my_project/
├── my_project_server/     # 🔵 SERVER - 소스 오브 트루스
│   ├── lib/
│   │   ├── src/
│   │   │   ├── endpoints/         # API 엔드포인트
│   │   │   ├── models/            # 데이터 모델 정의
│   │   │   └── generated/         # 자동 생성 코드
│   │   └── server.dart
│   ├── config/
│   │   ├── generator.yaml         # ⚡ 핵심 설정 파일
│   │   │   └── client_package_path: ../my_project_client
│   │   └── passwords.yaml
│   └── migrations/
│
├── my_project_client/     # 🟢 CLIENT - 자동 생성
│   ├── lib/
│   │   └── src/
│   │       └── protocol/          # 서버에서 생성된 프로토콜
│   │           ├── endpoints.dart
│   │           ├── models.dart
│   │           └── ...
│   └── pubspec.yaml
│       └── dependencies:
│           └── serverpod: ^2.0.0
│
└── my_project_flutter/    # 🟣 FLUTTER - 클라이언트 사용
    ├── lib/
    │   └── main.dart
    └── pubspec.yaml
        └── dependencies:
            └── my_project_client:
                path: ../my_project_client
```

### 코드 생성 흐름

```
┌─────────────────┐
│  개발자가 작성   │
│  Server 코드    │
│  (models/,      │
│   endpoints/)   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  serverpod generate     │
│  (server에서 실행)       │
└────────┬────────────────┘
         │
         ▼
┌─────────────────┐
│  Protocol 코드   │
│  자동 생성       │
│  (client로)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Flutter가      │
│  Client 사용    │
└─────────────────┘
```

### ServerPod Boost 설치 위치

**ServerPod Boost는 `*_server` 패키지에 설치해야 합니다:**

```bash
my_project_server/
├── .ai/
│   └── boost/              # Boost가 여기에 설치됨
│       ├── foundation.dart
│       ├── server/
│       ├── client/
│       └── flutter/
```

**이유:**
1. **Server가 소스 오브 트루스** - 모든 코드 정의가 여기서 시작
2. **코드 생성 발생지** - `serverpod generate`를 여기서 실행
3. **상대 경로 접근** - client와 flutter를 상대 경로로 접근 가능

### MCP 도구 - 3패키지 지원

| 도구 | 동작 대상 | 설명 |
|------|----------|------|
| `generate_protocol` | Server → Client | `serverpod generate` 실행 |
| `list_endpoints` | Server | 모든 엔드포인트 나열 |
| `list_models` | Server | 모든 모델 나열 |
| `validate_client` | Client | 생성된 클라이언트 코드 검증 |
| `find_flutter_usage` | Flutter | 엔드포인트 사용 위치 찾기 |
| `create_endpoint` | Server | 엔드포인트 스캐폴딩 |
| `create_model` | Server | 모델 스캐폴딩 |
| `get_database_schema` | Server | DB 스키마 조회 |
| `run_migrations` | Server | 마이그레이션 실행 |

### 스킬 시스템 - 패키지별 스킬

```
.ai/boost/
├── foundation.dart              # 기본 컨텍스트
├── server/
│   ├── core.dart               # Server 개발 기초
│   └── skill/endpoint-development/SKILL.dart
├── client/
│   ├── core.dart               # Client 사용법
│   └── skill/client-integration/SKILL.dart
└── flutter/
    ├── core.dart               # Flutter 통합
    └── skill/flutter-api/SKILL.dart
```

### generator.yaml 설정

```yaml
# my_project_server/config/generator.yaml
type: server  # 또는 'module'

# ⚡ 가장 중요한 설정
client_package_path: ../my_project_client

# Flutter 프로젝트 경로 (선택사항)
flutter_package_path: ../my_project_flutter

# 모듈 설정
modules:
  serverpod_auth:
    nickname: auth
```

### 개발 워크플로우

```bash
# 1. Server에서 모델/엔드포인트 작성
cd my_project_server
# ... lib/src/models/user.dart 작성
# ... lib/src/endpoints/user_endpoint.dart 작성

# 2. 코드 생성 (Server에서 실행)
dart run serverpod generate
# → my_project_client/lib/src/protocol/에 코드 생성됨

# 3. Client에서 (자동 생성된 코드로)
cd ../my_project_client
# lib/src/protocol/ 이미 생성되어 있음

# 4. Flutter에서 Client 사용
cd ../my_project_flutter
# client.userEndpoint.getUser(id) 등으로 사용
```

### 예시 프로젝트: Pilly

실제 구조는 `/Users/musinsa/always_summer/pilly`에서 확인할 수 있습니다:

```
pilly/
├── pilly_server/
│   ├── config/generator.yaml
│   │   └── client_package_path: ../pilly_client
│   └── lib/src/endpoints/
├── pilly_client/
│   └── lib/src/protocol/  (자동 생성됨)
└── pilly_flutter/
    └── pubspec.yaml
        └── pilly_client: { path: ../pilly_client }
```

### DO/DON'T: 3패키지 개발

| DO | DON'T |
|-----|--------|
| Server에서 `serverpod generate` 실행 | Client나 Flutter에서 실행 |
| Server에서 Boost 설치 | Client나 Flutter에 Boost 설치 |
| `generator.yaml`에 `client_package_path` 설정 | 경로를 하드코딩 |
| Flutter에서 Client 패키지 의존성 추가 | Flutter에서 직접 Server 코드 참조 |
| 생성된 Client 코드를 읽기 전용으로 취급 | `lib/src/protocol/`를 직접 수정 |

---

## 참고: ServerPod 프레임워크

이 섹션은 ServerPod 프레임워크 자체에 대한 참고입니다.

### ServerPod 핵심 컨벤션

**엔드포인트:**
- 클래스: `PascalCaseEndpoint` (예: `UserEndpoint`)
- 메서드: `Future<ReturnType> methodName(Session session, ...)`
- 파일: `lib/src/endpoints/`

**모델:**
- `Model` 클래스 상속
- `*.dart` 파일로 `lib/src/models/`에 정의
- `serverpod generate`로 코드 생성

**데이터베이스:**
- `session.db.find()`, `session.db.insertRow()` 등 사용
- 마이그레이션은 `migrations/`에 SQL 파일로

### 자세한 내용

- **ServerPod 문서**: https://docs.serverpod.dev
- **프레임워크 소스**: `/Users/musinsa/always_summer/serverpod`
- **예시 프로젝트**: `/Users/musinsa/always_summer/pilly`
- **Laravel Boost 참조**: `/Users/musinsa/always_summer/boost`

---

## 변경 로그

### 버전 0.1.0 (2025-02-04)
- 초기 프로젝트 구조 정의
- Laravel Boost 분석 완료
- ServerPod Boost 아키텍처 설계
- AGENTS.md 작성
- **ServerPod v3 전용 지원** (v2는 지원하지 않음)

---

**마지막 업데이트: 2025-02-04**
**유지 관리: ServerPod Boost 팀**
