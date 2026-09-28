---
type: pkm-spec
id: S-003
title: 저장소, 검증과 배포 상태 계약
domain: [repository, deployment, security, validation, documentation]
status: active
source_of_truth: [AGENTS.md, DEPLOYMENT_STATUS.md]
created: 2026-09-22
updated: 2026-09-22
---

# S-003. 저장소, 검증과 배포 상태 계약

_Git에 보관할 것과 실제 HA 인스턴스에만 둘 것을 구분하고 모든 변경의 검증 기준을 정의합니다._

---

## 📚 저장소 구조

| 경로 | 역할 |
| --- | --- |
| `setup/` | Windows, VirtualBox, HAOS 설치·진단·검증 |
| `home-assistant/packages/` | 스크립트, helper, 장면, 자동화 |
| `home-assistant/custom_components/switchbot_ir_allowlist/` | allowlist 전용 SwitchBot OpenAPI 서비스 |
| `home-assistant/custom_sentences/ko/` | 결정적 한국어 명령 |
| `home-assistant/dashboards/` | Lovelace 대시보드 |
| `docs/` | 사용자 설정과 HAOS 복구 문서 |
| `PKM/` | 에이전트용 사양, 재사용 절차, 장애 기록, 작업 Log |
| `CHECKLIST.md` | 사용자 물리 설정과 최종 검증 |
| `DEPLOYMENT_STATUS.md` | 마지막으로 실제 확인된 배포 상태 |
| `AGENTS.md` | 작업 안전 규칙과 필수 검사 |

## 🔐 Git 포함 경계

### 포함 가능

- placeholder만 있는 `secrets.yaml.example`
- 장면·자동화·대시보드·문장·설치 스크립트
- 비식별화된 진단 절차와 결과 요약
- PKM Spec, Module, Troubleshooting, Log

### 포함 금지

- 실제 SwitchBot token과 secret
- OpenAI API key와 Home Assistant access token
- 실제 장치 ID와 계정 식별 정보
- Home Assistant `.storage`, DB, 백업
- VDI, NVRAM, VM 설정 백업과 진단 스크린샷
- 공개 저장소에 부적합한 로컬 evidence 원본

## ✅ 커밋 전 필수 검사

1. 모든 PowerShell 파일을 Windows PowerShell parser로 검사
2. 사용자 통합 Python 파일 컴파일
3. 모든 YAML과 JSON 파일 파싱
4. 사용한 IR action과 allowlist 정의 비교
5. 전체 diff에 `git diff --check` 실행
6. staged 또는 전체 diff에서 자격 증명과 실제 장치 ID 검사

상세 순서는 [M-001](../Modules/M-001_repository-change-validation-pr-routine.md)을 따른다.

## 📊 확인된 배포 기준

| 항목 | 마지막 확인 |
| --- | --- |
| VirtualBox | 7.2.18 r175117 설치 |
| VM | Home Assistant VM 생성과 실행 |
| HAOS·Core | HAOS 18.3, Core 2026.9.3 |
| 리소스 | 2 vCPU, RAM 4096MB, EFI, 32GB 동적 VDI |
| 네트워크 | Intel Wi-Fi 브리지, NDIS6 필터 활성 |
| UI | 포트 80 HTTP 200 |
| Observer | 4357 Connected, Supported, Healthy |
| 성능 경고 | VBS·Memory Integrity 활성, NEM snail mode 관찰 |
| 백업 | 전원 종료 상태 VDI·설정·NVRAM 백업과 SHA-256 확인 |

정확한 최신 표시는 `DEPLOYMENT_STATUS.md`에서만 갱신한다. PKM은 진입점과 계약을 제공하며 라이브 상태를 대신하지 않는다.

## 🔄 Git과 PR 운영

- 행동 변경은 새 브랜치와 PR을 기본으로 한다.
- PR 본문에 장면, 안전 가드, 노출 범위, 임계값, IR 상태 가정의 변화를 설명한다.
- 원격 `main`이 로컬보다 앞설 수 있으므로 PR 생성 전 비교한다.
- CLI 인증이 실패하면 로컬 커밋을 보존하고 [T-002](../Troubleshooting/T-002_github-cli-auth-mcp-fallback.md)를 따른다.
- PR이 생성되면 Codex 작업에 artifact로 첨부한다.

## ✍️ 문서 동기화

- 사용자용 설명은 `docs/스마트홈 사용자 설정 및 운영 매뉴얼.md`에서 관리한다.
- 해당 문서의 Obsidian mirror는 별도 Vault 경로에 있으며 저장소 밖 파일임을 구분한다.
- 에이전트용 최소 컨텍스트는 `PKM/llms.md`다.
- 동작 변경 시 구현, Spec, 사용자 문서, 작업 Log의 모순을 검사한다.

## 🔗 관련 문서

- [S-001 시스템 아키텍처](S-001_system-architecture.md)
- [S-002 자동화 및 안전 계약](S-002_automation-and-safety-contract.md)
- [M-001 저장소 변경 루틴](../Modules/M-001_repository-change-validation-pr-routine.md)
