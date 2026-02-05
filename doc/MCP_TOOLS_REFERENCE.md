# ServerPod Boost MCP 도구 레퍼런스

이 문서는 ServerPod Boost가 제공하는 14개의 MCP(Model Context Protocol) 도구에 대한 상세 레퍼런스입니다. AI 어시스턴트(Claude Code, OpenCode, Cursor 등)가 이 도구들을 사용하여 ServerPod 프로젝트를 분석하고 이해합니다.

## 목차

1. [개요](#개요)
2. [Tier 1: 필수 도구 (8개)](#tier-1-필수-도구)
3. [Tier 2: 향상된 도구 (6개)](#tier-2-향상된-도구)
4. [모범 사례](#모범-사례)
5. [예제 워크플로우](#예제-워크플로우)

---

## 개요

### 도구 계층 구조

ServerPod Boost는 14개의 MCP 도구를 두 개의 계층으로 제공합니다:

| 계층 | 도구 수 | 목적 | 사용 빈도 |
|------|---------|------|----------|
| **Tier 1: 필수 도구** | 8개 | 프로젝트 핵심 정보 획득 | 매우 높음 |
| **Tier 2: 향상된 도구** | 6개 | 고급 분석 및 실행 | 중간 |

### 도구 분류

```
ServerPod Boost MCP Tools
├── Tier 1: Essential (필수)
│   ├── application_info      - 전체 프로젝트 개요
│   ├── list_endpoints        - 엔드포인트 목록
│   ├── endpoint_methods      - 엔드포인트 메서드 상세
│   ├── list_models           - 모델 목록
│   ├── model_inspector       - 모델 상세 정보
│   ├── config_reader         - 설정 파일 읽기
│   ├── database_schema       - 데이터베이스 스키마
│   └── migration_scanner     - 마이그레이션 파일 스캔
│
└── Tier 2: Enhanced (향상)
    ├── project_structure     - 프로젝트 파일 구조
    ├── find_files            - 파일 검색
    ├── read_file             - 파일 내용 읽기
    ├── search_code           - 코드 검색
    ├── call_endpoint         - 엔드포인트 호출 (플레이스홀더)
    └── service_config        - 서비스별 설정
```

---

## Tier 1: 필수 도구

필수 도구들은 프로젝트의 핵심 정보를 빠르게 파악하는 데 사용됩니다. AI 어시스턴트는 대화 시작 시 이 도구들을 먼저 호출하여 프로젝트를 이해합니다.

### 1. application_info

전체 ServerPod 애플리케이션에 대한 포괄적인 정보를 제공합니다.

#### 설명
프로젝트의 모든 주요 정보를 한 번에 반환하여, AI 어시스턴트가 프로젝트 전체를 빠르게 이해할 수 있게 합니다.

#### 사용 시점
- 새로운 대화의 시작
- 프로젝트 구조 파악 필요 시
- 전체 개요 요청 시

#### 파라미터
이 도구는 파라미터가 없습니다.

#### 반환 값 구조
```json
{
  "project": {
    "root": "string",      // 프로젝트 루트 경로
    "server": "string",    // server 패키지 경로
    "client": "string",    // client 패키지 경로
    "flutter": "string",   // flutter 패키지 경로
    "config": "string",    // config 디렉토리 경로
    "migrations": "string" // migrations 디렉토리 경로
  },
  "versions": {
    "dart": "string",      // Dart SDK 버전
    "serverpod": "string"  // ServerPod 버전
  },
  "database": {            // 데이터베이스 설정
    "host": "string",
    "port": number,
    "name": "string",
    "user": "string",
    "normalized": true
  },
  "endpoints": {           // 모든 엔드포인트
    "endpointName": {
      "file": "string",
      "methods": ["string"] // 메서드 시그니처 목록
    }
  },
  "models": [              // 모든 모델
    {
      "className": "string",
      "namespace": "string",
      "fields": [
        {
          "name": "string",
          "type": "string"
        }
      ]
    }
  ],
  "endpointCount": number,
  "modelCount": number
}
```

#### 예제 프롬프트
```
"프로젝트의 전체 개요를 보여주세요."
```

#### 예제 응답
```json
{
  "project": {
    "root": "/myproject/serverpod_boost",
    "server": "/myproject/serverpod_boost/serverpod_boost_server",
    "client": "/myproject/serverpod_boost/client",
    "flutter": null,
    "config": "/myproject/serverpod_boost/config",
    "migrations": "/myproject/serverpod_boost/serverpod_boost_server/migrations"
  },
  "versions": {
    "dart": "3.6.0",
    "serverpod": "2.2.0"
  },
  "database": {
    "host": "localhost",
    "port": 8090,
    "name": "mydb",
    "user": "postgres",
    "normalized": true
  },
  "endpoints": {
    "greeting": {
      "file": "/path/to/greeting_endpoint.dart",
      "methods": ["Future<String> hello(Session session, String name)"]
    }
  },
  "models": [
    {
      "className": "Greeting",
      "namespace": "greetings",
      "fields": [
        {"name": "id", "type": "int"},
        {"name": "message", "type": "String"}
      ]
    }
  ],
  "endpointCount": 1,
  "modelCount": 1
}
```

#### 관련 도구
- `list_endpoints` - 엔드포인트만 상세 조회
- `list_models` - 모델만 상세 조회
- `config_reader` - 설정 상세 조회

---

### 2. list_endpoints

프로젝트의 모든 엔드포인트를 나열합니다.

#### 설명
모든 엔드포인트 파일을 찾아서 엔드포인트 이름, 파일 경로, 메서드 수를 반환합니다. 필터를 사용하여 특정 엔드포인트만 검색할 수 있습니다.

#### 사용 시점
- 특정 엔드포인트 찾기
- 전체 엔드포인트 구조 파악
- 엔드포인트 이름 검색

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `filter` | string | 아니오 | 엔드포인트 이름 필터 (예: "user", "auth") |

#### 반환 값 구조
```json
{
  "endpoints": [
    {
      "name": "string",           // 엔드포인트 이름
      "file": "string",           // 파일 경로
      "methodCount": number,      // 메서드 수
      "methods": [                // 메서드 목록
        {
          "name": "string",       // 메서드 이름
          "returnType": "string", // 반환 타입
          "parameters": [         // 파라미터 목록
            {
              "type": "string",
              "name": "string"
            }
          ]
        }
      ]
    }
  ],
  "count": number
}
```

#### 예제 프롬프트
```
"사용자 관련 엔드포인트를 모두 찾아주세요."
"filter": "user"
```

#### 예제 응답
```json
{
  "endpoints": [
    {
      "name": "user",
      "file": "/server/src/endpoints/user_endpoint.dart",
      "methodCount": 5,
      "methods": [
        {
          "name": "createUser",
          "returnType": "Future<User?>",
          "parameters": [
            {"type": "Session", "name": "session"},
            {"type": "String", "name": "email"},
            {"type": "String", "name": "password"}
          ]
        },
        {
          "name": "getUser",
          "returnType": "Future<User?>",
          "parameters": [
            {"type": "Session", "name": "session"},
            {"type": "int", "name": "id"}
          ]
        }
      ]
    }
  ],
  "count": 1
}
```

#### 관련 도구
- `endpoint_methods` - 특정 엔드포인트의 상세 메서드 정보
- `application_info` - 전체 프로젝트 개요

---

### 3. endpoint_methods

특정 엔드포인트의 메서드 상세 정보를 반환합니다.

#### 설명
지정된 엔드포인트의 모든 메서드를 분석하여 파라미터 타입, 반환 타입, 전체 시그니처를 포함한 상세 정보를 제공합니다.

#### 사용 시점
- 특정 엔드포인트의 API 이해 필요 시
- 메서드 파라미터 타입 확인 필요 시
- 클라이언트 코드 작성 전 API 스펙 확인 시

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `endpoint_name` | string | 예 | 엔드포인트 이름 (예: "greeting", "user") |

#### 반환 값 구조
```json
{
  "endpoint": "string",
  "file": "string",
  "methods": [
    {
      "name": "string",              // 메서드 이름
      "returnType": "string",        // 반환 타입
      "signature": "string",         // 전체 시그니처
      "parameters": [                // 모든 파라미터
        {
          "type": "string",
          "name": "string",
          "isSession": boolean
        }
      ],
      "userParameters": [            // 사용자 파라미터만 (Session 제외)
        {
          "type": "string",
          "name": "string"
        }
      ]
    }
  ],
  "methodCount": number
}
```

#### 예제 프롬프트
```
"greeting 엔드포인트의 모든 메서드를 보여주세요."
"endpoint_name": "greeting"
```

#### 예제 응답
```json
{
  "endpoint": "greeting",
  "file": "/server/src/endpoints/greeting_endpoint.dart",
  "methods": [
    {
      "name": "hello",
      "returnType": "Future<String>",
      "signature": "Future<String> hello(Session session, String name)",
      "parameters": [
        {"type": "Session", "name": "session", "isSession": true},
        {"type": "String", "name": "name", "isSession": false}
      ],
      "userParameters": [
        {"type": "String", "name": "name"}
      ]
    },
    {
      "name": "createGreeting",
      "returnType": "Future<Greeting>",
      "signature": "Future<Greeting> createGreeting(Session session, String message)",
      "parameters": [
        {"type": "Session", "name": "session", "isSession": true},
        {"type": "String", "name": "message", "isSession": false}
      ],
      "userParameters": [
        {"type": "String", "name": "message"}
      ]
    }
  ],
  "methodCount": 2
}
```

#### 관련 도구
- `list_endpoints` - 모든 엔드포인트 목록
- `call_endpoint` - 엔드포인트 메서드 호출 (플레이스홀더)

---

### 4. list_models

프로젝트의 모든 프로토콜 모델을 나열합니다.

#### 설명
`.spy.yaml` 파일에서 정의된 모든 프로토콜 모델을 찾아서 클래스 이름, 네임스페이스, 필드 정보를 반환합니다.

#### 사용 시점
- 데이터 모델 구조 파악
- 모델 필드 확인
- 필터를 통한 특정 모델 검색

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `filter` | string | 아니오 | 모델 이름 필터 (예: "User", "Order") |

#### 반환 값 구조
```json
{
  "models": [
    {
      "className": "string",       // 모델 클래스 이름
      "namespace": "string",       // 네임스페이스
      "fieldCount": number,        // 필드 수
      "fields": [                  // 필드 목록
        {
          "name": "string",        // 필드 이름
          "type": "string",        // YAML 타입
          "dartType": "string",    // Dart 타입
          "isOptional": boolean    // null 허용 여부
        }
      ],
      "sourceFile": "string"       // 소스 파일 경로
    }
  ],
  "count": number
}
```

#### 예제 프롬프트
```
"사용자 관련 모델을 모두 찾아주세요."
"filter": "User"
```

#### 예제 응답
```json
{
  "models": [
    {
      "className": "User",
      "namespace": "users",
      "fieldCount": 6,
      "fields": [
        {"name": "id", "type": "int", "dartType": "int", "isOptional": false},
        {"name": "email", "type": "String", "dartType": "String", "isOptional": false},
        {"name": "name", "type": "String", "dartType": "String", "isOptional": true},
        {"name": "createdAt", "type": "DateTime", "dartType": "DateTime", "isOptional": false},
        {"name": "updatedAt", "type": "DateTime", "dartType": "DateTime", "isOptional": true},
        {"name": "profileImage", "type": "String?", "dartType": "String?", "isOptional": true}
      ],
      "sourceFile": "/server/src/models/users.spy.yaml"
    }
  ],
  "count": 1
}
```

#### 관련 도구
- `model_inspector` - 특정 모델의 상세 정보
- `application_info` - 전체 모델 개요

---

### 5. model_inspector

특정 프로토콜 모델의 상세 필드 정보를 반환합니다.

#### 설명
지정된 모델의 모든 필드에 대한 상세 정보를 제공합니다. 스칼라 타입, 관계 타입 등을 식별하여 더 나은 컨텍스트를 제공합니다.

#### 사용 시점
- 모델의 정확한 필드 타입 확인 필요 시
- 관계 매핑 이해 필요 시
- 데이터베이스 스키마와 모델 매핑 확인 시

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `model_name` | string | 예 | 모델 클래스 이름 (예: "User", "Greeting") |

#### 반환 값 구조
```json
{
  "className": "string",
  "namespace": "string",
  "sourceFile": "string",
  "fieldCount": number,
  "fields": [
    {
      "name": "string",          // 필드 이름
      "type": "string",          // YAML 타입
      "dartType": "string",      // Dart 타입
      "isOptional": boolean,     // null 허용 여부
      "isScalar": boolean,       // 스칼라 타입 여부
      "isRelation": boolean      // 관계 타입 여부
    }
  ]
}
```

#### 예제 프롬프트
```
"User 모델의 상세 정보를 보여주세요."
"model_name": "User"
```

#### 예제 응답
```json
{
  "className": "User",
  "namespace": "users",
  "sourceFile": "/server/src/models/users.spy.yaml",
  "fieldCount": 6,
  "fields": [
    {
      "name": "id",
      "type": "int",
      "dartType": "int",
      "isOptional": false,
      "isScalar": true,
      "isRelation": false
    },
    {
      "name": "email",
      "type": "String",
      "dartType": "String",
      "isOptional": false,
      "isScalar": true,
      "isRelation": false
    },
    {
      "name": "profile",
      "type": "UserProfile",
      "dartType": "UserProfile",
      "isOptional": true,
      "isScalar": false,
      "isRelation": true
    },
    {
      "name": "orders",
      "type": "List<Order>",
      "dartType": "List<Order>",
      "isOptional": false,
      "isScalar": false,
      "isRelation": false
    }
  ]
}
```

#### 관련 도구
- `list_models` - 모든 모델 목록
- `database_schema` - 데이터베이스 테이블 스키마

---

### 6. config_reader

ServerPod YAML 설정 파일을 읽습니다.

#### 설명
지정된 환경(development, production 등)의 설정 파일을 읽어서 파싱된 YAML을 JSON으로 반환합니다. 특정 섹션만 읽을 수도 있습니다.

#### 사용 시점
- 데이터베이스 설정 확인
- Redis 설정 확인
- 서비스 포트 및 설정 확인
- 환경별 설정 비교

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `environment` | string | 아니오 | 환경 (development/production/staging/test, 기본값: development) |
| `section` | string | 아니오 | 특정 설정 섹션 (예: "database", "redis") |

#### 반환 값 구조
```json
{
  "environment": "string",
  "file": "string",          // 설정 파일 경로
  "config": {                // 파싱된 YAML
    "section": "value"
  }
}
```

또는 섹션 지정 시:
```json
{
  "environment": "string",
  "section": "string",
  "config": {                // 해당 섹션만
    "key": "value"
  }
}
```

#### 예제 프롬프트
```
"개발 환경의 데이터베이스 설정을 보여주세요."
"environment": "development",
"section": "database"
```

#### 예제 응답
```json
{
  "environment": "development",
  "section": "database",
  "config": {
    "host": "localhost",
    "port": 8090,
    "name": "myapp_dev",
    "user": "postgres",
    "password": "***"
  }
}
```

#### 관련 도구
- `service_config` - 서비스별 설정 전용 도구
- `application_info` - 기본 데이터베이스 정보

---

### 7. database_schema

마이그레이션 파일에서 데이터베이스 스키마 정보를 추출합니다.

#### 설명
실제 데이터베이스에 연결하지 않고, 마이그레이션 파일을 파싱하여 테이블 정의, 컬럼, 인덱스, 외래 키 정보를 추출합니다.

#### 사용 시점
- 데이터베이스 구조 파악
- 테이블 스키마 확인
- 인덱스 및 제약조건 확인

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `table_filter` | string | 아니오 | 테이블 이름 필터 |

#### 반환 값 구조
```json
{
  "tables": [
    {
      "name": "string",           // 테이블 이름
      "columns": [                // 컬럼 목록
        {
          "name": "string",       // 컬럼 이름
          "type": "string",       // 컬럼 타입
          "nullable": boolean,    // null 허용 여부
          "primaryKey": boolean   // 기본 키 여부
        }
      ],
      "columnCount": number,
      "indexes": [                // 인덱스 목록 (있는 경우)
        {
          "name": "string",
          "columns": ["string"],
          "unique": boolean
        }
      ]
    }
  ],
  "tableCount": number,
  "migrationCount": number        // 마이그레이션 파일 수
}
```

#### 예제 프롬프트
```
"users 테이블의 스키마를 보여주세요."
"table_filter": "users"
```

#### 예제 응답
```json
{
  "tables": [
    {
      "name": "users",
      "columns": [
        {"name": "id", "type": "serial", "nullable": false, "primaryKey": true},
        {"name": "email", "type": "varchar", "nullable": false, "primaryKey": false},
        {"name": "name", "type": "varchar", "nullable": true, "primaryKey": false},
        {"name": "created_at", "type": "timestamp", "nullable": false, "primaryKey": false}
      ],
      "columnCount": 4,
      "indexes": [
        {
          "name": "users_email_idx",
          "columns": ["email"],
          "unique": true
        }
      ]
    }
  ],
  "tableCount": 1,
  "migrationCount": 3
}
```

#### 관련 도구
- `migration_scanner` - 마이그레이션 파일 목록
- `model_inspector` - 모델과의 매핑 확인

---

### 8. migration_scanner

모든 마이그레이션 파일을 나열합니다.

#### 설명
마이그레이션 파일 이름, 경로, 타임스탬프, 변경된 테이블 정보를 반환합니다. 필요한 경우 파일 내용을 포함할 수도 있습니다.

#### 사용 시점
- 데이터베이스 변경 내역 파악
- 마이그레이션 순서 확인
- 특정 테이블의 변경 이력 추적

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `table_filter` | string | 아니오 | 테이블 이름 필터 |
| `include_content` | boolean | 아니오 | 마이그레이션 파일 내용 포함 (기본값: false) |

#### 반환 값 구조
```json
{
  "migrations": [
    {
      "filename": "string",        // 파일명
      "path": "string",            // 전체 경로
      "table": "string",           // 관련 테이블 (추출된 경우)
      "modified": "string",        // 수정일 ISO 8601
      "size": number,              // 파일 크기 (bytes)
      "content": "string"          // 내용 (include_content=true时)
    }
  ],
  "count": number,
  "migrationsPath": "string"      // 마이그레이션 디렉토리 경로
}
```

#### 예제 프롬프트
```
"users 테이블의 모든 마이그레이션을 보여주세요."
"table_filter": "users"
```

#### 예제 응답
```json
{
  "migrations": [
    {
      "filename": "20240101000000_0000_initial.dart",
      "path": "/server/migrations/20240101000000_0000_initial.dart",
      "table": null,
      "modified": "2024-01-01T00:00:00.000Z",
      "size": 1024
    },
    {
      "filename": "20240102120000_0001_create_users_table.dart",
      "path": "/server/migrations/20240102120000_0001_create_users_table.dart",
      "table": "users",
      "modified": "2024-01-02T12:00:00.000Z",
      "size": 2048
    }
  ],
  "count": 2,
  "migrationsPath": "/server/migrations"
}
```

#### 관련 도구
- `database_schema` - 마이그레이션에서 추출한 스키마

---

## Tier 2: 향상된 도구

향상된 도구들은 더 깊은 분석과 고급 기능을 제공합니다.

### 9. project_structure

프로젝트의 파일 트리 구조를 반환합니다.

#### 설명
계층적인 파일 및 디렉토리 트리를 제공합니다. 깊이, 포함/제외 패턴 등을 지정하여 프로젝트 구조를 분석할 수 있습니다.

#### 사용 시점
- 프로젝트 조직 파악
- 파일 위치 찾기
- 프로젝트 구조 시각화

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `directory` | string | 아니오 | 스캔할 디렉토리 (프로젝트 루트 기준 상대 경로) |
| `depth` | integer | 아니오 | 최대 스캔 깊이 (기본값: 3) |
| `include_files` | boolean | 아니오 | 파일 포함 여부 (기본값: true) |
| `exclude_patterns` | array | 아니오 | 제외할 패턴 목록 (예: ["node_modules", ".git"]) |

#### 반환 값 구조
```json
{
  "root": {
    "name": "string",
    "path": "string",
    "type": "directory",  // 또는 "file"
    "size": number,        // 파일의 경우만
    "children": [          // 디렉토리의 경우
      {
        "name": "string",
        "path": "string",
        "type": "file"
      }
    ]
  },
  "path": "string",           // 스캔된 경로
  "relativePath": "string",   // 상대 경로
  "depth": number,
  "excludedPatterns": ["string"]
}
```

#### 예제 프롬프트
```
"server 디렉토리의 구조를 보여주세요 (2단계 깊이)."
"directory": "server",
"depth": 2
```

#### 예제 응답
```json
{
  "root": {
    "name": "server",
    "path": "/myproject/server",
    "type": "directory",
    "children": [
      {
        "name": "bin",
        "path": "/myproject/server/bin",
        "type": "directory",
        "children": [
          {"name": "main.dart", "path": "/myproject/server/bin/main.dart", "type": "file", "size": 1024}
        ]
      },
      {
        "name": "lib",
        "path": "/myproject/server/lib",
        "type": "directory",
        "children": [
          {"name": "src", "path": "...", "type": "directory", "children": []}
        ]
      }
    ]
  },
  "path": "/myproject/server",
  "relativePath": "server",
  "depth": 2,
  "excludedPatterns": ["node_modules", ".git", ".dart_tool"]
}
```

#### 관련 도구
- `find_files` - 특정 파일 검색
- `read_file` - 파일 내용 읽기

---

### 10. find_files

패턴으로 파일을 검색합니다.

#### 설명
glob 패턴을 사용하여 프로젝트에서 파일을 검색합니다. 유연한 패턴 매칭을 지원합니다.

#### 사용 시점
- 특정 파일 유형 찾기
- 파일 위치 검색
- 패턴 기반 파일 검색

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `pattern` | string | 예 | Glob 패턴 (예: "*.dart", "**/*_endpoint.dart") |
| `path` | string | 아니오 | 검색할 디렉토리 (프로젝트 루트 기준) |
| `exclude_patterns` | array | 아니오 | 제외할 패턴 목록 |
| `max_results` | integer | 아니오 | 최대 결과 수 (기본값: 100) |

#### 반환 값 구조
```json
{
  "files": [
    {
      "name": "string",           // 파일 이름
      "path": "string",           // 전체 경로
      "relativePath": "string",   // 프로젝트 루트 기준 상대 경로
      "size": number,             // 파일 크기
      "modified": "string"        // 수정일 ISO 8601
    }
  ],
  "count": number,
  "pattern": "string",
  "searchPath": "string",
  "maxResults": number,
  "truncated": boolean           // 결과가 잘렸는지 여부
}
```

#### 예제 프롬프트
```
"모든 엔드포인트 파일을 찾아주세요."
"pattern": "**/*_endpoint.dart"
```

#### 예제 응답
```json
{
  "files": [
    {
      "name": "greeting_endpoint.dart",
      "path": "/myproject/server/src/endpoints/greeting_endpoint.dart",
      "relativePath": "server/src/endpoints/greeting_endpoint.dart",
      "size": 2048,
      "modified": "2024-01-15T10:30:00.000Z"
    },
    {
      "name": "user_endpoint.dart",
      "path": "/myproject/server/src/endpoints/user_endpoint.dart",
      "relativePath": "server/src/endpoints/user_endpoint.dart",
      "size": 4096,
      "modified": "2024-01-16T14:20:00.000Z"
    }
  ],
  "count": 2,
  "pattern": "**/*_endpoint.dart",
  "searchPath": "/myproject",
  "maxResults": 100,
  "truncated": false
}
```

#### 관련 도구
- `project_structure` - 전체 구조 파악
- `read_file` - 파일 내용 읽기
- `search_code` - 파일 내용 검색

---

### 11. read_file

파일 내용을 읽습니다.

#### 설명
지정된 파일의 전체 내용을 반환합니다. 상대 경로 또는 절대 경로를 모두 지원합니다. 보안을 위해 프로젝트 내부 파일만 접근 가능합니다.

#### 사용 시점
- 소스 코드 확인
- 설정 파일 내용 확인
- 문서 파일 읽기

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `file_path` | string | 예 | 파일 경로 (상대 또는 절대) |
| `encoding` | string | 아니오 | 파일 인코딩 (기본값: utf-8) |

#### 반환 값 구조
```json
{
  "path": "string",              // 해결된 전체 경로
  "relativePath": "string",      // 프로젝트 루트 기준 상대 경로
  "content": "string",           // 파일 내용
  "size": number,                // 파일 크기
  "lineCount": number,           // 줄 수
  "encoding": "string",
  "hasCrLfLineEndings": boolean, // CRLF 줄바꿈 사용 여부
  "modified": "string"           // 수정일 ISO 8601
}
```

#### 예제 프롬프트
```
"pubspec.yaml 파일의 내용을 보여주세요."
"file_path": "server/pubspec.yaml"
```

#### 예제 응답
```json
{
  "path": "/myproject/server/pubspec.yaml",
  "relativePath": "server/pubspec.yaml",
  "content": "name: myapp_server\nversion: 1.0.0\n...",
  "size": 512,
  "lineCount": 25,
  "encoding": "utf-8",
  "hasCrLfLineEndings": false,
  "modified": "2024-01-10T09:00:00.000Z"
}
```

#### 관련 도구
- `find_files` - 파일 찾기
- `search_code` - 코드 검색

---

### 12. search_code

소스 코드에서 텍스트 패턴을 검색합니다.

#### 설명
파일 내용을 검색하여 일치하는 텍스트를 찾습니다. 정규표현식, 대소문자 구분 등의 옵션을 지원합니다.

#### 사용 시점
- 특정 코드 패턴 찾기
- 함수 사용 위치 찾기
- 변수/클래스 참조 찾기

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `query` | string | 예 | 검색할 텍스트 또는 정규표현식 |
| `file_pattern` | string | 아니오 | 파일 필터 패턴 (기본값: "*.dart") |
| `path` | string | 아니오 | 검색할 디렉토리 (프로젝트 루트 기준) |
| `case_sensitive` | boolean | 아니오 | 대소문자 구분 (기본값: false) |
| `use_regex` | boolean | 아니오 | 정규표현식 사용 (기본값: false) |
| `max_results` | integer | 아니오 | 최대 결과 수 (기본값: 50) |
| `context_lines` | integer | 아니오 | 컨텍스트 줄 수 (기본값: 0) |
| `exclude_patterns` | array | 아니오 | 제외할 파일 패턴 |

#### 반환 값 구조
```json
{
  "query": "string",
  "filePattern": "string",
  "searchPath": "string",
  "caseSensitive": boolean,
  "useRegex": boolean,
  "results": [
    {
      "filePath": "string",
      "relativePath": "string",
      "lineNumber": number,       // 1-based
      "line": "string",           // 줄 내용
      "start": number,            // 매치 시작 위치
      "end": number,              // 매치 끝 위치
      "match": "string"           // 매치된 텍스트
    }
  ],
  "resultCount": number,
  "filesSearched": number,
  "truncated": boolean
}
```

#### 예제 프롬프트
```
"'createUser' 함수를 찾아주세요."
"query": "createUser",
"file_pattern": "*.dart"
```

#### 예제 응답
```json
{
  "query": "createUser",
  "filePattern": "*.dart",
  "searchPath": "/myproject",
  "caseSensitive": false,
  "useRegex": false,
  "results": [
    {
      "filePath": "/myproject/server/src/endpoints/user_endpoint.dart",
      "relativePath": "server/src/endpoints/user_endpoint.dart",
      "lineNumber": 15,
      "line": "  Future<User?> createUser(Session session, String email, String password) {",
      "start": 13,
      "end": 23,
      "match": "createUser"
    },
    {
      "filePath": "/myproject/server/src/endpoints/user_endpoint_test.dart",
      "relativePath": "server/src/endpoints/user_endpoint_test.dart",
      "lineNumber": 8,
      "line": "    test('createUser should create a new user', () async {",
      "start": 10,
      "end": 20,
      "match": "createUser"
    }
  ],
  "resultCount": 2,
  "filesSearched": 15,
  "truncated": false
}
```

#### 관련 도구
- `find_files` - 파일 검색
- `read_file` - 파일 내용 읽기

---

### 13. call_endpoint

엔드포인트 메서드를 호출합니다 (플레이스홀더).

#### 설명
**현재는 플레이스홀더로만 구현되어 있습니다.** 향후 실제 엔드포인트 메서드를 호출하여 테스트할 수 있게 될 것입니다. 현재는 메서드 시그니처 정보만 반환합니다.

#### 사용 시점
- 현재 사용하지 않음 (플레이스홀더)
- 향후: 엔드포인트 메서드 테스트

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `endpoint` | string | 예 | 엔드포인트 이름 (예: "greeting") |
| `method` | string | 예 | 메서드 이름 (예: "hello") |
| `parameters` | object | 아니오 | 메서드 파라미터 (Session 제외) |

#### 반환 값 구조
```json
{
  "status": "placeholder",
  "message": "Endpoint calling not yet implemented",
  "endpoint": "string",
  "method": "string",
  "signature": "string",
  "returnType": "string",
  "parameters": object,
  "note": "This would call the endpoint method in a future implementation"
}
```

#### 예제 프롬프트
```
"greeting 엔드포인트의 hello 메서드를 호출해주세요."
"endpoint": "greeting",
"method": "hello",
"parameters": {"name": "World"}
```

#### 예제 응답
```json
{
  "status": "placeholder",
  "message": "Endpoint calling not yet implemented",
  "endpoint": "greeting",
  "method": "hello",
  "signature": "Future<String> hello(Session session, String name)",
  "returnType": "Future<String>",
  "parameters": {
    "name": "World"
  },
  "note": "This would call the endpoint method in a future implementation"
}
```

#### 관련 도구
- `endpoint_methods` - 메서드 시그니처 확인

---

### 14. service_config

서비스별 설정을 가져옵니다.

#### 설명
특정 서비스(Database, Redis, API Server 등)의 설정 정보를 반환합니다. `config_reader`와 비슷하지만 서비스별로 더 특화되어 있습니다.

#### 사용 시점
- 특정 서비스 설정 확인
- 서비스 연결 정보 확인
- 환경별 서비스 설정 비교

#### 파라미터
| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `service` | string | 예 | 서비스 유형 (database/redis/apiServer/insightsServer/webServer) |
| `environment` | string | 아니오 | 환경 (기본값: development) |

#### 반환 값 구조
```json
{
  "service": "string",
  "environment": "string",
  "config": {                 // 서비스 설정
    "key": "value"
  },
  "file": "string"            // 설정 파일 경로
}
```

#### 예제 프롬프트
```
"Redis 설정을 보여주세요."
"service": "redis",
"environment": "development"
```

#### 예제 응답
```json
{
  "service": "redis",
  "environment": "development",
  "config": {
    "host": "localhost",
    "port": 6379,
    "password": null
  },
  "file": "/myproject/config/development.yaml"
}
```

#### 관련 도구
- `config_reader` - 전체 설정 파일 읽기

---

## 모범 사례

### 1. 대화 시작 시

새로운 대화를 시작할 때는 먼저 `application_info`를 호출하여 프로젝트 전체를 이해하세요:

```javascript
// AI 어시스턴트가 먼저 실행해야 할 작업
application_info()
```

### 2. 계층적 접근

광범위한 도구에서 시작하여 점진적으로 구체화하세요:

```
application_info          // 전체 개요
    ↓
list_endpoints           // 모든 엔드포인트
    ↓
endpoint_methods         // 특정 엔드포인트 상세
```

### 3. 필터 활용

가능한 경우 필터를 사용하여 불필요한 데이터를 줄이세요:

```javascript
// 좋은 예
list_models({ filter: "User" })

// 덜 효율적
list_models() // 결과에서 수동으로 필터링
```

### 4. 관련 도구 확인

각 도구의 "관련 도구" 섹션을 참조하여 적절한 도구를 선택하세요.

### 5. 보안 고려사항

- 프로젝트 루트 외부의 파일은 접근할 수 없습니다
- 설정 파일의 민감 정보는 주의해서 처리하세요
- 마이그레이션 파일 내용은 필요한 경우에만 포함하세요

---

## 예제 워크플로우

### 워크플로우 1: 새로운 엔드포인트 추가

AI 어시스턴트가 새로운 엔드포인트를 추가하는 과정:

```
1. application_info()
   → 프로젝트 구조 파악

2. list_endpoints()
   → 기존 엔드포인트 확인

3. list_models()
   → 관련 모델 확인

4. model_inspector({ model_name: "User" })
   → 모델 필드 상세 확인

5. endpoint_methods({ endpoint_name: "user" })
   → 기존 메서드 패턴 학습

6. 코드 생성
   → 학습된 패턴 기반으로 새 엔드포인트 생성
```

### 워크플로우 2: 데이터베이스 스키마 변경

```
1. database_schema()
   → 현재 스키마 파악

2. migration_scanner()
   → 기존 마이그레이션 확인

3. model_inspector({ model_name: "TargetModel" })
   → 모델 정의 확인

4. read_file({ file_path: "server/migrations/latest.dart" })
   → 최신 마이그레이션 확인

5. 마이그레이션 생성
   → 새로운 마이그레이션 파일 생성
```

### 워크플로우 3: API 클라이언트 코드 생성

```
1. list_endpoints({ filter: "auth" })
   → 인증 엔드포인트 찾기

2. endpoint_methods({ endpoint_name: "auth" })
   → 모든 메서드 시그니처 확인

3. model_inspector({ model_name: "LoginRequest" })
   → 요청 모델 확인

4. model_inspector({ model_name: "LoginResponse" })
   → 응답 모델 확인

5. 클라이언트 코드 생성
   → 타입 안전한 API 클라이언트 메서드 생성
```

### 워크플로우 4: 버그 추적

```
1. search_code({
     query: "problematicFunction",
     file_pattern: "*.dart"
   })
   → 함수 사용 위치 찾기

2. read_file({ file_path: "found/file.dart" })
   → 코드 확인

3. endpoint_methods({ endpoint_name: "related" })
   → 관련 엔드포인트 시그니처 확인

4. database_schema({ table_filter: "related" })
   → 관련 테이블 스키마 확인

5. 버그 수정
   → 컨텍스트를 바탕으로 수정 제안
```

---

## 부록

### 도구 퀵 레퍼런스

| 도구 | 주요 용도 | 필수 파라미터 |
|------|----------|-------------|
| `application_info` | 프로젝트 전체 개요 | 없음 |
| `list_endpoints` | 모든 엔드포인트 목록 | 없음 |
| `endpoint_methods` | 엔드포인트 메서드 상세 | `endpoint_name` |
| `list_models` | 모든 모델 목록 | 없음 |
| `model_inspector` | 모델 상세 정보 | `model_name` |
| `config_reader` | 설정 파일 읽기 | 없음 |
| `database_schema` | 데이터베이스 스키마 | 없음 |
| `migration_scanner` | 마이그레이션 파일 목록 | 없음 |
| `project_structure` | 파일 트리 구조 | 없음 |
| `find_files` | 파일 검색 | `pattern` |
| `read_file` | 파일 내용 읽기 | `file_path` |
| `search_code` | 코드 검색 | `query` |
| `call_endpoint` | 엔드포인트 호출 (미구현) | `endpoint`, `method` |
| `service_config` | 서비스별 설정 | `service` |

### 지원되는 파일 패턴

도구에서 사용하는 glob 패턴 예시:

| 패턴 | 설명 | 예 |
|------|------|-----|
| `*.dart` | 현재 디렉토리의 Dart 파일 | `main.dart`, `app.dart` |
| `**/*_endpoint.dart` | 모든 엔드포인트 파일 | `src/endpoints/user_endpoint.dart` |
| `**/*.spy.yaml` | 모든 모델 정의 파일 | `models/user.spy.yaml` |
| `server/**/*.dart` | server 디렉토리의 모든 Dart 파일 | `server/src/main.dart` |
| `test/**/*_test.dart` | 모든 테스트 파일 | `test/user_test.dart` |

### 에러 처리

모든 도구는 다음과 같은 에러 형식을 반환할 수 있습니다:

```json
{
  "error": "에러 유형",
  "message": "상세 에러 메시지",
  "context": {}  // 추가 컨텍스트 (있는 경우)
}
```

일반적인 에러:
- `"Not a valid ServerPod project"` - ServerPod 프로젝트를 찾을 수 없음
- `"Endpoint not found"` - 지정된 엔드포인트를 찾을 수 없음
- `"Model not found"` - 지정된 모델을 찾을 수 없음
- `"File not found"` - 파일을 찾을 수 없음
- `"Access denied"` - 프로젝트 외부 파일 접근 시도

---

## 추가 정보

- **프로젝ct 저장소**: [https://github.com/your-org/serverpod_boost](https://github.com/your-org/serverpod_boost)
- **문서**: `/Users/musinsa/always_summer/serverpod_boost/doc/USER_GUIDE.md`
- **문제 보고**: GitHub Issues
- **기여 가이드**: CONTRIBUTING.md

---

**버전**: 1.0.0
**최종 업데이트**: 2025-02-05
**유지관리자**: ServerPod Boost 팀
