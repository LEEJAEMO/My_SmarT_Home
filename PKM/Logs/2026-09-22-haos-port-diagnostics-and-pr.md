---
type: pkm-work-log
date: 2026-09-22
title: HAOS 포트 진단 개선과 GitHub PR 생성
topics: [haos, virtualbox, port-80, diagnostics, github, pull-request]
branch: fix/haos-port-diagnostics
local_commit: c55cd33
remote_commit: 7a21c1e119ecb5f245ad8ed386a353255c0af8d5
pull_request: https://github.com/LEEJAEMO/My_SmarT_Home/pull/1
status: completed
---

# 2026-09-22 HAOS 포트 진단 개선과 PR 생성

_8123 포트 고정 가정으로 발생한 오진을 바로잡고 비파괴 진단 도구와 복구 문서를 추가한 작업 기록입니다._

---

## 🎯 목표

- 이전 세션의 미커밋 변경을 잃지 않고 검토
- HAOS, Supervisor, Core 상태를 포트별로 정확히 진단
- 저장소 필수 검증 완료
- 새 브랜치에 커밋하고 GitHub PR 생성

## 🔍 시작 상태

- 브랜치: `fix/haos-port-diagnostics` 생성 전 기존 작업이 로컬에 미커밋 상태
- 기존 변경: 수정 7개, 신규 2개
- 핵심 관찰: HAOS와 Supervisor는 정상이며 Core UI는 `192.168.0.9:80`에서 HTTP 200
- 문제: 저장소 스크립트와 문서가 8123 포트를 고정 가정

기존 작업을 reset하거나 checkout하지 않고 그대로 검토했다.

## 📋 근본 원인과 결정

| 항목 | 결론 |
| --- | --- |
| 장애 계층 | Home Assistant 장애가 아님 |
| 근본 원인 | 포트 8123 고정 가정 |
| 기본 URL | `http://homeassistant.local` |
| 대체 URL | 포트 80이 닫힌 경우에만 `:8123` |
| 주소 선택 | 여러 DNS 결과 중 IPv4 우선 |
| 복구 정책 | 진단을 먼저 수행하고 VDI 변경 전 백업 |

## ✍️ 변경 내용

### 수정

- `CHECKLIST.md`
- `DEPLOYMENT_STATUS.md`
- `README.md`
- `docs/스마트홈 사용자 설정 및 운영 매뉴얼.md`
- `setup/00_run_host_setup_as_admin.ps1`
- `setup/01_install_virtualbox_haos.ps1`
- `setup/03_validate_host.ps1`

### 신규

- `docs/HAOS VirtualBox 진단 및 복구.md`
- `setup/05_diagnose_haos_vm.ps1`

전체 규모는 9개 파일, 636 insertions, 39 deletions였다.

## ✅ 검증 결과

| 검사 | 결과 |
| --- | --- |
| PowerShell parser | 통과 |
| Python `py_compile` | 통과 |
| YAML·JSON | 7개 파싱 통과 |
| IR allowlist | 사용 18개와 허용 18개 일치 |
| `git diff --check` | 통과 |
| 자격 증명·장치 ID scan | 검출 없음 |
| 로컬·원격 파일 | 9개 blob 동일 |

초기 MCP 업로드 tree와 로컬 커밋 tree SHA는 `99667449f444d969cb897b2139661d0550b41afb`로 일치했다.

## 🔄 Git과 GitHub 결과

| 항목 | 결과 |
| --- | --- |
| 로컬 브랜치 | `fix/haos-port-diagnostics` |
| 로컬 커밋 | `c55cd33` |
| CLI push | HTTPS 비대화형 인증 실패 |
| 원격 처리 | GitHub MCP로 blob·tree·commit·branch 생성 |
| 원격 최신 main | 로컬 기준보다 4개 커밋 앞섰으며 변경 파일은 겹치지 않음 |
| 원격 PR head | `7a21c1e119ecb5f245ad8ed386a353255c0af8d5` |
| 최종 비교 | ahead 1, behind 0 |
| PR 상태 | open, mergeable true |

PR: [#1 fix: detect HAOS port 80 and add recovery diagnostics](https://github.com/LEEJAEMO/My_SmarT_Home/pull/1)

## ⚠️ 운영상 주의

- 로컬 `origin/main`은 원격 최신 `main`보다 뒤에 있었으므로 다음 작업에서 최신 여부를 다시 확인한다.
- 관찰된 `192.168.0.9`는 DHCP 주소이며 설정에 고정하지 않는다.
- 작업 중 후속 재부팅 직후 일시적으로 웹 포트가 닫힌 관찰이 있었으므로 현재 라이브 상태가 필요하면 M-002를 다시 실행한다.
- 이 일시 관찰은 이전에 확인한 포트 80 HTTP 200 사실을 삭제하지 않으며, 새 장애의 근본 원인으로 확정하지 않았다.

## ✍️ 남은 사용자 작업

- SwitchBot IR 버튼별 5회 시험
- HA UI 최초 로그인과 계정 연결
- 실제 장치 ID와 엔티티 입력
- S23 권한과 Assist 설정
- Station 버튼 장면과 SwitchBot 독립 CO₂ 경보
- 실기기 전체 검증

## 🔗 생성된 지식

- [M-001 저장소 변경·검증·PR 루틴](../Modules/M-001_repository-change-validation-pr-routine.md)
- [M-002 HAOS 호스트 진단 루틴](../Modules/M-002_haos-host-diagnosis-routine.md)
- [T-001 포트 8123 오진](../Troubleshooting/T-001_haos-port-8123-assumption.md)
- [T-002 GitHub MCP 대체](../Troubleshooting/T-002_github-cli-auth-mcp-fallback.md)
- [T-003 느린 부팅 판별](../Troubleshooting/T-003_haos-slow-boot-not-failure.md)
