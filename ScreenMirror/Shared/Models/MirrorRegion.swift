import Foundation
import CoreGraphics

struct MirrorRegion: Equatable {
    var rect: CGRect
    var displayID: CGDirectDisplayID

    // Screen coordinates (top-left origin, like NSScreen)
    static func zero(displayID: CGDirectDisplayID = CGMainDisplayID()) -> MirrorRegion {
        MirrorRegion(rect: .zero, displayID: displayID)
    }
}
