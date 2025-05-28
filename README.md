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

2. Xcode에서 `.xcodeproj` 또는 `.xcworkspace` 열기

3. 실제 기기를 연결하여 실행 (UWB 기능은 시뮬레이터에서 동작하지 않음)

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




