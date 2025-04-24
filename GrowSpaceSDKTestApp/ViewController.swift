//
//  ViewController.swift
//  GrowSpaceSDKTestApp
//
//  Created by min gwan choi on 3/14/25.
//

import UIKit

import SnapKit
import GrowSpaceSDK

@available(iOS 16.0, *)
class ViewController: UIViewController {
    private let growSpaceUWBSDK = GrowSpaceSDK(apiKey: "")
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        return stackView
    }()
    private let deviceStackView = UIStackView()
    private var deviceViews: [String: UIStackView] = [:]
    private let uwbStartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("UWB 스캔 시작", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(startUWBScan), for: .touchUpInside)
        return button
    }()
    private let uwbStopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("UWB 스캔 종료", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGray
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(stopUWBScan), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupLayout()
    }
    
    private func setupLayout() {
        self.view.addSubview(self.stackView)
        
        self.stackView.axis = .vertical
        self.stackView.spacing = 16
        self.stackView.alignment = .fill
        self.stackView.distribution = .equalSpacing
        
        self.stackView.addArrangedSubview(self.uwbStartButton)
        self.stackView.addArrangedSubview(self.uwbStopButton)
        
        self.stackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview().offset(100)
        }

        self.uwbStartButton.snp.makeConstraints {
            $0.height.equalTo(60)
        }

        self.uwbStopButton.snp.makeConstraints {
            $0.height.equalTo(60)
        }

        deviceStackView.axis = .vertical
        deviceStackView.spacing = 12
        deviceStackView.alignment = .fill
        view.addSubview(deviceStackView)

        deviceStackView.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
    @objc private func startUWBScan() {
        growSpaceUWBSDK.startUWBRanging(
            onUpdate: { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    let name = result.deviceName
                    if let view = self.deviceViews[name],
                       let labels = view.arrangedSubviews as? [UILabel], labels.count == 4 {
                        labels[1].text = "거리: \(result.distance)m"
                        labels[2].text = "방위각: \(result.azimuth)°"
                        labels[3].text = "고도: \(result.elevation)°"
                    } else {
                        let container = UIStackView()
                        container.axis = .vertical
                        container.spacing = 4
                        container.layer.cornerRadius = 8
                        container.backgroundColor = .systemGray6
                        container.isLayoutMarginsRelativeArrangement = true
                        container.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

                        let nameLabel = UILabel()
                        nameLabel.text = "디바이스: \(result.deviceName)"
                        nameLabel.font = .boldSystemFont(ofSize: 16)

                        let distanceLabel = UILabel()
                        distanceLabel.text = "거리: \(result.distance)m"

                        let azimuthLabel = UILabel()
                        azimuthLabel.text = "방위각: \(result.azimuth)°"

                        let elevationLabel = UILabel()
                        elevationLabel.text = "고도: \(result.elevation)°"

                        [nameLabel, distanceLabel, azimuthLabel, elevationLabel].forEach {
                            $0.textColor = .darkGray
                            container.addArrangedSubview($0)
                        }

                        self.deviceStackView.addArrangedSubview(container)
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
    }
    
    @objc private func stopUWBScan() {
        growSpaceUWBSDK.stopUWBRanging { result in
            switch result {
            case .success:
                print("UWB 정지 성공")
            case .failure(let error):
                print("정지 중 에러 발생: \(error)")
            }
        }
    }
}

