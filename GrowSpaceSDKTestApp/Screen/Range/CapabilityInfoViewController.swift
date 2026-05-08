//
//  CapabilityInfoViewController.swift
//  GrowSpaceSDKTestApp
//
//  현재 단말의 NearbyInteraction capability 표시 (디버그/QA).
//

import UIKit
import SnapKit
import GrowSpaceSDK

final class CapabilityInfoViewController: UIViewController {

    private let sdk: GrowSpaceSDK

    init(sdk: GrowSpaceSDK) {
        self.sdk = sdk
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Device Capability"
        view.backgroundColor = .systemBackground

        let caps = sdk.getUWBCapabilities()

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        view.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
        }

        let chipBadge = PaddingLabel()
        chipBadge.inset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        chipBadge.text = caps.supportsDirection ? "U1 UWB chip — 풀 기능" : "U2 UWB chip — direction 미지원"
        chipBadge.font = .boldSystemFont(ofSize: 16)
        chipBadge.textAlignment = .center
        chipBadge.textColor = caps.supportsDirection ? .systemGreen : .systemOrange
        chipBadge.backgroundColor = (caps.supportsDirection ? UIColor.systemGreen : .systemOrange).withAlphaComponent(0.15)
        chipBadge.layer.cornerRadius = 8
        chipBadge.layer.masksToBounds = true
        stack.addArrangedSubview(chipBadge)

        stack.addArrangedSubview(makeRow(title: "supportsDirection", value: caps.supportsDirection))
        stack.addArrangedSubview(makeRow(title: "supportsCameraAssistance", value: caps.supportsCameraAssistance))
        stack.addArrangedSubview(makeRow(title: "supportsPreciseDistanceMeasurement", value: caps.supportsPreciseDistanceMeasurement))
        stack.addArrangedSubview(makeRow(title: "supportsExtendedDistanceMeasurement", value: caps.supportsExtendedDistanceMeasurement))

        let note = UILabel()
        note.numberOfLines = 0
        note.font = .systemFont(ofSize: 12)
        note.textColor = .secondaryLabel
        note.text = """
        ▸ supportsDirection=false 인 경우 (U2 칩, iPhone 14+):
          • azimuth/elevation 항상 nil
          • SDK 는 모든 환경에서 AR/camera assistance 미사용 — 카메라 권한 미요구
          • distance 만 사용 가능

        ▸ supportsExtendedDistanceMeasurement=true 인 경우:
          • iOS 26 + U2↔U2 EDM 미업데이트 회귀 영향 받을 수 있음
          • SDK 가 BLE 연결 후 데이터 미수신 시 disconnectedDueToNoData 로 알림
        """
        stack.addArrangedSubview(note)
    }

    private func makeRow(title: String, value: Bool?) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        titleLabel.numberOfLines = 0
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(titleLabel)

        let valueLabel = UILabel()
        valueLabel.font = .boldSystemFont(ofSize: 14)
        valueLabel.textAlignment = .right
        if let v = value {
            valueLabel.text = v ? "✅ true" : "❌ false"
            valueLabel.textColor = v ? .systemGreen : .systemRed
        } else {
            valueLabel.text = "n/a"
            valueLabel.textColor = .secondaryLabel
        }
        row.addArrangedSubview(valueLabel)
        return row
    }

    private func makeRow(title: String, value: Bool) -> UIView {
        return makeRow(title: title, value: Optional<Bool>.some(value))
    }
}
