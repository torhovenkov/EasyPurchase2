# EasyPurchase2 Framework

EasyPurchase is a Swift package that simplifies the implementation of purchase logic and analytics for your iOS applications. It provides a set of public properties and functions to manage subscriptions, lifetime offers, the purchase process, and also collects and sends analytics data about user purchases. With EasyPurchase, you can seamlessly integrate in-app purchase functionality and gain valuable insights into user behavior.

## Features

- `consumables: [Offer]`: A published array of available consumables 
- `nonConsumables: [[Offer]`: A published array of available non consumables
- `renewableSubscribtions: [[Offer]`: A published array of available renewable subscribtions
- `purchasedSubscriptions: Set<Offer>`: A published array of already purchased renewable subscribtions 
- `purchasedNonConsumables: Set<Offer>`: A published array of available non consumables

### Public Functions

- `configure(appStoreId: String, productIds: [String], requestTrackerPermissionOnStart: Bool) async`: Configure EasyPurchase2 with the necessary parameters, including the App Store ID, product identifiers, and other settings.
- `requestTrackerPermission() async`: Request tracker permission if you don't hasn't requested it in configure function
- `restorePurchase() async`: Restore a previous purchase.
- `purchase(_ offer: Offer) async throws -> Transaction? `: Initiate a purchase for a specific offer.

## Getting Started

1. Add EasyPurchase2 as a Swift package dependency in your Xcode project.
2. Import the EasyPurchase framework into your code.
3. Configure EasyPurchase with the necessary parameters using the `configure` function, including your App Store ID, and other relevant settings.
4. Use the provided properties and functions to manage purchase logic in your app.
5. IMPORTANT! Add "Privacy - Tracking Usage Description" to your info.plist file 
value example(no brackets): "This identifier will be used to deliver personalized ads to you.".

## Example Usage

```swift
import EasyPurchase

// Configure EasyPurchase
let easyPurchase = EasyPurchase.shared
...
Task {
            await easyPurchase.configure(
                appStoreId: "123",
                productIds: productIds,
                requestTrackerPermissionOnStart: false
            )
        }

```

## Contact
If you have any questions, issues, or suggestions regarding EasyPurchase2, please create an issue on GitHub or contact us at vladislav.lnx@gmail.com.
