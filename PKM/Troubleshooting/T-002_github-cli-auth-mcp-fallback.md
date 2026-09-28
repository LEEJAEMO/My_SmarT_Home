---
type: pkm-troubleshooting
id: T-002
title: 비대화형 GitHub HTTPS push 인증 실패와 MCP 대체
domain: [git, github, mcp, authentication, codex]
symptom: "fatal: could not read Username for 'https://github.com': No such file or directory"
root_cause: Codex 비대화형 셸에 GitHub HTTPS 자격 증명이 제공되지 않음
resolution: 로컬 커밋을 보존하고 GitHub MCP Git Data API로 동일 blob과 tree를 생성해 브랜치와 PR 작성
resolved_date: 2026-09-22
severity: medium
reproducible: true
related_module: M-001
---

# T-002. GitHub CLI 인증 실패 시 MCP로 안전하게 이어가기

_로컬 커밋을 잃지 않고 GitHub 커넥터로 동일 변경을 원격 PR에 올린 사례입니다._

---

## 🔍 증상

`git push -u origin fix/haos-port-diagnostics` 실행 시 다음 오류가 발생했다.

~~~text
fatal: could not read Username for 'https://github.com': No such file or directory
~~~

작업 트리는 깨끗했고 로컬 커밋 `c55cd33`은 정상적으로 남아 있었다.

## 📋 근본 원인

원격 URL은 HTTPS였고 비대화형 Codex 셸에서 사용자명과 자격 증명을 요청할 수 없었다. 이는 변경 내용이나 Git 객체 손상이 아니라 인증 경로 문제다.

## 🔧 해결

1. 로컬 커밋과 작업 트리를 그대로 보존했다.
2. GitHub MCP로 9개 파일을 base64 blob으로 생성했다.
3. 생성한 tree SHA와 로컬 커밋 tree SHA가 `99667449f444d969cb897b2139661d0550b41afb`로 같은지 확인했다.
4. 원격 `main`이 로컬 기준보다 4개 커밋 앞선 것을 확인했다.
5. 겹치는 파일이 없음을 확인하고 최신 원격 `main` 위에 같은 9개 blob을 재적용했다.
6. 원격 브랜치와 PR #1을 생성했다.

## ✅ 최종 상태

| 항목 | 값 |
| --- | --- |
| 로컬 커밋 | `c55cd33` |
| 원격 PR head | `7a21c1e119ecb5f245ad8ed386a353255c0af8d5` |
| PR | [#1](https://github.com/LEEJAEMO/My_SmarT_Home/pull/1) |
| 비교 | ahead 1, behind 0 |
| 병합 가능 | true |

로컬과 원격 커밋 SHA는 생성 주체와 부모가 달라 서로 다르지만, 이번에 변경한 9개 파일 blob은 로컬과 동일하다.

## ⚠️ 다음 세션 주의

- 로컬 `origin/main`이 원격 최신 상태라고 가정하지 않는다.
- 새 작업 전 read-only fetch 또는 GitHub 비교로 기준점을 확인한다.
- 인증 실패를 해결하려고 토큰을 명령줄, 로그, PKM에 기록하지 않는다.
- 동기화를 위해 기존 로컬 커밋을 reset하거나 checkout으로 버리지 않는다.

## 🔄 재발 방지

- 일반 작업에서는 SSH 또는 안전한 자격 증명 저장 방식을 준비한다.
- Codex에서 GitHub 플러그인을 명시한 작업은 MCP를 우선 사용해도 된다.
- MCP 업로드 시 blob, tree, base commit, 최종 compare 결과를 검증한다.
