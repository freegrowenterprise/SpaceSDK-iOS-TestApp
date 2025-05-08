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
    private let growSpaceUWBSDK = GrowSpaceSDK(apiKey: "API-KEY")
    private var rowCount: Int = 5
    private var columnCount: Int = 5
    private var gridLayer = CALayer()
    private var uwbResults: [String: UWBResult] = [:]

    private let scrollView = UIScrollView()
    private let contentView = UIStackView()

    private let settingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("UWB 장비 위치 설정", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        return button
    }()

    private let gridInputStack = UIStackView()
    private let rowInput = UITextField()
    private let columnInput = UITextField()
    private let gridSetButton = UIButton(type: .system)

    private let statusLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private let resultLabel = UILabel()
    private let stopButton = UIButton(type: .system)
    private let startButton = UIButton(type: .system)

    private let gridView = UIView()

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
        setupKeyboardDismissGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        drawGrid()
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

        gridInputStack.axis = .horizontal
        gridInputStack.spacing = 8
        gridInputStack.distribution = .fillEqually
        rowInput.placeholder = "세로 (max 10)"
        rowInput.borderStyle = .roundedRect
        rowInput.keyboardType = .numberPad
        rowInput.text = "5"
        columnInput.placeholder = "가로 (max 10)"
        columnInput.borderStyle = .roundedRect
        columnInput.keyboardType = .numberPad
        columnInput.text = "5"
        gridSetButton.setTitle("설정", for: .normal)
        gridInputStack.addArrangedSubview(rowInput)
        gridInputStack.addArrangedSubview(columnInput)
        gridInputStack.addArrangedSubview(gridSetButton)
        contentView.addArrangedSubview(gridInputStack)

        gridView.layer.addSublayer(gridLayer)
        gridView.backgroundColor = .white
        contentView.addArrangedSubview(gridView)
        gridView.snp.makeConstraints {
            $0.height.equalTo(gridView.snp.width)
        }

        statusLabel.text = "위치 체크 중..."
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .gray
        statusLabel.isHidden = true
        contentView.addArrangedSubview(statusLabel)

        loadingIndicator.hidesWhenStopped = true
        contentView.addArrangedSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { $0.height.equalTo(24) }

        resultLabel.numberOfLines = 0
        resultLabel.textAlignment = .center
        resultLabel.font = .systemFont(ofSize: 16)
        resultLabel.text = "결과 위치: 없음"
        contentView.addArrangedSubview(resultLabel)

        let buttonStack = UIStackView(arrangedSubviews: [stopButton, startButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        stopButton.setTitle("위치 중지", for: .normal)
        stopButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.4)
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.layer.cornerRadius = 8
        startButton.setTitle("위치 시작", for: .normal)
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
        gridSetButton.addTarget(self, action: #selector(applyGridSetting), for: .touchUpInside)
    }

    private func setupKeyboardDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func updateResultLabel() {
        if uwbResults.isEmpty {
            resultLabel.text = "결과 없음"
        } else {
            let lines = uwbResults.values.map { result in
                let directionText = result.direction.map { String(format: "%.2f", $0) }.joined(separator: ", ")
                return "[\(result.deviceName)] → 거리: \(String(format: "%.2f", result.distance))m, 각도: azimuth \(result.azimuth)°, elevation \(result.elevation)°, 방향: [\(directionText)]"
            }
            resultLabel.text = lines.joined(separator: "\n\n")
            statusLabel.isHidden = true
            loadingIndicator.stopAnimating()
        }
    }

    @objc private func openUwbSetting() {
        let settingVC = UwbSettingViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(settingVC, animated: true)
    }

    @objc private func stopRtls() {
        statusLabel.isHidden = true
        loadingIndicator.stopAnimating()
        resultLabel.text = "위치 중지됨"

        growSpaceUWBSDK.stopUWBRanging(onComplete: { _ in })
    }

    @objc private func startRtls() {
        statusLabel.isHidden = false
        loadingIndicator.startAnimating()
        resultLabel.text = "위치 지정 중..."

        growSpaceUWBSDK.startUWBRanging(
            onUpdate: { [weak self] result in
                DispatchQueue.main.async {
                    self?.uwbResults[result.deviceName] = result
                    self?.updateResultLabel()
                }
            },
            onDisconnect: { [weak self] disconnect in
                DispatchQueue.main.async {
                    self?.uwbResults.removeValue(forKey: disconnect.deviceName)
                    self?.updateResultLabel()
                }
            }
        )
    }

    @objc private func applyGridSetting() {
        let row = Int(rowInput.text ?? "5") ?? 5
        let col = Int(columnInput.text ?? "5") ?? 5
        rowCount = max(1, min(10, row))
        columnCount = max(1, min(10, col))
        drawGrid()
    }

    private func drawGrid() {
        gridLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        gridView.subviews.forEach { $0.removeFromSuperview() }

        gridView.layoutIfNeeded()

        let gridSize = min(gridView.bounds.width, gridView.bounds.height)
        let cellSize = gridSize / CGFloat(max(rowCount, columnCount))

        for i in 0...rowCount {
            let y = CGFloat(i) * cellSize
            let line = CALayer()
            line.frame = CGRect(x: 0, y: y, width: cellSize * CGFloat(columnCount), height: 1)
            line.backgroundColor = UIColor.lightGray.cgColor
            gridLayer.addSublayer(line)
        }

        for j in 0...columnCount {
            let x = CGFloat(j) * cellSize
            let line = CALayer()
            line.frame = CGRect(x: x, y: 0, width: 1, height: cellSize * CGFloat(rowCount))
            line.backgroundColor = UIColor.lightGray.cgColor
            gridLayer.addSublayer(line)
        }

        for (name, point) in viewModel.deviceCoordinates {
            let dot = UIView()
            dot.backgroundColor = .red
            dot.layer.cornerRadius = 5
            dot.clipsToBounds = true
            dot.frame = CGRect(
                x: CGFloat(point.x) * cellSize - 5,
                y: CGFloat(point.y) * cellSize - 5,
                width: 10, height: 10
            )

            let label = UILabel(frame: CGRect(x: dot.frame.minX, y: dot.frame.minY - 16, width: 60, height: 14))
            label.text = name
            label.font = .systemFont(ofSize: 10)
            label.textColor = .black
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true

            gridView.addSubview(dot)
            gridView.addSubview(label)
        }
    }
}
