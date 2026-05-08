# 📡 Space UWB SDK Example App (iOS)

This project is the **official SDK example app** provided by **FREEGROW Inc.**, designed to integrate Grow Space UWB products with iOS devices.  
It enables direct testing of core features such as UWB connection, distance measurement, direction data retrieval, and **real-time device visualization via an intuitive UI**.

---

## 🔧 Requirements

### Software
- iOS 16.0 or later
- Xcode 14 or later
- Swift 5.7

### Hardware
- [UWB-supported iOS device](https://blog.naver.com/growdevelopers/223775171523)
- Actual UWB device [(Grow Space UWB product)](https://grow-space.io/product/n1-mk-01/)

---

## 🚀 Getting Started

1. Clone the repository:
    ```bash
    git clone https://github.com/freegrowenterprise/SpaceSDK-iOS-TestApp.git
    ```

2. Open `GrowSpaceSDKTestApp.xcodeproj` in Xcode. SwiftPM will automatically resolve the SDK dependency at `https://github.com/freegrowenterprise/SpaceSDK-iOS` (currently pinned to `0.0.43`).

3. Connect a physical device and run the app
   > UWB features are **not available** on the iOS simulator.

### Suppressing the widget-launch console message

When you Run the app from Xcode, you may see:
```
SendProcessControlEvent:toPid: encountered an error: Error Domain=com.apple.dt.deviceprocesscontrolservice
Code=8 "Failed to show Widget 'freegrow.GrowSpaceSDKTestApp.SpaceUWBLiveKitExtension'..."
```
This is harmless — the app contains a LiveActivity widget extension that Xcode tries to preview when no live activity is active yet. To run cleanly:

1. **Product → Scheme → Edit Scheme...** (`Cmd+<`)
2. Select **Run** on the left.
3. In the **Info** tab, set **Executable** to `GrowSpaceSDKTestApp.app` and **Launch** to **`Automatically`**.
4. If a **Widget Kind** field is shown, leave it empty / **None**.

---

## 📦 What’s Included

### ✅ SDK Integration Example
- End-to-end flow using the FREEGROW UWB SDK (`SpaceUwb`)
- BLE-based device discovery and UWB ranging process
- Real-time location estimation using RTLS algorithm

### ✅ Key Features

#### 📏 Distance & Direction Measurement
- After connecting to UWB devices via BLE,
- The app displays **distance**, **azimuth**, and **elevation** values in real-time.
- Devices are dynamically listed with updated measurements for each.

https://github.com/user-attachments/assets/9d222cfe-886a-490c-b21d-48da70ff4dd7

---

#### 🚫 Per-Device Disconnect & Block List (SDK 0.0.42+)

- Each device card on the ranging page has an **"⋯" option button** on the right (long-press also works as a fallback gesture). Tap it to choose between:
  - **이 디바이스만 끊기 (현재 세션)** — disconnects the device immediately. The scanner keeps running, but the same `GrowSpaceSDK` instance will not auto-reconnect to this device until a fresh ranging session is started.
  - **이 디바이스 차단 (영구)** — adds the device to a persistent block list backed by `UserDefaults`. The device is filtered out at scan time and stays blocked across app launches until you unblock it.
- A dedicated **차단 목록 (Block List)** page lets you review currently blocked devices, unblock individuals, or clear the entire list. The ranging session is preserved while you visit the block list and come back — scanning continues uninterrupted.

#### 📡 Capability Info

- A **Capability Info** page exposes the host phone's NearbyInteraction capabilities — direction support, camera assistance availability, precise distance measurement, and (on iOS 17.4+) extended distance measurement.
- The ranging page also shows a small badge with the host phone's UWB chip name (`U1` / `U2`).

#### 🎥 AR World View / Camera Assistance Toggle (SDK 0.0.43+)

- The ranging page exposes an **AR World View / Camera Assist** switch (default OFF).
- Switching ON: a system camera-permission prompt appears on first use. If the user denies, the app shows an "Open Settings" alert and reverts the switch to OFF — UWB ranging keeps working without the camera (direction stays available on U1, unavailable on U2).
- Switching the toggle while a scan is **already running** triggers a confirmation alert ("All active UWB sessions will be re-initialized"). On confirm, BLE stays connected but each NI session is stopped, invalidated, and re-created with the new `isCameraAssistanceEnabled` setting; ranging briefly pauses then resumes.
- The ranging page itself is now a single scrollable container (settings + connected device cards), so a long device list no longer squeezes the cards into a narrow strip.

---

#### 🧭 RTLS-Based Grid Visualization
- Anchor coordinates are preconfigured in the app.
- The RTLS engine calculates the **real-time (x, y, z) position** of the user.
- The result is visualized in a **grid-style canvas**, giving a clear representation of indoor movement and spatial location.

**Set UWB Anchor Locations**

https://github.com/user-attachments/assets/94d6af1b-1b81-4388-a21b-8e4df8aa87df

**Track Your Position**

https://github.com/user-attachments/assets/7a7eb3a4-af1b-4b8e-af1f-1d34c5b91269

---

## 🏢 Developed by

**FREEGROW Inc.**  
We specialize in indoor positioning and ultra-wideband (UWB) communication technologies to enable intelligent spatial awareness solutions.

---

## 📫 Contact

For technical support or suggestions, feel free to reach out to us:

📮 contact@freegrow.io  
🌐 https://grow-space.io
