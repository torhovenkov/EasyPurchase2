//
//  ExampleViewVM.swift
//  EasyPurchase2
//
//  Created by Vladyslav Torhovenkov on 23.10.2024.
//

import Foundation

@MainActor
final class ExampleViewVM: ObservableObject {
    @Published private(set) var subscribtions: [Offer] = []
    @Published private(set) var consumables: [Offer] = []
    @Published private(set) var nonConsumables: [Offer] = []
    @Published private(set) var selectedOffer: Offer?
    
    private let purchaseService: PurchaseService
    
    init() {
        self.purchaseService = PurchaseService.shared
        
        purchaseService.$subscribtions
            .assign(to: &$subscribtions)
        
        purchaseService.$consumables
            .assign(to: &$consumables)
        
        purchaseService.$nonConsumables
            .assign(to: &$nonConsumables)
    }
    
    var isButtonDisabled: Bool {
        selectedOffer == nil
    }
    
    var buttonText: String {
        isButtonDisabled ? "Select" : selectedOffer?.displayPrice ?? "Buy"
    }
    
    func select(_ offer: Offer) {
        selectedOffer = offer
    }
    
    func isSelected(_ offer: Offer) -> Bool {
        selectedOffer == offer
    }
    
    func purchase() {
        guard let selectedOffer else { return }
    }
}
