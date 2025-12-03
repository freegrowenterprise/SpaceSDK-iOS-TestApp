//
//  MQTTManager.swift
//  GrowSpaceSDKTestApp
//
//  Created for UWB Test System
//

import Foundation
import UIKit
import CocoaMQTT

class MQTTManager: NSObject {
    static let shared = MQTTManager()

    private var mqtt: CocoaMQTT5?
    private var isConnected = false

    // MQTT 설정
    var brokerHost: String = "3.38.52.15"
    var brokerPort: UInt16 = 1883
    private let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    var clientId: String = ""
    var username: String = "freegrow"
    var password: String = "gogrow!"

    // 토픽 설정
    var coordinateTopic: String = "uwb/coordinate"
    var distanceTopic: String = "uwb/distance"

    private override init() {
        super.init()
        // 초기 clientId 생성 (iOS-deviceUUID-timestamp)
        let timestamp = Int(Date().timeIntervalSince1970 * 1000) // milliseconds
        self.clientId = "ios-\(deviceUUID)-\(timestamp)"
    }

    // MQTT 연결
    func connect(host: String, port: UInt16, clientId: String? = nil, username: String? = nil, password: String? = nil) {
        self.brokerHost = host
        self.brokerPort = port

        if let id = clientId {
            // 전달된 clientId도 타임스탬프 추가
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            self.clientId = "\(id)-\(timestamp)"
        } else {
            // clientId가 없으면 새로 생성
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            self.clientId = "ios-\(deviceUUID)-\(timestamp)"
        }

        if let user = username {
            self.username = user
        }
        if let pass = password {
            self.password = pass
        }

        mqtt = CocoaMQTT5(clientID: self.clientId, host: host, port: port)

        guard let mqtt = mqtt else { return }

        // 인증 설정
        mqtt.username = self.username
        mqtt.password = self.password

        mqtt.autoReconnect = true
        mqtt.keepAlive = 60
        mqtt.delegate = self

        _ = mqtt.connect()
    }

    // MQTT 연결 해제
    func disconnect() {
        mqtt?.disconnect()
        isConnected = false
    }

    // 좌표 데이터 전송
    func publishCoordinate(deviceId: String, x: Float, y: Float, accuracy: Double? = nil, anchorCount: Int) {
        guard isConnected, let mqtt = mqtt else {
            return
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        var payload: [String: Any] = [
            "deviceId": deviceId,
            "x": x,
            "y": y,
            "timestamp": timestamp,
            "anchorCount": anchorCount
        ]

        // accuracy가 있으면 추가
        if let accuracy = accuracy {
            payload["accuracy"] = accuracy
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            mqtt.publish(coordinateTopic, withString: jsonString, qos: .qos1, properties: MqttPublishProperties())
        }
    }

    // 거리 데이터 전송 (개별 앵커)
    func publishDistance(deviceId: String, anchorId: String, distance: Float) {
        guard isConnected, let mqtt = mqtt else {
            return
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let payload: [String: Any] = [
            "deviceId": deviceId,
            "anchorId": anchorId,
            "distance": distance,
            "timestamp": timestamp
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            mqtt.publish(distanceTopic, withString: jsonString, qos: .qos1, properties: MqttPublishProperties())
        }
    }

    // 연결 상태 확인
    func getConnectionStatus() -> Bool {
        return isConnected
    }
}

// MARK: - CocoaMQTT5Delegate
extension MQTTManager: CocoaMQTT5Delegate {
    func mqtt5(_ mqtt: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData: MqttDecodeConnAck?) {
        isConnected = (ack == .success)
    }

    func mqtt5(_ mqtt: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {
        // Message published
    }

    func mqtt5(_ mqtt: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) {
        // Message acknowledged
    }

    func mqtt5(_ mqtt: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) {
        // QoS 2 메시지 수신 확인
    }

    func mqtt5(_ mqtt: CocoaMQTT5, didPublishComplete id: UInt16, pubCompData: MqttDecodePubComp?) {
        // QoS 2 메시지 전송 완료
    }

    func mqtt5(_ mqtt: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish?) {
        // Message received
    }

    func mqtt5(_ mqtt: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData: MqttDecodeSubAck?) {
        // Subscribed
    }

    func mqtt5(_ mqtt: CocoaMQTT5, didUnsubscribeTopics topics: [String], unsubAckData: MqttDecodeUnsubAck?) {
        // Unsubscribed
    }

    func mqtt5(_ mqtt: CocoaMQTT5, didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode) {
        isConnected = false
    }

    func mqtt5DidDisconnect(_ mqtt: CocoaMQTT5, withError err: Error?) {
        isConnected = false
    }

    func mqtt5DidPing(_ mqtt: CocoaMQTT5) {
        // Ping sent
    }

    func mqtt5DidReceivePong(_ mqtt: CocoaMQTT5) {
        // Pong received
    }

    func mqtt5(_ mqtt: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
        // Auth
    }

    func mqtt5(_ mqtt: CocoaMQTT5, didStateChangeTo state: CocoaMQTTConnState) {
        // State changed
    }
}
