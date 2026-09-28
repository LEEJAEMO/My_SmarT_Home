---
type: pkm-module-index
title: 스마트홈 Modules 인덱스
updated: 2026-09-22
---

# 스마트홈 Modules 인덱스

_반복 가능한 스마트홈 작업을 짧은 입력과 검증 가능한 출력으로 정의합니다._

---

## 📋 사용법

- 작업 시작 전에 유사 모듈을 찾고 그대로 재사용한다.
- 절차가 달라지면 관련 Spec과 실제 스크립트를 먼저 갱신한다.
- 완료 조건을 충족한 뒤에만 작업 Log에 성공으로 기록한다.

## 📚 모듈 목록

| ID | 제목 | 입력 | 출력 |
| --- | --- | --- | --- |
| M-001 | [저장소 변경·검증·PR 루틴](M-001_repository-change-validation-pr-routine.md) | 변경 요청과 기존 Git 상태 | 검증된 브랜치·커밋·PR·Log |
| M-002 | [HAOS 호스트 진단 루틴](M-002_haos-host-diagnosis-routine.md) | 접속 불가 또는 상태 점검 요청 | 비파괴 진단 결과와 다음 조치 |

## ⚙️ 파일 규칙

- 이름: `M-<3자리번호>_<slug>.md`
- 타입: `pkm-module`
- 필수 항목: 입력, 출력, 전제조건, 절차, 완료 조건, 관련 Spec과 Troubleshooting
