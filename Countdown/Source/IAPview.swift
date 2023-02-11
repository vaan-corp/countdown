//
//  IAPview.swift
//  Countdown
//
//  Created by Asif on 11/02/23.
//

import SwiftUI
//import CountdownKit
import SwiftyUserInterface
import StoreKit

struct IAPview: View {
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var preferences = Preferences.shared
  @ObservedObject var productStore = ProductStore.shared
  
  @State var isPurchaseCompleted = false
  @State var isLoading = false
  @State var showAlert = false
  @State var alertMessage = ""
  @State var alertTitle = ""
  @State var isRestored = false
  @State var showTermsOfUse = false
  
  var body: some View {
    VStack(spacing: .zero) {
      if isPurchaseCompleted {
        PurchaseCompletedView(isRestored: $isRestored)
      } else {
        skipButton
        icon
        title
        if productStore.products.isEmpty {
          staticPurchaseButtons
        } else {
          dynamicPurchaseButtons
          
        }
        PremiumFeaturesView()
          .padding([.top, .bottom], .small)
          .simpleAlert(isPresented: $showAlert, title: alertTitle, message: alertMessage)
        
        termsButton
          .padding(.bottom, .averageTouchSize)
      }
    }
    .embedInScrollView()
    .background(Color(.systemGroupedBackground))
    .overlayLoader(on: $isLoading)
  }
  
  var termsButton: some View {
    Button(action: {
      self.showTermsOfUse = true
    }, label: {
      Text("Terms of Use")
        .underline()
        .foregroundColor(.secondary)
        .sheet(isPresented: $showTermsOfUse, content: { TermsView() })
    })
  }
  
  var skipButton: some View {
    HStack {
      Button("Skip") {
        self.presentationMode.wrappedValue.dismiss()
      }
      .padding([.top, .leading], .medium)
      Spacer()
      Button("Restore") {
        self.isLoading = true
        IAPmanager.restorePurchases { isSuccess in
          self.isLoading = false
          if isSuccess {
            CDDefault.isPaidUser = true
            self.isRestored = true
            self.isPurchaseCompleted = true
          } else {
            self.alertTitle = "Restore failed"
            self.alertMessage = "Unable to process your request at the moment. Please try again later."
            self.showAlert = true
          }
        }
      }
      .padding([.top, .trailing], .medium)
    }
    .secondaryText()
  }
  
  var icon: some View {
    Image("calIcon")
      .resizable()
      .scaledToFit()
      .frame(width: 150)
      .padding([.bottom])
  }
  
  var title: some View {
    HStack(spacing: .small) {
      Text("Countdown")
        .font(.largeTitle)
      Text("Pro")
        .font(Font.largeTitle.smallCaps().monospacedDigit())
        .foregroundColor(Color(.systemBackground))
        .padding(EdgeInsets(top: .zero, leading: .small*1.25, bottom: .small*0.5, trailing: .small))
        .background(Capsule().fill(Color.primary))
    }
    .padding(.bottom, .large * 1.25)
  }
  
  func unitName(unitRawValue:UInt) -> String {
    switch unitRawValue {
    case 0: return "days"
    case 1: return "weeks"
    case 2: return "months"
    case 3: return "years"
    default: return ""
    }
  }
  
  @ViewBuilder var dynamicPurchaseButtons: some View {
    ForEach(productStore.products, id: \.productIdentifier) { product in
      Button(action: {
        self.isLoading = true
        IAPmanager.buy(product) { (isSuccess, errorCode) in
          self.isLoading = false
          if isSuccess {
            CDDefault.isPaidUser = true
            self.isPurchaseCompleted = true
          } else if let code = errorCode {
            self.alertTitle = "Purchase not completed"
            self.alertMessage = code.userAlertMessage
            self.showAlert = true
          }
          
        }
      }, label: {
        HStack {
          Text("\(product.localizedPrice ?? "\(product.price)")")
            .font(.headline)
          Spacer()
          Text(self.descriptionText(for: product))
            .font(.footnote)
        }
        .padding(.small)
      })
      .padding(.horizontal)
      .buttonStyle(CardButtonStyle())
    }
  }
  
