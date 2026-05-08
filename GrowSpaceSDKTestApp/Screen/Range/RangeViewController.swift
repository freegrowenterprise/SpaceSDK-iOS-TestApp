//
//  RangeViewController.swift
//  GrowSpaceSDKTestApp
//
//  Created by min gwan choi on 5/8/25.
//

import UIKit

import SnapKit
import GrowSpaceSDK
#if canImport(ActivityKit)
import ActivityKit
#endif

class RangeViewController: UIViewController {
    private let growSpaceUWBSDK = GrowSpaceSDK()
    private var maximumConnectionCount: Int = 4
    private var maximumConnectionDistance: Float = 80.0
    private var uwbUpdateTimeoutSeconds: Int = 5

    var rangingStarted = false
    var demoModeTimer: Timer?
    var isScanning = false

    var deviceDistanceMap: [String: Float] = [:]

    // MARK: - Component

    private let appBarView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()

    /// 현재 폰의 NI 칩 정보 + direction 지원 여부 표시 배지
    private let capabilityBadgeLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.inset = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.backgroundColor = .systemGray6
        label.textColor = .darkGray
        return label
    }()

    private let maxConnectionsLabel: UILabel = {
        let label = UILabel()
        label.text = "maximum connections"
        return label
    }()

    private let maxConnectionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("maximum: 4", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    private let explainMaxConnectionText: UILabel = {
        let label = UILabel()
        label.text = "OS collision occurs with 7+ connections"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 12)
        label.numberOfLines = 1
        return label
    }()

    private let dealyRemoveLabel: UILabel = {
        let label = UILabel()
        label.text = "Set automatic deletion time in case of delay (S)"
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    private let dealyRemoveTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "example: 5"
        textField.keyboardType = .decimalPad
        textField.textAlignment = .right
        textField.text = "5"
        return textField
    }()

    private let explainDelayRemoveText: UILabel = {
        let label = UILabel()
        label.text = "Time to automatically disconnect when the distance update stops abnormally."
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()

    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.text = "maximum connection distance (m)"
        return label
    }()

    private let distanceTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "example: 5.0"
        textField.keyboardType = .decimalPad
        textField.textAlignment = .right
        textField.text = "80.0"
        return textField
    }()

    private let explainDistanceText: UILabel = {
        let label = UILabel()
        label.text = "If you exceed the set distance, disconnect and connect to a new device."
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()

    private let rssiConditionLabel: UILabel = {
        let label = UILabel()
        label.text = "RSSI Priority Connection Settings"
        return label
    }()

    private let explainConnectText: UILabel = {
        let label = UILabel()
        label.text = "Attempt to connect UWB devices with the largest RSSI sequentially."
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()

    private let rssiConditionSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = true
        return toggle
    }()
    private let deviceContentStack = UIStackView()
    private var deviceViews: [String: UIView] = [:]
    private let deviceScrollView = UIScrollView()

    private let uwbStartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start UWB Scan", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        return button
    }()

    private let uwbStopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Stop UWB Scan", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGray
        button.layer.cornerRadius = 10
        return button
    }()
    private let buttonStackView = UIStackView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private let noDeviceLabel: UILabel = {
        let label = UILabel()
        label.text = "Device was not detected"
        label.textAlignment = .center
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        label.isHidden = false
        return label
    }()

    /// 호스트 단말의 capability. nil 이면 미조회 상태.
    private var hostCapabilities: UWBCapabilitiesResult?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.setupLayout()
        self.setupActions()
        self.setupMaxConnectionMenu()
        self.setupKeyboardDismissGesture()
        self.setupNavigationBar()
        self.refreshCapabilityBadge()
        self.navigationItem.title = "Space UWB Scanner"
        self.updateButtonStates()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed || navigationController?.isBeingDismissed == true {
            stopUWBScan()
        }
    }

    private func setupLayout() {
        let configStack = UIStackView()
        configStack.axis = .vertical
        configStack.spacing = 20
        configStack.alignment = .fill
        view.addSubview(configStack)
        configStack.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        // capability 배지를 가장 위에 배치
        capabilityBadgeLabel.snp.makeConstraints { $0.height.greaterThanOrEqualTo(28) }
        configStack.addArrangedSubview(capabilityBadgeLabel)

        let topSpacer = UIView()
        topSpacer.snp.makeConstraints { $0.height.equalTo(4) }
        configStack.addArrangedSubview(topSpacer)

        let maxConnectionRow = UIStackView()
        maxConnectionRow.axis = .horizontal
        maxConnectionRow.spacing = 8
        maxConnectionRow.alignment = .center
        maxConnectionRow.addArrangedSubview(maxConnectionsLabel)
        maxConnectionRow.addArrangedSubview(maxConnectionsButton)

        let maxConnectionGroup = UIStackView()
        maxConnectionGroup.axis = .vertical
        maxConnectionGroup.spacing = 4
        maxConnectionGroup.alignment = .fill
        maxConnectionGroup.addArrangedSubview(maxConnectionRow)
        maxConnectionGroup.addArrangedSubview(explainMaxConnectionText)
        configStack.addArrangedSubview(maxConnectionGroup)

        let delayRemoveRow = UIStackView()
        delayRemoveRow.axis = .horizontal
        delayRemoveRow.spacing = 8
        delayRemoveRow.alignment = .center
        delayRemoveRow.addArrangedSubview(dealyRemoveLabel)
        delayRemoveRow.addArrangedSubview(dealyRemoveTextField)

        dealyRemoveTextField.snp.makeConstraints {
            $0.width.equalTo(80)
        }

        let delayRemoveGroup = UIStackView()
        delayRemoveGroup.axis = .vertical
        delayRemoveGroup.spacing = 4
        delayRemoveGroup.alignment = .fill
        delayRemoveGroup.addArrangedSubview(delayRemoveRow)
        delayRemoveGroup.addArrangedSubview(explainDelayRemoveText)
        configStack.addArrangedSubview(delayRemoveGroup)

        let distanceRow = UIStackView()
        distanceRow.axis = .horizontal
        distanceRow.spacing = 8
        distanceRow.alignment = .center
        distanceRow.addArrangedSubview(distanceLabel)
        distanceRow.addArrangedSubview(distanceTextField)

        distanceTextField.snp.makeConstraints {
            $0.width.equalTo(80)
        }

        let distanceGroup = UIStackView()
        distanceGroup.axis = .vertical
        distanceGroup.spacing = 4
        distanceGroup.alignment = .fill
        distanceGroup.addArrangedSubview(distanceRow)
        distanceGroup.addArrangedSubview(explainDistanceText)
        configStack.addArrangedSubview(distanceGroup)

        let switchRow = UIStackView()
        switchRow.axis = .horizontal
        switchRow.spacing = 8
        switchRow.alignment = .center
        switchRow.addArrangedSubview(rssiConditionLabel)
        switchRow.addArrangedSubview(rssiConditionSwitch)

        let connectConditionGroup = UIStackView()
        connectConditionGroup.axis = .vertical
        connectConditionGroup.spacing = 4
        connectConditionGroup.alignment = .fill
        connectConditionGroup.addArrangedSubview(switchRow)
        connectConditionGroup.addArrangedSubview(explainConnectText)
        configStack.addArrangedSubview(connectConditionGroup)

        deviceContentStack.axis = .vertical
        deviceContentStack.spacing = 12
        deviceContentStack.alignment = .fill
        deviceScrollView.addSubview(deviceContentStack)
        deviceContentStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(deviceScrollView.snp.width)
        }

        loadingIndicator.hidesWhenStopped = true
        deviceContentStack.addArrangedSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints {
            $0.height.equalTo(44)
        }


        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fillEqually
        buttonStackView.addArrangedSubview(uwbStopButton)
        buttonStackView.addArrangedSubview(uwbStartButton)

        view.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints {
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(60)
        }

        view.addSubview(deviceScrollView)
        deviceScrollView.snp.makeConstraints {
            $0.top.equalTo(configStack.snp.bottom).offset(12)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.bottom.equalTo(buttonStackView.snp.top).offset(-12)
        }

        deviceScrollView.addSubview(noDeviceLabel)
        noDeviceLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func setupActions() {
        uwbStartButton.addTarget(self, action: #selector(startUWBScan), for: .touchUpInside)
        //        uwbStartButton.addTarget(self, action: #selector(startLiveActivity), for: .touchUpInside)
        uwbStopButton.addTarget(self, action: #selector(stopUWBScan), for: .touchUpInside)
        distanceTextField.addTarget(self, action: #selector(distanceTextFieldDidChange), for: .editingChanged)
        dealyRemoveTextField.addTarget(self, action: #selector(delayRemoveTextFieldDidChange), for: .editingChanged)
    }

    private func setupNavigationBar() {
        let blockListItem = UIBarButtonItem(
            image: UIImage(systemName: "nosign"),
            style: .plain,
            target: self,
            action: #selector(showBlockList)
        )
        let capabilityItem = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(showCapabilityInfo)
        )
        navigationItem.rightBarButtonItems = [capabilityItem, blockListItem]
    }

    private func setupMaxConnectionMenu() {
        let actions = (1...6).map { count in
            UIAction(title: "\(count)", handler: { [weak self] _ in
                self?.maximumConnectionCount = count
                self?.maxConnectionsButton.setTitle("maximum: \(count)", for: .normal)
            })
        }
        let menu = UIMenu(title: "", options: .displayInline, children: actions)
        maxConnectionsButton.menu = menu
    }

    private func setupKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func distanceTextFieldDidChange(_ textField: UITextField) {
        if let text = textField.text,
           let value = Float(text) {
            maximumConnectionDistance = value
        }
    }

    @objc private func delayRemoveTextFieldDidChange(_ textField: UITextField) {
        if let text = textField.text,
           let value = Int(text) {
            uwbUpdateTimeoutSeconds = value
        }
    }

    @objc private func showBlockList() {
        let vc = BlockListViewController(sdk: growSpaceUWBSDK)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func showCapabilityInfo() {
        let vc = CapabilityInfoViewController(sdk: growSpaceUWBSDK)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func updateNoDeviceLabel() {
        noDeviceLabel.isHidden = !deviceViews.isEmpty
    }

    private func updateButtonStates() {
        uwbStartButton.isEnabled = !isScanning
        uwbStopButton.isEnabled = isScanning

        uwbStartButton.backgroundColor = isScanning ? .systemGray : .systemBlue
        uwbStopButton.backgroundColor = isScanning ? .systemRed : .systemGray
    }

    /// 호스트 단말 capability 조회 후 배지 갱신
    private func refreshCapabilityBadge() {
        let caps = growSpaceUWBSDK.getUWBCapabilities()
        hostCapabilities = caps
        let chip = caps.supportsDirection ? "U1" : "U2"
        capabilityBadgeLabel.text = "This phone: \(chip) UWB chip"
        capabilityBadgeLabel.backgroundColor = UIColor.systemGray5
        capabilityBadgeLabel.textColor = .darkGray
    }


    @objc private func startUWBScan() {
        guard !isScanning else { return }

//        LiveActivityManager.shared.start()
        isScanning = true
        updateButtonStates()

        self.deviceViews.removeAll()
        self.deviceContentStack.arrangedSubviews.forEach { view in
            if view !== loadingIndicator && view !== noDeviceLabel {
                self.deviceContentStack.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
        }

        updateNoDeviceLabel()
        loadingIndicator.startAnimating()

//        print("UWB 연결 시작 : \(Activity<SpaceUWBLiveKitAttributes>.activities.first?.activityState)")

        growSpaceUWBSDK.startUWBRanging(
            maximumConnectionCount: self.maximumConnectionCount,
            replacementDistanceThreshold: self.maximumConnectionDistance,
            uwbUpdateTimeoutSeconds: self.uwbUpdateTimeoutSeconds,
            onUpdate: { [weak self] result in
                guard let self = self else { return }

                self.demoModeTimer?.invalidate()
                self.rangingStarted = true

                self.deviceDistanceMap[result.deviceName] = result.distance

//                LiveActivityManager.shared.updateDeviceDistanceMap(self.deviceDistanceMap)

                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.upsertDeviceCard(
                        deviceName: result.deviceName,
                        distance: result.distance,
                        azimuth: result.azimuth,
                        elevation: result.elevation,
                        isDirectionAvailable: result.isDirectionAvailable
                    )
                    self.updateNoDeviceLabel()
                }
            },
            onDisconnect: { [weak self] result in
                guard let self = self else { return }
                print("연결 끊어진 장치 이름 : \(result.deviceName)")
                print("연결 끊어짐 : \(result.disConnectType) time : \(Date.now)")

                self.deviceDistanceMap.removeValue(forKey: result.deviceName)
//                LiveActivityManager.shared.updateDeviceDistanceMap(self.deviceDistanceMap)

                DispatchQueue.main.async {
                    if let deviceView = self.deviceViews[result.deviceName] {
                        self.deviceContentStack.removeArrangedSubview(deviceView)
                        deviceView.removeFromSuperview()
                        self.deviceViews.removeValue(forKey: result.deviceName)
                    }

                    self.updateNoDeviceLabel()
                    self.showDisconnectToast(deviceName: result.deviceName, type: result.disConnectType)
                }
            }
        )

        self.demoModeTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if !self.rangingStarted {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.updateNoDeviceLabel()
                }
                self.showDemoModeAlert()
            }
        }

    }

    @objc private func stopUWBScan() {
        guard isScanning else { return }

//        LiveActivityManager.shared.stop()
        isScanning = false
        updateButtonStates()
        loadingIndicator.stopAnimating()

        self.demoModeTimer?.invalidate()
        updateNoDeviceLabel()
        growSpaceUWBSDK.stopUWBRanging { result in
            switch result {
            case .success:
                print("UWB 정지 성공")
            case .failure(let error):
                print("정지 중 에러 발생: \(error)")
            }
        }
    }

    func showDemoModeAlert() {
        let alert = UIAlertController(title: "Run Experience Mode", message: "Device connection was not detected. Do you want to run the experience version?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            self?.startDemoMode()
            self?.demoModeTimer?.invalidate()
            self?.isScanning = false
            self?.updateButtonStates()
            self?.growSpaceUWBSDK.stopUWBRanging { result in
                switch result {
                case .success:
                    print("UWB 정지 성공")
                case .failure(let error):
                    print("정지 중 에러 발생: \(error)")
                }
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }

    func startDemoMode() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            // 호스트 capability 에 맞춰 데모 데이터 시뮬: U2 면 direction nil
            let supportsDirection = self.hostCapabilities?.supportsDirection ?? true
            let fakeDeviceName = "DemoDevice"
            let randomDistance = Float.random(in: 0.5...5.0)
            let randomAzimuth: Int? = supportsDirection ? Int.random(in: -180...180) : nil
            let randomElevation: Int? = supportsDirection ? Int.random(in: -90...90) : nil

            self.deviceDistanceMap[fakeDeviceName] = randomDistance
//            LiveActivityManager.shared.updateDeviceDistanceMap(self.deviceDistanceMap)

            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                self.upsertDeviceCard(
                    deviceName: fakeDeviceName,
                    distance: randomDistance,
                    azimuth: randomAzimuth,
                    elevation: randomElevation,
                    isDirectionAvailable: supportsDirection
                )
                self.updateNoDeviceLabel()
            }
        }
    }

    // MARK: - Device Card Helpers

    /// 디바이스 카드 추가 또는 갱신. azimuth/elevation 이 nil 이면 "—" 표시.
    private func upsertDeviceCard(
        deviceName: String,
        distance: Float,
        azimuth: Int?,
        elevation: Int?,
        isDirectionAvailable: Bool
    ) {
        let azimuthText = azimuth.map { "\($0)°" } ?? "—"
        let elevationText = elevation.map { "\($0)°" } ?? "—"

        if let view = deviceViews[deviceName] {
            (view.viewWithTag(Self.distanceLabelTag) as? UILabel)?.text = "Distance: \(String(format: "%.2f", distance))m"
            (view.viewWithTag(Self.azimuthLabelTag) as? UILabel)?.text = "Azimuth: \(azimuthText)"
            (view.viewWithTag(Self.elevationLabelTag) as? UILabel)?.text = "Elevation: \(elevationText)"
            return
        }

        let container = UIView()
        container.layer.cornerRadius = 8
        container.backgroundColor = .systemGray6
        container.isUserInteractionEnabled = true

        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 4
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = "Device Name: \(deviceName)"
        nameLabel.font = .boldSystemFont(ofSize: 16)

        let distanceLabel = UILabel()
        distanceLabel.tag = Self.distanceLabelTag
        distanceLabel.text = "Distance: \(String(format: "%.2f", distance))m"

        let azimuthLabel = UILabel()
        azimuthLabel.tag = Self.azimuthLabelTag
        azimuthLabel.text = "Azimuth: \(azimuthText)"

        let elevationLabel = UILabel()
        elevationLabel.tag = Self.elevationLabelTag
        elevationLabel.text = "Elevation: \(elevationText)"

        [nameLabel, distanceLabel, azimuthLabel, elevationLabel].forEach {
            $0.textColor = .darkGray
            infoStack.addArrangedSubview($0)
        }

        // 발견 가능한 옵션 버튼: 단일 끊기 / 차단 액션 시트
        let moreButton = UIButton(type: .system)
        let moreImage = UIImage(systemName: "ellipsis.circle")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 22, weight: .regular))
        moreButton.setImage(moreImage, for: .normal)
        moreButton.tintColor = .systemGray
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        moreButton.accessibilityLabel = "디바이스 옵션"
        moreButton.addAction(UIAction { [weak self] _ in
            self?.presentDeviceActionSheet(for: deviceName)
        }, for: .touchUpInside)

        container.addSubview(infoStack)
        container.addSubview(moreButton)
        NSLayoutConstraint.activate([
            infoStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            infoStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            infoStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            infoStack.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -8),

            moreButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            moreButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            moreButton.widthAnchor.constraint(equalToConstant: 32),
            moreButton.heightAnchor.constraint(equalToConstant: 32),
        ])

        // 길게 눌러도 동일한 액션 메뉴 호출 (보조 제스처)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleDeviceLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        container.addGestureRecognizer(longPress)
        objc_setAssociatedObject(container, &Self.deviceNameKey, deviceName, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        deviceContentStack.addArrangedSubview(container)
        deviceViews[deviceName] = container
    }

    private static let distanceLabelTag = 1001
    private static let azimuthLabelTag = 1002
    private static let elevationLabelTag = 1003

    private static var deviceNameKey: UInt8 = 0

    @objc private func handleDeviceLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let view = gesture.view,
              let deviceName = objc_getAssociatedObject(view, &Self.deviceNameKey) as? String else {
            return
        }
        presentDeviceActionSheet(for: deviceName)
    }

    private func presentDeviceActionSheet(for deviceName: String) {
        let alert = UIAlertController(
            title: deviceName,
            message: "디바이스 액션 선택",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "이 디바이스만 끊기 (현재 세션)", style: .default) { [weak self] _ in
            self?.growSpaceUWBSDK.disconnectDevice(deviceName)
            self?.removeDeviceCard(deviceName)
        })
        alert.addAction(UIAlertAction(title: "이 디바이스 차단 (영구)", style: .destructive) { [weak self] _ in
            self?.growSpaceUWBSDK.blockDevice(deviceName)
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = alert.popoverPresentationController, let view = deviceViews[deviceName] {
            popover.sourceView = view
            popover.sourceRect = view.bounds
        }
        present(alert, animated: true)
    }

    private func removeDeviceCard(_ deviceName: String) {
        deviceDistanceMap.removeValue(forKey: deviceName)
        if let deviceView = deviceViews[deviceName] {
            deviceContentStack.removeArrangedSubview(deviceView)
            deviceView.removeFromSuperview()
            deviceViews.removeValue(forKey: deviceName)
        }
        updateNoDeviceLabel()
    }

    /// disconnect 사유에 맞는 짧은 토스트.
    private func showDisconnectToast(deviceName: String, type: DisconnectTypeResult) {
        let (message, color): (String, UIColor) = {
            switch type {
            case .disconnectedDueToDistance:
                return ("\(deviceName) — 거리 초과로 연결 해제", .systemBlue)
            case .disconnectedDueToSystem:
                return ("\(deviceName) — 시스템 종료로 연결 해제", .systemGray)
            case .disconnectedDueToTimeout:
                return ("\(deviceName) — 응답 끊김 (timeout)", .systemRed)
            case .disconnectedDueToNoData:
                return ("\(deviceName) — UWB 데이터 미수신 (iOS 26 EDM 회귀 가능성)", .systemOrange)
            }
        }()
        presentToast(message: message, backgroundColor: color)
    }

    private func presentToast(message: String, backgroundColor: UIColor) {
        let toast = PaddingLabel()
        toast.text = message
        toast.numberOfLines = 0
        toast.backgroundColor = backgroundColor.withAlphaComponent(0.92)
        toast.textColor = .white
        toast.font = .systemFont(ofSize: 13, weight: .medium)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.alpha = 0
        view.addSubview(toast)
        toast.snp.makeConstraints {
            $0.bottom.equalTo(buttonStackView.snp.top).offset(-12)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
        }
        UIView.animate(withDuration: 0.25, animations: {
            toast.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.4, delay: 2.4, options: [], animations: {
                toast.alpha = 0
            }, completion: { _ in
                toast.removeFromSuperview()
            })
        }
    }
}

/// padding 가 들어있는 UILabel (토스트용)
final class PaddingLabel: UILabel {
    var inset = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: inset))
    }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + inset.left + inset.right, height: s.height + inset.top + inset.bottom)
    }
}
