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

2. Open `.xcodeproj` or `.xcworkspace` in Xcode

3. Connect a physical device and run the app  
   > UWB features are **not available** on the iOS simulator.

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
