# Galaxy 스마트홈 구축 저장소

Galaxy Book6 Pro의 Home Assistant OS, SwitchBot Cloud, Hub Mini 및 Galaxy S23 Ultra용 설정과 검증 자료입니다. GitHub 저장소 변경만으로 실제 HA 설정이 바뀌지는 않습니다.

## 2026-09-28 구현 기준

- 실제 HA에 SwitchBot Cloud 기기 6개가 등록된 것을 확인했습니다. 09-27 읽기 전용 관찰에서는 커튼·CO₂ 센서가 unavailable이었습니다. 현재 상태는 다시 확인해야 합니다.
- Daikin의 두 수동 패널은 각각 전원 토글, 모드 다음 단계, 종료 예약 다음 단계입니다. ‘끄기’나 특정 온도에 대응하는 확정 신호가 없어 기존 에어컨 프리셋 스크립트는 명시적으로 차단했습니다.
- Comfee는 실기기 검증된 SwitchBot `Others` 리모컨의 `customize` 버튼 `POWER`, `Fan Speed 3`, `Timer`, `Mute`를 토글·순환으로 유지합니다. 약풍·강풍·2시간을 절대값으로 설정하지 않습니다. 실제 리모컨 ID는 HA의 `/config/secrets.yaml`에만 둡니다.
- 기본 장면은 커튼 준비 동작만, 환기는 기록·CO₂ 조건부 알림만 담당합니다. 조명·프로젝터·Station은 실제 통신 방식과 동작 검증 후 연결합니다.
- 수동 IR/HA 패널 명령은 `verified: false`가 기본값입니다. 실제 패널 의미·서비스·실기기 동작 확인 뒤 명령별로 켭니다. HA 응답은 명령 접수이며 물리 가전의 전원 피드백이 아닙니다.
- 자동화·음성·알림도 각각 관리자 helper로 명시적으로 활성화합니다. SwitchBot 앱의 독립 CO₂ 경보는 별도로 유지합니다.

## 주요 파일

| 파일 | 목적 |
| --- | --- |
| [적용 체크리스트](CHECKLIST.md) | 실제 HA 배포, 연결, 실기기 확인 순서 |
| [개선 계획](docs/스마트홈%20실기기%20기반%20개선%20계획%202026-09-26.md) | 제품별 가능 범위와 단계 |
| [패키지](home-assistant/packages/smart_home.yaml) | 안전 기본값의 장면·센서·알림 |
| [대시보드](home-assistant/dashboards/smart_home.yaml) | 검증된 버튼만 표시하는 홈·관리 화면 |
| [allowlist 통합](home-assistant/custom_components/switchbot_ir_allowlist/__init__.py) | 확인된 HA 엔티티 또는 IR 명령만, 2초 간격·중복 차단 |
| [구성 예시](home-assistant/configuration.yaml.example) | 실제 `/config/configuration.yaml`에 병합할 예시 |
| [검증](setup/06_validate_repository.ps1) | PowerShell/Python/YAML/JSON/Jinja·모의 백엔드 테스트 |
| [에이전트 컨텍스트](PKM/llms.md) | 필요한 Spec/Module/Log로의 최소 라우팅 |

## 적용

`setup/06_validate_repository.ps1`로 로컬 코드를 먼저 검증합니다. 그다음 [CHECKLIST.md](CHECKLIST.md)의 복구본 생성, 실제 엔티티 대조, HA 구성 검사, 재시작, 실기기 검증 순서를 따릅니다. 이전 상태를 덮어쓰거나 실물 확인 전에 준비 장면을 자동으로 켜지 않습니다.

Comfee는 기존 HA에서 `Others` 리모컨의 `POWER`·`Fan Speed 3`·`Timer`·`Mute`가 실제 동작했습니다. 새 allowlist v2에는 각각 `fan_power`·`fan_speed_cycle`·`fan_timer_cycle`·`fan_mute_toggle`로 대응하며 모두 기본 차단입니다. 실기기 재확인 뒤 하나씩 허용합니다. 선풍기는 목표 상태를 추정하거나 토글을 자동 재시도하지 않습니다.

실제 Token, Secret, HA 접근키, 기기 ID, `/config/.storage`, DB, 백업, VM 디스크는 저장소에 넣지 않습니다. `secrets.yaml.example`은 자리표시자입니다.

## ChatGPT·GitHub 작업

다음 작업에서는 [AGENTS.md](AGENTS.md)와 [PKM/llms.md](PKM/llms.md)를 먼저 읽고, 관련 Spec과 로그만 확인합니다. GitHub MCP는 코드·문서 관리 경로이며 HA 실시간 제어에는 인증된 HA 연결이 별도로 필요합니다.
