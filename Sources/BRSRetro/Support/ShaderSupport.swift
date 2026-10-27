import SwiftUI

/// Access to the Metal shaders compiled into this package's resource bundle.
enum RetroShaders {
    static let library = ShaderLibrary.bundle(.module)
}
