// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
// Generated using tuist — https://github.com/tuist/tuist

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// MARK: - Implementation Details

public final class UIComponentsColors: Sendable {
  public let name: String

  #if os(macOS)
  public typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  public typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
  public var color: Color {
    return Color(resource: self)
  }

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
  public var swiftUIColor: SwiftUI.Color {
      return SwiftUI.Color(self)
  }
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

public extension UIComponentsColors.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
  convenience init(resource asset: UIComponentsColors) {
    let bundle = Bundle.module
    #if os(iOS) || os(tvOS) || os(visionOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)!
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)!
    #elseif os(watchOS)
    self.init(named: asset.name)!
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
  init(_ asset: UIComponentsColors) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle)
  }
}
#endif

public struct UIComponentsImages: Sendable {
  public let name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  public typealias Image = UIImage
  #endif

  public var image: Image {
    let bundle = Bundle.module
    #if os(iOS) || os(tvOS) || os(visionOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let image = bundle.image(forResource: NSImage.Name(name))
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \\(name).")
    }
    return result
  }

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
  public var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(self)
  }
  #endif
}

public extension UIImage {
    convenience init(resource asset: UIComponentsImages) {
        let bundle = Bundle.module
        self.init(named: asset.name, in: bundle, compatibleWith: nil)!
    }
    
    convenience init?(assetName: String) {
        let bundle = Bundle.module
        self.init(named: assetName, in: bundle, compatibleWith: nil)
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Image {
  init(_ asset: UIComponentsImages) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle)
  }

  init(_ asset: UIComponentsImages, label: Text) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: UIComponentsImages) {
    let bundle = Bundle.module
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// MARK: Nested Accessors for Color Groups

extension UIComponentsColors {

        public static let accentColor = UIComponentsColors(name: "AccentColor")
          public struct Appearance {
          }
          public struct Background {
        public static let backgroundQuintuple = UIComponentsColors(name: "Background/backgroundQuintuple")
          public static let backgroundTertiary = UIComponentsColors(name: "Background/backgroundTertiary")
          public static let backgroundTertiaryInverted = UIComponentsColors(name: "Background/backgroundTertiaryInverted")
          public static let customBackground = UIComponentsColors(name: "Background/customBackground")
          public static let tipsBackground = UIComponentsColors(name: "Background/tipsBackground")
          }
          public struct Labels {
        public static let labelPrimary = UIComponentsColors(name: "Labels/labelPrimary")
          public static let labelPrimaryInvariably = UIComponentsColors(name: "Labels/labelPrimaryInvariably")
          public static let labelPrimaryInverted = UIComponentsColors(name: "Labels/labelPrimaryInverted")
          public static let labelPrimaryInvertedInvariably = UIComponentsColors(name: "Labels/labelPrimaryInvertedInvariably")
          public static let labelQuaternary = UIComponentsColors(name: "Labels/labelQuaternary")
          public static let labelQuintuple = UIComponentsColors(name: "Labels/labelQuintuple")
          public static let labelSecondary = UIComponentsColors(name: "Labels/labelSecondary")
          public static let labelSecondaryInverted = UIComponentsColors(name: "Labels/labelSecondaryInverted")
          public static let labelTertiary = UIComponentsColors(name: "Labels/labelTertiary")
          public static let labelTertiaryInverted = UIComponentsColors(name: "Labels/labelTertiaryInverted")
          }
          public struct Separator {
        public static let separatorPrimary = UIComponentsColors(name: "Separator/separatorPrimary")
          public static let separatorPrimaryInverted = UIComponentsColors(name: "Separator/separatorPrimaryInverted")
          public static let separatorSecondary = UIComponentsColors(name: "Separator/separatorSecondary")
          public static let separatorSecondaryInverted = UIComponentsColors(name: "Separator/separatorSecondaryInverted")
          }
        public static let accentRed = UIComponentsColors(name: "accentRed")
        public static let accentgrey = UIComponentsColors(name: "accentgrey")
        public static let nonOpaque = UIComponentsColors(name: "non-opaque")
}

extension UIComponentsImages {

          public struct Appearance {
        public static let colorPicker = UIComponentsImages(name: "Appearance/colorPicker")
          public static let colorful = UIComponentsImages(name: "Appearance/colorful")
          public static let colorfulDark = UIComponentsImages(name: "Appearance/colorfulDark")
          public static let dark = UIComponentsImages(name: "Appearance/dark")
          public static let light = UIComponentsImages(name: "Appearance/light")
          public static let minimal = UIComponentsImages(name: "Appearance/minimal")
          public static let minimalDark = UIComponentsImages(name: "Appearance/minimalDark")
          public static let system = UIComponentsImages(name: "Appearance/system")
          }
          public struct Background {
          }
          public struct Labels {
          }
          public struct Separator {
          }
}

// swiftlint:enable all
// swiftformat:enable all
