//
//  TrackServiceProtocol.swift
//  EasyPurchase2
//
//  Created by Vladyslav Torhovenkov on 22.10.2024.
//


import Foundation
import AppTrackingTransparency
import AdSupport
import Network
import StoreKit

#if !os(tvOS)
import AdServices
#endif

protocol TrackServiceProtocol {
    func configure(with appstoreId: String, allProducts: [Product]) async
    func trackPurchase(_ product: Product, with transaction: Transaction) async
    func updatePurchases(of products: Set<Transaction>) async
}

actor Tracker: TrackServiceProtocol {
    static let shared = Tracker()
    
    private var appUserId: String = ""
    private var idfa: String = ""
    private var vendorId: String = ""
    private var isNotConfigure = true
    private var allProducts: [Product] = []
    
#if os(macOS)
    private var didBecomeActiveNotification = NSApplication.didBecomeActiveNotification
#else
    private var didBecomeActiveNotification = UIApplication.didBecomeActiveNotification
#endif
    
    private init() { }
    
    func configure(with appstoreId: String, allProducts: [Product]) async {
        self.allProducts = allProducts
        self.appUserId = getUserId()
        let _ = await ATTrackingManager.requestTrackingAuthorization()
        await sendData()
        
        func sendData() async {
            guard isNotConfigure else { return }
            isNotConfigure = false
            
            let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            self.idfa = idfa
            self.vendorId = vendorId
            
            let handleAttribution = await handleAttribution()
            
            let userSetups = UserSetups(
                attribution: handleAttribution?.attrubution,
                campaignId: handleAttribution?.campaignId,
                campaignRegion: handleAttribution?.campaignRegion,
                appBundleId: Bundle.main.bundleIdentifier ?? "",
                appUserId: self.appUserId,
                idfa: idfa,
                vendorId: vendorId,
                appVersion: Bundle.main.appVersion,
                appstoreId: appstoreId,
                iosVersion: systemVersion,
                device: modelName,
                locale: Locale.current.identifier,
                countryCode: Locale.current.countryCode
            )
            
            send(userSetups, to: .configure)
        }
        
        var vendorId: String {
#if os(macOS)
            CFPreferencesCopyAppValue("VendorIdentifier" as CFString, (Bundle.main.bundleIdentifier ?? "") as CFString) as? String  ?? ""
#else
            UIDevice.current.identifierForVendor?.uuidString ?? ""
#endif
        }
        
        var systemVersion: String {
#if os(macOS)
            let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
            return "\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"
#else
            UIDevice.current.systemVersion
#endif
        }
    }
    
    func trackPurchase(_ product: Product, with transaction: Transaction) async {
        var token = ""
        
        if let url = Bundle.main.appStoreReceiptURL,
           let data = try? Data(contentsOf: url) {
            token = data.base64EncodedString()
        }
        
        let purchaseDetail = PurchaseDetail(transaction, product: product, appUserId: self.appUserId, token: token)
        
        send(purchaseDetail, to: .trackPurchase)
    }
    
    func updatePurchases(of transactions: Set<Transaction>) async {
        let isFirstRun: Bool = Storage.getFromDefaults(.isFirstRun) ?? true
        print("!@ANALITIC Old Purchases prepeare: \(isFirstRun)")
        guard isFirstRun else { return }
        Storage.saveInDefaults(false, by: .isFirstRun)
        print("!@ANALITIC Old Purchases start")
        
        let productDetails = transactions.compactMap { transaction in
            if let product = product(by: transaction.productID) {
                return PurchaseDetail(transaction, product: product, appUserId: appUserId, token: nil)
            } else {
                return nil
            }
        }
        
        send(AllPurchaseDetail(purchases: productDetails), to: .trackAllPurchases)
    }
    
    func product(by productId: String) -> Product? {
        allProducts.first(where: { $0.id == productId })
    }
}

private func handleAttribution() async -> UserAttribution? {
#if targetEnvironment(simulator) || os(tvOS)
    return nil
#endif
    
    let attributionToken = try? AAAttribution.attributionToken()
    guard let attributionToken else { return nil }
    
    var request = URLRequest(url: URL(string:"https://api-adservices.apple.com/api/v1/")!)
    request.httpMethod = "POST"
    request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
    request.httpBody = Data(attributionToken.utf8)
    
    guard let (data, _) = try? await URLSession.shared.data(for: request),
       let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any],
       let attribution = result["attribution"] as? Bool,
       let campaignId = result["campaignId"] as? Int,
       let countryOrRegion = result["countryOrRegion"] as? String,
          campaignId != 1234567890 else { return nil }
    
    return UserAttribution(attrubution: attribution, campaignId: String(campaignId), campaignRegion: countryOrRegion)
}

// MARK: - Helpers

extension Tracker {
    private func send<T: DictionaryConvertable>(_ data: T, to endpoint: NetworkService.TrackerEndpoint) {
        NetworkService.send(data, endpoint: endpoint)
    }
    
    private func getUserId() -> String {
        if let appUserId: String = Storage.getFromDefaults(.appUserId) {
            return appUserId
        } else {
            let appUserId = "\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
            Storage.saveInDefaults(appUserId, by: .appUserId)
            Storage.saveInDefaults(true, by: .isFirstRun)
            return appUserId
        }
    }
}

extension Date {
    var milliseconds: Int64 {
        Int64(self.timeIntervalSince1970 * 1000)
    }
}

fileprivate extension Tracker {
    var modelName: String {
#if targetEnvironment(simulator)
        let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Name not found"
#else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
#endif
        return identifier
    }
}

fileprivate extension Bundle {
    var displayName: String {
        object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Could not determine the application name"
    }
    
    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Could not determine the application build number"
    }
    
    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Could not determine the application version"
    }
}

fileprivate extension Locale {
    var countryCode: String {
        if #available(iOS 16, macOS 13, tvOS 16, *) {
            return self.language.region?.identifier ?? ""
        } else {
            return self.regionCode  ?? ""
        }
    }
}
