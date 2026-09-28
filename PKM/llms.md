---
type: pkm-index
title: 스마트홈 에이전트 컨텍스트
domain: [smart-home, home-assistant, switchbot, github, codex]
updated: 2026-09-28
---

# 스마트홈 에이전트 컨텍스트

> 2026-09-28 구현 기준: [S-005](Specs/S-005_verified-panel-implementation.md)와 [적용 체크리스트](../CHECKLIST.md)를 우선한다. 안전 구현은 [draft PR #4](https://github.com/LEEJAEMO/My_SmarT_Home/pull/4)에 게시했고 저장소 코드 오프라인 테스트 24개가 통과했다. 실제 HA 반영과 재시작, 실기기 검증은 별개다. 09-27 HA UI에서 커튼·CO₂가 unavailable이었다. 09-28에는 Observer만 응답하고 Core UI는 불통이었다. 아래 09-22 기준점과 PR #1은 역사적 기록이다.

_Git, Home Assistant, ChatGPT/Codex가 작업을 이어갈 때 가장 먼저 읽는 최소 컨텍스트입니다._

---

## 📍 시작 순서

> 사용자 확인(2026-09-26): `에어컨 수동` ON/OFF는 모두 전원 토글. 다른 에어컨 패널의 ON=모드 순환, OFF=종료 예약 순환이다. 확정 OFF·냉방26 프리셋은 현재 사용 가능하다고 가정하지 않는다. [S-004 버튼 계약](Specs/S-004_active-device-planning.md)을 우선한다.

> 최신 기준(2026-09-26): 사용자는 실제 HA SwitchBot 패널을 사용 중이다. [S-004](Specs/S-004_active-device-planning.md)를 먼저 읽는다. 아래 09-22 기준표는 역사적 관찰이며 현행 소스에는 선풍기 토글/순환과 15개 allowlist가 있다. [실기기 개선 계획](../docs/스마트홈%20실기기%20기반%20개선%20계획%202026-09-26.md)은 미배포 계획이다.

1. 이 파일을 읽고 현재 기준점과 금지 사항을 확인한다.
2. 작업 종류에 맞는 상세 문서만 선택해서 읽는다.
3. 코드를 바꾸기 전 `git status --short --branch`, `git diff --stat`, `git diff`를 확인한다.
4. 완료 후 관련 PKM 문서와 `Logs/` 작업 로그를 함께 갱신한다.

> 📌 **원칙:** 전체 저장소를 매번 다시 읽지 않는다. 이 인덱스에서 필요한 문서와 실제 변경 대상만 연다.

## 📋 현재 기준점

| 구분 | 현재 정본 |
| --- | --- |
| 주 사용자 기기 | Galaxy S23 Ultra, Galaxy Book6 Pro |
| 실행 환경 | Windows 11 Home + VirtualBox + HAOS |
| 확인된 버전 | VirtualBox 7.2.18, HAOS 18.3, Home Assistant Core 2026.9.3 |
| VM 사양 | 2 vCPU, RAM 4GB, EFI, 32GB 동적 VDI, Intel Wi-Fi 브리지 |
| 기본 접속 | `http://homeassistant.local` 또는 발견된 IPv4의 포트 80 |
| 대체 접속 | 포트 80이 닫힌 설치에서만 `:8123` 검사 |
| Observer | 포트 4357 |
| 실제 확인 | 2026-09-22에 `192.168.0.9:80` HTTP 200 확인 |
| 자동화 정본 | `home-assistant/packages/smart_home.yaml` |
| 배포 상태 정본 | `DEPLOYMENT_STATUS.md` |
| 사용자 절차 정본 | `CHECKLIST.md`, `docs/스마트홈 사용자 설정 및 운영 매뉴얼.md` |
| 역사적 PR | GitHub PR #1, `fix/haos-port-diagnostics`; 최신 PR은 GitHub에서 재확인 |

관찰된 IPv4는 DHCP로 바뀔 수 있으므로 설정에 고정하지 않는다. 접속 판단은 포트 80, 8123, 4357을 각각 확인한다.

## 🔐 변경 불가 안전 계약

- 실제 토큰, 비밀키, Home Assistant 토큰, 장치 ID, `.storage`, DB, 백업, VDI를 커밋하지 않는다.
- AI에는 검증된 준비 장면만 노출한다. 수동 IR 버튼, `switchbot_ir_allowlist.send`, 원시 OpenAPI는 노출하지 않는다.
- 에어컨의 냉방 26℃, 난방 20℃, 제습, 확정 종료 프리셋은 현재 지원하지 않는다. 기존 스크립트는 차단 상태다.
- IR 명령 사이에는 최소 2초를 유지하고 토글 명령을 자동 재시도하지 않는다.
- 선풍기는 `Others`의 검증된 네 버튼을 stateless 토글·순환으로만 다룬다. 토글형 프로젝터의 assumed-state 가드를 보존한다.
- 프로젝터 전원을 강제 차단하지 않는다.
- SwitchBot의 독립 CO₂ 경보를 유지한다.
- 확인하지 않은 런타임 상태를 `DEPLOYMENT_STATUS.md`에 기록하지 않는다.

## 🔗 작업별 라우팅

| 작업 | 먼저 읽을 문서 |
| --- | --- |
| 전체 구조·연동 변경 | [S-001 시스템 아키텍처](Specs/S-001_system-architecture.md) |
| 장면·IR·AI 노출 변경 | [S-002 자동화 및 안전 계약](Specs/S-002_automation-and-safety-contract.md) |
| 저장소·검증·배포 상태 | [S-003 저장소 및 배포 계약](Specs/S-003_repository-and-deployment-contract.md) |
| 코드 변경과 PR | [M-001 변경 검증 및 PR 루틴](Modules/M-001_repository-change-validation-pr-routine.md) |
| HAOS 접속 장애 | [M-002 HAOS 진단 루틴](Modules/M-002_haos-host-diagnosis-routine.md) |
| 포트 8123 오진 | [T-001 포트 가정 오류](Troubleshooting/T-001_haos-port-8123-assumption.md) |
| GitHub CLI 인증 실패 | [T-002 GitHub MCP 대체](Troubleshooting/T-002_github-cli-auth-mcp-fallback.md) |
| 느린 부팅·NEM | [T-003 부팅 지연 판별](Troubleshooting/T-003_haos-slow-boot-not-failure.md) |
| 이번 작업의 근거 | [2026-09-22 작업 로그](Logs/2026-09-22-haos-port-diagnostics-and-pr.md) |

## ✍️ 사용자 작업 대기

- SwitchBot 앱에서 각 IR 버튼을 학습하고 버튼별 5회 시험
- Home Assistant UI 최초 로그인과 Cloud/OpenAI/SwitchBot 연결
- 실제 엔티티 이름과 장치 ID를 HA의 실제 `/config/secrets.yaml`에 입력
- S23 위치·알림·백그라운드·Assist 권한 설정
- SmartThings Station 버튼 장면과 SwitchBot 독립 CO₂ 경보 설정
- 전체 실기기 검증과 assumed-state 동기화 확인

## 🔄 PKM 갱신 규칙

- 재사용 가능한 절차는 `Modules/M-NNN_*.md`에 기록한다.
- 재발 가능한 장애는 해결 후 `Troubleshooting/T-NNN_*.md`에 기록한다.
- 현재 시스템의 정본은 `Specs/S-NNN_*.md`에서 갱신한다.
- 매 작업의 사실·검증·커밋·PR은 `Logs/YYYY-MM-DD-*.md`에 남긴다.
- 이 인덱스에는 현재 기준점과 라우팅만 유지하고 장문의 조사 기록은 넣지 않는다.
