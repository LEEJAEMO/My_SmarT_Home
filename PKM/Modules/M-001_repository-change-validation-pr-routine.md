---
type: pkm-module
id: M-001
title: 스마트홈 저장소 변경·검증·PR 루틴
domain: [git, github, codex, validation, security]
task_type: workflow
input: 변경 요청, 현재 작업 트리, 관련 Spec
output: 기존 작업을 보존한 검증 완료 커밋과 PR, 작업 Log
related_spec: S-003
related_troubleshooting: [T-002]
created: 2026-09-22
updated: 2026-09-22
---

# M-001. 스마트홈 저장소 변경·검증·PR 루틴

_기존 사용자 변경을 보존하면서 코드, 문서, 검증 증거와 PR을 일관되게 만드는 반복 절차입니다._

---

## 📋 입력과 출력

| 항목 | 내용 |
| --- | --- |
| 입력 | 사용자 요청, 현재 Git 상태, 관련 Spec과 Troubleshooting |
| 출력 | 새 브랜치, 검증된 커밋, PR, 갱신된 Spec 또는 Log |
| 실패 시 | 변경을 버리지 않고 실패 지점과 안전한 다음 조치를 기록 |

## 🔍 1단계: 기존 작업 보호

먼저 다음 세 명령으로 상태를 확인한다.

~~~powershell
git status --short --branch
git diff --stat
git diff
~~~

- 추적되지 않은 파일은 `git diff`에 나타나지 않으므로 별도로 연다.
- 사용자 변경과 이번 작업을 구분한다.
- `git reset --hard`, `git checkout -- <path>`처럼 기존 작업을 버리는 명령을 사용하지 않는다.
- 현재 브랜치와 원격 `main`이 같은 기준점인지 확인한다.

## 📚 2단계: 최소 컨텍스트 로드

1. `PKM/llms.md`를 읽는다.
2. 작업과 직접 관련된 Spec 하나 이상을 읽는다.
3. 증상이 있으면 Troubleshooting을 검색한다.
4. 실제 변경 대상과 테스트 파일만 추가로 연다.

전체 저장소를 무조건 다시 읽는 대신 인덱스가 지정한 경로로 좁힌다.

## ✍️ 3단계: 변경

- 기존 안전 계약을 유지한다.
- 실제 비밀값 대신 `secrets.yaml.example`의 자리표시자를 사용한다.
- HA 동작을 바꾸면 자동화 Spec과 사용자 문서를 함께 갱신한다.
- 재사용 가능한 절차나 새 장애 해결법이 생기면 PKM 항목을 만든다.
- `DEPLOYMENT_STATUS.md`에는 실제로 확인한 사실만 쓴다.

## ✅ 4단계: 필수 검증

모든 커밋 전에 다음 여섯 범주를 확인한다.

| 검사 | 통과 기준 |
| --- | --- |
| PowerShell | 모든 `.ps1`이 Windows PowerShell parser 오류 없음 |
| Python | 사용자 통합 Python 파일 컴파일 성공 |
| YAML·JSON | 저장소 내 모든 YAML·JSON 파싱 성공 |
| IR allowlist | 모든 `switchbot_ir_allowlist.send` action이 허용 목록에 존재 |
| Git 형식 | `git diff --check` 오류 없음 |
| 비밀정보 | 전체 diff에 토큰·키·실제 장치 ID·VM 산출물 없음 |

문서만 바꿔도 비밀정보와 Git 형식 검사는 생략하지 않는다. 저장소 규칙이 모든 변경에 전체 검증을 요구하면 여섯 검사를 모두 실행한다.

## 🔄 5단계: 브랜치·커밋·PR

1. `codex/` 또는 요청된 접두사의 새 브랜치를 사용한다.
2. 의도한 파일만 스테이징하고 staged diff를 다시 검토한다.
3. 한 가지 목적을 설명하는 커밋을 만든다.
4. 최신 원격 `main`과 비교해 behind 상태나 겹치는 파일을 확인한다.
5. PR 본문에 변경 이유, 안전 영향, 검증 결과, 남은 사용자 작업을 기록한다.
6. 생성한 PR을 현재 Codex 작업에 첨부한다.

CLI 인증이 실패해도 로컬 커밋을 버리지 않는다. [T-002](../Troubleshooting/T-002_github-cli-auth-mcp-fallback.md)에 따라 GitHub MCP로 동일한 blob과 tree를 업로드한다.

## ✍️ 6단계: 작업 Log

로그에는 다음을 남긴다.

- 시작 당시 브랜치와 변경 상태
- 근본 원인 또는 설계 결정
- 생성·수정한 파일
- 실제 실행한 검증과 결과
- 로컬 및 원격 커밋 SHA
- PR URL과 병합 가능 여부
- 아직 사용자가 해야 하는 물리·계정 작업

## 🎯 완료 조건

- [ ] 기존 사용자 작업이 보존됨
- [ ] 필요한 Spec과 문서가 구현과 일치함
- [ ] 필수 검증이 모두 통과함
- [ ] 비밀정보가 포함되지 않음
- [ ] 브랜치와 PR이 최신 `main` 기준으로 검토 가능함
- [ ] 작업 Log가 다음 세션에서 재조사를 막을 만큼 충분함

## 🔗 관련 문서

- [S-003 저장소 및 배포 계약](../Specs/S-003_repository-and-deployment-contract.md)
- [T-002 GitHub CLI 인증 실패](../Troubleshooting/T-002_github-cli-auth-mcp-fallback.md)
- [작업 Log 인덱스](../Logs/llms.md)
