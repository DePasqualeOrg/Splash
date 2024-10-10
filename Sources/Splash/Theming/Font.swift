/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

#if !os(Linux)

/// A representation of a font, for use with a `Theme`.
/// Since Splash aims to be cross-platform, it uses this
/// simplified font representation rather than `NSFont`
/// or `UIFont`.
public struct Font: Sendable {
    /// The underlying resource used to load the font
    public var resource: Resource
    public var size: Double

    /// Initialize an instance with a path to a font file
    /// on disk and a size.
    public init(path: String, size: Double) {
        resource = .path((path as NSString).expandingTildeInPath)
        self.size = size
    }

    /// Initialize an instance with a size, and use an
    /// appropriate system font to render text.
    public init(size: Double) {
        resource = .system
        self.size = size
    }
}

public extension Font {
    /// Sendable representation of a font
    struct FontRepresentation: Sendable {
        let name: String
        let size: Double

        init(name: String, size: Double) {
            self.name = name
            self.size = size
        }
    }

    /// Enum describing how to load the underlying resource for a font
    enum Resource: Sendable {
        /// Use an appropriate system font
        case system
        /// Use a pre-loaded font
        case preloaded(FontRepresentation)
        /// Load a font file from a given file system path
        case path(String)
    }
}

internal extension Font {
    func load() -> LoadedFont {
        switch resource {
            case .system:
                return loadDefaultFont()
            case .preloaded(let fontRepresentation):
                return LoadedFont(name: fontRepresentation.name, size: CGFloat(fontRepresentation.size)) ?? loadDefaultFont()
            case .path(let path):
                return load(fromPath: path) ?? loadDefaultFont()
        }
    }

    private func loadDefaultFont() -> LoadedFont {
        let font: LoadedFont?

#if os(iOS)
        font = UIFont(name: "Menlo-Regular", size: CGFloat(size))
#else
        font = load(fromPath: "/Library/Fonts/Courier New.ttf")
#endif

        return font ?? .systemFont(ofSize: CGFloat(size))
    }

    private func load(fromPath path: String) -> LoadedFont? {
        guard
            let url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path as CFString, .cfurlposixPathStyle, false),
            let provider = CGDataProvider(url: url),
            let font = CGFont(provider)
        else {
            return nil
        }

        return CTFontCreateWithGraphicsFont(font, CGFloat(size), nil, nil)
    }
}

#endif

#if os(iOS)

import UIKit

public extension Font {
    typealias LoadedFont = UIFont
}

#elseif os(macOS)

import Cocoa

public extension Font {
    typealias LoadedFont = NSFont
}

#endif
