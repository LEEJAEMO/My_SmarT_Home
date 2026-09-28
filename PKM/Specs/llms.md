---
type: pkm-spec-index
title: 스마트홈 Specs 인덱스
updated: 2026-09-28
---

# 스마트홈 Specs 인덱스

_현재 시스템이 어떻게 구성되고 어떤 동작을 허용하는지 정의하는 정본입니다._

---

## 📋 명세 목록

| ID | 정본 범위 | 파일 |
| --- | --- | --- |
| S-001 | 기기·클라우드·Home Assistant 연결 구조 | [시스템 아키텍처](S-001_system-architecture.md) |
| S-002 | IR 프리셋·장면·AI 노출·안전 가드 | [자동화 및 안전 계약](S-002_automation-and-safety-contract.md) |
| S-003 | 저장소 구조·비밀정보·검증·배포 상태 | [저장소 및 배포 계약](S-003_repository-and-deployment-contract.md) |
| S-004 | 실제 SwitchBot 패널 중심 최신 계획·과거 사양 정정 | [실기기 개선 기준](S-004_active-device-planning.md) |
| S-005 | 검증된 패널 기반 구현과 배포 가드 | [실기기 구현 계약](S-005_verified-panel-implementation.md) |

## 🔄 갱신 규칙

- 실제 구성 변경과 같은 커밋에서 관련 Spec을 갱신한다.
- 구현 예정과 실제 검증 완료를 구분한다.
- 장치 ID, 토큰, 계정 정보와 VM 산출물은 기록하지 않는다.
- 배포 사실은 `DEPLOYMENT_STATUS.md`와 모순되지 않게 유지한다.
