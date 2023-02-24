//
//  CommonUI.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import StoreKit
import SwiftUI
import SwiftyStoreKit
import SwiftyUserInterface

public struct TappableButton: ButtonStyle {
  @Binding var isRoundedCorners: Bool
  var cornerRadius: CGFloat
  
  public init(isRoundedCorners: Binding<Bool> = .constant(false),
              cornerRadius: CGFloat = .zero) {
    self._isRoundedCorners = isRoundedCorners
    self.cornerRadius = cornerRadius
  }
  
  public func makeBody(configuration: Configuration) -> some View {
    ZStack {
      background(basedOn: configuration)
      configuration.label
    }
  }
  
  @ViewBuilder func background(basedOn config: Configuration) -> some View {
    if isRoundedCorners {
      color(basedOn: config)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    } else {
      color(basedOn: config)
    }
  }
  
  func color(basedOn config: Configuration) -> Color {
    config.isPressed ? Color(.systemGray3) : Color.clear
  }
}

public extension View {
  /// overlays an activity indicator and the background color in a ZStack
  /// make sure to pass color which suits default activity indicator and is
  /// translucent for better UI/UX
  @ViewBuilder func overlayLoader(on isLoading: Binding<Bool>,
                                  bgColor: Color = Color(.systemBackground).opacity(0.66)) -> some View {
    if isLoading.wrappedValue {
      self.overlay(
        ZStack {
          bgColor.edgesIgnoringSafeArea(.all)
          ActivityIndicator.large
        }
      )
    } else {
      self
    }
  }
}

extension Color {
  static var appTintColor: Color { .pink }
}

extension Image {
  static func resizable(withName name: String, andMode contentMode: ContentMode = .fill) -> some View {
    Image(name)
      .resizable()
      .aspectRatio(contentMode: contentMode)
  }
}

class ProductStore: ObservableObject {
  private init() { }
  
  public static let shared = ProductStore()
  
  @Published var products: [SKProduct] = []
}

public struct SKErrorMessage {
  public static var current = ""
  public static var general = "Unable to connect to App Store at the moment. Please try again later."
  public static var userCantPurchase = "Kindly enable payments in this account/device to continue."
  //    public static var unableToLoadProducts = "Unable to connect to "
}

class IAPmanager {
  static var productIdentifiers: Set<String> = []
  static var purchasedProductIdentifiers: Set<String> = []
  //    static var purchasedProducts: Set<SKProduct> = []
  
  static var products: Set<SKProduct> = []
  static var productsSortedByPrice: [SKProduct] { products.sorted(by: { $0.price.intValue < $1.price.intValue })}
  static var isPaidUser: Bool { !purchasedProductIdentifiers.isEmpty }
  
  static func initialize(productIdentifiers: Set<String>) {
    IAPmanager.productIdentifiers = productIdentifiers
    IAPmanager.finishTransactions()
    updateProductsInfo()
  }
  
  static func updateProductsInfo() {
    SwiftyStoreKit.retrieveProductsInfo(productIdentifiers) { result in
      IAPmanager.products = result.retrievedProducts
      ProductStore.shared.products = IAPmanager.productsSortedByPrice
      for product in result.retrievedProducts {
        let priceString = product.localizedPrice
        debugPrint("Product: \(product.localizedTitle), price: \(priceString ?? ""), " +
                   "description: \(product.localizedDescription)")
      }
      
      for productId in result.invalidProductIDs {
        debugPrint("Invalid product identifier: \(productId)")
        SKErrorMessage.current = SKErrorMessage.general
      }
      
      if let error = result.error {
        debugPrint("Error: \(error.localizedDescription)")
        SKErrorMessage.current = SKErrorMessage.general
      }
    }
  }
  
  static func finishTransactions() {
    guard SKPaymentQueue.canMakePayments() else {
      SKErrorMessage.current = SKErrorMessage.userCantPurchase
      return
    }
    
    SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
      var hasExpired = true
      for purchase in purchases {
        switch purchase.transaction.transactionState {
        case .purchased, .restored:
          if purchase.needsFinishTransaction {
            // Deliver content from server, then:
            SwiftyStoreKit.finishTransaction(purchase.transaction)
          }
          hasExpired = false
          purchasedProductIdentifiers.insert(purchase.productId)
        case .failed, .purchasing, .deferred:
          break // do nothing
          
        @unknown default:
          break
        }
      }
      
      if hasExpired,
         CDDefault.isPaidUser {
        CDDefault.isPaidUser = false
        CDDefault.hasSubscriptionEnded = true
      }
    }
  }
  
  static func restorePurchases(onCompletion handler: @escaping (Bool) -> Void) {
    SwiftyStoreKit.restorePurchases { results in
      for purchase in results.restoredPurchases {
        purchasedProductIdentifiers.insert(purchase.productId)
      }
      
      //            if !results.restoredPurchases.isEmpty {
      //                handler(true)
      //            }
      
      handler(!results.restoredPurchases.isEmpty)
      
      //            if !results.restoreFailedPurchases.isEmpty {
      //                handler(false)
      //            }
    }
  }
  
  static func buy(_ product: SKProduct, onCompletion handler: @escaping (Bool, SKError.Code?) -> Void) {
    SwiftyStoreKit.purchaseProduct(product.productIdentifier, quantity: 1, atomically: true) { result in
      switch result {
      case .success(let purchase):
        debugPrint("Purchase Success: \(purchase.productId)")
        purchasedProductIdentifiers.insert(purchase.productId)
        handler(true, nil)
      case .error(let error):
        switch error.code {
        case .unknown: print("Unknown error. Please contact support")
        case .clientInvalid: print("Not allowed to make the payment")
        case .paymentCancelled: "User cancelled payment".log()
        case .paymentInvalid: print("The purchase identifier was invalid")
        case .paymentNotAllowed: print("The device is not allowed to make the payment")
        case .storeProductNotAvailable: print("The product is not available in the current storefront")
        case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
        case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
        case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
        default: print((error as NSError).localizedDescription)
        }
        handler(false, error.code)
      case .deferred(purchase: let purchase):
        handler(true, nil)
      }
    }
  }
}

public extension SKError.Code {
  var userAlertMessage: String {
    switch self {
    case .clientInvalid:
      return "Unable to process payment from this account. Please try again later."
    case .paymentNotAllowed:
      return "Unable to process payment from this device. Please try again later."
    case .unknown, .paymentInvalid, .unauthorizedRequestData,
        .invalidOfferPrice, .invalidSignature, .invalidOfferIdentifier, .missingOfferParams:
      return "Unable to process your purchase at the moment. Please try again later."
    case .paymentCancelled:
      return "We regret that you changed your mind. You can come back anytime to upgrade. " +
      "Kindly consider leaving a feedback in the meantime."
    case .storeProductNotAvailable:
      return "We regret to inform you that this product is not availble in your region. " +
      "We are working hard to bring it here, please stay tuned."
    case .cloudServicePermissionDenied, .cloudServiceRevoked:
      return "Unable to access clould services at the moment. " +
      "Kindly check your permission settings and try again later."
    case .cloudServiceNetworkConnectionFailed:
      return "Unable to access clould services at the moment. Please try again later."
    case .privacyAcknowledgementRequired:
      return "Kindly accept the App Store's privacy policy to proceed with the purchase."
    @unknown default:
      return "Unable to process your purchase at the moment. Please try again later."
    }
  }
}

extension SKProductSubscriptionPeriod {
  var unitName: String {
    switch unit {
    case .day: return "days"
    case .week: return "weeks"
    case .month: return "months"
    case .year: return "years"
    default: return ""
    }
  }
}
