//
//  PurchaseService.swift
//  EasyPurchase2
//
//  Created by Vladyslav Torhovenkov on 22.10.2024.
//

import Foundation
import StoreKit

@MainActor
final class PurchaseService: ObservableObject {
    @Published private(set) var subscribtions: [Offer] = []
    @Published private(set) var consumables: [Offer] = []
    @Published private(set) var nonConsumables: [Offer] = []
    
    private let easyPurchase: EasyPurchase2
    
    private let productIds: [String] = [
        "sub.1",
        "sub.2",
        "points.100",
        "points.500",
        "lifetime",
    ]
    
    static let shared = PurchaseService()
    
    private init() {
        easyPurchase = EasyPurchase2.shared
        
        Task {
            await easyPurchase.configure(appStoreId: "", productIds: productIds, requestTrackerPermissionOnStart: false)
            
            easyPurchase.$renewableSubscribtions
                .assign(to: &$subscribtions)
            
            easyPurchase.$consumables
                .assign(to: &$consumables)
            
            easyPurchase.$nonConsumables
                .assign(to: &$nonConsumables)
        }
    }
    
    func purchase(_ offer: Offer) async throws -> Transaction? {
        try await easyPurchase.purchase(offer)
    }
}