  func descriptionText(for product: SKProduct) -> String {
    if !product.localizedDescription.isEmpty {
      return product.localizedDescription
    }
    
    "description not available from app store for \(product.productIdentifier)".log()
    
    switch product.productIdentifier {
    case "imthath_countdown_lifetime": return "one time purchase"
    case "imthath_countdown_oneyear": return "yearly (first 2 weeks free)"
    default: return "tap for details"
      
    }
  }
  var staticPurchaseButtons: some View {
//    IAPmanager.updateProductsInfo()
    "ideally this should never be reached, because we have checked the same in settings page".log()
    
    return VStack {
      Text("Unable to connect to app store at the moment. Please check your internet connection and try again later.").multilineTextAlignment(.center)
        .padding()
      DismissButton(title: "Dismiss", presentationMode: presentationMode)
    }
    .rectangleBackground(with: Color(.secondarySystemGroupedBackground))
  }
}

public struct PurchaseCompletedView: View {
  
  @Binding var isRestored: Bool
  @Environment(\.presentationMode) var presentationMode
  
  public var body: some View {
    VStack(spacing: .averageTouchSize) {
      Image(systemName: "gift.fill")
        .font(.system(size: 72))
        .padding(.top)
      //                .padding(.averageTouchSize)
      //                .foregroundColor(.yellow)
      
      //            Spacer()
      Text("Thank you for \(isRestored ? "continuing with us" : "purchasing")!")
        .font(.largeTitle)
      //                .rectangleBackground(with: Color(.secondarySystemBackground))
      textGroup
      Button("Continue") {
        Preferences.shared.isPaidUser = true
        self.presentationMode.wrappedValue.dismiss()
      }.buttonStyle(CardButtonStyle())
    }
    .padding()
    .multilineTextAlignment(.center)
  }
  
  var textGroup: some View {
    VStack(spacing: .large) {
      //            Spacer()
      Text("We are committed to providing best app experience for the long haul.")
      //            Spacer()
      Text("If you face any issue or would like a new feature, kindly contact us at imthath.m@icloud.com.")
      //            Spacer()
      Text("We value your feedback and we are committed to respond within 3 days.")
      //            Spacer()
    }
  }
}

public struct PremiumFeaturesView: View {
  public var body: some View {
    VStack(alignment: .leading, spacing: .large) {
      
      Text("The upgrade adds the ability to")
        .foregroundColor(.secondary)
        .font(Font.body.monospacedDigit())
        .fontWeight(.bold)
      //                    .secondaryText()
      
      HStack(spacing: .small) {
        ScaledImage(systemName: "rectangle.fill.on.rectangle.angled.fill", scale: .medium).foregroundColor(Color.yellow)//.opacity(0.8))
        Text("Add widgets in today view")
        Spacer()
      }
      
      HStack(spacing: .small) {
        ScaledImage(systemName: "heart.fill").foregroundColor(.red)
        Text("Add favorite events")
        Spacer()
      }
      
      HStack(spacing: .small) {
        ScaledImage(systemName: "arrow.clockwise.icloud.fill").foregroundColor(.blue)
        Text("iCloud sync across your devices")
        Spacer()
      }
      
      HStack(spacing: .small) {
        ScaledImage(systemName: "calendar.badge.plus").foregroundColor(Color.purple.opacity(0.9))
        Text("Access all Calendars and Events")
          .multilineTextAlignment(.leading)
          .layoutPriority(1)
        //                Spacer()
      }
      
      HStack(spacing: .small) {
        ScaledImage(systemName: "sparkles").foregroundColor(Color.green.opacity(0.9))
        Text("Support for all upcoming features")
        Spacer()
      }
      
      //            HStack(spacing: .small) {
      //                XCodeImage()
      //                    .frame(minWidth: .averageTouchSize)
      //                    .foregroundColor(Color.blue)
      //                Text("Support indie app devleopment")
      //                Spacer()
      //            }
    }
    .rectangleBackground(with: Color(.secondarySystemGroupedBackground))
  }
}

