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

class RTLSViewController: UIViewController {
    private let viewModel: DeviceCoordinateViewModel
    private let growSpaceUWBSDK = GrowSpaceSDK()
    private let growSpaceRTLS = GrowSpaceRTLS()
    private var uwbResults: [String: UWBRangeResult] = [:]
    private let mqttManager = MQTTManager.shared
    private var deviceId: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "iOS-Unknown"
    }

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
    }

    @objc private func startRtls() {
        statusLabel.text = "Starting..."
        loadingIndicator.startAnimating()

        var lastMqttPublishTime: Date?
        let mqttPublishInterval: TimeInterval = 0.1  // 100ms = 10Hz
        var anchorLastUpdateTime: [String: Date] = [:]  // 각 앵커의 마지막 업데이트 시각

        // 1초마다 오래된 앵커 제거
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()

            // 1초 이상 업데이트 안 된 앵커 제거
            for (anchorId, lastUpdate) in anchorLastUpdateTime {
                if now.timeIntervalSince(lastUpdate) > 1.0 {
                    self.uwbResults.removeValue(forKey: anchorId)
                    anchorLastUpdateTime.removeValue(forKey: anchorId)
                }
            }

            // 앵커가 3개 미만이면 좌표 삭제
            if self.uwbResults.count < 3 {
                self.viewModel.setCurrentLocation(nil)
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

                    // MQTT: 앵커 간 거리 전송 (각 앵커마다 개별 전송)
                    self.mqttManager.publishDistance(
                        deviceId: self.deviceId,
                        anchorId: result.deviceName,
                        distance: result.distance
                    )

                    // 앵커가 3개 이상이면 RTLS 계산
                    guard self.uwbResults.count >= 3 else {
                        self.viewModel.setCurrentLocation(nil)
                        return
                    }

                    let anchors = self.convertToAnchorResults(
                        from: self.uwbResults,
                        coordinates: self.viewModel.deviceCoordinates
                    )

                    self.growSpaceRTLS.startUwbRtls(
                        anchors: anchors,
                        onResult: { location in
                            DispatchQueue.main.async {
                                self.viewModel.setCurrentLocation(CGPoint(x: location.x, y: location.y))
                                self.updateLabels()

                                // MQTT: 실시간 좌표 전송 (10Hz throttle)
                                let now = Date()
                                if lastMqttPublishTime == nil || now.timeIntervalSince(lastMqttPublishTime!) >= mqttPublishInterval {
                                    self.mqttManager.publishCoordinate(
                                        deviceId: self.deviceId,
                                        x: location.x,
                                        y: location.y
                                    )
                                    lastMqttPublishTime = now
                                }
                            }
                        }
                    )
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
}
