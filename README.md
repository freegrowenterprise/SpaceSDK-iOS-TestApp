# 📡 Space UWB SDK Example App

이 프로젝트는 **FREEGROW Inc**의 UWB 제품을 iOS 기기와 연동하여 사용할 수 있도록 만든 **공식 SDK 예제 앱**입니다.  
UWB 연결, 거리 측정, 방향 데이터 수신 등 핵심 기능을 직접 테스트할 수 있도록 구성되어 있으며, **화면 녹화 예시도 함께 포함**되어 있습니다.

---

## 📦 구성 내용

### ✅ SDK 연동 예제
- FREEGROW UWB SDK를 활용한 장치 연결 흐름
- BLE를 통한 디바이스 검색 및 UWB Ranging 처리
- 여러 디바이스를 동시 연결하여 거리/방위각 수신

### ✅ UI 기능
- 최대 연결 개수, 거리 제한, 연결 우선 조건 설정 UI
- 연결된 각 디바이스의 실시간 정보 표시
- 스캔 시작/종료 버튼 포함


---

## 🔧 요구 사항

- iOS 16.0 이상
- Xcode 14 이상
- Swift 5.7
- 실제 UWB 디바이스 **(Grow Space UWB 제품)**

---

## 🚀 시작하기

1. 프로젝트 클론:
    ```bash
    git clone https://github.com/freegrowenterprise/SpaceSDK-iOS-TestApp.git
    ```

2. Xcode에서 `.xcodeproj` 또는 `.xcworkspace` 열기

3. 실제 기기를 연결하여 실행 (UWB 기능은 시뮬레이터에서 동작하지 않음)

---

## 🎥 예제 영상

> 화면 녹화 파일은 `Recordings/` 디렉토리에 포함되어 있으며,  
> 실제 디바이스 연결 및 거리 측정 동작을 확인할 수 있습니다.

https://github.com/user-attachments/assets/9d222cfe-886a-490c-b21d-48da70ff4dd7

---

## 🧭 개발자용 설정 옵션

| 항목 | 설명 | Type | 기본값 |  
|------|------|------|------|
| 최대 연결 수 | 동시에 연결 가능한 디바이스 수 설정 | Int | 4 |
| 연결 거리 제한(m) | 일정 거리 초과 시 연결 해제 | Float | 8 |
| 신호 세기 우선 | RSSI 높은 순으로 우선 연결 시도 | Bool | true |


```swift
let growSpaceSDK = GrowSpaceSDK(apiKey: "API-KEY")

growSpaceSDK.startUWBRanging(
    maximumConnectionCount: 4, // 최대 연결 수
    replacementDistanceThreshold: 8, // 연결 거리 제한 (단위: m)
    isConnectStrongestSignalFirst: true, // 신호 세기 우선
    onUpdate: {
        // UWB 측정 값 전달
    },
    onDisconnect: {
        // 장치와 연결 끊어짐 감지
    }
)
```

---

## 🏢 제작

**FREEGROW Inc.**  
실내 측위와 근거리 무선 통신 기술을 바탕으로 한 UWB 솔루션을 개발하고 있습니다.

---

## 📫 문의

기술 문의나 개선 제안은 아래 메일로 연락주세요.

📮 contact@freegrow.io

🌐 https://grow-space.io




