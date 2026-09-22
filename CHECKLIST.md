# 스마트홈 최종 연결 체크리스트

컴퓨터에서 자동화 파일을 만드는 단계까지는 자동화할 수 있지만, 물리 리모컨 학습·휴대전화 권한·삼성/SwitchBot/OpenAI 로그인·유료 구독 확인은 사용자가 직접 해야 합니다. 아래 순서대로 진행하면 엔티티 이름을 다시 고치는 일을 줄일 수 있습니다.

## 0. Galaxy Book 호스트 완성

탐색기에서 `setup/00_run_host_setup_as_admin.ps1`를 PowerShell로 실행하고 Windows 관리자 승인 창에서 `예`를 선택합니다. 이 스크립트는 VirtualBox를 설치하고, 로컬에 미리 받은 HAOS 디스크로 `Home Assistant` VM(2 vCPU, RAM 4GB, 32GB, EFI, Wi-Fi 브리지)을 만든 뒤 로그인 자동 시작을 등록합니다. 전원 연결 중 절전/최대 절전은 해제하며 배터리 설정은 보존합니다.

완료 후 일반 PowerShell에서 다음 검증을 실행합니다.

```powershell
& '.\setup\03_validate_host.ps1'
```

## 1. SwitchBot IR 리모컨 학습

Hub Mini를 네 가전과 직접 시야가 확보되고 5V 전원이 안정적인 곳에 고정합니다. IR 명령이 닿지 않는 가전이 하나라도 있으면 위치부터 조정합니다.

### 다이킨 에어컨

SwitchBot 앱에서 일반 모델 검색 대신 `에어컨 > 버튼 학습`을 사용합니다. 에어컨 리모컨은 현재 온도·모드·풍량 전체 상태를 한 번에 보내므로 리모컨 화면을 정확한 상태로 만든 뒤 ON 코드를 학습합니다.

- `다이킨_냉방26`: 냉방 26℃, 풍량 자동 ON
- `다이킨_난방20`: 난방 20℃, 풍량 자동 ON
- `다이킨_제습`: 평소 사용하는 제습 ON
- OFF 신호: 위 가상 리모컨 중 하나의 OFF 버튼에 학습하고, 그 리모컨의 ID를 `switchbot_daikin_off_device_id`에 사용

각 가상 리모컨의 ON/OFF를 앱에서 5회씩 시험합니다. 에어컨이 이미 켜진 상태에서도 OFF가 항상 종료되는지 확인합니다.

### Comfee 선풍기

먼저 `Fan` 유형으로 학습합니다. 모든 버튼이 Home Assistant/SwitchBot API에 나타나지 않으면 `Others`로 다시 만들고 버튼명을 정확히 다음과 같이 고정합니다.

- `전원`, `약풍`, `중풍`, `강풍`, `회전`, `자연풍`, `2시간타이머`

제공된 기본 구성은 `Others + customize` 방식입니다. Fan 유형을 유지하려면 OpenAPI 장치 목록과 명령 규격에 맞춰 `configuration.yaml`의 `fan_*` 명령을 바꿉니다. 전원 버튼이 토글이면 구축 후 물리 리모컨 사용을 피합니다.

### 전등과 프로젝터

- 전등 버튼명: `ON`, `OFF`, `밝기증가`, `밝기감소`
- 프로젝터 분리형 버튼명: `ON`, `OFF`
- 프로젝터 토글형 버튼명: `전원`

프로젝터가 분리 ON/OFF면 Home Assistant의 `프로젝터 ON/OFF 분리 코드 사용` 도우미를 켭니다. 토글형이면 끈 상태에서 도우미 `프로젝터 추정 전원`도 꺼짐으로 맞춥니다. 프로젝터 냉각을 위해 스마트 플러그 강제 차단은 사용하지 않습니다.

## 2. SwitchBot OpenAPI 값 확인

SwitchBot 앱의 `프로필 > 환경설정 > 개발자 옵션`에서 Token과 Secret을 발급합니다. Windows PowerShell에서 다음을 실행하면 토큰을 파일에 저장하지 않고 장치 ID를 확인할 수 있습니다.

```powershell
& '.\setup\04_discover_switchbot_devices.ps1'
```

출력된 IR 가상 리모컨 ID를 `/config/secrets.yaml`에 입력합니다. 실제 Token/Secret 파일은 공유하거나 공개 저장소에 올리지 않습니다.

## 3. Home Assistant 최초 설정과 파일 배포

1. `http://homeassistant.local`에서 최초 관리자 계정을 만들고 집 위치·시간대를 실제 주소와 `Asia/Tokyo`로 확인합니다. 열리지 않을 때만 `http://homeassistant.local:8123`을 시도합니다.
2. `설정 > 애드온 > 애드온 스토어`에서 `File editor`를 설치합니다.
3. 이 폴더의 `home-assistant/custom_components`, `packages`, `custom_sentences`, `dashboards`를 HA의 `/config` 아래 같은 경로로 복사합니다.
4. `configuration.yaml.example` 내용을 기존 `/config/configuration.yaml`에 병합합니다. 기존 `default_config:`는 삭제하지 않습니다.
5. `secrets.yaml.example`을 참고해 실제 `/config/secrets.yaml`을 채웁니다.
6. `개발자 도구 > YAML > 구성 검사`를 실행합니다. 오류가 0개일 때만 재시작합니다.
7. `스마트홈` 대시보드에서 `연결 설정`의 사람·커튼·CO₂·온도·S23 알림 서비스 엔티티 ID를 실제 값으로 고칩니다.

