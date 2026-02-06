# ServerPod Boost 사용자 가이드

**ServerPod Boost**는 ServerPod v3 프로젝트를 위한 AI 가속화 도구입니다. Laravel Boost에서 영감을 받아, AI 어시스턴트(Claude, OpenCode 등)가 ServerPod 프로젝트를 더 잘 이해하고 고품질의 코드를 생성할 수 있도록 도와줍니다.

## 목차

1. [소개](#소개)
2. [설치](#설치)
3. [빠른 시작](#빠른-시작)
4. [MCP 도구 레퍼런스](#mcp-도구-레퍼런스)
5. [스킬 시스템](#스킬-시스템)
6. [CLI 명령어](#cli-명령어)
7. [일반적인 워크플로우](#일반적인-워크플로우)
8. [트러블슈팅](#트러블슈팅)

---

## 소개

### ServerPod Boost란 무엇인가요?

ServerPod Boost는 **MCP(Model Context Protocol)** 서버로, AI 어시스턴트에게 다음과 같은 능력을 제공합니다:

- 📁 **프로젝트 인식**: ServerPod v3 모노레포 구조 자동 감지
- 🔍 **엔드포인트 분석**: 모든 엔드포인트와 메서드 시그니처 파싱
- 📊 **모델 이해**: 프로토콜 모델 정의를 소스 `.spy.yaml` 파일에서 읽기
- 🗄️ **데이터베이스 컨텍스트**: 마이그레이션 파일과 데이터베이스 스키마 접근
- ⚙️ **설정 접근**: 모든 YAML 설정 파일 읽기
- 🔎 **코드 검색**: 소스 코드 전체 텍스트 검색

### 왜 ServerPod Boost인가요?

AI 어시스턴트가 ServerPod 프로젝트에서 작업할 때 겪는 어려움을 해결합니다:

| 문제 | ServerPod Boost 해결책 |
|------|----------------------|
| 프로젝트 구조를 이해하지 못함 | 자동 프로젝트 감지 및 구조 분석 |
| 엔드포인트 시그니처를 알 수 없음 | 메서드 파라미터와 반환 타입 자동 파싱 |
| 모델 필드를 모름 | `.spy.yaml` 파일에서 모델 정의 읽기 |
| 데이터베이스 스키마를 모름 | 마이그레이션 파일에서 스키마 추출 |
| 설정 값을 알 수 없음 | YAML 설정 파일 직접 접근 |

### 버전 지원

| 버전 | 지원 | 상태 |
|------|------|------|
| **ServerPod v3.x** | ✅ 예 | 완전 지원 |
| ServerPod v2.x | ❌ 아니오 | 지원하지 않음 - v3로 마이그레이션 권장 |

---

## 설치

### 방법 1: 자동 설치 (추천)

가장 쉬운 방법은 Dart 명령어로 자동 설치하는 것입니다:

```bash
# ServerPod 프로젝트 루트로 이동
cd your_serverpod_project

# 자동 설치 실행
dart run serverpod_boost:install
```

설치 프로세스가 자동으로 다음을 수행합니다:
- ✅ ServerPod 프로젝트 구조 감지
- ✅ `run-boost.sh` 래퍼 스크립트 생성
- ✅ 필요한 모든 의존성 설치
- ✅ Claude Desktop 설정 안내 출력

### 방법 2: 대화형 설치 스크립트

대화형 설치 스크립트를 사용할 수도 있습니다:

```bash
# ServerPod 프로젝트 루트로 이동
cd your_serverpod_project

# 설치 스크립트 실행
bash /path/to/serverpod_boost/bin/install.sh
```

### 방법 3: 수동 설치

```bash
# ServerPod 프로젝트의 server 패키지로 이동
cd your_project_server

# Boost 디렉토리 생성
mkdir -p .ai/boost
cd .ai/boost

# 로컬 패키지로 추가
dart pub add serverpod_boost --path=/path/to/serverpod_boost
```

### 방법 4: 전역 설치

```bash
# 전역으로 활성화
dart pub global activate serverpod_boost

# PATH에 추가 (이미 없는 경우)
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### Claude Desktop 설정

Claude Desktop에서 ServerPod Boost를 사용하려면 MCP 설정을 추가해야 합니다.

**새로운 래퍼 스크립트 방식 (추천)**:

설치 명령어를 실행하면 자동으로 `run-boost.sh` 스크립트가 생성됩니다:

```bash
dart run serverpod_boost:install
```

그 후 Claude Desktop 설정에 다음을 추가합니다:

**모든 플랫폼 (macOS, Windows, Linux)**:
```json
{
  "mcpServers": {
    "serverpod-boost": {
      "command": "/path/to/your/project/run-boost.sh",
      "args": []
    }
  }
}
```

설정 파일 경로:
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

**예시**:
```json
{
  "mcpServers": {
    "serverpod-boost": {
      "command": "/Users/username/projects/my_project/run-boost.sh",
      "args": []
    }
  }
}
```

**장점**:
- ✅ 자동으로 프로젝트 구조를 감지합니다
- ✅ `server` 디렉토리로 자동 이동합니다
- ✅ 복잡한 경로 설정이 필요 없습니다
- ✅ 모든 ServerPod 프로젝트 구조에서 작동합니다

### 설치 확인

```bash
# MCP 서버로 실행 (기본 모드)
dart run bin/boost.dart

# CLI 명령어 테스트
boost skill:list

# 프로젝트 정보 확인
boost info
```

---

## 빠른 시작

### 5분 만에 시작하기

**1단계: 설치**

```bash
cd your_serverpod_project
dart run serverpod_boost:install
```

이 명령어가 `run-boost.sh` 래퍼 스크립트를 자동으로 생성합니다.

**2단계: Claude Desktop 설정**

Claude Desktop 설정 파일에 다음을 추가하세요:

```json
{
  "mcpServers": {
    "serverpod-boost": {
      "command": "/path/to/your/project/run-boost.sh",
      "args": []
    }
  }
}
```

**3단계: Claude Desktop 재시작**

Claude Desktop을 완전히 종료했다가 다시 시작합니다.

**3단계: 프로젝트 정보 요청**

Claude에 다음과 같이 질문하세요:

```
이 ServerPod 프로젝트에 대해 알려줘
```

ServerPod Boost가 자동으로 프로젝트 구조를 분석하고 정보를 제공합니다.

**4단계: 엔드포인트 탐색**

```
이 프로젝트에 어떤 엔드포인트가 있어?
```

```
userEndpoint의 메서드들을 보여줘
```

**5단계: 모델 확인**

```
User 모델의 필드는 어떻게 되어 있어?
```

### 첫 번째 엔드포인트 생성하기

AI에게 엔드포인트 생성을 요청하세요:

```
게시물(Post)을 관리하는 엔드포인트를 만들어줘.
다음 기능이 필요해:
- 목록 조회 (페이지네이션)
- ID로 조회
- 생성
- 수정
- 삭제
```

ServerPod Boost가 프로젝트의 기존 엔드포인트와 모델을 분석하여, 프로젝트 스타일에 맞는 코드를 생성합니다.

---

## MCP 도구 레퍼런스

ServerPod Boost는 **14개의 내장 도구**를 제공합니다.

### 필수 도구 (Tier 1)

#### 1. application_info

프로젝트의 전체 정보를 가져옵니다.

**설명**: ServerPod 애플리케이션의 포괄적인 개요를 제공합니다.

**사용법**:
```
이 프로젝트에 대해 요약해줘
```

**반환 정보**:
- 프로젝트 구조와 경로
- Dart와 ServerPod 버전
- 데이터베이스 설정
- 모든 엔드포인트와 메서드
- 모든 프로토콜 모델

**예시 출력**:
```json
{
  "projectName": "my_project",
  "serverPath": "/path/to/my_project_server",
  "clientPath": "/path/to/my_project_client",
  "flutterPath": "/path/to/my_project_flutter",
  "serverpodVersion": "3.2.3",
  "dartVersion": "3.8.0",
  "endpoints": [...],
  "models": [...]
}
```

---

#### 2. list_endpoints

모든 엔드포인트를 나열합니다.

**설명**: 프로젝트의 모든 엔드포인트를 찾아서 목록을 보여줍니다.

**사용법**:
```
모든 엔드포인트를 보여줘
```

```
인증 관련 엔드포인트만 보여줘
```

**파라미터**:
- `filter` (선택): 엔드포인트 이름으로 필터링 (예: "auth", "user")

**예시 출력**:
```json
{
  "endpoints": [
    {
      "name": "userEndpoint",
      "fileName": "lib/src/endpoints/user_endpoint.dart",
      "className": "UserEndpoint",
      "methods": ["getUser", "createUser", "updateUser", "deleteUser"]
    },
    {
      "name": "authEndpoint",
      "fileName": "lib/src/endpoints/auth_endpoint.dart",
      "className": "AuthEndpoint",
      "methods": ["signIn", "signOut", "resetPassword"]
    }
  ]
}
```

---

#### 3. endpoint_methods

엔드포인트의 메서드 상세 정보를 가져옵니다.

**설명**: 특정 엔드포인트의 모든 메서드와 시그니처를 보여줍니다.

**사용법**:
```
userEndpoint의 메서드들을 자세히 보여줘
```

```
authEndpoint에서 어떤 메서드를 호출할 수 있어?
```

**파라미터**:
- `endpoint_name` (필수): 엔드포인트 이름 (예: "userEndpoint")

**예시 출력**:
```json
{
  "endpointName": "userEndpoint",
  "className": "UserEndpoint",
  "methods": [
    {
      "name": "getUser",
      "returnType": "User?",
      "parameters": [
        {"name": "session", "type": "Session"},
        {"name": "userId", "type": "int"}
      ],
      "isNullable": true,
      "isFuture": true
    },
    {
      "name": "createUser",
      "returnType": "User",
      "parameters": [
        {"name": "session", "type": "Session"},
        {"name": "user", "type": "User"}
      ]
    }
  ]
}
```

---

#### 4. list_models

모든 프로토콜 모델을 나열합니다.

**설명**: 프로젝트에 정의된 모든 프로토콜 모델을 보여줍니다.

**사용법**:
```
이 프로젝트에 어떤 모델들이 있어?
```

```
User 관련 모델만 보여줘
```

**파라미터**:
- `filter` (선택): 모델 이름으로 필터링

**예시 출력**:
```json
{
  "models": [
    {
      "name": "User",
      "fileName": "lib/src/models/user.dart",
      "yamlFile": "lib/src/models/user.spy.yaml",
      "fields": ["id", "email", "name", "createdAt"]
    },
    {
      "name": "Post",
      "fileName": "lib/src/models/post.dart",
      "yamlFile": "lib/src/models/post.spy.yaml",
      "fields": ["id", "title", "content", "authorId", "createdAt"]
    }
  ]
}
```

---

#### 5. model_inspector

모델의 필드 상세 정보를 가져옵니다.

**설명**: 특정 모델의 모든 필드와 타입을 자세히 보여줍니다.

**사용법**:
```
User 모델의 필드들을 자세히 보여줘
```

```
Post 모델에 어떤 필드가 있어?
```

**파라미터**:
- `model_name` (필수): 모델 클래스 이름 (예: "User")

**예시 출력**:
```json
{
  "modelName": "User",
  "yamlFile": "lib/src/models/user.spy.yaml",
  "fields": [
    {
      "name": "id",
      "type": "int",
      "isNullable": false,
      "isList": false
    },
    {
      "name": "email",
      "type": "String",
      "isNullable": false,
      "isList": false
    },
    {
      "name": "name",
      "type": "String?",
      "isNullable": true,
      "isList": false
    },
    {
      "name": "createdAt",
      "type": "DateTime",
      "isNullable": false,
      "isList": false
    }
  ]
}
```

---

#### 6. config_reader

ServerPod YAML 설정 파일을 읽습니다.

**설명**: 개발/운영/테스트 환경의 설정을 읽어옵니다.

**사용법**:
```
개발 환경 설정을 보여줘
```

```
데이터베이스 설정이 어떻게 되어 있어?
```

**파라미터**:
- `environment` (선택): "development", "production", "staging", "test" (기본값: "development")
- `section` (선택): 특정 설정 섹션

**예시 출력**:
```json
{
  "environment": "development",
  "config": {
    "apiServer": {
      "port": 8080,
      "publicHost": "localhost",
      "publicPort": 8080,
      "publicScheme": "http"
    },
    "database": {
      "host": "localhost",
      "port": 5432,
      "name": "mydb",
      "user": "postgres"
    },
    "redis": {
      "host": "localhost",
      "port": 6379
    }
  }
}
```

---

#### 7. database_schema

마이그레이션 파일에서 데이터베이스 스키마를 가져옵니다.

**설명**: 모든 마이그레이션 파일을 분석하여 현재 데이터베이스 구조를 보여줍니다.

**사용법**:
```
데이터베이스 스키마를 보여줘
```

```
users 테이블의 구조가 어떻게 되어 있어?
```

**파라미터**:
- `table_filter` (선택): 테이블 이름으로 필터링

**예시 출력**:
```json
{
  "tables": [
    {
      "name": "users",
      "columns": [
        {"name": "id", "type": "serial", "nullable": false, "primaryKey": true},
        {"name": "email", "type": "varchar(255)", "nullable": false},
        {"name": "name", "type": "varchar(255)", "nullable": true},
        {"name": "created_at", "type": "timestamp", "nullable": false}
      ],
      "indexes": ["users_email_idx"]
    }
  ]
}
```

---

#### 8. migration_scanner

마이그레이션 파일과 내용을 나열합니다.

**설명**: 모든 마이그레이션 파일과 그 내용을 보여줍니다.

**사용법**:
```
모든 마이그레이션을 보여줘
```

```
마이그레이션 히스토리를 알려줘
```

**파라미터**:
- `table_filter` (선택): 테이블 이름으로 필터링
- `include_content` (선택): 마이그레이션 파일 내용 포함

**예시 출력**:
```json
{
  "migrations": [
    {
      "fileName": "20240201_initial_schema.sql",
      "table": "users",
      "timestamp": "2024-02-01T10:00:00Z",
      "content": "CREATE TABLE users (...);"
    },
    {
      "fileName": "20240202_add_posts.sql",
      "table": "posts",
      "timestamp": "2024-02-02T10:00:00Z",
      "content": "CREATE TABLE posts (...);"
    }
  ]
}
```

---

### 향상된 도구 (Tier 2)

#### 9. project_structure

프로젝트의 파일 트리 구조를 가져옵니다.

**설명**: 디렉토리와 파일의 계층 구조를 보여줍니다.

**사용법**:
```
프로젝트 구조를 보여줘
```

```
lib 디렉토리 안에 뭐가 있어?
```

**파라미터**:
- `directory` (선택): 스캔할 디렉토리
- `depth` (선택): 최대 깊이 (기본값: 3)
- `include_files` (선택): 파일 포함 (기본값: true)
- `exclude_patterns` (선택): 제외할 패턴

---

#### 10. find_files

패턴으로 파일을 찾습니다.

**설명**: Glob 패턴을 사용하여 파일을 검색합니다.

**사용법**:
```
모든 엔드포인트 파일을 찾아줘
```

```
*_test.dart 파일들을 찾아줘
```

**파라미터**:
- `pattern` (필수): Glob 패턴 (예: "*.dart", "**/*_test.dart")
- `path` (선택): 검색할 디렉토리
- `exclude_patterns` (선택): 제외할 패턴
- `max_results` (선택): 최대 결과 수 (기본값: 100)

---

#### 11. read_file

파일 내용을 읽습니다.

**설명**: 텍스트 파일의 내용을 읽어옵니다.

**사용법**:
```
greeting 엔드포인트 파일을 읽어줘
```

```
development.yaml 설정을 보여줘
```

**파라미터**:
- `file_path` (필수): 파일 경로
- `encoding` (선택): 파일 인코딩 (기본값: utf-8)

---

#### 12. search_code

소스 코드에서 텍스트 패턴을 검색합니다.

**설명**: 소스 코드 내에서 텍스트나 정규식을 검색합니다.

**사용법**:
```
Dart 파일에서 'hello'를 검색해줘
```

```
Future<> 반환 타입을 모두 찾아줘
```

**파라미터**:
- `query` (필수): 텍스트 또는 정규식 패턴
- `file_pattern` (선택): 파일 필터 (기본값: "*.dart")
- `path` (선택): 검색할 디렉토리
- `case_sensitive` (선택): 대소문자 구분 (기본값: false)
- `use_regex` (선택): 정규식 사용 (기본값: false)

---

#### 13. call_endpoint

엔드포인트 메서드를 호출하여 테스트합니다 (플레이스홀더).

**설명**: 엔드포인트 메서드를 테스트 호출합니다. (현재는 플레이스홀더)

**사용법**:
```
greeting 엔드포인트의 hello 메서드를 테스트해줘
```

**파라미터**:
- `endpoint` (필수): 엔드포인트 이름
- `method` (필수): 메서드 이름
- `parameters` (선택): 메서드 파라미터

---

#### 14. service_config

서비스 설정을 가져옵니다.

**설명**: 특정 서비스의 설정을 상세히 보여줍니다.

**사용법**:
```
Redis 설정을 보여줘
```

```
API 서버 설정이 어떻게 되어 있어?
```

**파라미터**:
- `service` (필수): "database", "redis", "apiServer", "insightsServer", "webServer"
- `environment` (선택): "development", "production", "staging", "test"

---

## 스킬 시스템

ServerPod Boost는 **8개의 내장 스킬**을 제공하여 AI가 도메인별 지식을 활용할 수 있게 합니다.

### 내장 스킬 목록

#### 1. Core (핵심)

**경로**: `.ai/skills/serverpod/core/`

ServerPod 개발의 기본 가이드라인과 모범 사례를 제공합니다.

**포함 내용**:
- 프로젝트 구조 이해
- 엔드포인트 기본 사항
- 모델 정의 기초
- 세션 관리
- 에러 처리

**활성화 시점**: ServerPod 프로젝트에서 작업할 때 자동으로 활성화됨

---

#### 2. Endpoints (엔드포인트)

**경로**: `.ai/skills/serverpod/endpoints/`

엔드포인트 개발 패턴과 모범 사례를 제공합니다.

**포함 내용**:
- 엔드포인트 생성 구조
- 메서드 시그니처 작성법
- 파라미터 검증
- 비동기 처리
- 예외 처리

**예시 코드**:
```dart
class UserEndpoint extends Endpoint {
  Future<User?> getUser(Session session, int userId) async {
    // 세션 로깅
    session.log('Fetching user: $userId');

    // 데이터베이스 조회
    final user = await User.db.findById(session, userId);

    return user;
  }

  Future<User> createUser(Session session, User user) async {
    // 검증
    if (user.email.isEmpty) {
      throw InvalidEmailException();
    }

    // 삽입
    await User.db.insertRow(session, user);

    return user;
  }
}
```

---

#### 3. Models (모델)

**경로**: `.ai/skills/serverpod/models/`

프로토콜 모델 정의와 사용법을 제공합니다.

**포함 내용**:
- `.spy.yaml` 파일 구조
- 모델 필드 타입
- 직렬화/역직렬화
- 중첩 모델
- enum 정의

**예시 코드**:
```yaml
# lib/src/models/user.spy.yaml
class: User
fields:
  email: String
  name: String?
  age: int
  createdAt: DateTime
  posts: List<Post>?  # 관계
```

```dart
// 생성된 코드 사용
final user = User(
  email: 'user@example.com',
  name: 'John Doe',
  age: 30,
  createdAt: DateTime.now(),
);
```

---

#### 4. Database (데이터베이스)

**경로**: `.ai/skills/serverpod/migrations/`

데이터베이스 설계와 마이그레이션을 다룹니다.

**포함 내용**:
- 마이그레이션 파일 작성
- 테이블 정의
- 인덱스 생성
- 관계 설정
- 쿼리 패턴

**예시 코드**:
```dart
// 조회
final users = await User.db.find(
  session,
  where: (t) => t.isActive.equals(true),
  orderBy: (t) => t.createdAt,
  orderDescending: true,
  limit: 10,
);

// 삽입
await User.db.insertRow(session, newUser);

// 수정
final user = await User.db.findById(session, userId);
user.name = 'Updated Name';
await User.db.updateRow(session, user);

// 삭제
await User.db.deleteRow(session, user);
```

---

#### 5. Testing (테스팅)

**경로**: `.ai/skills/serverpod/testing/`

테스트 작성 가이드라인을 제공합니다.

**포함 내용**:
- 단위 테스트 작성
- 통합 테스트
- 엔드포인트 테스트
- 모의(Mocking) 세션
- 테스트 데이터베이스 설정

**예시 코드**:
```dart
test('should create user', () async {
  // 세션 설정
  final session = await server.createTestSession();

  // 엔드포인트 호출
  final user = await userEndpoint.createUser(
    session,
    User(email: 'test@example.com', name: 'Test'),
  );

  // 검증
  expect(user.id, isNotNull);
  expect(user.email, equals('test@example.com'));
});
```

---

#### 6. Authentication (인증)

**경로**: `.ai/skills/serverpod/authentication/`

인증 구현 방법을 다룹니다.

**포함 내용**:
- ServerPod Auth 통합
- 사용자 로그인/로그아웃
- 토큰 관리
- 세션 관리
- 권한 검사

**예시 코드**:
```dart
class AuthEndpoint extends Endpoint {
  Future<String> signIn(Session session, String email, String password) async {
    // 사용자 찾기
    final user = await User.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );

    if (user == null) {
      throw InvalidCredentialsException();
    }

    // 비밀번호 검증
    if (!user.verifyPassword(password)) {
      throw InvalidCredentialsException();
    }

    // 토큰 생성
    final token = await createAuthToken(session, user.id);

    return token;
  }
}
```

---

#### 7. Webhooks (웹훅)

**경로**: `.ai/skills/serverpod/webhooks/`

웹훅 구현 패턴을 제공합니다.

**포함 내용**:
- 웹훅 엔드포인트 작성
- 서명 검증
- 재시도 로직
- 비동기 처리

---

#### 8. Redis (레디스)

**경로**: `.ai/skills/serverpod/redis/`

Redis 캐싱과 세션 관리를 다룹니다.

**포함 내용**:
- 캐싱 패턴
- 세션 저장소
- Pub/Sub
- 큐 구현

**예시 코드**:
```dart
// 캐시에 저장
await session.redis.put('user:$userId', user.toJson());

// 캐시에서 읽기
final cached = await session.redis.get('user:$userId');
if (cached != null) {
  return User.fromJson(jsonDecode(cached));
}

// 캐시 만료 설정
await session.redis.putWithExpiry('user:$userId', data, Duration(minutes: 5));
```

---

### 리모트 스킬

GitHub 리포지토리에서 스킬을 추가할 수 있습니다.

**스킬 추가**:
```bash
# 리포지토리의 모든 스킬 목록 보기
boost skill:add username/repo

# 특정 스킬 추가
boost skill:add username/repo skill-name
```

**스킬 제거**:
```bash
boost skill:remove skill-name
```

**스킬 목록**:
```bash
boost skill:list
```

---

## CLI 명령어

ServerPod Boost는 강력한 CLI를 제공합니다.

### boost install

ServerPod Boost MCP 서버용 래퍼 스크립트를 생성합니다.

```bash
dart run serverpod_boost:install
```

이 명령어가 프로젝트 루트에 `run-boost.sh` 스크립트를 생성합니다. 스크립트는:
- 자동으로 프로젝트 구조를 감지합니다
- `server` 디렉토리로 자동 이동합니다
- MCP 서버를 올바른 경로에서 실행합니다

래퍼 스크립트를 생성한 후에는 Claude Desktop 설정에서 이 스크립트 경로를 사용하세요:

```json
{
  "mcpServers": {
    "serverpod-boost": {
      "command": "/path/to/your/project/run-boost.sh",
      "args": []
    }
  }
}
```

---

### boost skill:list

사용 가능한 모든 스킬을 나열합니다.

```bash
boost skill:list
```

**출력 예시**:
```
Available Skills:
├── core (v1.0.0)
│   └── Core ServerPod development guidelines
├── endpoints (v1.0.0)
│   └── Endpoint development patterns
├── models (v1.0.0)
│   └── Protocol model definitions
├── migrations (v1.0.0)
│   └── Database migration patterns
├── testing (v1.0.0)
│   └── Testing best practices
├── authentication (v1.0.0)
│   └── Authentication implementation
├── webhooks (v1.0.0)
│   └── Webhook patterns
└── redis (v1.0.0)
    └── Redis caching and sessions
```

---

### boost skill:show

특정 스킬의 상세 정보를 보여줍니다.

```bash
boost skill:show endpoints
```

**출력 예시**:
```
Skill: endpoints
Version: 1.0.0
Description: ServerPod endpoint development patterns and best practices

Tags:
  - serverpod
  - endpoints
  - api

Files:
  - SKILL.md.mustache
  - meta.yaml
  - examples/basic_endpoint.dart
  - examples/advanced_endpoint.dart

Examples:
  1. Basic endpoint creation
  2. Parameter validation
  3. Error handling
  4. Async patterns
```

---

### boost skill:render

스킬 템플릿을 렌더링합니다.

```bash
# 표준 출력으로
boost skill:render create-endpoint

# 파일로 저장
boost skill:render create-endpoint output.md
```

---

### boost skill:add

GitHub 리포지토리에서 스킬을 추가합니다.

```bash
# 리포지토리의 모든 스킬 목록
boost skill:add username/serverpod-skills

# 특정 스킬 추가
boost skill:add username/serverpod-skills pagination
```

---

### boost skill:remove

로컬 스킬을 제거합니다.

```bash
boost skill:remove my-custom-skill
```

강제 제거:
```bash
boost skill:remove my-custom-skill --force
```

---

### boost skill:show

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `SERVERPOD_BOOST_LOG_LEVEL` | 로그 레벨 | info |
| `SERVERPOD_BOOST_NO_COLOR` | 색상 출력 비활성화 | false |
| `SERVERPOD_BOOST_SKILLS_PATH` | 스킬 디렉토리 경로 | .ai/skills |

---

## 일반적인 워크플로우

### 워크플로우 1: 새 엔드포인트 생성

**목표**: 사용자 관리 엔드포인트 생성

```
[사용자]
이 프로젝트에 어떤 엔드포인트가 있어?
```

```
[Claude + Boost]
application_info 도구로 프로젝트 분석
list_endpoints 도구로 기존 엔드포인트 나열
```

```
[사용자]
userEndpoint를 보여줘
```

```
[Claude + Boost]
endpoint_methods 도구로 userEndpoint 분석
```

```
[사용자]
비슷한 스타일로 Post 모델과 PostEndpoint를 만들어줘
```

```
[Claude + Boost]
model_inspector 도구로 User 모델 분석
list_models 도구로 기존 모델 확인
스킬: models, endpoints 활성화
프로젝트 스타일에 맞춰 코드 생성
```

**결과**:
```dart
// lib/src/models/post.dart
class Post extends Model {
  // ... 자동 생성된 코드
}

// lib/src/endpoints/post_endpoint.dart
class PostEndpoint extends Endpoint {
  Future<Post?> getPost(Session session, int postId) async {
    // 구현
  }

  Future<List<Post>> listPosts(Session session, {int limit = 10}) async {
    // 구현
  }

  Future<Post> createPost(Session session, Post post) async {
    // 구현
  }
}
```

---

### 워크플로우 2: 데이터베이스 이해하기

**목표**: 데이터베이스 구조 파악

```
[사용자]
데이터베이스 스키마를 보여줘
```

```
[Claude + Boost]
database_schema 도구로 모든 테이블 조회
```

```
[사용자]
users 테이블의 인덱스는 어떻게 되어 있어?
```

```
[Claude + Boost]
database_schema 도구에 table_filter: "users" 적용
인덱스 정보 추출
```

```
[사용자]
최근 마이그레이션을 보여줘
```

```
[Claude + Boost]
migration_scanner 도구로 마이그레이션 히스토리 조회
```

---

### 워크플로우 3: 기존 코드 이해하기

**목표**: 복잡한 엔드포인트 로직 이해

```
[사용자]
authEndpoint의 signIn 메서드가 어떻게 동작해?
```

```
[Claude + Boost]
1. endpoint_methods 도구로 시그니처 확인
2. read_file 도구로 소스 코드 읽기
3. search_code 도구로 관련 코드 검색
4. 스킬: authentication 활성화
```

```
[사용자]
비밀번호 검증 로직을 찾아줘
```

```
[Claude + Boost]
search_code 도구로 "verifyPassword" 또는 "hash" 검색
관련 메서드와 호출 위치 파악
```

---

### 워크플로우 4: 테스트 작성

**목표**: 엔드포인트 테스트 작성

```
[사용자]
PostEndpoint의 테스트를 작성해줘
```

```
[Claude + Boost]
1. endpoint_methods 도구로 메서드 목록 확인
2. find_files 도구로 기존 테스트 파일 찾기
3. read_file 도구로 테스트 예제 확인
4. 스킬: testing 활성화
5. 프로젝트 테스트 스타일에 맞춰 테스트 코드 생성
```

**결과**:
```dart
// test/endpoints/post_endpoint_test.dart
void main() {
  group('PostEndpoint', () {
    late ServerPod server;
    late PostEndpoint postEndpoint;

    setUpAll(() async {
      server = ServerPod(...);
      postEndpoint = PostEndpoint();
      await server.start();
    });

    test('should get post by id', () async {
      final session = await server.createTestSession();
      final post = await postEndpoint.getPost(session, 1);

      expect(post, isNotNull);
      expect(post!.id, equals(1));
    });

    test('should create post', () async {
      final session = await server.createTestSession();
      final newPost = Post(title: 'Test', content: 'Content');

      final created = await postEndpoint.createPost(session, newPost);

      expect(created.id, isNotNull);
    });
  });
}
```

---

### 워크플로우 5: 디버깅

**목표**: 설정 문제 해결

```
[사용자]
개발 환경에서 Redis 연결이 안 돼
```

```
[Claude + Boost]
1. config_reader 도구로 development.yaml 확인
2. service_config 도구로 Redis 설정 상세 조회
3. search_code 도구로 Redis 사용 코드 검색
4. 문제점 식별 및 해결 방안 제시
```

```
[사용자]
사용자 인증이 실패해
```

```
[Claude + Boost]
1. endpoint_methods 도구로 authEndpoint 메서드 확인
2. read_file 도구로 인증 로직 분석
3. search_code 도구로 "signIn" 관련 코드 검색
4. database_schema 도구로 users 테이블 구조 확인
5. 버그 식별 및 수정 제안
```

---

## 트러블슈팅

### "유효한 ServerPod 프로젝트가 아닙니다"

**증상**:
```
Error: Not a valid ServerPod project!
```

**원인**: ServerPod 프로젝트 구조가 올바르지 않음

**해결책**:

1. 프로젝트 구조 확인:
```bash
ls -la
```

다음이 있어야 합니다:
```
project_root/
├── project_server/     # 필수
│   ├── lib/
│   │   ├── server.dart
│   │   └── src/
│   ├── config/
│   └── pubspec.yaml
├── project_client/     # 선택사항
└── project_flutter/    # 선택사항
```

2. 수동으로 프로젝트 루트 지정:
```bash
dart run bin/boost.dart --path=/path/to/project
```

3. server.dart 파일 확인:
```bash
ls project_server/lib/server.dart
```

---

### 엔드포인트를 찾을 수 없음

**증상**:
```
No endpoints found
```

**원인**: 엔드포인트 파일이 잘못된 위치에 있거나 네이밍이 틀림

**해결책**:

1. 파일 위치 확인:
```bash
ls project_server/lib/src/endpoints/
```

2. 파일 네이밍 확인:
- `_endpoint.dart`로 끝나야 함 (예: `user_endpoint.dart`)
- `generated/` 디렉토리 내부에 있으면 안 됨

3. 올바른 구조:
```
project_server/lib/src/
├── endpoints/
│   ├── user_endpoint.dart      ✓
│   ├── auth_endpoint.dart      ✓
│   └── generated/
│       └── protocol.dart       ✓ (자동 생성됨)
└── models/
    ├── user.dart               ✓
    └── user.spy.yaml          ✓
```

---

### MCP 도구가 응답하지 않음

**증상**: Claude가 도구 호출 후 응답이 없음

**원인**: MCP 서버가 실행 중이 아님

**해결책**:

1. Claude Desktop 설정 확인:
```json
{
  "mcpServers": {
    "serverpod-boost": {
      "command": "/absolute/path/to/your/project/run-boost.sh",
      "args": []
    }
  }
}
```

2. 경로가 절대 경로인지 확인:
```json
"command": "/Users/username/projects/my_project/run-boost.sh"  ✓
"command": "~/projects/my_project/run-boost.sh"               ✗
```

3. 래퍼 스크립트에 실행 권한이 있는지 확인:
```bash
chmod +x /path/to/your/project/run-boost.sh
```

4. 래퍼 스크립트가 존재하는지 확인:
```bash
ls -la /path/to/your/project/run-boost.sh
```

스크립트가 없으면 다시 설치:
```bash
cd /path/to/your/project
dart run serverpod_boost:install
```

5. 상세 로깅으로 디버깅:
```bash
export SERVERPOD_BOOST_LOG_LEVEL=debug
```

4. Claude Desktop 재시작:
- 완전히 종료 (Cmd+Q 또는 종료 메뉴)
- 다시 시작

---

### 모델을 찾을 수 없음

**증상**:
```
No models found in project
```

**원인**: `.spy.yaml` 파일이 없거나 잘못된 위치

**해결책**:

1. 모델 파일 확인:
```bash
find project_server -name "*.spy.yaml"
```

2. 파일 구조 확인:
```
project_server/lib/src/models/
├── user.dart           # Dart 모델 클래스
├── user.spy.yaml      # YAML 정의 (필수)
├── post.dart
└── post.spy.yaml      # YAML 정의 (필수)
```

3. YAML 파일 형식 확인:
```yaml
# user.spy.yaml
class: User
fields:
  email: String
  name: String?
  age: int
```

---

### 마이그레이션을 찾을 수 없음

**증상**:
```
No migrations found
```

**해결책**:

1. 마이그레이션 디렉토리 확인:
```bash
ls project_server/migrations/
```

2. 파일 네이밍 확인:
```
20240201_create_users.sql    ✓
20240202_add_posts.sql       ✓
migration.sql                ✗ (타임스탬프 필요)
```

---

### 권한 문제

**증상**:
```
Permission denied
```

**해결책**:

1. 실행 권한 추가:
```bash
chmod +x bin/boost.dart
```

2. pubspec.lock 확인:
```bash
cd .ai/boost
dart pub get
```

---

### 버전 호환성 문제

**증상**: 이상한 동작이나 오류

**해결책**:

1. ServerPod 버전 확인:
```bash
grep 'serverpod:' project_server/pubspec.yaml
```

2. Dart 버전 확인:
```bash
dart --version
```

**요구사항**:
- ServerPod: 3.2.3+
- Dart: 3.8.0+

3. 업그레이드:
```bash
# ServerPod 업그레이드
dart pub upgrade serverpod

# Dart 업그레이드 (SDK 다운로드 페이지 참조)
```

---

### 로그 확인

상세 로깅을 활성화하여 문제를 진단하세요:

```bash
# 환경 변수 설정
export SERVERPOD_BOOST_LOG_LEVEL=debug

# MCP 서버 실행
dart run bin/boost.dart
```

**로그 예시**:
```
[INFO] ServerPod Boost v0.1.0
[INFO] Project: /path/to/project
[INFO] Server: /path/to/project/project_server
[INFO] Tools: 14
[INFO] MCP server ready, listening for requests...
[DEBUG] Detected 5 endpoints
[DEBUG] Loaded 12 models
[DEBUG] Parsed 8 migration files
```

---

## 추가 리소스

### 공식 문서

- [ServerPod 공식 문서](https://docs.serverpod.dev)
- [MCP 프로토콜 사양](https://modelcontextprotocol.io)
- [Laravel Boost](https://github.com/joelbutcher/laravel Boost) (영감 원천)

### 커뮤니티

- [ServerPad Discord](https://discord.gg/serverpod)
- [GitHub Issues](https://github.com/serverpod/serverpod/issues)

### 관련 프로젝트

| 프로젝트 | 설명 |
|---------|------|
| **Laravel Boost** | PHP Laravel을 위한 원본 프로젝트 |
| **ServerPod** | Dart 백엔드 프레임워크 |
| **Claude Code** | Anthropic의 AI IDE |

---

## 변경 로그

### v0.1.0 (2026-02-04)

**추가됨**:
- ✨ JSON-RPC 2.0 over stdio MCP 서버 구현
- ✨ 14개의 내장 도구
- ✨ ServerPod v3 모노레po 프로젝트 루트 감지
- ✨ .spy.yaml 모델 정의용 YAML 파서
- ✨ 엔드포인트용 메서드 시그니처 파서
- ✨ 중앙 집중식 프로젝트 접근용 서비스 로케이터
- ✨ MCP 프로토콜 리소스 및 프롬프트 지원
- ✨ 색상 출력이 포함된 포괄적 로깅
- ✨ Pilly 프로젝트에 대한 통합 테스트
- ✨ 8개의 내장 스킬 (core, endpoints, models, migrations, testing, authentication, webhooks, redis)
- ✨ 리모트 스킬 지원 (GitHub 리포지토리)
- ✨ 대화형 설치 CLI
- ✨ AGENTS.md/CLAUDE.md 스마트 병합

**변경됨**:
- 🔄 초기 릴리스

---

## 라이선스

MIT License - [LICENSE](../LICENSE) 파일을 참조하세요.

---

## 기여

기여를 환영합니다! [CONTRIBUTING.md](../CONTRIBUTING.md)를 참조하세요.

---

**ServerPod 커뮤니티를 위해 ❤️로 만들었습니다**
