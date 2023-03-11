//
//  CommonUI.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import StoreKit
import SwiftUI
import SwiftyStoreKit

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
          ProgressView()
        }
      )
    } else {
      self
    }
  }
  
  func rectangleBackground<T: View>(with color: T) -> some View {
      self
           .padding(EdgeInsets(top: .medium, leading: .small, bottom: .medium, trailing: .small))
          .background(color)
          .cornerRadius(.small)
          .padding(EdgeInsets(top: .small, leading: .medium, bottom: .small, trailing: .medium))
  }
  
  func secondaryText() -> some View {
      self
          .font(.footnote)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.leading)
  }
  
  func centerHorizontally() -> some View {
      HStack {
          Spacer()
          self
          Spacer()
      }
  }
  
  func simpleAlert(isPresented: Binding<Bool>, title: String = "Alert", message: String) -> some View {
      return self.alert(isPresented: isPresented, content: {
          Alert(title: Text(title), message: Text(message))
      })
  }
  
  func embedInScrollView(canShowIndicators showsIndicators: Bool = false,
                         canBounce bounces: Bool = false) -> some View {
      GeometryReader { geometry in
          ScrollView(showsIndicators: showsIndicators) {
              self
          }
          .frame(minHeight: geometry.size.height)
      }
  }
  
  func alternateLoader(on isLoading: Binding<Bool>) -> some View {
      Group {
          if isLoading.wrappedValue {
              ProgressView()
          } else {
              self
          }
      }
  }
  
  func makeTag(with color: Color) -> some View {
      self
      .padding(EdgeInsets(top: .small * 0.5, leading: .small, bottom: .small * 0.5, trailing: .small))
      .background(color)
      .cornerRadius(.small * 1.5)
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
      handler(!results.restoredPurchases.isEmpty)
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

public struct CardButtonStyle: ButtonStyle {
  let backgroundColor: Color
  let textColor: Color
  let height: CGFloat
  
  public init(backgroundColor: Color = .blue,
              textColor: Color = .white,
              height: CGFloat = .averageTouchSize * 1.25) {
    self.backgroundColor = backgroundColor
    self.textColor = textColor
    self.height = height
  }
  
  public func makeBody(configuration: Configuration) -> some View {
    Card(cornerRadius: .small, fillColor: bgColor(for: configuration)) {
      configuration.label.foregroundColor(self.fgColor(for: configuration))
    }
    .frame(height: height)
    .padding(.vertical, .small)
  }
  
  func fgColor(for configuration: Configuration) -> Color {
    configuration.isPressed ? textColor.opacity(0.6) : textColor
  }
  
  func bgColor(for configuration: Configuration) -> Color {
    configuration.isPressed ? backgroundColor.opacity(0.3) : backgroundColor
  }
}

public struct Card<Content>: View where Content: View {
  var alignment: Alignment = .center
  var cornerRadius: CGFloat = .medium
  var fillColor: Color = Color(UIColor.secondarySystemBackground)
  var shadowRadius: CGFloat = .zero
  var padding: CGFloat = .small
  var content: () -> Content
  
  public init(alignment: Alignment = .center,
              cornerRadius: CGFloat = .medium,
              fillColor: Color = Color(UIColor.secondarySystemBackground),
              shadowRadius: CGFloat = .zero,
              padding: CGFloat = .small,
              content: @escaping () -> Content) {
    self.alignment = alignment
    self.cornerRadius = cornerRadius
    self.fillColor = fillColor
    self.shadowRadius = shadowRadius
    self.padding = padding
    self.content = content
  }
  
  public var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: self.alignment) {
        RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
          .fill(self.fillColor)
          .shadow(radius: self.shadowRadius)
        
        self.content()
          .padding(self.padding)
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
  }
}



public extension CGFloat {
    static var small: CGFloat { 8 }
    static var medium: CGFloat { 16 }
    static var large: CGFloat { 24 }
    
    static var averageTouchSize: CGFloat { 44 }
    static var imageSize: CGFloat { 72 }
}