## 4. Home Assistant 통합

`설정 > 장치 및 서비스 > 통합 추가`에서 다음 순서로 연결합니다.

1. `SwitchBot Cloud`: SwitchBot 계정 연결. 커튼, Meter Pro CO₂, 지원되는 IR 리모컨을 확인합니다.
2. `Home Assistant Cloud`: 계정 로그인, 원격 접속, 한국어 Speech-to-text/Text-to-speech를 설정합니다.
3. `OpenAI`: API 키를 입력합니다. 추천 설정을 끄고 모델을 `gpt-5.6-luna`로 지정하며 웹 검색과 요청 저장은 끕니다. OpenAI 프로젝트에 낮은 월 사용 한도와 알림을 먼저 설정합니다.
4. `SmartThings`는 Station 버튼 이벤트를 Home Assistant로 직접 가져올 때만 추가합니다. 단순 SwitchBot 제어는 SmartThings 앱의 연결된 서비스로 충분합니다.

Home Assistant의 `설정 > 음성 어시스턴트 > 노출`에서 다음만 Assist에 노출합니다.

- 에어컨 프리셋 4개, 선풍기 스크립트, 전등, 프로젝터, 여섯 장면
- CO₂와 온도 센서(읽기 전용)
- 커튼

`switchbot_ir_allowlist.send`, 토큰, 장치 ID, 모든 설정 도우미는 노출하지 않습니다. OpenAI 대화 에이전트 지침에는 `openai_instructions_ko.txt` 내용을 붙여 넣습니다.

## 5. Galaxy S23 Ultra

1. Home Assistant Companion 앱을 설치하고 Cloud 원격 URL로 로그인합니다.
2. 위치 권한은 `항상 허용`, 정확한 위치를 켭니다. 배터리는 `제한 없음`, 백그라운드 데이터와 알림을 허용합니다.
3. HA 앱 `설정 > Companion app > Manage sensors`에서 위치 센서를 켭니다.
4. Android `설정 > 앱 > 기본 앱 > 디지털 어시스턴트 앱`에서 Home Assistant Assist를 선택합니다.
5. HA 앱에서 홈 화면 Assist 위젯을 만들고, 실험 기능을 허용할 경우에만 `Hey Nabu`를 켭니다.
6. 집 Wi-Fi를 끈 상태에서도 Cloud URL 접속, 알림, 음성 명령이 되는지 확인합니다.

## 6. SmartThings와 Station 버튼

SmartThings 앱 `메뉴 > 연결된 서비스 > SwitchBot`에서 계정을 연결합니다. 커튼과 표시되는 IR 장치만 Bixby의 간단한 전원 명령에 사용합니다.

Station 버튼 루틴은 다음과 같이 지정합니다.

- 짧게: `영화`
- 두 번: `환기`
- 길게: `수면`

사용자 지정 IR 버튼이 SmartThings에 없으면 해당 루틴을 억지로 만들지 않습니다. 대신 Home Assistant의 SmartThings 통합에서 Station이 이벤트 엔티티로 나타나는 경우, 각 이벤트 유형을 HA의 `script.scene_movie`, `script.scene_ventilation`, `script.scene_sleep`에 연결합니다. 엔티티가 나타나지 않으면 S23의 스마트홈 대시보드/음성 위젯을 사용합니다.

## 7. SwitchBot 앱의 독립 CO₂ 경보

Galaxy Book이 꺼진 때도 경보가 남도록 SwitchBot 앱 자동화를 별도로 만듭니다.

- CO₂ `>= 1000ppm`: 일반 환기 알림
- CO₂ `>= 1500ppm`: 긴급 재알림

Meter Pro CO₂는 USB 5V에 연결해 약 1분 갱신 주기로 사용합니다. Home Assistant SwitchBot Cloud 센서는 클라우드 폴링 특성상 더 늦을 수 있으므로 안전 경보는 SwitchBot 앱 알림을 주 경로로 유지합니다.

## 8. 검증표

- [ ] 각 IR 버튼을 SwitchBot 앱에서 5회씩 시험
- [ ] Home Assistant에서 냉방 26도, 난방 20도, 제습, OFF 시험
- [ ] 선풍기 약/중/강, 회전, 자연풍, 2시간 타이머, OFF 시험
- [ ] 전등 ON/OFF/밝기와 프로젝터 정상 냉각 종료 시험
- [ ] `냉방 26도로 켜`, `선풍기 강풍`, `영화 모드`, `환기 시작` 한국어 명령 시험
- [ ] 지원하지 않는 `냉방 25도`가 실행되지 않고 프리셋 안내만 하는지 확인
- [ ] S23가 홈 존을 벗어난 뒤 10분 후 외출 장면 시험
- [ ] 28℃ 초과/16℃ 미만 귀가 분기 시험
- [ ] CO₂ 1000/1500 알림과 800 미만 10분 환기 완료 알림 시험
- [ ] Galaxy Book 재부팅 후 VM 자동 시작과 `http://homeassistant.local` 복구 시험(필요 시 `:8123` 대체 포트 확인)
- [ ] Galaxy Book 종료 중 SwitchBot 앱, SmartThings 기본 제어, CO₂ 독립 알림 시험
