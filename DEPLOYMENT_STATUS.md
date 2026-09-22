# 배포 상태 — 2026-09-22

## 실제 확인 완료

- Oracle VirtualBox `7.2.18 r175117` 설치
- `Home Assistant` VM 생성 및 실행 확인
- VM UUID: 공개 저장소에는 기록하지 않음
- HAOS `18.3`, Home Assistant Core `2026.9.3`
- VM 사양: 2 vCPU, RAM 4096MB, EFI, Intel Wi-Fi 브리지, 32GB 동적 VDI
- HAOS IPv4 및 `homeassistant.local` mDNS 응답 확인
- Observer 4357: `Connected`, `Supported`, `Healthy`
- Home Assistant UI: 포트 80에서 HTTP 200 확인
- Home Assistant 2026.8 이후 Supervisor 설치의 포트 80 기본값을 문서와 검증 스크립트에 반영
- VirtualBox NDIS6 브리지 필터 활성화 확인
- Windows VBS와 Memory Integrity 활성화 확인
- VirtualBox NEM snail mode 확인. 현재 기능 장애가 아니라 부팅 성능 주의 사항으로 분류
- 전원이 꺼진 상태에서 VDI 바이트 복사본, VM 설정, NVRAM 백업 생성
- 원본 VDI와 바이트 복사본의 SHA-256 일치 확인
- Home Assistant 장면·자동화·한국어 문장·대시보드 구성 작성
- SwitchBot OpenAPI 허용 목록 사용자 통합 작성
- 모든 PowerShell 파일 문법 검사 통과
- Python 사용자 통합 컴파일 통과
- YAML·JSON 파싱 통과
- Home Assistant에서 호출하는 IR 작업 18개가 허용 목록 18개에 모두 존재함을 확인
- Git diff 형식 검사와 비밀값 패턴 검사 통과

## 현재 접속 주소

```text
http://homeassistant.local
```

포트 80을 사용할 수 없는 설치에서만 `http://homeassistant.local:8123`을 시도한다.

## 로컬 복구 자료

- VM: `%LOCALAPPDATA%\HomeAssistantVM\vm\Home Assistant`
- VDI: `%LOCALAPPDATA%\HomeAssistantVM\vm\haos_ova-18.3.vdi`
- 사전 복구 백업: `%LOCALAPPDATA%\HomeAssistantVM\backups\2026-09-22-pre-recovery`
- 진단 스크린샷과 체크포인트: `%LOCALAPPDATA%\HomeAssistantVM\evidence`

백업과 증거 파일은 공개 GitHub 저장소에 올리지 않는다.

## 사용자 계정·물리 작업 대기

- SwitchBot 앱에서 IR 코드 학습과 5회 반복 시험
- 포트 80 주소로 Home Assistant UI 로그인 확인
- SwitchBot Cloud, Home Assistant Cloud, OpenAI, 필요 시 SmartThings 로그인
- S23 위치·백그라운드·알림·기본 Assist 권한 설정
- 실제 SwitchBot/OpenAPI 엔티티 및 장치 ID 입력
- Station 버튼 루틴과 SwitchBot 독립 CO₂ 경보 생성
- 실기기 전체 검증

## 알려진 정상 지연

HAOS 18.3은 VirtualBox 부팅 중 QEMU guest-agent용 장치를 최대 90초 기다릴 수 있다. 콘솔이 해당 줄에 잠시 머물러도 이후 `System is ready`와 포트 80 응답이 확인되면 부팅 실패가 아니다.
