---
type: pkm-work-log
date: 2026-09-28
title: 실제 패널 기반 안전 구현과 HA 접속 진단
status: local-implementation-validated-live-deployment-pending
live_changes: false
topics: [home-assistant, switchbot, audit, github]
---

# 2026-09-28 실기기 기반 구현 작업 로그

## 시작 상태

- 로컬 `main` HEAD `df46467`, `AGENTS.md`·`README.md` 및 `PKM/` 미커밋 변경이 있었다. 기존 변경을 reset/checkout으로 버리지 않았다.
- 09-27 인증된 HA UI: SwitchBot Cloud 기기 6개 등록, 두 에어컨 수동 패널은 switch 엔티티, 커튼·CO₂ 센서는 unavailable. 어떤 실기기 명령도 실행하지 않았다.
- GitHub MCP로 `LEEJAEMO/My_SmarT_Home`의 저장소 권한과 main 소스를 읽었다. 로컬 Git HTTPS 접속은 불가한 환경이다.

## 구현

- 에어컨 확정 프리셋을 차단하고 수동 세 버튼 의미를 분리했다. 선풍기는 토글·순환 표시만 남겼다.
- 사용자 통합을 명시적 검증·native HA 엔티티/IR 허용 목록, 최소 2초 간격, 중복·재시도 차단, 전달/물리 상태 구분으로 보강했다.
- 장면은 커튼만, 환기는 기록만 담당하게 줄였다. CO₂ 데이터 지연 때 값과 환기 완료 판단을 차단한다.
- 장면·알림·자동화·음성 활성화 스위치를 도입했다. 대시보드의 미검증 가전 실행 버튼을 숨겼다.
- CHECKLIST, README, 사용자 매뉴얼의 최신 우선 경고, S-005에 동작 계약을 기록했다.

## 검증 및 한계

- `setup/06_validate_repository.ps1`: PowerShell 7개, Python 3개, YAML 6개, JSON 1개, Jinja 템플릿 52개 구문 통과. 모의 HA 백엔드·정적 안전 테스트 24개 통과. `git diff --check` 통과.
- 첫 테스트 실행에서는 테스트 하네스가 intent의 action 목록을 문자열로 취급하는 오류 1건이 있었다. 하네스를 수정했고 추가 안전 조건 두 개를 검사했다. 최종 24개가 통과했다. 이는 앱 제품 결함이나 실기기 시험 실패가 아니다.
- 09-28 14:23 JST 읽기 전용 `setup/05_diagnose_haos_vm.ps1`: VirtualBox 7.2.18, VM running, Wi-Fi 브리지 필터 on, NEM snail mode, Observer 4357 true, Core UI 80/8123 false. 웹 UI 배포·구성 검사·재시작은 못 했다. 09-27 실기기 unavailable 상태는 현재 재확인이 필요하다.
- UI audit: 이전 활성 dashboard는 기본 HA 카드였고 장면 `toggle` 6개가 관찰됐다. 새 dashboard는 HA에 미배포라 활성 리소스 parity·프런트엔드 클릭·S23 touch·실기기 검증은 미실행. 모의 백엔드 테스트가 이를 대체하지 않는다.
- 자격 증명이나 실제 device ID를 저장소로 옮기지 않았다. 운영 HA의 기존 파일은 아직 변경하지 않았다.

## 다음 시작점

Core UI 복구를 확인한 다음 각 파일의 복구본, 실제 엔티티·서비스 매핑, HA 구성 검사, 재시작, 활성 리소스 지문과 실기기 테스트 순서로 진행한다. PR/원격 병합만으로 HA가 배포되지는 않는다. 조명·프로젝터·Station 기능은 물리·프로토콜 시험 전 차단한다.
