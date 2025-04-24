////
////  SpaceNetwork.swift
////  GrowSpaceSDKTestApp
////
////  Created by min gwan choi on 3/17/25.
////
//
//import Foundation
//
//import GrowSpacePrivateSDK
//
//struct SpaceNetwork {
//    private let apiKey: String
//    
//    init(apiKey: String) {
//        self.apiKey = apiKey
//    }
//    
//    func sendGetRequestToServer(macAddress: String) async -> SpaceZoneResponse? {
//        let baseURL = "https://v2.api-freegrow-test.com/grow-space/indoor-location/beacon/my"
//        let apiKey = self.apiKey
//        
//        guard let url = URL(string: "\(baseURL)") else {
//            print("유효하지 않은 URL")
//            return nil
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue(apiKey, forHTTPHeaderField: "API-Key")
//        
//        let bodyData: [String: Any] = [
//            "beaconUuid": macAddress
//        ]
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData, options: [])
//        } catch {
//            print("❌ JSON 변환 오류: \(error.localizedDescription)")
//            return nil
//        }
//        
//        do {
//            let (data, response) = try await URLSession.shared.data(for: request)
//            
//            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
//                print("❌ 서버 응답 오류: \(response.debugDescription)")
//                return nil
//            }
//            
//            let decodedResponse = try JSONDecoder().decode(SpaceZoneResponse.self, from: data)
//            return decodedResponse
//            
//        } catch {
//            print("❌ 네트워크 요청 실패 또는 JSON 파싱 오류: \(error.localizedDescription)")
//            return nil
//        }
//    }
//}
