# 실제 패널 기반 스마트홈 적용 체크리스트

2026-09-28 기준. [개선 계획](docs/스마트홈%20실기기%20기반%20개선%20계획%202026-09-26.md)과 [S-004](PKM/Specs/S-004_active-device-planning.md)의 실제 버튼 의미를 따른다. 이 저장소의 변경사항이 HA에 자동 배포되지는 않는다.

## 1. 현재 확인된 사실

- HA SwitchBot Cloud에 6개 기기: 에어컨 3종, 전동커튼 3E, CO₂ 센서, Comfee 선풍기.
- 2026-09-27 읽기 전용 확인에서 전동커튼과 CO₂ 센서는 `unavailable`이었다. 배포 전에 다시 확인한다.
- ‘에어컨 수동’ ON/OFF는 모두 전원 버튼 한 번이다.
- ‘에어컨 off 모드 변경/ on 1시간 切’ ON은 모드 다음, OFF는 종료 예약 다음이다.
- 냉방26·난방20·제습·확정 OFF는 확보된 실제 명령이 아니다.
- Hxlight 조명·프로젝터의 HA 경로와 Station 모델·이벤트는 미확인이다.

## 2. 배포 전 복구·검증

- [ ] VM 상태와 `http://homeassistant.local` 접속을 재확인한다. 자동화의 커튼·CO₂ 수신이 `unavailable`이면 먼저 SwitchBot 연결 원인을 확인한다.
- [ ] HA File editor의 현재 `/config/packages/smart_home.yaml`, `/config/dashboards/smart_home.yaml`, `/config/custom_sentences/ko/smart_home.yaml`, `/config/custom_components/switchbot_ir_allowlist`, `/config/configuration.yaml`을 각각 별도 복구본으로 보존한다. 비밀이 포함될 수 있는 `secrets.yaml`은 공개 저장소에 복사하지 않는다.
- [ ] 로컬 `setup/06_validate_repository.ps1`의 PowerShell/Python/YAML/JSON/allowlist 테스트가 모두 통과한다.
- [ ] 파일 반영 후 HA ‘구성 검사’를 통과한 경우에만 재시작한다. 실패하면 복구본으로 돌아가고 원인을 기록한다.

## 3. 실제 패널 연결

- [ ] HA 엔티티에서 커튼 `cover.*`, CO₂·온도 `sensor.*`, 재실 `person.*`, 알림 `notify.mobile_app_*`의 현재 엔티티 ID를 확인한다.
- [ ] 관리자 화면의 연결 helper를 채운 뒤 실제 센서 값·마지막 HA 수신 시각을 확인한다. 이 값이 항상 1분마다 새로 도착한다고 가정하지 않는다.
- [ ] 커튼이 available이고 물리 동작을 확인했을 때만 `smarthome_curtain_verified`를 켠다.
- [ ] 에어컨 수동용 3개 native 명령은 실제 스위치 엔티티와 ON/OFF 의미를 확인한 뒤 HA 로컬 설정에서 `verified: true`로 바꾼다. example은 모두 false다. 실기기 버튼을 각 5회씩 시험하고 결과·지연·실패를 기록한다. 실제 전원·모드·예약 상태는 리모컨 화면으로 확인한다.
- [x] Comfee `Others`의 `POWER`, `Fan Speed 3`, `Timer`, `Mute`가 기존 HA에서 실기기 동작함을 확인했다(기존 배포 기록). 새 allowlist v2에서는 각 `verified`가 기본 false이므로 재배포 후 동작을 확인해 하나씩 활성화한다. 전원·속도·타이머는 토글 또는 순환으로만 표시한다.
- [ ] Hxlight 조명은 리모컨 IR 여부와 앱 BLE/RF 방식을 확인한 뒤 연결 경로를 결정한다. 확인되지 않으면 Hxlight 앱을 사용한다.
- [ ] 프로젝터는 정상 종료 절차·냉각 팬을 먼저 검증한다. 스마트 플러그 전원 차단은 사용하지 않는다.

## 4. 장면·환경 알림·음성

- [ ] 현재 기상·외출·영화·수면 준비 장면은 검증된 커튼만 호출한다. 귀가는 낮에만 커튼을 연다. 전등·에어컨·선풍기·프로젝터 자동 명령은 없다.
- [ ] ‘환기 기록 시작’은 창문을 직접 열고 CO₂ 새 수신이 확인될 때 실행한다. 에어컨·선풍기는 직접 확인한다.
- [ ] S23의 실제 알림 서비스 ID와 1000/1500ppm 경고를 시험한 뒤 `smarthome_notifications_enabled`를 켠다. 수신 지연 때 환기 완료를 말하지 않는지 확인한다.
- [ ] 재실 위치 인식과 커튼 동작을 검증한 뒤 `smarthome_automations_enabled`를 켠다.
- [ ] 고정 한국어 문장과 Assist 노출 목록을 실제 HA에서 점검한 뒤 `smarthome_voice_enabled`를 켠다. 에어컨·선풍기 수동 버튼, 원시 allowlist 서비스, 구성 helper를 AI에 노출하지 않는다.
- [ ] SwitchBot 앱에 독립 CO₂ 1000/1500ppm 알림을 유지한다. Galaxy Book 종료 중에도 실제 알림이 오는지 별도로 확인한다.

## 5. S23·Station·안정화

- [ ] Galaxy S23 Ultra의 HA 앱 위치·알림·백그라운드 설정과 실외 연결을 사용자 화면에서 확인한다.
- [ ] Station의 제품 모델과 SmartThings 버튼 이벤트를 확인하고, 한 번 누름 한 동작만 시험한다. 같은 장면을 HA와 SmartThings 양쪽에서 중복 실행하지 않는다.
- [ ] Hub/HA 끊김, 앱 재시작, 물리 리모컨 사용 후 표시 상태·명령 전달 상태를 확인한다.
- [ ] 최소 일주일간 실패·지연·불필요 알림을 기록하고 검증된 기능만 확장한다.

## 자동 배포의 경계

GitHub PR 생성이나 병합은 HA 배포가 아니다. 구성 검사·HA 재시작·실기기 시험은 별도 단계다. 실제 토큰, Device ID, HA 접근 토큰, `.storage`, VM 파일은 GitHub에 올리지 않는다.
