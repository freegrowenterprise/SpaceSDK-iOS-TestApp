//
//  MQTTSettingViewController.swift
//  GrowSpaceSDKTestApp
//
//  Created for UWB Test System
//

import UIKit
import SnapKit

class MQTTSettingViewController: UIViewController {
    private let mqttManager = MQTTManager.shared

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let hostField = UITextField()
    private let portField = UITextField()
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let clientIdField = UITextField()
    private let coordinateTopicField = UITextField()
    private let distanceTopicField = UITextField()

    private let connectButton = UIButton(type: .system)
    private let disconnectButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "MQTT Settings"
        setupUI()
        setupActions()
        loadSettings()
        setupKeyboardDismissGesture()
    }

    private func setupUI() {
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
            $0.width.equalTo(scrollView.snp.width).offset(-32)
        }

        // Broker Host
        let hostLabel = UILabel()
        hostLabel.text = "Broker Host"
        hostLabel.font = .systemFont(ofSize: 14, weight: .medium)
        contentStack.addArrangedSubview(hostLabel)

        hostField.placeholder = "3.38.52.15"
        hostField.borderStyle = .roundedRect
        hostField.keyboardType = .URL
        contentStack.addArrangedSubview(hostField)

        // Broker Port
        let portLabel = UILabel()
        portLabel.text = "Broker Port"
        portLabel.font = .systemFont(ofSize: 14, weight: .medium)
        contentStack.addArrangedSubview(portLabel)

        portField.placeholder = "1883"
        portField.borderStyle = .roundedRect
        portField.keyboardType = .numberPad
        contentStack.addArrangedSubview(portField)

        // Username
        let usernameLabel = UILabel()
        usernameLabel.text = "Username"
        usernameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        contentStack.addArrangedSubview(usernameLabel)

        usernameField.placeholder = "freegrow"
        usernameField.borderStyle = .roundedRect
        usernameField.keyboardType = .default
        usernameField.autocapitalizationType = .none
        contentStack.addArrangedSubview(usernameField)

        // Password
        let passwordLabel = UILabel()
        passwordLabel.text = "Password"
        passwordLabel.font = .systemFont(ofSize: 14, weight: .medium)
        contentStack.addArrangedSubview(passwordLabel)

        passwordField.placeholder = "gogrow!"
        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true
        passwordField.keyboardType = .default
        contentStack.addArrangedSubview(passwordField)

        // Client ID
        let clientIdLabel = UILabel()
        clientIdLabel.text = "Client ID (Optional)"
        clientIdLabel.font = .systemFont(ofSize: 14, weight: .medium)
        contentStack.addArrangedSubview(clientIdLabel)

        clientIdField.placeholder = "Auto-generated if empty"
        clientIdField.borderStyle = .roundedRect
        clientIdField.keyboardType = .default
        contentStack.addArrangedSubview(clientIdField)

        // Coordinate Topic
        let coordinateTopicLabel = UILabel()
        coordinateTopicLabel.text = "Coordinate Topic"
        coordinateTopicLabel.font = .systemFont(ofSize: 14, weight: .medium)
        contentStack.addArrangedSubview(coordinateTopicLabel)

        coordinateTopicField.placeholder = "uwb/coordinate"
        coordinateTopicField.borderStyle = .roundedRect
        coordinateTopicField.keyboardType = .default
        contentStack.addArrangedSubview(coordinateTopicField)

        // Distance Topic
        let distanceTopicLabel = UILabel()
        distanceTopicLabel.text = "Distance Topic"
        distanceTopicLabel.font = .systemFont(ofSize: 14, weight: .medium)
        contentStack.addArrangedSubview(distanceTopicLabel)

        distanceTopicField.placeholder = "uwb/distance"
        distanceTopicField.borderStyle = .roundedRect
        distanceTopicField.keyboardType = .default
        contentStack.addArrangedSubview(distanceTopicField)

        // Status Label
        statusLabel.text = "Disconnected"
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .systemRed
        contentStack.addArrangedSubview(statusLabel)
        contentStack.setCustomSpacing(24, after: statusLabel)

        // Buttons
        let buttonStack = UIStackView(arrangedSubviews: [disconnectButton, connectButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.backgroundColor = .systemGray
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 8

        connectButton.setTitle("Connect", for: .normal)
        connectButton.backgroundColor = .systemBlue
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 8

        contentStack.addArrangedSubview(buttonStack)
        buttonStack.snp.makeConstraints {
            $0.height.equalTo(48)
        }
    }

    private func setupActions() {
        connectButton.addTarget(self, action: #selector(connectToMQTT), for: .touchUpInside)
        disconnectButton.addTarget(self, action: #selector(disconnectFromMQTT), for: .touchUpInside)
    }

    private func setupKeyboardDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func loadSettings() {
        hostField.text = mqttManager.brokerHost
        portField.text = "\(mqttManager.brokerPort)"
        usernameField.text = mqttManager.username
        passwordField.text = mqttManager.password
        clientIdField.text = mqttManager.clientId
        coordinateTopicField.text = mqttManager.coordinateTopic
        distanceTopicField.text = mqttManager.distanceTopic

        updateConnectionStatus()
    }

    private func saveSettings() {
        if let coordinateTopic = coordinateTopicField.text, !coordinateTopic.isEmpty {
            mqttManager.coordinateTopic = coordinateTopic
        }
        if let distanceTopic = distanceTopicField.text, !distanceTopic.isEmpty {
            mqttManager.distanceTopic = distanceTopic
        }
    }

    private func updateConnectionStatus() {
        if mqttManager.getConnectionStatus() {
            statusLabel.text = "Connected to \(mqttManager.brokerHost):\(mqttManager.brokerPort)"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "Disconnected"
            statusLabel.textColor = .systemRed
        }
    }

    @objc private func connectToMQTT() {
        guard let host = hostField.text, !host.isEmpty else {
            showAlert(message: "Please enter broker host")
            return
        }

        guard let portText = portField.text, let port = UInt16(portText) else {
            showAlert(message: "Please enter valid port number")
            return
        }

        saveSettings()

        let clientId = clientIdField.text?.isEmpty == false ? clientIdField.text : nil
        let username = usernameField.text?.isEmpty == false ? usernameField.text : nil
        let password = passwordField.text?.isEmpty == false ? passwordField.text : nil

        mqttManager.connect(
            host: host,
            port: port,
            clientId: clientId,
            username: username,
            password: password
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.updateConnectionStatus()
        }
    }

    @objc private func disconnectFromMQTT() {
        mqttManager.disconnect()
        updateConnectionStatus()
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "MQTT Settings", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
