//
//  LiveActivityManager.swift
//  GrowSpaceSDKTestApp
//
//  Created by min gwan choi on 4/29/25.
//

import UserNotifications
import ActivityKit

final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var activity: Activity<SpaceUWBLiveKitAttributes>?
    var notificationTimer: Timer?
    
    private init() {}
    
    private var latestDeviceDistanceMap: [String: Float] = [:]
    
    func updateDeviceDistanceMap(_ map: [String: Float]) {
        self.latestDeviceDistanceMap = map
    }

    func start() {
        // Background functionality disabled
//        guard activity == nil else { return }
//
//        let attributes = SpaceUWBLiveKitAttributes(name: "Grow Space")
//        let contentState = SpaceUWBLiveKitAttributes.ContentState(emoji: "😀")
//        let content = ActivityContent(state: contentState, staleDate: nil)
//        
//        do {
//            self.activity = try Activity<SpaceUWBLiveKitAttributes>.request(
//                attributes: attributes,
//                content: content,
//                pushType: nil
//            )
//            self.startNotificationTimer()
//        } catch {
//            print(error)
//        }
        print("LiveActivity start disabled")
    }
    
    func startNotificationTimer() {
//        notificationTimer?.invalidate() // 혹시 이전 타이머 있으면 정리
//        notificationTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
//            self.sendLocalNotification()
//        }
    }
    
    func sendLocalNotification() {
//        let content = UNMutableNotificationContent()
//        content.title = "UWB 상태 업데이트"
//        let deviceInfoList = latestDeviceDistanceMap.map { (key, value) in
//                return "\(key): \(String(format: "%.2f", value))m"
//            }
//            .joined(separator: "\n") // 줄바꿈으로 이어붙이기
//            
//            content.body = deviceInfoList.isEmpty ? "수신된 장치 없음" : deviceInfoList
//        content.sound = .default
//
//        let request = UNNotificationRequest(
//            identifier: UUID().uuidString,
//            content: content,
//            trigger: nil // 즉시 표시
//        )
//        
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("알림 등록 실패: \(error.localizedDescription)")
//            } else {
//                print("알림 등록 성공")
//            }
//        }
    }
    
    func stop() {
//        Task {
//            for activity in Activity<SpaceUWBLiveKitAttributes>.activities {
//                await activity.end(dismissalPolicy: .immediate)
//            }
//        }
//        notificationTimer?.invalidate()
//        notificationTimer = nil
        print("LiveActivity stop disabled")
    }
}
