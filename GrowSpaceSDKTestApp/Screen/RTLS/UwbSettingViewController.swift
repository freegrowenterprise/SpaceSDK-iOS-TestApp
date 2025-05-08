//
//  UwbSettingViewController.swift
//  GrowSpaceSDKTestApp
//
//  Created by min gwan choi on 5/8/25.
//

import UIKit
import CoreBluetooth
import SnapKit

class UwbSettingViewController: UIViewController, CBCentralManagerDelegate {
    private let viewModel: DeviceCoordinateViewModel
    private var centralManager: CBCentralManager?
    private var discoveredDevices: [CBPeripheral] = []

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "BLE 장치 설정"
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()

    private let scanStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "발견된 장치: 0개"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()

    private let scanStartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("시작", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        return button
    }()

    private let scanStopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("중지", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .lightGray
        button.layer.cornerRadius = 8
        return button
    }()

    private let scrollView = UIScrollView()
    private let deviceListView = UIStackView()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("저장", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        return button
    }()
    
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
        self.title = "UWB 설정"
        setupUI()
        setupActions()
        setupKeyboardDismissGesture()
        setupKeyboardObservers()

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            $0.centerX.equalToSuperview()
        }

        view.addSubview(scanStatusLabel)
        scanStatusLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }

        let scanButtonStack = UIStackView(arrangedSubviews: [scanStopButton, scanStartButton])
        scanButtonStack.axis = .horizontal
        scanButtonStack.spacing = 12
        scanButtonStack.distribution = .fillEqually
        view.addSubview(scanButtonStack)
        scanButtonStack.snp.makeConstraints {
            $0.top.equalTo(scanStatusLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        view.addSubview(saveButton)
        saveButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.equalTo(scanButtonStack.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(saveButton.snp.top).offset(-16)
        }

        deviceListView.axis = .vertical
        deviceListView.spacing = 8
        scrollView.addSubview(deviceListView)
        deviceListView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }
    }

    private func setupActions() {
        scanStartButton.addTarget(self, action: #selector(startScan), for: .touchUpInside)
        scanStopButton.addTarget(self, action: #selector(stopScan), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveCoordinates), for: .touchUpInside)
    }

    private func setupKeyboardDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let bottomInset = keyboardFrame.height + 16
        scrollView.contentInset.bottom = bottomInset
        scrollView.scrollIndicatorInsets.bottom = bottomInset
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func startScan() {
        discoveredDevices.removeAll()
        deviceListView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
        scanStatusLabel.text = "BLE 시작..."
    }

    @objc private func stopScan() {
        centralManager?.stopScan()
        scanStatusLabel.text = "시작 중지됨"
    }

    @objc private func saveCoordinates() {
        viewModel.deviceCoordinates.forEach { name, coord in
            print("[\(name)] → X=\(coord.x), Y=\(coord.y)")
        }
        self.navigationController?.popViewController(animated: true)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            print("Bluetooth is not available")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = advertisementData[CBAdvertisementDataLocalNameKey]  as? String,
              name.starts(with: "FGU-"),
              !discoveredDevices.contains(peripheral) else {
            return
        }
        discoveredDevices.append(peripheral)
        addDevice(name: name, x: 0.0, y: 0.0)
        scanStatusLabel.text = "발견된 장치: \(discoveredDevices.count)개"
    }

    private func addDevice(name: String, x: Double, y: Double) {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 4

        let nameLabel = UILabel()
        nameLabel.text = "장치 : \(name)"

        let xField = UITextField()
        xField.borderStyle = .roundedRect
        xField.keyboardType = .decimalPad
        xField.placeholder = "X 좌표"
        xField.text = "\(x)"

        let yField = UITextField()
        yField.borderStyle = .roundedRect
        yField.keyboardType = .decimalPad
        yField.placeholder = "Y 좌표"
        yField.text = "\(y)"

        xField.addTarget(self, action: #selector(updateCoordinate(_:)), for: .editingChanged)
        yField.addTarget(self, action: #selector(updateCoordinate(_:)), for: .editingChanged)
        xField.tag = name.hashValue ^ 0x1
        yField.tag = name.hashValue ^ 0x2

        container.addArrangedSubview(nameLabel)
        container.addArrangedSubview(xField)
        container.addArrangedSubview(yField)

        deviceListView.addArrangedSubview(container)
    }

    @objc private func updateCoordinate(_ textField: UITextField) {
        for view in deviceListView.arrangedSubviews {
            guard let stack = view as? UIStackView, stack.arrangedSubviews.count == 3,
                  let nameLabel = stack.arrangedSubviews[0] as? UILabel,
                  let xField = stack.arrangedSubviews[1] as? UITextField,
                  let yField = stack.arrangedSubviews[2] as? UITextField else { continue }

            let name = nameLabel.text?.replacingOccurrences(of: "장치 : ", with: "") ?? ""
            let x = CGFloat(Double(xField.text ?? "0") ?? 0)
            let y = CGFloat(Double(yField.text ?? "0") ?? 0)
            viewModel.setCoordinate(macAddress: name, x: x, y: y)
        }
    }
}
