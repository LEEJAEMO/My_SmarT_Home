---
type: pkm-module
id: M-002
title: HAOS VirtualBox 호스트 진단 루틴
domain: [home-assistant, haos, virtualbox, windows, network]
task_type: workflow
input: Home Assistant 접속 불가, 느린 부팅, 상태 점검 요청
output: VM·네트워크·Core·Supervisor를 분리한 비파괴 진단 결과
related_spec: [S-001, S-003]
related_troubleshooting: [T-001, T-003]
created: 2026-09-22
updated: 2026-09-22
---

# M-002. HAOS VirtualBox 호스트 진단 루틴

_복구 작업 전에 VM, 게스트 네트워크, Supervisor, Core UI를 분리해 확인하는 절차입니다._

---

## 🎯 진단 원칙

- 먼저 읽기 전용으로 조사한다.
- 포트 8123 하나만으로 장애를 판정하지 않는다.
- 포트 80, 8123, Observer 4357을 독립적으로 확인한다.
- mDNS가 IPv6와 IPv4를 함께 반환하면 IPv4부터 시험한다.
- NEM snail mode나 guest-agent 대기는 부팅 지연 신호이지 단독 장애 증거가 아니다.
- 디스크 변경이나 복구 전에 VM을 종료하고 VDI와 VM 설정을 백업한다.

## 🔍 1단계: 통합 진단 실행

저장소 루트에서 다음을 실행한다.

~~~powershell
& '.\setup\05_diagnose_haos_vm.ps1'
~~~

JSON 증거가 필요하면 공개 저장소 밖의 로컬 evidence 경로를 지정한다.

~~~powershell
& '.\setup\05_diagnose_haos_vm.ps1' -EvidencePath '<local-evidence-path>\haos-diagnosis.json'
~~~

진단 파일에는 환경 정보가 포함될 수 있으므로 Git에 추가하지 않는다.

## 📊 2단계: 결과 판별

| 관찰 | 해석 | 다음 조치 |
| --- | --- | --- |
| 80 열림 | 현재 HA UI 정상 | `http://homeassistant.local` 접속 |
| 8123만 열림 | 레거시 또는 대체 포트 | `:8123`으로 접속 |
| 4357만 열림 | HAOS·Supervisor 응답, Core UI 문제 | HA CLI에서 Core 정보와 로그 확인 |
| 세 포트 모두 닫힘 | 부팅 또는 게스트 네트워크 문제 | 콘솔, 브리지, DHCP, VM 상태 확인 |
| VM 정지 | 호스트 실행 문제 | 자동 시작 작업과 VM 상태 확인 |

관찰된 IP 주소는 그 시점의 증거일 뿐 설정 정본이 아니다.

## ⚙️ 3단계: 계층별 확인

### Windows·VirtualBox

- VirtualBox 설치 및 버전
- VM 존재와 실행 상태
- EFI, vCPU, RAM, 브리지 어댑터
- Oracle NDIS6 브리지 필터
- VBS·Memory Integrity·Windows 하이퍼바이저
- `VBox.log`의 NEM snail mode 문구

### HAOS·Supervisor

- 콘솔이 부팅을 완료했는지 확인
- Observer 4357 연결 여부 확인
- 필요할 때 HA CLI에서 `ha supervisor info`와 `ha core info` 확인

### Home Assistant Core

- 포트 80과 8123을 각각 TCP 검사
- 열린 포트에 HTTP 요청을 보내 상태 코드를 확인
- HTTP 200이 확인되면 Core UI는 정상으로 분류

## 🔧 4단계: 복구로 넘어가는 조건

다음 조건을 확인하기 전에는 디스크 복구나 재설치를 시작하지 않는다.

- VM이 충분한 시간 동안 실행되었음
- 80, 8123, 4357 모두 닫혀 있음
- 콘솔과 로그가 같은 계층의 실패를 가리킴
- 브리지 또는 NAT 격리 시험 결과가 있음
- 데이터 보존형 백업이 완료됨

세부 복구 절차는 `docs/HAOS VirtualBox 진단 및 복구.md`를 따른다. 데이터 디스크 wipe와 프로젝터 전원 차단 같은 파괴적 우회는 사용하지 않는다.

## ✅ 완료 조건

- [ ] VM, 네트워크, Supervisor, Core 상태가 구분됨
- [ ] 실제 열린 포트와 접속 URL이 기록됨
- [ ] 과거 IP나 포트 가정에 의존하지 않음
- [ ] 복구가 필요하면 먼저 백업과 증거가 확보됨
- [ ] 결과가 새 사실일 때만 배포 상태와 Log가 갱신됨

## 🔗 관련 문서

- [T-001 포트 8123 고정 가정](../Troubleshooting/T-001_haos-port-8123-assumption.md)
- [T-003 느린 부팅 판별](../Troubleshooting/T-003_haos-slow-boot-not-failure.md)
- [S-003 저장소 및 배포 계약](../Specs/S-003_repository-and-deployment-contract.md)
- [2026-09-22 작업 Log](../Logs/2026-09-22-haos-port-diagnostics-and-pr.md)
