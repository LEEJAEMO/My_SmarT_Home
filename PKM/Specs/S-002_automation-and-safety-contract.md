---
type: pkm-spec
id: S-002
title: 자동화, IR 프리셋과 AI 안전 계약
domain: [home-assistant, switchbot, ir, automation, assist, safety]
status: configuration-implemented-hardware-validation-pending
source_of_truth:
  - home-assistant/packages/smart_home.yaml
  - home-assistant/configuration.yaml.example
  - home-assistant/openai_instructions_ko.txt
created: 2026-09-22
updated: 2026-09-22
---

# S-002. 자동화, IR 프리셋과 AI 안전 계약

> 2026-09-28 현재 안전 동작 정본은 [S-005](S-005_verified-panel-implementation.md)다. 아래 초기 4개 에어컨 프리셋과 6개 장면 내용은 미검증 구상이며 실제 기능으로 사용하지 않는다.

> 사용자 추가 확인(2026-09-26): 현재 에어컨은 전원 토글·모드 순환·예약 순환뿐이다. 본문의 냉방26/난방20/제습/확정 OFF는 향후 확보할 코드의 허용 범위로만 읽는다. 실제 기능과 자동화 제한은 [S-004](S-004_active-device-planning.md) 참조.

> 2026-09-26 주석: 본문의 선풍기 절대 풍량·2시간 설정·18개 allowlist는 과거 사양이다. 현행 소스는 전원/풍량/타이머/음소거의 토글·순환 방식과 15개 allowlist를 사용한다. 조명 IR 지원도 미확정이다. 기존 안전 규칙은 유지하고, 최신 기능 판단은 [S-004](S-004_active-device-planning.md)를 따른다.

_구형 IR 가전을 예측 가능하게 제어하기 위한 허용 동작, 상태 가드와 자동화 조건의 정본입니다._

---

## 🔐 핵심 안전 계약

- AI는 사전 정의된 스크립트와 장면, 읽기 전용 센서만 사용한다.
- 원시 `switchbot_ir_allowlist.send`, 장치 ID, 토큰, 구성 helper는 AI에 노출하지 않는다.
- IR 전송은 전역 잠금으로 최소 2초 간격을 유지한다.
- 토글 명령은 자동 재시도하지 않는다.
- 물리 리모컨 사용 후 assumed-state가 실제 상태와 달라질 수 있다.
- 프로젝터는 정상 종료 IR만 사용하며 스마트 플러그로 전원을 차단하지 않는다.

## ❄️ Daikin 에어컨

지원 상태는 다음 네 개뿐이다.

| 허용 action | 사용자 의미 | 상태 |
| --- | --- | --- |
| `daikin_cool_26` | 냉방 26℃, 풍량 자동 | 허용 |
| `daikin_heat_20` | 난방 20℃, 풍량 자동 | 허용 |
| `daikin_dry` | 학습된 제습 상태 | 허용 |
| `daikin_off` | 확정 OFF | 허용 |

임의 온도 요청은 실행하지 않고 가능한 프리셋을 안내한다. 새 온도는 실제 IR 프리셋을 먼저 학습하고 안전 검토를 거친 경우에만 추가한다.

## ⚙️ 기타 IR 허용 목록

| 장치 | 허용 action |
| --- | --- |
| Comfee 선풍기 | `fan_power`, `fan_low`, `fan_medium`, `fan_high`, `fan_oscillate`, `fan_natural`, `fan_timer_2h` |
| 전등 | `light_on`, `light_off`, `light_brighter`, `light_dimmer` |
| 프로젝터 | `projector_on`, `projector_off`, `projector_power` |

총 18개 action이 `configuration.yaml.example`의 allowlist에 정의되어 있다. 실제 장치 ID는 HA 인스턴스의 `/config/secrets.yaml`에만 둔다.

## 🔄 assumed-state 가드

| helper | 의미 | 필수 가드 |
| --- | --- | --- |
| `input_boolean.aircon_assumed_on` | HA가 마지막으로 기록한 에어컨 전원 | 프리셋·OFF 실행 후 갱신 |
| `input_select.aircon_assumed_mode` | 꺼짐·냉방26·난방20·제습 | 임의 값 추가 금지 |
| `input_boolean.fan_assumed_on` | 선풍기 전원 추정 | OFF일 때만 power-on 토글, ON일 때만 power-off 토글 |
| `input_select.fan_assumed_speed` | 꺼짐·약풍·중풍·강풍 | 속도 스크립트 후 갱신 |
| `input_boolean.projector_assumed_on` | 프로젝터 전원 추정 | 토글형 종료 시 ON 기록일 때만 전송 |
| `input_boolean.projector_discrete_power` | ON/OFF 분리 코드 여부 | 분리 코드와 토글 경로 선택 |
| `input_boolean.ventilation_active` | 환기 장면 진행 상태 | CO₂ 완료 자동화 조건 |

## 🏠 장면 계약

| 장면 | 조건과 동작 |
| --- | --- |
| 기상 | 일출 30분 후이면서 06:30 이전은 금지, 재실 시 커튼 열기와 전등 켜기 |
| 외출 | 10분 부재 후 에어컨·선풍기·전등 종료, 커튼 닫기, 안전한 프로젝터 종료 |
| 귀가 | 낮에는 커튼 열기, 일몰 후 전등 켜기, 28℃ 초과 냉방26, 16℃ 미만 난방20 |
| 영화 | 커튼 닫기 → 전등 끄기 → 2초 후 프로젝터 켜기 |
| 수면 | 커튼 닫기, 전등·프로젝터 끄기, 선풍기 약풍 2시간, 온도에 따른 냉난방 프리셋 |
| 환기 | 에어컨 끄기, 선풍기 강풍, 사용자가 창문을 직접 열고 닫음 |

## 📊 CO₂ 자동화

| 조건 | Home Assistant 동작 | 독립 경로 |
| --- | --- | --- |
| 1000ppm 이상, 1500ppm 미만 | 환기 권고 알림 | SwitchBot 앱에도 생성 |
| 1500ppm 이상 | 긴급 고우선순위 알림 | SwitchBot 앱에도 생성 |
| 환기 중 800ppm 미만 10분 | 선풍기 종료, 창문 닫기 알림 | HA 장면 상태 사용 |

센서는 USB 5V 전원 사용을 전제로 약 1분 단위 갱신을 목표로 한다.

## 🧠 AI와 한국어 명령

- 결정적 한국어 문장은 `home-assistant/custom_sentences/ko/smart_home.yaml`에서 처리한다.
- OpenAI 지침은 `home-assistant/openai_instructions_ko.txt`를 사용한다.
- 노출 대상은 에어컨 프리셋, 선풍기 스크립트, 전등, 프로젝터, 커튼, 여섯 장면과 읽기 전용 환경 센서다.
- 지원하지 않는 에어컨 온도는 실행하지 않고 지원 프리셋을 말한다.

## ✅ 실기기 검증 조건

- 모든 학습 IR 버튼을 SwitchBot 앱에서 5회씩 시험
- Hub Mini와 네 IR 가전 사이의 시야 확인
- HA에서 냉방26, 선풍기 강풍, 영화, 환기 명령 시험
- 물리 리모컨 사용 뒤 assumed-state 불일치 처리 확인
- 프로젝터 냉각 팬이 정상 종료되는지 확인
- Galaxy Book 종료 중 보조 제어와 독립 CO₂ 경보 확인

## 🔗 관련 문서

- [S-001 시스템 아키텍처](S-001_system-architecture.md)
- [S-003 저장소 및 배포 계약](S-003_repository-and-deployment-contract.md)
- `CHECKLIST.md`
