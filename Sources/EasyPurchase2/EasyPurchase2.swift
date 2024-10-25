// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import StoreKit

@MainActor
public final class EasyPurchase2: ObservableObject {
    public static var shared = EasyPurchase2()
    
    @Published public private(set) var consumables: [Offer] = []
    @Published public private(set) var nonConsumables: [Offer] = []
    @Published public private(set) var renewableSubscribtions: [Offer] = []
    
    @Published public private(set) var purchasedSubscriptions: Set<Offer> = []
    @Published public private(set) var purchasedNonConsumables: Set<Offer> = []
    
    private var allProducts: [Product] = []
    private var productIds: [String] = []
    private var updateListenerTask: Task<Void, Error>? = nil
    private var isTrackerConfigured: Bool = false
    private var appStoreId: String = ""
    
    private let tracker = Tracker.shared
    
    private init() {
        updateListenerTask = listenForTransactions()
    }
    
    public func configure(appStoreId: String, productIds: [String], requestTrackerPermissionOnStart: Bool) async {
        self.productIds = productIds
        self.appStoreId = appStoreId
        
        await requestProducts()
        
        await updateCustomerProductStatus()
        
        if requestTrackerPermissionOnStart {
            await requestTrackerPermission()
        }
    }
    
    public func requestTrackerPermission() async {
        guard !isTrackerConfigured else { return }
        await tracker.configure(with: appStoreId, allProducts: allProducts)
        isTrackerConfigured = true
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    public func findOffer(by id: String) -> Offer? {
        if let product = allProducts.first(where: { $0.id == id }) {
            return Offer(product: product)
        }
        
        return nil
    }
    
    public func purchase(_ offer: Offer) async throws -> Transaction? {
        let result = try await offer.product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            await updateCustomerProductStatus()
            
            await transaction.finish()
            
            return transaction
        case .userCancelled, .pending: return nil
        default: return nil
        }
    }
    
    public func restorePurchases() async throws {
        try await AppStore.sync()
    }
    
    private func requestProducts() async {
        do {
            allProducts = try await Product.products(for: productIds)
            
            var consumables: [Product] = []
            var nonConsumables: [Product] = []
            var subscriptions: [Product] = []
            
            for product in allProducts {
                switch product.type {
                case .consumable:
                    consumables.append(product)
                case .autoRenewable:
                    subscriptions.append(product)
                case .nonConsumable:
                    nonConsumables.append(product)
                default:
                    print("--EasyPurchase2--","Unknown product:", product.id)
                }
            }
            
            self.consumables = consumables.map(Offer.init)
            self.nonConsumables = nonConsumables.map(Offer.init)
            self.renewableSubscribtions = subscriptions.map(Offer.init)
        } catch {
            print("--EasyPurchase2--","Failed product request from the App Store server. \(error)")
        }
    }
    
    private func updateCustomerProductStatus() async {
        var allPurchased: Set<Transaction> = []
        var purchasedSubscriptions: Set<Offer> = []
        var purchasedNonConsumables: Set<Offer> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                allPurchased.insert(transaction)
                
                switch transaction.productType {
                case .autoRenewable:
                    if let subscription = renewableSubscribtions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.insert(subscription)
                    }
                case .nonConsumable:
                    if let nonConsumable = nonConsumables.first(where: { $0.id == transaction.productID }) {
                        purchasedNonConsumables.insert(nonConsumable)
                    }
                default: break
                }
            } catch {
                print("--EasyPurchase2--",error)
            }
        }
        
        self.purchasedNonConsumables = purchasedNonConsumables
        self.purchasedSubscriptions = purchasedSubscriptions
        
        await tracker.updatePurchases(of: allPurchased)
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    await self.updateCustomerProductStatus()
                    
                    await transaction.finish()
                } catch {
                    print("--EasyPurchase2--","Transaction failed verification with error:", error.localizedDescription)
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
    }
}

extension EasyPurchase2 {
    enum StoreError: LocalizedError {
        case failedVerification
        
        var errorDescription: String? {
            switch self {
            case .failedVerification: "Cannot verify purchase"
            }
        }
    }
}
