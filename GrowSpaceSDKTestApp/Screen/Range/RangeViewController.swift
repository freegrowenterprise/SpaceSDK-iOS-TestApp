//
//  RangeViewController.swift
//  GrowSpaceSDKTestApp
//
//  Created by min gwan choi on 5/8/25.
//

import UIKit

import SnapKit
import GrowSpaceSDK
import ActivityKit

class RangeViewController: UIViewController {
    private let growSpaceUWBSDK = GrowSpaceSDK(apiKey: "API-KEY")
    private var maximumConnectionCount: Int = 4
    private var maximumConnectionDistance: Float = 8.0
    
    var rangingStarted = false
    var demoModeTimer: Timer?
    
    var deviceDistanceMap: [String: Float] = [:]
    
    // MARK: - Component
    
    private let appBarView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let appBarTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Space UWB Scanner"
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .black
        return label
    }()
    
    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    private let maxConnectionsLabel: UILabel = {
        let label = UILabel()
        label.text = "최대 연결 개수 설정"
        return label
    }()
    
    private let maxConnectionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("최대 연결 수: 4", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private let explainMaxConnectionText: UILabel = {
        let label = UILabel()
        label.text = "7개 이상 동시 연결시 OS 내부적으로 충돌이 발생합니다."
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.text = "최대 연결 거리 설정 (m)"
        return label
    }()
    
    private let distanceTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "예: 5.0"
        textField.keyboardType = .decimalPad
        textField.textAlignment = .right
        textField.text = "8.0"
        return textField
    }()
    
    private let explainDistanceText: UILabel = {
        let label = UILabel()
        label.text = "설정 거리에서 초과되었을 때 연결을 끊고 새로운 장치 연결을 시도합니다."
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()
    
    private let rssiConditionLabel: UILabel = {
        let label = UILabel()
        label.text = "신호 강한 순 우선 연결 설정"
        return label
    }()
    
    private let explainConnectText: UILabel = {
        let label = UILabel()
        label.text = "RSSI가 가장 큰 UWB 장치부터 연결을 시도합니다."
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
    private var deviceViews: [String: UIStackView] = [:]
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.setupLayout()
        self.setupActions()
        self.setupMaxConnectionMenu()
        self.setupKeyboardDismissGesture()
    }
    
    private func setupLayout() {
        view.addSubview(appBarView)
        appBarView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(48)
        }
        
        appBarView.addSubview(appBarTitleLabel)
        appBarTitleLabel.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
        
        view.addSubview(divider)
        divider.snp.makeConstraints {
            $0.top.equalTo(appBarView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        
        let configStack = UIStackView()
        configStack.axis = .vertical
        configStack.spacing = 20
        configStack.alignment = .fill
        view.addSubview(configStack)
        configStack.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom).offset(12)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        
        let topSpacer = UIView()
        topSpacer.snp.makeConstraints { $0.height.equalTo(12) }
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
        
        let distanceRow = UIStackView()
        distanceRow.axis = .horizontal
        distanceRow.spacing = 8
        distanceRow.alignment = .center
        distanceRow.addArrangedSubview(distanceLabel)
        distanceRow.addArrangedSubview(distanceTextField)
        
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
    }
    
    private func setupActions() {
        uwbStartButton.addTarget(self, action: #selector(startUWBScan), for: .touchUpInside)
        //        uwbStartButton.addTarget(self, action: #selector(startLiveActivity), for: .touchUpInside)
        uwbStopButton.addTarget(self, action: #selector(stopUWBScan), for: .touchUpInside)
        distanceTextField.addTarget(self, action: #selector(distanceTextFieldDidChange), for: .editingChanged)
    }
    
    private func setupMaxConnectionMenu() {
        let actions = (1...6).map { count in
            UIAction(title: "\(count)", handler: { [weak self] _ in
                self?.maximumConnectionCount = count
                self?.maxConnectionsButton.setTitle("최대 연결 수: \(count)", for: .normal)
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
    
    
    @objc private func startUWBScan() {
        LiveActivityManager.shared.start()
        self.deviceViews.removeAll()
        self.deviceContentStack.arrangedSubviews.forEach { view in
            if view !== loadingIndicator {
                self.deviceContentStack.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
        }
        
        loadingIndicator.startAnimating()
        
//        print("UWB 연결 시작 : \(Activity<SpaceUWBLiveKitAttributes>.activities.first?.activityState)")
        
        growSpaceUWBSDK.startUWBRanging(
            maximumConnectionCount: self.maximumConnectionCount,
            replacementDistanceThreshold: self.maximumConnectionDistance,
            onUpdate: { [weak self] result in
                guard let self = self else { return }
                
                self.demoModeTimer?.invalidate()
                self.rangingStarted = true

                let name = result.deviceName
                let distance = result.distance
                
                self.deviceDistanceMap[result.deviceName] = result.distance
                
                LiveActivityManager.shared.updateDeviceDistanceMap(self.deviceDistanceMap)

                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    
                    let name = result.deviceName
                    if let view = self.deviceViews[name],
                       let labels = view.arrangedSubviews as? [UILabel], labels.count == 4 {
                        labels[1].text = "Distance: \(result.distance)m"
                        labels[2].text = "Azimuth: \(result.azimuth)°"
                        labels[3].text = "Elevation: \(result.elevation)°"
                    } else {
                        let container = UIStackView()
                        container.axis = .vertical
                        container.spacing = 4
                        container.layer.cornerRadius = 8
                        container.backgroundColor = .systemGray6
                        container.isLayoutMarginsRelativeArrangement = true
                        container.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
                        
                        let nameLabel = UILabel()
                        nameLabel.text = "Device Name: \(result.deviceName)"
                        nameLabel.font = .boldSystemFont(ofSize: 16)
                        
                        let distanceLabel = UILabel()
                        distanceLabel.text = "Distance: \(result.distance)m"
                        
                        let azimuthLabel = UILabel()
                        azimuthLabel.text = "Azimuth: \(result.azimuth)°"
                        
                        let elevationLabel = UILabel()
                        elevationLabel.text = "Elevation: \(result.elevation)°"
                        
                        [nameLabel, distanceLabel, azimuthLabel, elevationLabel].forEach {
                            $0.textColor = .darkGray
                            container.addArrangedSubview($0)
                        }
                        
                        self.deviceContentStack.addArrangedSubview(container)
                        self.deviceViews[name] = container
                    }
                }
            },
            onDisconnect: { [weak self] disconnect in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let view = self.deviceViews[disconnect.deviceName] {
                        view.removeFromSuperview()
                        self.deviceViews.removeValue(forKey: disconnect.deviceName)
                    }
                }
            }
        )
        
        self.demoModeTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if !self.rangingStarted {
                self.showDemoModeAlert()
            }
        }
        
    }
    
    @objc private func stopUWBScan() {
        LiveActivityManager.shared.stop()
        self.demoModeTimer?.invalidate()
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
        let alert = UIAlertController(title: "체험 모드 실행", message: "장치 연결이 감지되지 않았습니다. 체험 버전을 실행하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "실행", style: .default, handler: { [weak self] _ in
            self?.startDemoMode()
            self?.demoModeTimer?.invalidate()
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
            
            // 랜덤 가짜 장치명 및 거리값 생성
            let fakeDeviceName = "DemoDevice"
            let randomDistance = Float.random(in: 0.5...5.0)
            
            self.deviceDistanceMap[fakeDeviceName] = randomDistance
            LiveActivityManager.shared.updateDeviceDistanceMap(self.deviceDistanceMap)
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                if let view = self.deviceViews[fakeDeviceName],
                   let labels = view.arrangedSubviews as? [UILabel], labels.count == 4 {
                    labels[1].text = "Distance: \(randomDistance)m"
                    labels[2].text = "Azimuth: \(Float.random(in: -180...180))°"
                    labels[3].text = "Elevation: \(Float.random(in: -90...90))°"
                } else {
                    let container = UIStackView()
                    container.axis = .vertical
                    container.spacing = 4
                    container.layer.cornerRadius = 8
                    container.backgroundColor = .systemGray6
                    container.isLayoutMarginsRelativeArrangement = true
                    container.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
                    
                    let nameLabel = UILabel()
                    nameLabel.text = "Device Name: \(fakeDeviceName)"
                    nameLabel.font = .boldSystemFont(ofSize: 16)
                    
                    let distanceLabel = UILabel()
                    distanceLabel.text = "Distance: \(randomDistance)m"
                    
                    let azimuthLabel = UILabel()
                    azimuthLabel.text = "Azimuth: \(Float.random(in: -180...180))°"
                    
                    let elevationLabel = UILabel()
                    elevationLabel.text = "Elevation: \(Float.random(in: -90...90))°"
                    
                    [nameLabel, distanceLabel, azimuthLabel, elevationLabel].forEach {
                        $0.textColor = .darkGray
                        container.addArrangedSubview($0)
                    }
                    
                    self.deviceContentStack.addArrangedSubview(container)
                    self.deviceViews[fakeDeviceName] = container
                }
            }
        }
    }
}
