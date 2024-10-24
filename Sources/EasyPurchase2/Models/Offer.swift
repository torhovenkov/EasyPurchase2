//
//  Offer.swift
//  EasyPurchase2
//
//  Created by Vladyslav Torhovenkov on 21.10.2024.
//

import Foundation
import StoreKit

public struct Offer: Hashable {
    public let product: Product
    
    public init(product: Product) {
        self.product = product
    }
    
    public var id: String { product.id }
    
    public var displayName: String { product.displayName }
    
    public var displayPrice: String { product.displayPrice }
    
    public var price: Decimal { product.price }
    
    public var subscribtionPeriod: Product.SubscriptionPeriod? {
        product.subscription?.subscriptionPeriod
    }
    
    public var subscribtionPeriodFormatted: String? {
        getFormattedPeriod(for: subscribtionPeriod)
    }
    
    public var subscribtionOfferPeriod: Product.SubscriptionPeriod? {
        product.subscription?.introductoryOffer?.period
    }
    
    public var subscribtionOfferPeriodFormatted: String? {
        getFormattedPeriod(for: subscribtionOfferPeriod)
    }
    
    public var offerPrice: String? {
        product.subscription?.introductoryOffer?.displayPrice
    }
    
    public var priceInDouble: Double {
        Double(truncating: product.price as NSNumber)
    }
    
    private var days: Int? {
        guard let duration = product.subscription?.subscriptionPeriod.value,
              let days: Int = {
                  switch product.subscription?.subscriptionPeriod.unit {
                  case .day: return 1
                  case .week: return 7
                  case .month: return 30
                  case .year: return 365
                  default: return nil
                  }
              }()
        else {
            return nil
        }
        
        return duration * days
    }
    
    public func discount(to baseOffer: Offer) -> Int? {
        guard let baseOfferDays = baseOffer.days,
              let selfDays = self.days
        else {
            return nil
        }
        
        let baseOfferPriceInDouble = baseOffer.priceInDouble
        let selfPriceInDouble = self.priceInDouble
        
        let discount = 1.0 - (selfPriceInDouble / Double(selfDays)) / (baseOfferPriceInDouble / Double(baseOfferDays))
        return Int(discount * 100.0)
    }
    
    private func getFormattedPeriod(for period: Product.SubscriptionPeriod?) -> String? {
        guard let period else { return nil }
        
        return switch period.unit {
        case .day: "\(period.value) day"
        case .week: "\(period.value) week"
        case .month: "\(period.value) month"
        case .year: "\(period.value) year"
        default: "Unknown"
        }
    }
}
