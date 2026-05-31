import CoreGraphics
import AppKit

extension CGRect {
    /// Converts from global NSScreen coordinates (bottom-left origin) to the display-local
    /// coordinate space required by ScreenCaptureKit (top-left origin, relative to that display).
    func toScreenCaptureCoordinates(in screen: NSScreen) -> CGRect {
        // screen.frame.maxY is the top edge of this screen in global NSScreen coords.
        // Subtract this rect's maxY to flip the y-axis, then offset x by the screen's left edge.
        let flippedY = screen.frame.maxY - self.maxY
        let localX   = self.origin.x - screen.frame.minX
        return CGRect(x: localX, y: flippedY, width: self.width, height: self.height)
    }
}
