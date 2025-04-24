////
////  GrowSpaceSDK.swift
////  GrowSpaceSDK
////
////  Created by min gwan choi on 3/14/25.
////
//
//import CoreBluetooth
//
//public class GrowSpaceSDK {
//    private let apiKey: String
//    
//    private var scanner: BLEScanner?
//    private var network: SpaceNetwork
//    
//    public init(apiKey: String) {
//        self.apiKey = apiKey
//        self.network = SpaceNetwork(
//            apiKey: apiKey
//        )
//        if scanner == nil {
//            scanner = BLEScanner()
//        }
//    }
//    
//    public func startBeacon(onDiscoverDevices: @escaping (String, Int) -> Void) {
//        scanner?.startScan(onDeviceDiscovered: {
//            onDiscoverDevices($0, $1)
//        })
//    }
//    
//    public func stopSearchGrowSpaceBeacon() {
//        if let scanner = scanner {
//            print("stopSearchGrowSpaceBeacon 실행")
//            scanner.stopScanning()
//            self.scanner = nil
//        }
//    }
//    
//    public func spaceBeaconLocation(macAddress: String) async -> SpaceZoneResponse? {
//        return await self.network.sendGetRequestToServer(macAddress: macAddress)
//    }
//}
