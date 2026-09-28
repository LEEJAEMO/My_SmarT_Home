---
type: pkm-moc
title: 스마트홈 PKM
domain: [smart-home, home-assistant, operations]
updated: 2026-09-22
---

# 스마트홈 PKM

_스마트홈의 설계, 반복 절차, 장애 해결, 작업 이력을 Git과 함께 관리하는 지식 지도입니다._

---

## 🎯 목적

이 PKM은 Git 저장소, Home Assistant 실제 환경, ChatGPT/Codex 작업 사이의 기억 손실을 줄인다. 다음 작업은 [에이전트 컨텍스트](llms.md)에서 시작하고 필요한 상세 문서만 추가로 읽는다.

~~~mermaid
flowchart LR
    accTitle: 스마트홈 지식 순환
    accDescr: 실제 Home Assistant 상태와 Git 변경, 에이전트 작업 기록이 Specs, Modules, Troubleshooting, Logs를 통해 다음 세션으로 전달되는 흐름

    actual_state([🏠 실제 HA 상태]) --> verify[🔍 증거 확인]
    verify --> specs[📋 Specs 갱신]
    verify --> troubleshoot[🔧 Troubleshooting 기록]
    change[✏️ Git 변경] --> validate[✅ 필수 검증]
    validate --> modules[🔄 Modules 재사용]
    validate --> work_log[📝 작업 Log]
    specs --> next_agent([🤖 다음 에이전트])
    troubleshoot --> next_agent
    modules --> next_agent
    work_log --> next_agent
    next_agent --> change

    classDef source fill:#ede9fe,stroke:#7c3aed,stroke-width:2px,color:#3b0764
    classDef process fill:#dbeafe,stroke:#2563eb,stroke-width:2px,color:#1e3a5f
    classDef knowledge fill:#dcfce7,stroke:#16a34a,stroke-width:2px,color:#14532d

    class actual_state,next_agent source
    class verify,change,validate process
    class specs,troubleshoot,modules,work_log knowledge
~~~

## 📚 영역

| 영역 | 역할 | 갱신 시점 |
| --- | --- | --- |
| [Modules](Modules/llms.md) | 반복 가능한 작업 절차 | 같은 절차를 다시 쓸 가치가 생길 때 |
| [Troubleshooting](Troubleshooting/llms.md) | 증상·원인·해결·재발 방지 | 장애의 근본 원인을 확인했을 때 |
| [Specs](Specs/llms.md) | 현재 시스템의 정본 | 구조·안전 계약·운영 기준이 바뀔 때 |
| [Logs](Logs/llms.md) | 날짜별 작업과 검증 증거 | 작업을 마칠 때 |

## 📍 정본 우선순위

충돌이 있으면 실제 증거, 실행 구성, 명세, 작업 로그, 설명 문서 순으로 판단한다.

1. 실제 Home Assistant와 호스트에서 새로 수집한 증거
2. `home-assistant/`와 `setup/`의 실행 구성
3. `PKM/Specs/`
4. `PKM/Logs/`
5. `README.md`와 사용자 문서

> ⚠️ **주의:** 작업 로그의 과거 관찰을 현재 상태로 단정하지 않는다. 현재 상태가 필요하면 읽기 전용 진단을 다시 실행한다.

## 🔄 운영 방식

- 에이전트는 먼저 [llms.md](llms.md)를 읽는다.
- 변경 전 Git 상태와 기존 사용자 변경을 확인한다.
- 변경 후 필수 검증과 비밀정보 검사를 수행한다.
- 동작이나 안전 계약이 바뀌면 Spec과 Log를 같은 변경에 포함한다.
- 해결된 장애가 다시 발생할 수 있으면 Troubleshooting 문서를 추가한다.
