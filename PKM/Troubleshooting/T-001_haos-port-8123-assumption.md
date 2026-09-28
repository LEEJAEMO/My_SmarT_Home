---
type: pkm-troubleshooting
id: T-001
title: Home Assistant가 정상인데 8123 포트 검사로 장애 오진
domain: [home-assistant, haos, supervisor, network, port]
symptom: homeassistant.local:8123 연결 실패로 HAOS 또는 Core 장애처럼 보임
root_cause: 현재 Supervisor 기반 설치가 Core UI를 포트 80에 게시하지만 기존 검사와 문서가 8123만 가정함
resolution: 포트 80, 8123, Observer 4357을 독립 검사하고 실제 열린 포트를 URL로 보고
resolved_date: 2026-09-22
severity: high
reproducible: true
related_module: M-002
---

# T-001. 포트 8123 고정 가정으로 인한 HAOS 장애 오진

_정상 Home Assistant Core를 잘못된 포트 가정 때문에 장애로 판단한 사례입니다._

---

## 🔍 증상

- `http://homeassistant.local:8123`이 열리지 않는다.
- VirtualBox 콘솔이 느려 보여 HAOS 부팅 실패처럼 보인다.
- 기존 검증 스크립트가 8123 실패만 보고 오류 코드를 반환한다.

## ⚠️ 오진 방지

8123 연결 실패만으로 Core 장애, Supervisor 장애, HAOS 손상 또는 네트워크 실패를 결론 내리지 않는다. 포트 80과 Observer 4357을 먼저 확인한다.

## 📋 확인된 근본 원인

2026-09-22 진단에서 다음이 확인됐다.

| 계층 | 결과 |
| --- | --- |
| HAOS | 실행 확인 |
| Supervisor | Observer 4357에서 Healthy |
| Core UI | `192.168.0.9:80`에서 HTTP 200 |
| 8123 | 기존 가정과 달리 기본 UI 포트가 아니었음 |

즉 장애 원인은 Home Assistant가 아니라 저장소의 고정 포트 가정이었다. `192.168.0.9`는 당시 관찰값이며 고정 주소로 사용하지 않는다.

## 🔧 해결

- `setup/03_validate_host.ps1`이 80과 8123을 모두 검사하도록 수정
- `setup/05_diagnose_haos_vm.ps1`을 추가해 80, 8123, 4357을 분리 진단
- 문서의 기본 URL을 `http://homeassistant.local`로 변경
- 80이 닫힌 경우에만 `:8123`을 대체 경로로 안내
- DNS가 여러 주소를 반환할 때 IPv4를 우선 시험

## ✅ 검증

- 포트 80 HTTP 200 확인
- Observer가 Connected, Supported, Healthy 상태임을 확인
- PowerShell parser와 전체 저장소 검증 통과
- 원격 PR에서 변경 파일 9개와 의도한 diff를 확인

## 🔄 재발 방지

- 포트 번호를 Home Assistant의 영구 상수로 간주하지 않는다.
- 새 진단 코드에서는 서비스 계층별 포트를 별도 필드로 기록한다.
- IP 주소와 포트는 진단 시점의 증거와 설정 정본을 구분한다.
- 관련 진단은 [M-002](../Modules/M-002_haos-host-diagnosis-routine.md)를 재사용한다.
