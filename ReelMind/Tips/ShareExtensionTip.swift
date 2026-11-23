import Foundation
import SwiftUI
import TipKit

public struct ShareExtensionTip: Tip {
    public var title: Text {
        Text("Save Reels from Any App")
    }

    public var message: Text? {
        Text("Tap Share in Instagram, TikTok, YouTube, or X and select ReelMind to automatically extract AI tools, prompts, and steps.")
    }

    public var image: Image? {
        Image(systemName: "square.and.arrow.up.circle.fill")
    }
}
