---
type: pkm-spec
id: S-004
title: 실제 SwitchBot 패널 중심 개선 기준
status: implementation-in-repository-live-deployment-pending
created: 2026-09-26
updated: 2026-09-28
domain: [smart-home, switchbot, hxlight, projector, planning]
---

# S-004. 실제 SwitchBot 패널 중심 개선 기준

> 2026-09-28 저장소 구현은 [S-005](S-005_verified-panel-implementation.md)를 따른다. 이 문서의 ‘이번 단계는 문서만’은 09-26 작성 당시 기록이다.

_2026-09-26 사용자 요구와 로컬·GitHub 소스 검토에 근거한 계획. 실제 HA 기기 제어는 미실행._

## 📋 현재 결정

- HA에서 사용 중인 SwitchBot 패널의 실제 entity/action을 기준으로 개선한다.
- 사용자 확인: `전동커튼 3E` 유지. `에어컨 수동` ON/OFF는 모두 전원 토글이다.
- 사용자 확인: `에어컨 off 모드 변경 / on 1시간 切`의 ON은 자동→제습→냉방→난방→송풍 순환, OFF는 종료 예약 1~9시간→없음 순환이다. 패널 이름만 보고 역매핑하지 않는다.
- 확정 에어컨 OFF·냉방26 등 프리셋은 현재 확보되지 않았다. 미래 허용 범위와 현재 기능을 구분한다. 실제 매핑 검증 전 자동 OFF·냉난방을 계획에 포함하지 않는다.
- 앱 이름은 Hxlight로 사용자 확인, 배치는 원룸이다. 벽 간 통신보다 IR 시야·가구 가림을 확인한다.
- 원본 계획서: [실기기 기반 개선 계획](../../docs/스마트홈%20실기기%20기반%20개선%20계획%202026-09-26.md).
- Hxlight 조명 ASIN B0F4L3B2VM의 IR 여부와 HA 호환성은 미확정이다.
- 프로젝터 ASIN B0F5GQLNWP의 PC Bluetooth 연결은 사용자 확인 사항이지만 전원/미디어 제어 가능성은 미확정이다.
- SmartThings Station의 모델과 버튼 이벤트 전달 경로를 확인한 뒤 보조 입력으로 검토한다.
- 이번 단계에서는 문서만 작성한다. 배포, 자동화 변경, 장치 호출, 추가 구매는 실행하지 않았다.

## ⚠️ 과거 사양 정정

- S-001/S-002의 09-22 실기기 연결 대기 표는 역사적 상태다. 사용자는 현재 HA SwitchBot 패널을 사용 중이라고 밝혔다.
- 현행 소스에는 선풍기 power·speed cycle·timer cycle·mute toggle이 있으며, 약풍/강풍 직접 지정은 없다.
- 현행 로컬 configuration 예시의 allowlist는 15개다. 18/18은 이전 revision 검증 결과다.
- 소스 존재는 실제 HA 배포나 버튼 작동의 증거가 아니다. 운영 HA와의 대조가 필요하다.
- 조명과 프로젝터의 IR 통신은 제품별로 다시 확인한다.
- 센서 하드웨어 측정 주기와 HA 수신 주기는 구분한다. 근거와 후속 검증은 계획서 참조.

## 🔄 최소 실행 순서

1. 실제 패널 인벤토리: 기능, 호출, 상태 출처를 기록한다.
2. 검증된 기기 조작만 대시보드로 재사용한다.
3. 조명·프로젝터 연결 경로를 제한된 시험으로 판정한다.
4. 작은 장면과 센서 알림을 검증한다.
5. Station과 음성 명령을 후속으로 연결한다.

## 🔗 근거

- 로컬 HEAD: df46467; 기존 AGENTS.md·README.md·PKM 변경 보존.
- GitHub dashboard blob: edf283e4c0d4564cf8ed7b7c4d5f656860c03a0f.
- GitHub package blob: bd61ca195e94684693782dd0a0fe30a40977438e.
- [작업 Log](../Logs/2026-09-26-active-device-plan.md).
