---
type: pkm-work-log
date: 2026-09-26
title: 실제 SwitchBot 패널 기반 개선 계획
status: document-saved-to-obsidian
topics: [home-assistant, switchbot, hxlight, projector, smartthings]
live_changes: false
---

# 2026-09-26 실기기 기반 개선 계획

## 🎯 요청과 범위

실제 HA SwitchBot 패널을 기준으로 조명·프로젝터·Station의 도입 범위를 판단하고, Obsidian Life/스마트홈 폴더에 property 포함 계획서를 작성하는 요청. HA Interaction Audit 및 GitHub 플러그인을 사용했다.

## 🔍 조사 결과

- 로컬 main HEAD df46467. 기존 AGENTS.md·README.md·PKM 미커밋 변경을 보존했다.
- 추가 사용자 답변으로 커튼 이름·에어컨 전원 토글/모드/예약 순환·Hxlight 앱명·원룸 배치를 확인하고 계획을 수정했다. 가장 큰 제한은 확정 에어컨 OFF와 온도 프리셋이 없다는 점이다.
- GitHub MCP로 main dashboard와 package를 읽었다. blob SHA는 S-004에 기록했다.
- 선풍기 토글/순환 사양 및 현행 15개 allowlist와 과거 PKM의 불일치를 발견했다.
- Hxlight 공식 앱 설명은 Bluetooth/RF를 명시하지만 보유 조명의 리모컨 방식·프로토콜은 미확정이다.
- 프로젝터 PC Bluetooth 페어링을 전원 제어 가능성으로 해석하지 않았다.
- Amazon 본문 확보 실패로 상품 광고 사양은 확정하지 않았다.
- 공식 SwitchBot/HA/삼성 문서 및 BLE ADV 프로젝트 제작자 문서를 계획서에 연결했다.

## ✍️ 산출물

- [실기기 기반 개선 계획](../../docs/스마트홈%20실기기%20기반%20개선%20계획%202026-09-26.md): Obsidian 속성, 기능별 타당성, 단계별 실행, 수용 기준, 출처.
- [S-004](../Specs/S-004_active-device-planning.md): 다음 세션용 최신 의사결정과 과거 사양 정정.
- PKM 진입점과 Spec/Log 인덱스에 최신 경로 추가.
- 기존 S-001/S-002에 역사적 상태·최신 계획 우선 안내 추가.
- 요청한 Obsidian Vault의 `2. Area/2.3 Life/2. 스마트홈/스마트홈 실기기 기반 개선 계획 2026-09-26.md`에 새 파일로 저장했다. 기존 파일을 덮어쓰지 않았으며 저장 후 로컬 원본과 SHA256 일치를 확인했다.

## ✅ 감사 범위와 한계

- 이번 증거 층: 사용자 진술, 로컬 소스, GitHub 소스, 공식 문서.
- HA 인증 읽기 접근, 활성 리소스 확인, 프런트엔드 격리 테스트, S23·실기기 시험은 수행하지 않았다.
- 계획된 감사 13건: blocked 1(HA 읽기 접근), not-run 12. passed/failed 0.
- 장치 제어·HA 재시작·배포·커밋·원격 쓰기는 수행하지 않았다.
- 수정한 Markdown 8개 파일의 YAML properties·단일 H1·상대 링크·자격 증명 패턴, 계획서 출처 참조와 감사 항목 13개를 검증했다. `git diff --check`도 통과했다. 이는 문서 검증이며 실기기 시험 통과를 뜻하지 않는다.

## 🔄 다음 시작점

S-004와 계획서의 P0만 읽고 실제 패널의 entity/action·상태 근거를 확보한다. 과거 18개 허용 목록과 임의 선풍기 프리셋을 복원하지 않는다. 조명·프로젝터 모델과 통신 방식이 확인되기 전 호환성을 확정하지 않는다.
