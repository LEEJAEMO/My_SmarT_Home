---
type: pkm-spec
id: S-001
title: 스마트홈 시스템 아키텍처
domain: [smart-home, home-assistant, switchbot, smartthings, galaxy]
status: implemented-with-user-setup-pending
source_of_truth: [README.md, DEPLOYMENT_STATUS.md, home-assistant]
created: 2026-09-22
updated: 2026-09-22
---

# S-001. 스마트홈 시스템 아키텍처

> 2026-09-26 주석: 본문은 09-22 구성 기록이다. 사용자는 현재 HA SwitchBot 패널을 사용하고 있으며, 조명·프로젝터의 IR 여부는 다시 확인해야 한다. 최신 계획과 미확정 사항은 [S-004](S-004_active-device-planning.md)를 우선한다.

_Galaxy Book6 Pro의 Home Assistant를 주 제어 계층으로 사용하고 SwitchBot·SmartThings를 보조 경로로 유지하는 구조입니다._

---

## 📋 구성 요소

| 계층 | 구성 | 역할 | 상태 |
| --- | --- | --- | --- |
| 사용자 | Galaxy S23 Ultra | HA 앱, Assist, 알림, SmartThings, Bixby | 사용자 설정 대기 |
| 호스트 | Galaxy Book6 Pro | Windows 11 Home, VirtualBox 실행 | 설치·VM 확인 |
| 자동화 | Home Assistant OS | 장면, 조건, 한국어 명령, 상태 추정 | 구성 파일 작성 |
| AI | Home Assistant Cloud + OpenAI | 원격 접속, 한국어 음성, 허용된 자연어 해석 | 계정 연결 대기 |
| 장치 클라우드 | SwitchBot Cloud/OpenAPI | 커튼·센서·IR 리모컨 연결 | 실기기 연결 대기 |
| 보조 제어 | SmartThings + SwitchBot 앱 | HA 중단 시 기본 제어와 CO₂ 경보 | 사용자 설정 대기 |
| 물리 장치 | 커튼, CO₂ 센서, Daikin, Comfee, 전등, 프로젝터 | 실제 환경 제어 | IR 학습·검증 대기 |

## 🔗 연결 구조

~~~mermaid
flowchart LR
    accTitle: 스마트홈 제어 아키텍처
    accDescr: Galaxy S23에서 Home Assistant를 주 경로로 사용하고 SmartThings와 SwitchBot 앱을 보조 경로로 유지하며 Hub Mini가 IR 가전을 제어하는 구조

    user([👤 Galaxy S23]) --> ha_cloud[☁️ HA Cloud와 Assist]
    ha_cloud --> haos[🖥️ HAOS VM]
    ai[🧠 OpenAI 안전 명령] <--> haos
    haos --> switchbot[🔌 SwitchBot Cloud]
    switchbot --> hub[🌐 Hub Mini]
    hub --> appliances[⚙️ IR 가전]
    switchbot --> curtain[⚙️ 커튼]
    meter[📊 CO₂ 센서] --> switchbot
    user --> fallback[🔌 SmartThings와 SwitchBot 앱]
    fallback --> switchbot

    classDef primary fill:#dbeafe,stroke:#2563eb,stroke-width:2px,color:#1e3a5f
    classDef device fill:#dcfce7,stroke:#16a34a,stroke-width:2px,color:#14532d
    classDef fallback_style fill:#fef9c3,stroke:#ca8a04,stroke-width:2px,color:#713f12

    class user,ha_cloud,haos,ai primary
    class switchbot,hub,appliances,curtain,meter device
    class fallback fallback_style
~~~

## ⚙️ Home Assistant 호스트

| 항목 | 사양 |
| --- | --- |
| VirtualBox | 7.2.18 r175117 |
| HAOS | 18.3 |
| Home Assistant Core | 2026.9.3 |
| CPU·메모리 | 2 vCPU, RAM 4096MB |
| 디스크 | 32GB 동적 VDI |
| 펌웨어 | EFI |
| 네트워크 | Intel Wi-Fi 브리지 |
| 기본 URL | `http://homeassistant.local` |
| 진단 포트 | UI 80, 대체 UI 8123, Observer 4357 |

2026-09-22에 HAOS와 Supervisor가 정상이며 Core UI가 관찰된 IPv4 `192.168.0.9`의 포트 80에서 HTTP 200으로 응답하는 것을 확인했다. IPv4는 DHCP로 변경될 수 있다.

## 🏠 장치 모델

| 장치 | 제어 방식 | 상태 특성 |
| --- | --- | --- |
| SwitchBot Curtain | SwitchBot 통합 | 위치 또는 개폐 제어 |
| Meter Pro CO₂ | SwitchBot 통합 | CO₂와 실내 온도 센서 |
| Daikin 구형 에어컨 | 학습한 IR 프리셋 | 완전 상태 코드를 프리셋별 전송 |
| Comfee 선풍기 | 사용자 지정 IR 버튼 | 전원 토글과 assumed-state 필요 |
| 전등 | 학습한 IR 버튼 | ON·OFF 분리, 밝기 증감 |
| 빔프로젝터 | 학습한 IR 버튼 | 분리 ON/OFF 또는 토글, 냉각 종료 필요 |
| SmartThings Station 2 | SmartThings 루틴 | 장면 호출용 보조 입력 |

## 🔄 가용성 경계

- Galaxy Book이 켜져 있을 때 Home Assistant가 복합 자동화의 주 계층이다.
- Galaxy Book이 꺼져 있어도 SwitchBot 앱과 SmartThings의 기본 제어를 남긴다.
- CO₂ 1000ppm·1500ppm 경보는 SwitchBot 앱에도 독립적으로 구성한다.
- 노트북을 자주 외부로 가져가게 되면 HA Green 또는 N100 미니 PC 이전을 별도 결정한다.

## 🔗 관련 문서

- [S-002 자동화 및 안전 계약](S-002_automation-and-safety-contract.md)
- [S-003 저장소 및 배포 계약](S-003_repository-and-deployment-contract.md)
- [M-002 HAOS 진단 루틴](../Modules/M-002_haos-host-diagnosis-routine.md)
