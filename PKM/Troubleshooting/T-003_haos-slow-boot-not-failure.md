---
type: pkm-troubleshooting
id: T-003
title: HAOS 느린 부팅을 시스템 실패로 오진
domain: [haos, virtualbox, windows, nem, boot]
symptom: HAOS 콘솔이 특정 줄에 오래 머물고 웹 포트가 즉시 열리지 않음
root_cause: Windows 하이퍼바이저 경유 NEM snail mode와 QEMU guest-agent 장치 대기 가능성
resolution: 충분한 시간 후 콘솔 완료, 포트 80·8123·4357과 로그를 함께 판정
resolved_date: 2026-09-22
severity: medium
reproducible: conditional
related_module: M-002
---

# T-003. HAOS 느린 부팅은 단독 장애 증거가 아님

_VirtualBox의 느린 실행 경로와 HAOS 초기 대기를 실제 부팅 실패와 구분합니다._

---

## 🔍 증상

- HAOS 콘솔이 호스트 persistent config 또는 guest-agent 관련 줄에 머문다.
- VM 상태는 running이지만 웹 포트가 바로 열리지 않는다.
- `VBox.log`에 `Snail execution mode is active`가 나타난다.

## ⚠️ 오진 방지

NEM snail mode 문구나 약 90초의 guest-agent 대기만으로 디스크 손상이나 HAOS 실패를 결론 내리지 않는다. 해당 문구는 성능 저하 가능성을 뜻하며 Core 불통의 단독 증거가 아니다.

## 📋 판별 기준

| 증거 | 판단 |
| --- | --- |
| 시간이 지난 뒤 포트 80 HTTP 응답 | 느렸지만 정상 부팅 |
| 4357만 응답 | Supervisor는 살아 있고 Core를 추가 조사 |
| 세 포트가 계속 닫히고 콘솔도 진행하지 않음 | 부팅 또는 네트워크 조사 필요 |
| NAT에서는 되고 브리지에서 실패 | 브리지 어댑터·필터 문제 가능 |

## 🔧 해결 절차

1. VM 실행 시간을 확인하고 초기 대기 시간을 허용한다.
2. [M-002](../Modules/M-002_haos-host-diagnosis-routine.md)를 실행한다.
3. 콘솔, `VBox.log`, 80·8123·4357 결과를 함께 본다.
4. 필요하면 데이터 보존형 백업 후 NAT 격리 시험을 수행한다.
5. VBS와 Memory Integrity 변경은 영향과 복구 방법을 검토한 뒤 별도 작업으로 한다.

## 🔄 재발 방지

- 검증 스크립트에 단일 타임아웃 결과만 저장하지 않는다.
- 성능 경고와 기능 장애를 별도 필드로 기록한다.
- 최신 라이브 상태가 필요하면 과거 로그 대신 진단을 다시 실행한다.
