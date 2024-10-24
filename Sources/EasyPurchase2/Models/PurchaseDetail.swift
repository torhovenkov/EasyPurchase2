//
//  PurchaseDetail.swift
//  EasyPurchase2
//
//  Created by Vladyslav Torhovenkov on 22.10.2024.
//


import Foundation
import StoreKit

struct PurchaseDetail: DictionaryConvertable {
    let appBundleId: String?
    let appUserId: String?
    let productId: String?
    let transactionId: String?
    let token: String?
    let priceInPurchasedCurrency: String?
    let currency: String?
    let purchasedAtMs: String?
    let expirationAtMs: String?
    let withTrial: Bool?
}

extension PurchaseDetail {
    init(_ transaction: Transaction, product: Product, appUserId: String?, token: String?) {
        var expirationAtMs: String? = nil
        if let expirationTimeMs = transaction.expirationDate?.milliseconds {
            expirationAtMs = String(expirationTimeMs)
        }
        
        self.appBundleId = Bundle.main.bundleIdentifier ?? ""
        self.appUserId = appUserId
        self.productId = transaction.productID
        self.transactionId = String(transaction.id)
        self.token = token
        self.priceInPurchasedCurrency = product.displayPrice
        self.currency = transaction.currencyCode ?? ""
        self.purchasedAtMs = String(transaction.purchaseDate.milliseconds)
        self.expirationAtMs = expirationAtMs
        self.withTrial = product.subscription?.introductoryOffer != nil
       
    }
}

struct AllPurchaseDetail: DictionaryConvertable {
    let purchases: [PurchaseDetail]
}
