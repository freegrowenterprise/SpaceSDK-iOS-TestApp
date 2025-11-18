//
//  DeviceCoordinateViewModel.swift
//  GrowSpaceSDKTestApp
//
//  Created by min gwan choi on 5/8/25.
//

import Foundation
import CoreGraphics

class DeviceCoordinateViewModel {
    // MARK: - 저장된 좌표 정보
    private(set) var deviceCoordinates: [String: CGPoint] = [:]

    // MARK: - 실시간 거리 정보
    private(set) var anchorDistances: [String: Float] = [:]

    // MARK: - 현재 RTLS 측정 위치
    private(set) var currentRtlsLocation: CGPoint?

    // MARK: - 좌표 설정
    func setCoordinate(macAddress: String, x: CGFloat, y: CGFloat) {
        deviceCoordinates[macAddress] = CGPoint(x: x, y: y)
    }

    // MARK: - 현재 위치 업데이트
    func setCurrentLocation(_ point: CGPoint?) {
        currentRtlsLocation = point
    }

    // MARK: - 거리 정보 업데이트
    func updateAnchorDistances(_ map: [String: Float]) {
        anchorDistances = map
    }

    // MARK: - 초기화 또는 삭제
    func reset() {
        deviceCoordinates.removeAll()
        anchorDistances.removeAll()
        currentRtlsLocation = nil
    }
}
