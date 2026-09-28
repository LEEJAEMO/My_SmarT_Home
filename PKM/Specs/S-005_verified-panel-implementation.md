---
type: pkm-spec
id: S-005
title: 실제 패널 기반 안전 구현 계약
status: repository-implemented-live-deployment-pending
created: 2026-09-28
updated: 2026-09-28
domain: [home-assistant, switchbot, safety, dashboard, deployment]
source_of_truth:
  - home-assistant/packages/smart_home.yaml
  - home-assistant/custom_components/switchbot_ir_allowlist/__init__.py
  - home-assistant/dashboards/smart_home.yaml
  - CHECKLIST.md
---

# S-005. 실제 패널 기반 안전 구현 계약

## 현재 동작과 근거

2026-09-27 인증된 HA UI의 읽기 전용 확인: SwitchBot Cloud 기기 6개가 등록돼 있었다. `에어컨 수동`은 SwitchBot Cloud DIY Air Conditioner의 `switch`와 `climate` 엔티티를 가졌고, `에어컨 off 모드 변경/ on 1시간 切`도 `switch`와 `climate` 엔티티를 가졌다. `전동커튼 3E`와 `CO2 센서`의 엔티티는 `unavailable`이었다. 사용자 확인 버튼 의미가 물리 동작의 근거이며, 실제 서비스 호출이나 원시 IR 학습 상태는 이번 감사에서 시험하지 않았다. 운영 엔티티 ID와 Device ID는 공개 Spec에 기록하지 않는다.

2026-09-28 현재: VM은 running, 브리지 필터 활성, Observer 4357 응답. Core UI 80·8123은 응답하지 않았다. 이에 따라 새 구성은 실제 HA에 배포·활성화되지 않았고, 새 대시보드도 아직 렌더링 검증을 못 했다. 진단 결과는 [작업 로그](../Logs/2026-09-28-verified-panel-implementation.md)에 기록한다.

## 코드 안전 기본값

| 영역 | 구현 |
| --- | --- |
| 에어컨 | 기존 냉방26·난방20·제습·확정 OFF 스크립트는 명시적 오류로 차단. 세 수동 스크립트는 전원 1회, 모드 다음, 종료 예약 다음 의미만 보냄. |
| 허용 목록 | `verified: false` 기본. `backend: ha`는 `switch`/`button`/`climate`/`fan`의 정해진 기본 서비스와 같은 도메인 entity만 허용. 기존 `backend: ir`도 검증 전 차단. |
| 명령 간격 | 하나의 통합 내부에서 전역 최소 2초, 같은 action의 동시·즉시 재입력 거절. timeout은 결과 미확인, 자동 재시도 없음. 외부 SwitchBot 앱의 송신까지 통합 잠금이 보장하지는 않음. |
| 상태 | `switchbot_ir_allowlist.status`는 요청·응답 상태와 마지막 action만 기록. 물리 전원 상태는 `unknown`. |
| Comfee | 기존 HA에서 `Others`의 `POWER`, `Fan Speed 3`, `Timer`, `Mute` 실기기 동작 확인 기록이 GitHub `main`에 있음. 새 allowlist v2에서는 네 action 모두 기본 `verified: false`이며 적용 후 재확인 필요. |
| 장면 | 기상·외출·영화·수면 준비는 검증된 커튼 한 동작만. 귀가는 낮 커튼. 환기는 최신 CO₂ 수신이 있을 때 수동 기록만 시작하며 가전을 조작하지 않음. |
| 센서 | HA 마지막 수신 15분 초과·값 없음·unavailable면 표시 `unavailable`, 환기 완료 차단. 1000/1500ppm 안내는 알림 helper 활성화 후에만 발송. |
| UI | 수동 에어컨/선풍기 버튼은 각 action `verified`일 때만 표시하며 실행 전 확인 문구 사용. 장면 버튼은 한 번의 `script` 실행을 요청. 관리자 helper는 별도 화면. |
| 음성 | 스크립트 경로는 관리자 `smarthome_voice_enabled`가 켜져야 실행. 지원하지 않는 확정 에어컨·선풍기·전체 종료는 무동작 안내. 실제 Assist/OpenAI 노출 관리도 HA UI에서 별도로 필요. |
| 프로젝트/조명 | 실제 호환성 증거가 없어 자동 장면·일상 UI에서 제외. 기존 프로젝터 개별 스크립트는 검증 플래그와 추정 상태 가드를 유지함. |

## 실 HA 활성화 전 필수 확인

1. 현재 Core UI 복구. 구성·파일 백업과 변경 전 소스 지문을 확보한다.
2. 현재 `configuration.yaml`과 repository example의 차이를 읽되 비밀값을 기록하지 않는다. 예시를 통째로 덮어쓰지 않는다.
3. 실제 패널 entity와 서비스/버튼 결과를 확인하고 명령별로 `verified`를 켠다. 조명·프로젝터는 별도 기술 가능성 판정 전 계속 차단한다.
4. 로컬 24개 모의 백엔드·정적 안전 테스트, 전 저장소 문법, 전체 allowlist·비밀정보 검사. HA 구성 검사를 거쳐 재시작한다.
5. 새 대시보드의 활성 리소스 지문·카드 렌더링, 단일 요청, 실패·중복 입력, 휴대전화 화면을 별도 검사한다. 장치 물리 5회 시험과 HA 인터랙션 시뮬레이션은 아직 통과한 적이 없다.
6. 원본 SwitchBot CO₂ 경보를 유지하고 S23 알림, Station 버튼은 실제 사용 가능성 확인 후 확장한다.

## 변경 파일과 검증 루틴

설정 예시, 패키지, 사용자 통합, 고정 한국어 문장, 대시보드, AI 지침, `CHECKLIST.md`, `README.md`, `tests/test_safety.py`, `setup/06_validate_repository.ps1`, `setup/validate_repository.py`를 함께 갱신했다. 테스트는 YAML/Jinja 구문 및 모의 백엔드 호출을 확인한다. 테스트 통과가 HA 런타임 구성 검사나 실제 장치 성공을 뜻하지 않는다.

## 관련 기록

- [S-004 계획](S-004_active-device-planning.md)
- [2026-09-28 작업 로그](../Logs/2026-09-28-verified-panel-implementation.md)
