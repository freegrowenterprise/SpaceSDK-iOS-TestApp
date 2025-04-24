////
////  BLEScanner.swift
////  GrowSpaceSDK
////
////  Created by min gwan choi on 3/14/25.
////
//
//import CoreBluetooth
//
//struct RssiTime {
//    var rssi: Int
//    var time: Date
//}
//
//class BLEScanner: NSObject, CBCentralManagerDelegate {
////    private var apiKey: String
//    private var centralManager: CBCentralManager!
//    private var discoveredDevices: [String: NSNumber] = [:]
//    private var onDeviceDiscovered: ((String, Int) -> Void)?
//    
//    private var growSpaceBeaconData: [String: RssiTime] = [:]
//    private var previousKeys: Set<String> = []
//    private var count = 0
//    
//    override init() {
////        self.apiKey = apiKey
////        self.onDeviceDiscovered = onDeviceDiscovered
//        super.init()
//        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
//    }
//    
//    func startScan(onDeviceDiscovered: @escaping (String, Int) -> Void) {
//        
//    }
//    
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        if central.state == .poweredOn {
//            print("BLE 사용 가능. 스캔 시작")
//            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
//        } else {
//            print("BLE를 사용할 수 없음. 상태: \(central.state.rawValue)")
//        }
//    }
//    
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
//        guard RSSI.intValue < 0 else { return }
//        guard RSSI.intValue > -76 else { return }
//        
//        var macAddress: String? = nil
//        
//        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
//            for (key, value) in serviceData {
//                if key.uuidString.lowercased() == "ffe1" {
//                    if value.count == 14, value[0] == 161, value[1] == 8, value[2] == 100 {
//                        macAddress = ""
//                        macAddress! += toHexWithPadding(value[8])
//                        macAddress! += toHexWithPadding(value[7])
//                        macAddress! += toHexWithPadding(value[6])
//                        macAddress! += toHexWithPadding(value[5])
//                        macAddress! += toHexWithPadding(value[4])
//                        macAddress! += toHexWithPadding(value[3])
//                    }
//                }
//            }
//        }
//        
//        if let mac = macAddress {
//            if discoveredDevices[mac] == nil || RSSI.intValue != discoveredDevices[mac]!.intValue {
//                discoveredDevices[mac] = RSSI
//
//
//                growSpaceBeaconData = growSpaceBeaconData.filter { Date().timeIntervalSince1970 - $0.value.time.timeIntervalSince1970 < 3 }
//
//                updateGrowSpaceBeaconData(key: mac, value: RssiTime(rssi: RSSI.intValue, time: Date.now))
//                
//            }
//        }
//    }
//    
//    func stopScanning() {
//        centralManager.stopScan()
//        print("BLE 스캔 중지됨")
//    }
//    
//    private func toHexWithPadding(_ byte: UInt8) -> String {
//        return String(format: "%02X", byte)
//    }
//    
//    func updateGrowSpaceBeaconData(key: String, value: RssiTime) {
//        growSpaceBeaconData[key] = value
//        checkForChanges(macAddress: key, rssi: value.rssi)
//    }
//    
//    private func checkForChanges(macAddress: String, rssi: Int) {
//        let currentKeys = Set(growSpaceBeaconData.keys)
//        guard currentKeys.count > 0 else { return }
//        
//        if previousKeys.count != currentKeys.count || !previousKeys.isSubset(of: currentKeys) {
//            previousKeys = currentKeys
//            let result = growSpaceBeaconData.max(by: { $0.value.rssi < $1.value.rssi })?.key ?? ""
//            print("API 호출!!!! : \(result)")
//            onDeviceDiscovered?(macAddress, rssi)
//        }
//    }
//}
