//
//  ViewController.swift
//  GrowSpaceSDKTestApp
//
//  Created by min gwan choi on 3/14/25.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    private let viewModel = DeviceCoordinateViewModel()
    
    private let rangeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("거리 측정", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        return button
    }()
    
    private let rtlsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("RTLS", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.navigationItem.title = "Space UWB"
        setupLayout()
        setupActions()
    }
    
    private func setupLayout() {
        let buttonStack = UIStackView(arrangedSubviews: [rangeButton, rtlsButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 20
        buttonStack.distribution = .fillEqually
        buttonStack.alignment = .fill
        
        view.addSubview(buttonStack)
        buttonStack.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(40) // 앱바가 없어졌으므로 바로 top 기준
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(32)
            $0.height.equalTo(120)
        }
    }
    
    private func setupActions() {
        rangeButton.addTarget(self, action: #selector(openFirstPage), for: .touchUpInside)
        rtlsButton.addTarget(self, action: #selector(openSecondPage), for: .touchUpInside)
    }
    
    @objc private func openFirstPage() {
        let vc = RangeViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func openSecondPage() {
        let vc = RTLSViewController(viewModel: viewModel)
        navigationController?.pushViewController(vc, animated: true)
    }
}
