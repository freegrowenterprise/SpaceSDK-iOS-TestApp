//
//  RTLSViewController.swift
//  GrowSpaceSDKTestApp
//
//  Created by min gwan choi on 5/8/25.
//

import UIKit
import SnapKit
import GrowSpacePrivateSDK
import GrowSpaceSDK
import CoreMotion

class RTLSViewController: UIViewController {
    private let viewModel: DeviceCoordinateViewModel
    private let growSpaceUWBSDK = GrowSpaceSDK()
    private let growSpaceRTLS = GrowSpaceRTLS()
    private var uwbResults: [String: UWBRangeResult] = [:]
    private let mqttManager = MQTTManager.shared
    private var deviceId: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "iOS-Unknown"
    }

    // 위치 히스토리 및 추정 관련
    private var positionHistory: [(position: CGPoint, timestamp: Date)] = []
    private let maxHistoryCount = 10
    private var lastEstimationStartTime: Date?
    private var lastThreeAnchorTime: Date?  // 마지막으로 3개 앵커였던 시각

    // IMU 센서 관련
    private let motionManager = CMMotionManager()
    private var currentHeading: Double = 0.0  // 현재 진행 방향 (라디안)
    private var isMoving: Bool = false  // 이동 중 여부

    // Low Pass Filter 관련 (앵커 거리 MQTT 전송용)
    private var filteredDistances: [String: Float] = [:]  // 앵커별 필터링된 거리
    private let distanceFilterAlpha: Float = 0.3  // LPF alpha (0.0~1.0, 낮을수록 스무딩 강함)
    private var isDistanceMqttRunning: Bool = false  // 거리 MQTT 전송 활성화 여부
    private var activeAnchorTimers: Set<String> = []  // 타이머가 돌고 있는 앵커 ID

    private let scrollView = UIScrollView()
    private let contentView = UIStackView()

    private let settingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("UWB equipment positioning", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        return button
    }()

    private let statusLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private let distanceLabel = UILabel()
    private let coordinateLabel = UILabel()
    private let stopButton = UIButton(type: .system)
    private let startButton = UIButton(type: .system)

    init(viewModel: DeviceCoordinateViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.title = "RTLS"
        setupUI()
        setupActions()

        // MQTT 자동 연결 (clientId는 자동 생성됨)
        mqttManager.connect(
            host: "3.38.52.15",
            port: 1883,
            username: "freegrow",
            password: "gogrow!"
        )
    }

    deinit {
        mqttManager.disconnect()
    }

    private func setupUI() {
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(80)
        }

        contentView.axis = .vertical
        contentView.spacing = 24
        contentView.alignment = .fill
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
            $0.width.equalTo(scrollView.snp.width).offset(-32)
        }

        contentView.addArrangedSubview(settingButton)
        settingButton.snp.makeConstraints { $0.height.equalTo(44) }

        statusLabel.text = "Ready to start UWB..."
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .gray
        contentView.addArrangedSubview(statusLabel)

        loadingIndicator.hidesWhenStopped = true
        contentView.addArrangedSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { $0.height.equalTo(24) }

        // 거리 정보 박스
        let distanceBox = UIView()
        distanceBox.backgroundColor = UIColor(white: 0.95, alpha: 1)
        distanceBox.layer.cornerRadius = 8
        distanceLabel.numberOfLines = 0
        distanceLabel.textAlignment = .left
        distanceLabel.font = .systemFont(ofSize: 14)
        distanceLabel.text = "Distance: -"
        distanceLabel.textColor = .darkGray
        distanceBox.addSubview(distanceLabel)
        distanceLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }
        contentView.addArrangedSubview(distanceBox)

        // 좌표 정보 박스
        let coordinateBox = UIView()
        coordinateBox.backgroundColor = UIColor(white: 0.95, alpha: 1)
        coordinateBox.layer.cornerRadius = 8
        coordinateLabel.numberOfLines = 0
        coordinateLabel.textAlignment = .left
        coordinateLabel.font = .systemFont(ofSize: 14)
        coordinateLabel.text = "Coordinate: -"
        coordinateLabel.textColor = .darkGray
        coordinateBox.addSubview(coordinateLabel)
        coordinateLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }
        contentView.addArrangedSubview(coordinateBox)

        let buttonStack = UIStackView(arrangedSubviews: [stopButton, startButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        stopButton.setTitle("Stop", for: .normal)
        stopButton.backgroundColor = .lightGray
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.layer.cornerRadius = 8
        startButton.setTitle("Start", for: .normal)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 8
        view.addSubview(buttonStack)
        buttonStack.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
    }

    private func setupActions() {
        settingButton.addTarget(self, action: #selector(openUwbSetting), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(stopRtls), for: .touchUpInside)
        startButton.addTarget(self, action: #selector(startRtls), for: .touchUpInside)
    }

    private func updateLabels() {
        // 거리 정보 업데이트
        if uwbResults.isEmpty {
            distanceLabel.text = "Distance: -"
        } else {
            let lines = uwbResults.values.map { result in
                return "  [\(result.deviceName)] → \(String(format: "%.2f", result.distance))m"
            }
            distanceLabel.text = "Distance:\n" + lines.joined(separator: "\n")
            statusLabel.text = "UWB Running..."
            loadingIndicator.stopAnimating()
        }

        // 좌표 정보 업데이트
        if let location = viewModel.currentRtlsLocation {
            coordinateLabel.text = String(format: "Coordinate:\n  X: %.2f m\n  Y: %.2f m", location.x, location.y)
        } else {
            coordinateLabel.text = "Coordinate: -"
        }
    }

    @objc private func openUwbSetting() {
        let settingVC = UwbSettingViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(settingVC, animated: true)
    }

    @objc private func stopRtls() {
        statusLabel.text = "Stopped"
        loadingIndicator.stopAnimating()
        distanceLabel.text = "Distance: -"
        coordinateLabel.text = "Coordinate: -"

        growSpaceUWBSDK.stopUWBRanging(onComplete: { _ in })
        stopIMUSensors()  // IMU 센서 중지
        isDistanceMqttRunning = false  // 거리 MQTT 전송 중지
    }

    @objc private func startRtls() {
        statusLabel.text = "Starting..."
        loadingIndicator.startAnimating()

        // IMU 센서 시작
        startIMUSensors()

        // 히스토리 초기화
        positionHistory.removeAll()
        lastEstimationStartTime = nil

        // Low Pass Filter 초기화
        filteredDistances.removeAll()

        // 거리 MQTT 전송 활성화 (앵커별 타이머는 데이터 수신 시 시작)
        isDistanceMqttRunning = true
        activeAnchorTimers.removeAll()

        var lastMqttPublishTime: Date?
        let mqttPublishInterval: TimeInterval = 0.1  // 100ms = 10Hz
        var anchorLastUpdateTime: [String: Date] = [:]  // 각 앵커의 마지막 업데이트 시각

        // 1초마다 오래된 앵커 제거
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()

            // 2초 이상 업데이트 안 된 앵커 제거
            for (anchorId, lastUpdate) in anchorLastUpdateTime {
                if now.timeIntervalSince(lastUpdate) > 2.0 {
                    self.uwbResults.removeValue(forKey: anchorId)
                    anchorLastUpdateTime.removeValue(forKey: anchorId)
                }
            }
        }

        // UWB Ranging 시작
        growSpaceUWBSDK.startUWBRanging(
            replacementDistanceThreshold: 80.0,
            onUpdate: { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.uwbResults[result.deviceName] = result
                    anchorLastUpdateTime[result.deviceName] = Date()  // 업데이트 시각 기록
                    self.updateLabels()

                    // Low Pass Filter 적용 (MQTT 전송은 앵커별 타이머에서 처리)
                    let anchorId = result.deviceName
                    let rawDistance = result.distance

                    let previousFiltered = self.filteredDistances[anchorId] ?? rawDistance
                    let filtered = self.distanceFilterAlpha * rawDistance + (1 - self.distanceFilterAlpha) * previousFiltered
                    self.filteredDistances[anchorId] = filtered

                    // 해당 앵커의 타이머가 없으면 시작
                    if !self.activeAnchorTimers.contains(anchorId) {
                        self.activeAnchorTimers.insert(anchorId)
                        self.scheduleNextDistanceMqtt(for: anchorId)
                    }

                    let anchorCount = self.uwbResults.count
                    let anchors = self.convertToAnchorResults(
                        from: self.uwbResults,
                        coordinates: self.viewModel.deviceCoordinates
                    )

                    var estimatedPosition: CGPoint?
                    var usedAnchorCount = 0

                    // 앵커 개수별 처리
                    if anchorCount >= 3 {
                        // [3개 이상] 정상 RTLS 삼변측량
                        self.lastEstimationStartTime = nil  // 추정 모드 종료
                        self.lastThreeAnchorTime = Date()  // 3개 앵커 시각 기록

                        self.growSpaceRTLS.startUwbRtls(
                            anchors: anchors,
                            onResult: { location in
                                DispatchQueue.main.async {
                                    let position = CGPoint(x: location.x, y: location.y)
                                    self.viewModel.setCurrentLocation(position)
                                    self.addPositionToHistory(position)
                                    self.updateLabels()

                                    // MQTT: 실시간 좌표 전송 (10Hz throttle)
                                    let now = Date()
                                    if lastMqttPublishTime == nil || now.timeIntervalSince(lastMqttPublishTime!) >= mqttPublishInterval {
                                        self.mqttManager.publishCoordinate(
                                            deviceId: self.deviceId,
                                            x: Float(location.x),
                                            y: Float(location.y),
                                            anchorCount: anchorCount
                                        )
                                        lastMqttPublishTime = now
                                    }
                                }
                            }
                        )

                    } else if anchorCount == 2 {
                        // [2개] 교점 계산 - 3개에서 2개로 전환 시 1초 대기
                        let now = Date()

                        // 3개 앵커였다가 2개로 줄어든 경우, 1초 대기
                        if let lastThree = self.lastThreeAnchorTime,
                           now.timeIntervalSince(lastThree) < 1.0 {
                            // 1초 안에 다시 3개가 될 수 있으므로 대기
                            return
                        }

                        // 2개 앵커는 시간 제한 없이 계속 유지
                        let lastPos = self.viewModel.currentRtlsLocation
                        estimatedPosition = self.calculatePositionWith2Anchors(
                            anchors: anchors,
                            lastPosition: lastPos
                        )

                        if let pos = estimatedPosition {
                            usedAnchorCount = 2
                            self.viewModel.setCurrentLocation(pos)
                            self.updateLabels()

                            // MQTT 전송
                            let now = Date()
                            if lastMqttPublishTime == nil || now.timeIntervalSince(lastMqttPublishTime!) >= mqttPublishInterval {
                                self.mqttManager.publishCoordinate(
                                    deviceId: self.deviceId,
                                    x: Float(pos.x),
                                    y: Float(pos.y),
                                    anchorCount: 2
                                )
                                lastMqttPublishTime = now
                            }
                        } else {
                            self.viewModel.setCurrentLocation(nil)
                        }

                    } else {
                        // [1개 이하] 좌표 삭제
                        self.viewModel.setCurrentLocation(nil)
                    }
                }
            },
            onDisconnect: { _ in
            }
        )
    }

    private func convertToAnchorResults(
        from uwbResults: [String: UWBRangeResult],
        coordinates: [String: CGPoint]
    ) -> [RTLSAnchorResult] {
        return uwbResults.values.compactMap { result in
            guard let point = coordinates[result.deviceName] else {
                return nil  // 좌표가 없는 장치는 제외
            }

            let x = Double(point.x)
            let y = Double(point.y)
            let z = 1.0  // 고정값 또는 필요 시 변경

            return RTLSAnchorResult(
                id: result.deviceName,
                x: x,
                y: y,
                z: z,
                distance: Double(result.distance)
            )
        }
    }

    // MARK: - 위치 히스토리 관리
    private func addPositionToHistory(_ position: CGPoint) {
        let now = Date()
        positionHistory.append((position: position, timestamp: now))

        // 최대 개수 유지
        if positionHistory.count > maxHistoryCount {
            positionHistory.removeFirst()
        }
    }

    // 속도 벡터 계산 (m/s)
    private func calculateVelocity() -> CGPoint? {
        guard positionHistory.count >= 2 else { return nil }

        let recent = positionHistory.suffix(5)  // 최근 5개
        guard recent.count >= 2 else { return nil }

        let latest = recent.last!
        let oldest = recent.first!

        let timeDiff = latest.timestamp.timeIntervalSince(oldest.timestamp)
        guard timeDiff > 0 else { return nil }

        let dx = latest.position.x - oldest.position.x
        let dy = latest.position.y - oldest.position.y

        return CGPoint(x: dx / timeDiff, y: dy / timeDiff)
    }

    // MARK: - 2개 앵커: 교점 계산 (속도 벡터 + IMU 활용)
    private func calculatePositionWith2Anchors(
        anchors: [RTLSAnchorResult],
        lastPosition: CGPoint?
    ) -> CGPoint? {
        guard anchors.count == 2 else { return nil }

        let a1 = anchors[0]
        let a2 = anchors[1]

        let x1 = a1.x, y1 = a1.y, r1 = a1.distance
        let x2 = a2.x, y2 = a2.y, r2 = a2.distance

        // 두 원의 교점 계산
        let d = sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2))

        // 원이 너무 멀거나 겹치지 않으면 실패
        if d > r1 + r2 || d < abs(r1 - r2) || d == 0 {
            return nil
        }

        let a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
        let h = sqrt(r1 * r1 - a * a)

        let px = x1 + a * (x2 - x1) / d
        let py = y1 + a * (y2 - y1) / d

        // 두 교점
        let intersection1 = CGPoint(
            x: px + h * (y2 - y1) / d,
            y: py - h * (x2 - x1) / d
        )
        let intersection2 = CGPoint(
            x: px - h * (y2 - y1) / d,
            y: py + h * (x2 - x1) / d
        )

        // 교점 선택: 마지막 위치에서 가장 가까운 점 선택
        if let last = lastPosition {
            let dist1 = distance(from: last, to: intersection1)
            let dist2 = distance(from: last, to: intersection2)
            return dist1 < dist2 ? intersection1 : intersection2
        }

        // 마지막 위치가 없으면 첫 번째 교점
        return intersection1
    }

    // MARK: - 1개 앵커: Dead Reckoning
    private func calculatePositionWith1Anchor(
        timeSinceEstimationStart: TimeInterval,
        lastPosition: CGPoint?,
        velocity: CGPoint?
    ) -> CGPoint? {
        guard let last = lastPosition, let vel = velocity else { return nil }

        // 최대 2초까지만
        if timeSinceEstimationStart > 2.0 {
            return nil
        }

        // 마지막 위치 + 속도 * 시간
        return CGPoint(
            x: last.x + vel.x * timeSinceEstimationStart,
            y: last.y + vel.y * timeSinceEstimationStart
        )
    }

    // 두 점 사이 거리
    private func distance(from p1: CGPoint, to p2: CGPoint) -> Double {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(Double(dx * dx + dy * dy))
    }

    // MARK: - IMU 센서 관리
    private func startIMUSensors() {
        guard motionManager.isDeviceMotionAvailable else {
            print("⚠️ Device Motion not available")
            return
        }

        motionManager.deviceMotionUpdateInterval = 0.1  // 10Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else { return }

            // 자이로: 회전 방향 추적
            let rotationRate = motion.rotationRate
            // z축 회전을 누적해서 현재 방향 계산
            self.currentHeading += rotationRate.z * 0.1

            // 가속도: 이동 여부 감지
            let userAccel = motion.userAcceleration
            let accelMagnitude = sqrt(userAccel.x * userAccel.x + userAccel.y * userAccel.y + userAccel.z * userAccel.z)

            // 일정 가속도 이상이면 이동 중으로 판단
            self.isMoving = accelMagnitude > 0.1
        }
    }

    private func stopIMUSensors() {
        motionManager.stopDeviceMotionUpdates()
        isMoving = false
        currentHeading = 0.0
    }

    // MARK: - 거리 MQTT 전송 (앵커별 랜덤 간격)
    private func scheduleNextDistanceMqtt(for anchorId: String) {
        guard isDistanceMqttRunning, activeAnchorTimers.contains(anchorId) else { return }

        // 랜덤 간격: 65~100ms (약 10~15Hz)
        let randomInterval = Double.random(in: 0.065...0.100)

        DispatchQueue.main.asyncAfter(deadline: .now() + randomInterval) { [weak self] in
            guard let self = self,
                  self.isDistanceMqttRunning,
                  self.activeAnchorTimers.contains(anchorId),
                  let filteredDistance = self.filteredDistances[anchorId] else {
                // 앵커가 제거되었으면 타이머 종료
                self?.activeAnchorTimers.remove(anchorId)
                return
            }

            // 해당 앵커의 필터링된 거리 값 전송
            self.mqttManager.publishDistance(
                deviceId: self.deviceId,
                anchorId: anchorId,
                distance: filteredDistance
            )

            // 다음 전송 스케줄
            self.scheduleNextDistanceMqtt(for: anchorId)
        }
    }
}
