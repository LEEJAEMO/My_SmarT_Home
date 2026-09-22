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
- Comfee 선풍기를 SwitchBot `Others` IR 리모컨으로 등록하고 `POWER`, `Fan Speed 3`, `Timer`, `Mute` custom 명령이 Home Assistant에서 실제 동작함을 확인
- Comfee 실제 가상 리모컨 ID는 `/config/secrets.yaml`에만 저장하고 공개 저장소에는 기록하지 않음
- Home Assistant `/config`가 Git `ha-deploy` 브랜치를 추적하도록 전환하고 `configuration.yaml` 및 기존 `secrets.yaml` 보존 확인
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

## 다음 구축 대상

- 다이킨 에어컨: 냉방 26℃ / 난방 20℃ / 제습 / OFF IR 학습 및 반복 시험
- 전등: ON / OFF / 밝기 증가 / 밝기 감소 IR 학습 및 반복 시험
- 프로젝터: 분리 ON/OFF 여부 확인, 정상 종료·냉각 검증
- SwitchBot Hub Mini: 에어컨·전등·프로젝터까지 포함한 최종 IR 시야/배치 검증
- SwitchBot Curtain: Home Assistant 실제 엔티티 연결 및 열기/닫기 동작 검증
- Home Assistant Cloud, OpenAI, 필요 시 SmartThings 로그인
- S23 위치·백그라운드·알림·기본 Assist 권한 설정
- Station 버튼 루틴과 SwitchBot 독립 CO₂ 경보 생성
- 전체 장면 및 실기기 통합 검증

## 알려진 정상 지연

HAOS 18.3은 VirtualBox 부팅 중 QEMU guest-agent용 장치를 최대 90초 기다릴 수 있다. 콘솔이 해당 줄에 잠시 머물러도 이후 `System is ready`와 포트 80 응답이 확인되면 부팅 실패가 아니다.
