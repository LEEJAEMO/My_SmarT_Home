# 배포 상태 — 2026-08-09

## 이 작업에서 실제 적용 완료

- Galaxy Book6 Pro 호스트 환경 점검
- Windows `SAMSUNG MODE` 전원 구성에서 AC 절전: `사용 안 함(0초)`
- Windows `SAMSUNG MODE` 전원 구성에서 AC 최대 절전: `사용 안 함(0초)`
- 배터리 절전 설정 보존
- 공식 HAOS `18.2` VDI 다운로드 및 압축 해제
- 다운로드 SHA-256 검증 통과: `fdcb5055cfe89cc2d11e58f2e9ba17d453d7394cfe12c1952e2b2211d394655a`
- Home Assistant 장면·자동화·한국어 문장·대시보드 구성 작성
- SwitchBot OpenAPI 허용 목록 사용자 통합 작성
- YAML, JSON, Python, Windows PowerShell 문법 검증 통과
- Home Assistant에서 호출하는 모든 IR 작업이 허용 목록에 존재하는지 교차 검증 통과

## 로컬 준비 파일

- HAOS ZIP: `%LOCALAPPDATA%\HomeAssistantVM\downloads\haos_ova-18.2.vdi.zip`
- HAOS VDI: `%LOCALAPPDATA%\HomeAssistantVM\vm\haos_ova-18.2.vdi`

## 관리자 승인 후 자동 수행될 항목

- Oracle VirtualBox 설치
- `Home Assistant` VM 생성: 2 vCPU, RAM 4096MB, EFI, Wi-Fi 브리지, 32GB 가상 디스크
- VM 헤드리스 시작
- Windows 로그인 30초 후 VM 자동 시작 작업 등록

실행 파일: `setup/00_run_host_setup_as_admin.ps1`

## 사용자 계정·물리 작업 대기

- SwitchBot 앱에서 IR 코드 학습과 5회 반복 시험
- Home Assistant 최초 관리자 계정 생성
- SwitchBot Cloud, Home Assistant Cloud, OpenAI, 필요 시 SmartThings 로그인
- S23 위치·백그라운드·알림·기본 Assist 권한 설정
- 실제 SwitchBot/OpenAPI 엔티티 및 장치 ID 입력
- Station 버튼 루틴과 SwitchBot 독립 CO₂ 경보 생성
- 실기기 전체 검증
