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



// MARK: - Colors
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var accentColor: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "AccentColor", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("AccentColor"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "AccentColor")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var accentColor: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("AccentColor", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var accentColor: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("AccentColor", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var accentRed: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "accentRed", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("accentRed"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "accentRed")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var accentRed: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("accentRed", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var accentRed: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("accentRed", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var accentgrey: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "accentgrey", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("accentgrey"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "accentgrey")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var accentgrey: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("accentgrey", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var accentgrey: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("accentgrey", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var backgroundQuintuple: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "backgroundQuintuple", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("backgroundQuintuple"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "backgroundQuintuple")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var backgroundQuintuple: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("backgroundQuintuple", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var backgroundQuintuple: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("backgroundQuintuple", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var backgroundTertiary: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "backgroundTertiary", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("backgroundTertiary"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "backgroundTertiary")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var backgroundTertiary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("backgroundTertiary", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var backgroundTertiary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("backgroundTertiary", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var backgroundTertiaryInverted: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "backgroundTertiaryInverted", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("backgroundTertiaryInverted"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "backgroundTertiaryInverted")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var backgroundTertiaryInverted: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("backgroundTertiaryInverted", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var backgroundTertiaryInverted: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("backgroundTertiaryInverted", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var customBackground: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "customBackground", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("customBackground"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "customBackground")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var customBackground: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("customBackground", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var customBackground: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("customBackground", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var tipsBackground: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "tipsBackground", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("tipsBackground"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "tipsBackground")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var tipsBackground: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("tipsBackground", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var tipsBackground: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("tipsBackground", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var labelPrimary: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "labelPrimary", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("labelPrimary"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "labelPrimary")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var labelPrimary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelPrimary", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var labelPrimary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelPrimary", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var labelPrimaryInvariably: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "labelPrimaryInvariably", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("labelPrimaryInvariably"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "labelPrimaryInvariably")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var labelPrimaryInvariably: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelPrimaryInvariably", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var labelPrimaryInvariably: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelPrimaryInvariably", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var labelPrimaryInverted: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "labelPrimaryInverted", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("labelPrimaryInverted"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "labelPrimaryInverted")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var labelPrimaryInverted: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelPrimaryInverted", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var labelPrimaryInverted: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelPrimaryInverted", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var labelPrimaryInvertedInvariably: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "labelPrimaryInvertedInvariably", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("labelPrimaryInvertedInvariably"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "labelPrimaryInvertedInvariably")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var labelPrimaryInvertedInvariably: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelPrimaryInvertedInvariably", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var labelPrimaryInvertedInvariably: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelPrimaryInvertedInvariably", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var labelQuaternary: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "labelQuaternary", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("labelQuaternary"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "labelQuaternary")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var labelQuaternary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelQuaternary", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var labelQuaternary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelQuaternary", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var labelQuintuple: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "labelQuintuple", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("labelQuintuple"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "labelQuintuple")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var labelQuintuple: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelQuintuple", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var labelQuintuple: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelQuintuple", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var labelSecondary: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "labelSecondary", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("labelSecondary"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "labelSecondary")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var labelSecondary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelSecondary", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var labelSecondary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelSecondary", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var labelSecondaryInverted: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "labelSecondaryInverted", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("labelSecondaryInverted"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "labelSecondaryInverted")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var labelSecondaryInverted: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelSecondaryInverted", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var labelSecondaryInverted: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelSecondaryInverted", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var labelTertiary: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "labelTertiary", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("labelTertiary"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "labelTertiary")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var labelTertiary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelTertiary", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var labelTertiary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelTertiary", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var labelTertiaryInverted: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "labelTertiaryInverted", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("labelTertiaryInverted"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "labelTertiaryInverted")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var labelTertiaryInverted: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelTertiaryInverted", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var labelTertiaryInverted: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("labelTertiaryInverted", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var nonOpaque: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "non-opaque", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("non-opaque"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "non-opaque")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var nonOpaque: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("non-opaque", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var nonOpaque: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("non-opaque", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var separatorPrimary: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "separatorPrimary", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("separatorPrimary"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "separatorPrimary")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var separatorPrimary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("separatorPrimary", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var separatorPrimary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("separatorPrimary", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var separatorPrimaryInverted: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "separatorPrimaryInverted", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("separatorPrimaryInverted"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "separatorPrimaryInverted")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var separatorPrimaryInverted: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("separatorPrimaryInverted", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var separatorPrimaryInverted: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("separatorPrimaryInverted", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var separatorSecondary: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "separatorSecondary", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("separatorSecondary"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "separatorSecondary")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var separatorSecondary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("separatorSecondary", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var separatorSecondary: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("separatorSecondary", bundle: bundle)
    }
}
#endif
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
public extension UIComponentsColors.Color {
    static var separatorSecondaryInverted: UIComponentsColors.Color {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsColors.Color(named: "separatorSecondaryInverted", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return UIComponentsColors.Color(named: NSColor.Name("separatorSecondaryInverted"), bundle: bundle)!
        #elseif os(watchOS)
        return UIComponentsColors.Color(named: "separatorSecondaryInverted")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
    static var separatorSecondaryInverted: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("separatorSecondaryInverted", bundle: bundle)
    }
}

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {
    static var separatorSecondaryInverted: SwiftUI.Color {
        let bundle = Bundle.module
        return SwiftUI.Color("separatorSecondaryInverted", bundle: bundle)
    }
}
#endif

// MARK: - Images
public extension UIComponentsImages.Image {
    static var colorful: UIComponentsImages.Image {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsImages.Image(named: "Appearance/colorful", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return bundle.image(forResource: NSImage.Name("Appearance/colorful"))!
        #elseif os(watchOS)
        return UIComponentsImages.Image(named: "Appearance/colorful")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Image {
    static var colorful: SwiftUI.Image {
        let bundle = Bundle.module
        return SwiftUI.Image("Appearance/colorful", bundle: bundle)
    }
}
#endif
public extension UIComponentsImages.Image {
    static var dark: UIComponentsImages.Image {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsImages.Image(named: "Appearance/dark", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return bundle.image(forResource: NSImage.Name("Appearance/dark"))!
        #elseif os(watchOS)
        return UIComponentsImages.Image(named: "Appearance/dark")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Image {
    static var dark: SwiftUI.Image {
        let bundle = Bundle.module
        return SwiftUI.Image("Appearance/dark", bundle: bundle)
    }
}
#endif
public extension UIComponentsImages.Image {
    static var light: UIComponentsImages.Image {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsImages.Image(named: "Appearance/light", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return bundle.image(forResource: NSImage.Name("Appearance/light"))!
        #elseif os(watchOS)
        return UIComponentsImages.Image(named: "Appearance/light")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Image {
    static var light: SwiftUI.Image {
        let bundle = Bundle.module
        return SwiftUI.Image("Appearance/light", bundle: bundle)
    }
}
#endif
public extension UIComponentsImages.Image {
    static var minimal: UIComponentsImages.Image {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsImages.Image(named: "Appearance/minimal", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return bundle.image(forResource: NSImage.Name("Appearance/minimal"))!
        #elseif os(watchOS)
        return UIComponentsImages.Image(named: "Appearance/minimal")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Image {
    static var minimal: SwiftUI.Image {
        let bundle = Bundle.module
        return SwiftUI.Image("Appearance/minimal", bundle: bundle)
    }
}
#endif
public extension UIComponentsImages.Image {
    static var system: UIComponentsImages.Image {
        let bundle = Bundle.module
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIComponentsImages.Image(named: "Appearance/system", in: bundle, compatibleWith: nil)!
        #elseif os(macOS)
        return bundle.image(forResource: NSImage.Name("Appearance/system"))!
        #elseif os(watchOS)
        return UIComponentsImages.Image(named: "Appearance/system")!
        #endif
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Image {
    static var system: SwiftUI.Image {
        let bundle = Bundle.module
        return SwiftUI.Image("Appearance/system", bundle: bundle)
    }
}
#endif


// swiftlint:enable all
// swiftformat:enable all