struct XCodeImage: View {
  let fontSize: CGFloat = 20
  var x: CGFloat { fontSize / 14 }
  var body: some View {
    ZStack {
      Image(systemName: "wrench")
        .rotationEffect(.init(degrees: 270))
        .offset(x: -4*x, y: x)
        .font(.system(size: 12*x))
      Image(systemName: "hammer.fill")
      
        .font(.system(size: 14*x))
      //                .rotationEffect(.init(degrees: 15))
    }
  }
}

public struct PurchaseCard: View {
  
  @Environment(\.colorScheme) var colorScheme
  
  public var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: .small) {
        Text("Unlock all features").font(Font.body.smallCaps())
        Text("Upgrade to PRO").font(.title)
      }
      .foregroundColor(textColor)
      Spacer()
      image
    }
    .padding(.leading, .small)
    .padding(.vertical)
    .rectangleBackground(with: Color.blue)
    //        .rectangleBackground(with: LinearGradient(gradient: Gradient.init(colors: [systemBlue.opacity(0.5), systemBlue]), startPoint: .leading, endPoint: .trailing))
  }
  
  var image: some View {
    
    Image(systemName: "wand.and.stars")
    //                    Image(systemName: "cart.fill.badge.plus")
      .font(.system(size: .averageTouchSize * 1.25) )
      .rotationEffect(.init(degrees: 90))
      .padding(.trailing)
      .foregroundColor(wandColor)
  }
  
  var textColor: Color {
    colorScheme == .light ? .black : .white
  }
  
  var wandColor: Color {
    .white
  }
  
  //    var gradient: [Color] {
  //        if colorScheme == .dark {
  //            return [Color.blue.opacity(0.5), Color.blue.opacity(0.2)]
  //        }
  //
  //        return [Color.blue.opacity(0.5), .blue]
  //    }
  
  var systemBlue: Color { Color(#colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1))}
}

public struct TermsView: View {
  @Environment(\.presentationMode) var presentationMode
  @State var showMail = false
  
  public var body: some View {
    NavigationView {
      textStack
        .navigationBarTitle("Terms of Use", displayMode: .inline)
    }
  }
  
  var textStack: some View {
    VStack(alignment: .leading, spacing: .medium) {
      Text("Free version").font(.title)
      Text("Countdown app provides a free version in which you can view the list of events in your calendar and their countdown. ")
        .padding(.bottom, .medium)
      Text("Pro upgrade").font(.title)
      Text("Countdown PRO provides support for favorites, widgets and many exciting features. You can upgrade by opting for yearly subscription or one time purchase from within the app.")
        .padding(.bottom, .averageTouchSize)
      Spacer()
      
      Button("Contact us") {
        self.showMail = true
      }.buttonStyle(CardButtonStyle())
      
      Button("Close") {
        self.presentationMode.wrappedValue.dismiss()
      }
      .foregroundColor(.secondary)
      .padding(.top)
      .centerHorizontally()
    }
    .sheet(isPresented: $showMail, content: { ComposeMail() })
    .padding()
    .embedInScrollView()
  }
}

struct IAPview_Previews: PreviewProvider {
  static var previews: some View {
    //        Group {
    //            PurchaseCard()
    //            PurchaseCard().preferredColorScheme(.dark)
    //        }
    //        .previewLayout(.sizeThatFits)
    //        Group {
    //            PurchaseCompletedView(isRestored: .constant(false)).preferredColorScheme(.dark)
    //            PurchaseCompletedView(isRestored: .constant(true)).preferredColorScheme(.light)
    //        }
    //        .previewLayout(.sizeThatFits)
    TermsView()
  }
}

