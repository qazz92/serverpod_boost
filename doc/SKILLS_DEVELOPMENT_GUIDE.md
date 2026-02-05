# ServerPod Boost 스킬 개발 가이드

이 가이드는 ServerPod Boost에서 사용자 정의 스킬을 만드는 방법을 안내합니다.

## 목차

1. [스킬이란 무엇인가요?](#스킬이란-무엇인가요)
2. [스킬 구조](#스킬-구조)
3. [Mustache 템플릿 문법](#mustache-템플릿-문법)
4. [사용 가능한 템플릿 변수](#사용-가능한-템플릿-변수)
5. [첫 번째 스킬 만들기](#첫-번째-스킬-만들기)
6. [스킬 의존성](#스킬-의존성)
7. [GitHub에 스킬 게시](#github에-스킬-게시)
8. [모범 사례](#모범-사례)
9. [내장 스킬 예제](#내장-스킬-예제)

---

## 스킬이란 무엇인가요?

**스킬(Skill)**은 AI 코딩 패턴을 제공하는 재사용 가능한 Mustache 템플릿입니다. 스킬을 사용하면:

- **일관된 코드 패턴**: 프로젝트 전체에서 일관된 코딩 스타일 유지
- **AI 지원**: Claude와 같은 AI에게 프로젝트별 컨텍스트 제공
- **재사용성**: 공통 패턴을 템플릿으로 재사용
- **커뮤니티 공유**: GitHub를 통해 스킬 공유 가능

### 스킬의 이점

- ✅ 프로젝트별 맞춤형 AI 가이드라인 제공
- ✅ 반복적인 코딩 패턴 자동화
- ✅ 팀 전체의 코드 품질 향상
- ✅ 신규 개발자 온보딩 간소화

---

## 스킬 구조

스킬은 두 개의 파일로 구성됩니다:

```
my-skill/
├── meta.yaml           # 스킬 메타데이터
└── SKILL.md.mustache   # Mustache 템플릿
```

### meta.yaml

스킬의 정보를 정의하는 YAML 파일입니다:

```yaml
name: my_skill              # 스킬 이름 (필수)
description: 내 스킬 설명    # 스킬 설명 (필수)
version: 1.0.0              # 스킬 버전 (필수)
minServerpodVersion: 2.0.0  # 최소 ServerPod 버전 (선택)
dependencies:               # 의존하는 다른 스킬 (선택)
  - core
  - endpoints
tags:                       # 태그 (선택)
  - serverpod
  - custom
  - api
```

#### meta.yaml 필드 설명

| 필드 | 타입 | 필수여부 | 설명 |
|------|------|---------|------|
| `name` | String | ✅ | 스킬의 고유 이름 (소문자, 밑줄 사용) |
| `description` | String | ✅ | 스킬에 대한 간단한 설명 |
| `version` | String | ✅ | 시맨틱 버전 (예: 1.0.0) |
| `minServerpodVersion` | String | ❌ | 필요한 최소 ServerPod 버전 |
| `dependencies` | List<String> | ❌ | 이 스킬이 의존하는 다른 스킬 목록 |
| `tags` | List<String> | ❌ | 검색 및 분류를 위한 태그 |

### SKILL.md.mustache

실제 AI에게 제공될 내용을 담은 Mustache 템플릿 파일입니다:

```markdown
# 내 스킬

{{project_name}} 프로젝트를 위한 맞춤형 가이드입니다.

## 프로젝트 정보

- 프로젝트 이름: {{project_name}}
- ServerPod 버전: {{serverpod_version}}

{{#has_endpoints}}
## 기존 엔드포인트

이 프로젝트에는 {{endpoint_count}}개의 엔드포인트가 있습니다:

{{#endpoints}}
- {{name}}
{{/endpoints}}
{{/has_endpoints}}

## 사용 예제

코드 예제와 설명을 여기에 작성하세요...
```

---

## Mustache 템플릿 문법

스킬 템플릿은 [Mustache](https://mustache.github.io/) 문법을 사용합니다.

### 변수

```
{{variable_name}}
```

변수의 값으로 치환됩니다.

### 섹션 (Sections)

**조건부 섹션:**

```mustache
{{#condition}}
  이 내용은 condition이 참일 때만 표시됩니다.
{{/condition}}

{{^condition}}
  이 내용은 condition이 거짓일 때 표시됩니다.
{{/condition}}
```

**반복 섹션:**

```mustache
{{#items}}
  - {{name}}: {{description}}
{{/items}}
```

리스트의 각 항목에 대해 반복합니다.

### 주석

```mustache
{{! 이것은 주석입니다. 출력에 포함되지 않습니다. }}
```

---

## 사용 가능한 템플릿 변수

ServerPod Boost는 스킬 템플릿에서 다음 변수를 제공합니다:

### 기본 변수

| 변수 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `{{project_name}}` | String | 프로젝트 이름 | `my_project` |
| `{{serverpod_version}}` | String | ServerPod 버전 | `2.0.0` |
| `{{pascal_case project_name}}` | String | 파스칼 케이스 프로젝트 이름 | `MyProject` |

### 프로젝트 상태

| 변수 | 타입 | 설명 |
|------|------|------|
| `{{has_endpoints}}` | Boolean | 엔드포인트가 있는지 여부 |
| `{{has_models}}` | Boolean | 모델이 있는지 여부 |
| `{{has_migrations}}` | Boolean | 마이그레이션이 있는지 여부 |
| `{{uses_postgres}}` | Boolean | PostgreSQL을 사용하는지 |
| `{{uses_sqlite}}` | Boolean | SQLite를 사용하는지 |
| `{{uses_redis}}` | Boolean | Redis를 사용하는지 |
| `{{uses_serverpod_auth}}` | Boolean | serverpod_auth를 사용하는지 |

### 카운트 변수

| 변수 | 타입 | 설명 |
|------|------|------|
| `{{endpoint_count}}` | Integer | 엔드포인트 개수 |
| `{{model_count}}` | Integer | 모델 개수 |
| `{{migration_count}}` | Integer | 마이그레이션 개수 |

### 반복 가능한 목록

#### 엔드포인트

```mustache
{{#endpoints}}
- {{name}}
- {{file}}
- {{method_count}}
{{#methods}}
  - {{signature}}
{{/methods}}
{{/endpoints}}
```

#### 모델

```mustache
{{#models}}
- {{class_name}}
- {{namespace}}
{{/models}}
```

---

## 첫 번째 스킬 만들기

단계별로 첫 번째 스킬을 만들어 보겠습니다.

### 1단계: 스킬 디렉토리 만들기

로컬 스킬 디렉토리에 스킬을 만듭니다:

```bash
mkdir -p ~/.serverpod_boost/skills/logging
cd ~/.serverpod_boost/skills/logging
```

### 2단계: meta.yaml 만들기

```yaml
# meta.yaml
name: logging
description: 로깅 설정 및 사용법을 위한 스킬
version: 1.0.0
dependencies:
  - core
tags:
  - serverpod
  - logging
  - monitoring
```

### 3단계: SKILL.md.mustache 만들기

```markdown
# {{project_name}} 로깅 가이드

이 프로젝트는 ServerPod {{serverpod_version}}을 사용합니다.

## 로거 설정

ServerPod는 내장된 로깅 시스템을 제공합니다.

### 기본 사용법

```dart
import 'package:serverpod/serverpod.dart';

class MyEndpoint extends Endpoint {
  Future<String> myMethod(Session session, String input) async {
    // 정보 로그
    session.log('Processing input: $input');

    // 경고 로그
    if (input.length > 100) {
      session.logWarning('Input is very long');
    }

    // 에러 로그
    try {
      await processSomething(session);
    } catch (e, stackTrace) {
      session.logError('Processing failed', e, stackTrace);
    }

    return 'Done';
  }
}
```

## 로그 레벨

- **`session.log()`**: 정보성 메시지
- **`session.logWarning()`**: 경고 메시지
- **`session.logError()`**: 에러 메시지와 스택 트레이스

## 커스텀 로거

```dart
class CustomLogger {
  static void logUserAction(
    Session session,
    String action,
    Map<String, dynamic> details,
  ) {
    session.log(
      'User action: $action',
      details: details,
    );
  }
}

// 사용
CustomLogger.logUserAction(
  session,
  'user_login',
  {'userId': session.userId, 'timestamp': DateTime.now().toIso8601String()},
);
```

{{#has_endpoints}}
## 기존 엔드포인트

프로젝트의 {{endpoint_count}}개 엔드포인트에 로깅을 추가하세요:

{{#endpoints}}
### {{name}}
{{file}}
{{/endpoints}}
{{/has_endpoints}}

## 모범 사례

1. **중요한 작업 로깅**: 데이터베이스 변경, 외부 API 호출
2. **에러 컨텍스트**: 에러 발생 시 관련 컨텍스트 포함
3. **민감한 정보 피하기**: 비밀번호, 토큰 등을 로그에 포함하지 마세요

```dart
// ✅ 좋은 예
session.log('User logged in', details: {'userId': user.id});

// ❌ 나쁜 예
session.log('User logged in with password: $password');
```
```

### 4단계: 스킬 사용하기

```bash
# 스킬 활성화
serverpod boost load logging

# 또는 여러 스킬과 함께
serverpod boost load core endpoints logging
```

---

## 스킬 의존성

스킬은 다른 스킬에 의존할 수 있습니다. 의존성은 `meta.yaml`의 `dependencies` 필드에 정의합니다.

### 의존성 예시

```yaml
name: authentication_jwt
description: JWT 기반 인증 구현
version: 1.0.0
dependencies:
  - core
  - endpoints
  - models
tags:
  - serverpod
  - auth
  - jwt
```

이 경우 `authentication_jwt` 스킬은 `core`, `endpoints`, `models` 스킬이 먼저 로드되어야 합니다.

### 의존성 확인

스킬을 로드할 때 ServerPod Boost는 의존성을 자동으로 확인하고 로드합니다:

```bash
$ serverpod boost load authentication_jwt
Loading dependencies: core, endpoints, models
Loading skill: authentication_jwt
```

### 순환 의존성 피하기

스킬 간 순환 의존성을 만들지 마세요:

```yaml
# ❌ 나쁜 예: 순환 의존성
# skill_a/meta.yaml
dependencies:
  - skill_b

# skill_b/meta.yaml
dependencies:
  - skill_a
```

대신 공통 기능을 별도 스킬로 분리하세요:

```yaml
# ✅ 좋은 예
# common/meta.yaml
# (의존성 없음)

# skill_a/meta.yaml
dependencies:
  - common

# skill_b/meta.yaml
dependencies:
  - common
```

---

## GitHub에 스킬 게시

스킬을 GitHub에 게시하여 커뮤니티와 공유할 수 있습니다.

### GitHub 저장소 구조

```
username/serverpod-skills/
├── README.md
├── skills/
│   ├── my_skill_1/
│   │   ├── meta.yaml
│   │   └── SKILL.md.mustache
│   └── my_skill_2/
│       ├── meta.yaml
│       └── SKILL.md.mustache
```

### README.md 작성

```markdown
# ServerPod Skills

내 ServerPod 스킬 모음입니다.

## 사용 가능한 스킬

### my_skill_1

설명과 사용법.

### my_skill_2

설명과 사용법.

## 설치 방법

```bash
# 단일 스킬 로드
serverpod boost load github:username/serverpod-skills/my_skill_1

# 모든 스킬 로드
serverpod boost load github:username/serverpod-skills
```

## 라이선스

MIT
```

### GitHub에서 스킬 로드

```bash
# 저장소의 모든 스킬 로드
serverpod boost load github:username/serverpod-skills

# 특정 스킬 로드
serverpod boost load github:username/serverpod-skills/my_skill
```

---

## 모범 사례

### 1. 명확한 이름과 설명

```yaml
# ✅ 좋은 예
name: postgres_full_text_search
description: PostgreSQL 전체 텍스트 검색 구현 가이드
version: 1.0.0

# ❌ 나쁜 예
name: stuff
description: 여러가지 것들
version: 1.0.0
```

### 2. 적절한 의존성 관리

```yaml
# ✅ 필요한 의존성만 포함
dependencies:
  - core
  - models

# ❌ 불필요한 의존성 포함
dependencies:
  - core
  - endpoints
  - models
  - migrations
  - testing
  - authentication
```

### 3. 코드 예제 포함

스킬에는 항상 실제 코드 예제를 포함하세요:

```markdown
## 사용 예제

```dart
// 명확하고 실행 가능한 코드
Future<User> createUser(Session session, String email) async {
  final user = User(email: email);
  await user.insert(session);
  return user;
}
```
```

### 4. 조건부 콘텐츠 활용

프로젝트 상태에 따라 다른 콘텐츠를 제공하세요:

```mustache
{{#has_endpoints}}
이 프로젝트에는 이미 엔드포인트가 있습니다. 기존 패턴을 따르세요.
{{/has_endpoints}}

{{^has_endpoints}}
이 프로젝트에 첫 번째 엔드포인트를 만들어 보세요.
{{/has_endpoints}}
```

### 5. 문서 구조화

일관된 문서 구조를 사용하세요:

```markdown
# 스킬 제목

간단한 소개...

## 전제 조건

필요한 설정이나 의존성...

## 설정

설정 단계...

## 사용법

코드 예제와 설명...

## 고급 기능

추가 기능...

## 문제 해결

일반적인 문제와 해결 방법...
```

### 6. 버전 관리

시맨틱 버전 관리를 따르세요:

- **MAJOR**: 호환되지 않는 변경
- **MINOR**: 새로운 기능 (호환성 유지)
- **PATCH**: 버그 수정

```yaml
version: 2.1.3  # MAJOR.MINOR.PATCH
```

### 7. 태그 활용

검색과 분류를 위해 태그를 활용하세요:

```yaml
tags:
  - serverpod
  - database
  - postgres
  - advanced
```

---

## 내장 스킬 예제

ServerPod Boost에 포함된 8개의 내장 스킬을 참고하여 자신만의 스킬을 만드세요.

### 1. core (핵심)

**위치**: `.ai/skills/serverpod/core/`

**목적**: ServerPod 개발의 기본 가이드라인과 모범 사례

**주요 내용**:
- 프로젝트 구조
- 개발 워크플로우
- 공통 패턴 (세션 관리, 에러 처리, 트랜잭션)

### 2. endpoints (엔드포인트)

**위치**: `.ai/skills/serverpod/endpoints/`

**목적**: 엔드포인트 개발 패턴과 모범 사례

**주요 내용**:
- 기존 엔드포인트 분석 (`{{#has_endpoints}}`)
- 새 엔드포인트 생성
- 메서드 서명 가이드라인
- 스트리밍, 인증, 입력 검증

### 3. models (모델)

**위치**: `.ai/skills/serverpod/models/`

**목적**: 모델 정의와 데이터베이스 쿼리 패턴

**주요 내용**:
- 모델 정의와 필드 어노테이션
- 데이터베이스 쿼리
- 관계 (일대다, 다대다)
- 집계와 카운트

### 4. migrations (마이그레이션)

**위치**: `.ai/skills/serverpod/migrations/`

**목적**: 데이터베이스 마이그레이션 관리

**주요 내용**:
- 마이그레이션 생성
- 스키마 정의
- 마이그레이션 실행

### 5. testing (테스트)

**위치**: `.ai/skills/serverpod/testing/`

**목적**: ServerPod 프로젝트 테스트

**주요 내용**:
- 테스트 설정
- 엔드포인트 테스트
- 모델 테스트

### 6. authentication (인증)

**위치**: `.ai/skills/serverpod/authentication/`

**목적**: 사용자 인증과 권한 부여

**주요 내용**:
- serverpod_auth 설정
- 사용자 등록/로그인
- 보호된 엔드포인트
- RBAC (역할 기반 액세스 제어)
- 소셜 인증

**의존성**: core

### 7. webhooks (웹훅)

**위치**: `.ai/skills/serverpod/webhooks/`

**목적**: 웹훅 수신 및 처리

**주요 내용**:
- 웹훅 엔드포인트 생성
- 서명 검증
- 재시도 로직

**의존성**: endpoints, core

### 8. redis (Redis)

**위치**: `.ai/skills/serverpod/redis/`

**목적**: Redis 캐싱, 세션 저장소, Pub/Sub

**주요 내용**:
- Redis 연결
- 캐싱 패턴
- 세션 저장
- Pub/Sub
- 속도 제한

**의존성**: core

---

## 완전한 예제: API 버전 관리 스킬

다음은 실전에서 사용할 수 있는 완전한 스킬 예제입니다.

### meta.yaml

```yaml
name: api_versioning
description: API 버전 관리를 위한 스킬
version: 1.0.0
dependencies:
  - core
  - endpoints
tags:
  - serverpod
  - api
  - versioning
```

### SKILL.md.mustache

```markdown
# {{project_name}} API 버전 관리

이 가이드는 {{project_name}} 프로젝트에서 API 버전 관리를 구현하는 방법을 안내합니다.

## 개요

API 버전 관리는 API 변경사항을 관리하고 하위 호환성을 유지하는 데 도움이 됩니다.

## 버전 관리 전략

### URL 경로 버전 관리

```dart
// lib/src/endpoints/v1/user_endpoint.dart
class UserEndpointV1 extends Endpoint {
  Future<UserData> getProfile(Session session, int userId) async {
    final user = await User.findById(session, userId);
    return user!.toV1Data();
  }
}

// lib/src/endpoints/v2/user_endpoint.dart
class UserEndpointV2 extends Endpoint {
  Future<UserDataV2> getProfile(Session session, int userId) async {
    final user = await User.findById(session, userId);
    return user!.toV2Data(); // 추가 필드 포함
  }
}
```

### 헤더 기반 버전 관리

```dart
// lib/src/endpoints/versioned_endpoint.dart
class VersionedEndpoint extends Endpoint {
  Future<dynamic> getData(Session session) async {
    final version = session.headers['API-Version'] ?? '1';

    switch (version) {
      case '1':
        return _getDataV1(session);
      case '2':
        return _getDataV2(session);
      default:
        throw InvalidInputException('Unsupported API version: $version');
    }
  }

  Future<dynamic> _getDataV1(Session session) async {
    // V1 구현
  }

  Future<dynamic> _getDataV2(Session session) async {
    // V2 구현 (향상된 기능)
  }
}
```

## 버전 관리 모범 사례

### 1. 명시적 버전

```dart
// ✅ 좋은 예
class UserEndpointV1 extends Endpoint { }
class UserEndpointV2 extends Endpoint { }

// ❌ 나쁜 예
class UserEndpoint extends Endpoint { } // 버전 불명
```

### 2. 버전 간 코드 공유

```dart
// lib/src/endpoints/user_endpoint_base.dart
abstract class UserEndpointBase extends Endpoint {
  Future<User?> findUser(Session session, int userId) async {
    return await User.findById(session, userId);
  }
}

// lib/src/endpoints/v1/user_endpoint.dart
class UserEndpointV1 extends UserEndpointBase {
  Future<UserData> getProfile(Session session, int userId) async {
    final user = await findUser(session, userId);
    return user!.toV1Data();
  }
}

// lib/src/endpoints/v2/user_endpoint.dart
class UserEndpointV2 extends UserEndpointBase {
  Future<UserDataV2> getProfile(Session session, int userId) async {
    final user = await findUser(session, userId);
    return user!.toV2Data();
  }
}
```

### 3. 버전 폐기 안내

```dart
class UserEndpointV1 extends Endpoint {
  @override
  Future<void> initialize() async {
    super.initialize();
    session.logWarning(
      'API V1 is deprecated. Please migrate to V2 by 2025-01-01.',
    );
  }
}
```

{{#has_endpoints}}
## 기존 엔드포인트 버전 관리

현재 프로젝트의 {{endpoint_count}}개 엔드포인트를 버전 관리하세요:

{{#endpoints}}
### {{name}}

새 버전을 만들려면:
1. `{{file}}`을 `v1/{{file}}`로 이동
2. `{{name}}`을 `{{name}}V1`으로 이름 변경
3. `v2/` 디렉토리에 새 버전 생성
4. 공통 로직을 베이스 클래스로 추출

{{/endpoints}}
{{/has_endpoints}}

## 마이그레이션 가이드

### V1에서 V2로

```dart
// V1
final data = await session.user.getProfile(userId);

// V2 (추가 필드 포함)
final data = await session.userV2.getProfile(userId);
final preferences = data.preferences; // 새 필드
```

## 테스트

```dart
// test/endpoints/v1/user_endpoint_test.dart
void main() {
  group('UserEndpointV1', () {
    testWithServerpod('getProfile returns V1 format', (session, endpoints) async {
      final user = await endpoints.userV1.getProfile(session, 1);
      expect(user, isA<UserData>());
    });
  });
}

// test/endpoints/v2/user_endpoint_test.dart
void main() {
  group('UserEndpointV2', () {
    testWithServerpod('getProfile returns V2 format', (session, endpoints) async {
      final user = await endpoints.userV2.getProfile(session, 1);
      expect(user, isA<UserDataV2>());
      expect(user.preferences, isNotNull);
    });
  });
}
```
```

---

## 스킬 테스트

스킬을 만든 후에는 제대로 작동하는지 테스트하세요.

### 1단계: 스킬 로드

```bash
serverpod boost load ~/.serverpod_boost/skills/my_skill
```

### 2단계: 렌더링된 콘텐츠 확인

```bash
serverpod boost render my_skill
```

### 3단계: 실제 프로젝트에서 테스트

```bash
cd /path/to/serverpod/project
serverpod boost apply my_skill
```

### 4단계: AI 응답 확인

Claude와 같은 AI에 프로젝트 관련 질문을 하고 스킬의 가이드가 적용되는지 확인하세요.

---

## 문제 해결

### 스킬이 로드되지 않음

**증상**: `Skill not found` 에러

**해결**:
1. `meta.yaml` 파일이 있는지 확인
2. `name` 필드가 올바른지 확인
3. 파일 경로가 올바른지 확인

### 템플릿 변수가 작동하지 않음

**증상**: `{{variable}}`이 그대로 출력됨

**해결**:
1. 변수 이름이 올바른지 확인
2. 조건부 변수의 경우 해당 조건이 충족되는지 확인
3. 문법에 오타가 없는지 확인

### 의존성 문제

**증상**: `Dependency not found` 에러

**해결**:
1. 의존하는 스킬이 먼저 로드되었는지 확인
2. 순환 의존성이 없는지 확인
3. `dependencies` 목록에 스킬 이름이 올바른지 확인

---

## 추가 리소스

- [Mustache 문법](https://mustache.github.io/)
- [ServerPod 공식 문서](https://serverpod.dev/)
- [내장 스킬 소스 코드](.ai/skills/serverpod/)
- [GitHub 이슈](https://github.com/your-repo/issues)

---

## 도움말

스킬 개발 중 문제가 있거나 질문이 있으시면:

1. 이 가이드의 문제 해결 섹션 확인
2. 내장 스킬 예제 참고
3. GitHub 이슈 생성
4. 커뮤니티 포럼에 질문

즐거운 스킬 개발 되세요!
