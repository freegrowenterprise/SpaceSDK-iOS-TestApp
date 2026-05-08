# 📡 Space UWB SDK Example App (iOS)

이 프로젝트는 **FREEGROW Inc**의 UWB 제품을 iOS 기기와 연동하여 사용할 수 있도록 만든 **공식 SDK 예제 앱**입니다.  
UWB 연결, 거리 측정, 방향 데이터 수신 등 핵심 기능을 직접 테스트할 수 있도록 구성되어 있으며, **직관적인 UI와 실시간 디바이스 상태 시각화 기능을 포함**하고 있습니다.

---

## 🔧 요구 사항

###  Software
- iOS 16.0 이상
- Xcode 14 이상
- Swift 5.7

### Hardware
- [UWB 지원 iOS 휴대폰](https://blog.naver.com/growdevelopers/223775171523)
- 실제 UWB 디바이스 [(Grow Space UWB 제품)](https://grow-space.io/product/n1-mk-01/)

---


## 🚀 시작하기

1. 프로젝트 클론:
    ```bash
    git clone https://github.com/freegrowenterprise/SpaceSDK-iOS-TestApp.git
    ```

2. Xcode에서 `GrowSpaceSDKTestApp.xcodeproj` 열기. SwiftPM 이 `https://github.com/freegrowenterprise/SpaceSDK-iOS` 의 `0.0.43` 태그를 자동으로 가져옵니다.

3. 실제 기기를 연결하여 실행 (UWB 기능은 시뮬레이터에서 동작하지 않음)

### 위젯 실행 콘솔 메시지 정리

Xcode Run 시 아래 메시지가 보일 수 있어요:
```
SendProcessControlEvent:toPid: encountered an error: Error Domain=com.apple.dt.deviceprocesscontrolservice
Code=8 "Failed to show Widget 'freegrow.GrowSpaceSDKTestApp.SpaceUWBLiveKitExtension'..."
```
앱에 LiveActivity 위젯 익스텐션이 포함돼 있고 아직 활성 LiveActivity 가 없어서 Xcode 가 위젯 미리보기를 띄우려다 실패하는 정상적 메시지로, 앱 동작과는 무관합니다. 깔끔하게 띄우려면:

1. **Product → Scheme → Edit Scheme...** (`Cmd+<`)
2. 좌측 **Run** 선택
3. **Info** 탭에서 **Executable** 을 `GrowSpaceSDKTestApp.app` 으로, **Launch** 를 **`Automatically`** 로 설정
4. **Widget Kind** 항목이 보이면 **None** / 빈 값으로 두기

---

## 📦 구성 내용

### ✅ SDK 연동 예제
- FREEGROW UWB SDK(SpaceUwb)를 활용한 장치 연결 흐름
- BLE를 통한 디바이스 검색 및 UWB Ranging 처리
- RTLS 알고리즘을 통한 실시간 위치 추정

### ✅ 주요 기능

#### 📏 거리 및 방향 측정 기능
- UWB 장치와 BLE를 통해 연결한 후,
- 실시간으로 **거리(distance)**, **방위각(azimuth)**, **고도(elevation)** 값을 측정하여 UI에 표시합니다.
- 연결된 디바이스들은 리스트로 정렬되어 각 장치의 실시간 상태를 확인할 수 있습니다.

https://github.com/user-attachments/assets/9d222cfe-886a-490c-b21d-48da70ff4dd7

---

#### 🚫 개별 디바이스 끊기 / 차단 목록 (SDK 0.0.42+)

- Ranging 페이지의 디바이스 카드 우측에 **"⋯" 옵션 버튼** 이 있습니다 (카드를 길게 눌러도 동일 메뉴 노출). 탭하면 두 가지 액션:
  - **이 디바이스만 끊기 (현재 세션)** — 즉시 BLE/UWB 연결 종료. 스캐너는 계속 동작하지만, 같은 `GrowSpaceSDK` 인스턴스 안에선 자동 재연결을 하지 않음. 페이지를 떠났다 다시 들어와 새 ranging 세션을 시작하면 다시 연결될 수 있음.
  - **이 디바이스 차단 (영구)** — `UserDefaults` 영구 차단 목록에 추가. 스캔 단계에서 필터되어 앱 재실행 후에도 잡히지 않음. 언블록할 때까지 유지.
- 별도의 **차단 목록** 페이지에서 차단된 디바이스를 확인 / 개별 언블록 / 전체 초기화 가능. 차단 목록 페이지로 push 했다가 돌아와도 ranging 세션과 스캔이 그대로 유지됩니다.

#### 📡 Capability Info

- **Capability Info** 페이지에서 단말의 NearbyInteraction capability(direction 지원, camera assistance 지원, precise distance, iOS 17.4+ extended distance)를 직접 확인할 수 있습니다.
- Ranging 페이지 상단의 작은 배지에 단말의 UWB 칩 이름(`U1` / `U2`)이 표시됩니다.

#### 🎥 AR World View / Camera Assistance 토글 (SDK 0.0.43+)

- Ranging 페이지에 **AR World View / Camera Assist** 스위치 노출 (기본 OFF).
- ON 으로 바꾸면 첫 사용 시 시스템 카메라 권한 다이얼로그가 뜹니다. 거부하면 "Open Settings" 안내 alert + 스위치 자동 OFF — UWB ranging 자체는 계속 동작 (U1 은 방향 측정 유지, U2 는 방향 비활성).
- **스캔 중**에 토글하면 컨펌 alert ("All active UWB sessions will be re-initialized") 가 한 번 더 끼어듭니다. Continue 누르면 BLE 는 유지되고 NI 세션만 stop → invalidate → 새 `isCameraAssistanceEnabled` 로 재시작; ranging 이 잠깐 끊겼다 다시 흐릅니다.
- Ranging 페이지 자체가 단일 스크롤 컨테이너로 변경되어(설정 영역 + 디바이스 카드 한 묶음), 디바이스 목록이 길어져도 카드 영역이 좁게 눌리지 않습니다.

---

#### 🧭 RTLS 격자 기반 위치 표시 기능
- 각 UWB 앵커 장치의 위치를 좌표값으로 설정한 뒤,
- RTLS 알고리즘을 통해 **현재 사용자 위치(x, y, z)** 를 실시간으로 계산합니다.
- 계산된 위치는 **앱 내 격자 기반 UI(Canvas/Grid)** 상에 시각적으로 표시되어,
  공간 내에서의 이동 상태를 직관적으로 확인할 수 있습니다.

**UWB 장비 위치 세팅**

https://github.com/user-attachments/assets/94d6af1b-1b81-4388-a21b-8e4df8aa87df

**내 위치 확인**

https://github.com/user-attachments/assets/7a7eb3a4-af1b-4b8e-af1f-1d34c5b91269


---



## 🏢 제작

**FREEGROW Inc.**  
실내 측위와 근거리 무선 통신 기술을 바탕으로 한 UWB 솔루션을 개발하고 있습니다.

---

## 📫 문의

기술 문의나 개선 제안은 아래 메일로 연락주세요.

📮 contact@freegrow.io

🌐 https://grow-space.io




