//
//  BlockListViewController.swift
//  GrowSpaceSDKTestApp
//
//  차단된 UWB 디바이스 목록. 개별 unblock + clear all.
//

import UIKit
import SnapKit
import GrowSpaceSDK

final class BlockListViewController: UIViewController {

    private let sdk: GrowSpaceSDK
    private var blockedDevices: [String] = []

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "차단된 디바이스가 없습니다"
        l.textAlignment = .center
        l.textColor = .lightGray
        l.font = .systemFont(ofSize: 15)
        return l
    }()

    init(sdk: GrowSpaceSDK) {
        self.sdk = sdk
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "차단 목록"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "전체 해제",
            style: .plain,
            target: self,
            action: #selector(clearAllTapped)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        tableView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        emptyLabel.snp.makeConstraints { $0.center.equalTo(view.safeAreaLayoutGuide) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private func reload() {
        blockedDevices = Array(sdk.getBlockedDevices()).sorted()
        emptyLabel.isHidden = !blockedDevices.isEmpty
        tableView.reloadData()
    }

    @objc private func clearAllTapped() {
        guard !blockedDevices.isEmpty else { return }
        let alert = UIAlertController(
            title: "전체 해제",
            message: "\(blockedDevices.count) 개 디바이스를 모두 차단 해제할까요?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "해제", style: .destructive) { [weak self] _ in
            self?.sdk.clearBlockedDevices()
            self?.reload()
        })
        present(alert, animated: true)
    }
}

extension BlockListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedDevices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = blockedDevices[indexPath.row]
        cell.textLabel?.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let name = blockedDevices[indexPath.row]
        // Unblock 은 destructive(파괴적)가 아니라 일반 액션이므로 .normal style 사용
        let action = UIContextualAction(style: .normal, title: "Unblock") { [weak self] _, _, completion in
            self?.sdk.unblockDevice(name)
            self?.reload()
            completion(true)
        }
        action.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let name = blockedDevices[indexPath.row]
        let alert = UIAlertController(title: name, message: "차단 해제할까요?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "Unblock", style: .default) { [weak self] _ in
            self?.sdk.unblockDevice(name)
            self?.reload()
        })
        present(alert, animated: true)
    }
}
