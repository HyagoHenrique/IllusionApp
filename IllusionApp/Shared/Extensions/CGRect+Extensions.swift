import CoreGraphics
import AppKit

extension CGRect {
    /// Converts from NSScreen coordinates (origin bottom-left) to screen physical
    /// coordinates (origin top-left), as required by ScreenCaptureKit.
    func toScreenCaptureCoordinates(in screen: NSScreen) -> CGRect {
        let screenHeight = screen.frame.height
        let flippedY = screenHeight - self.maxY
        return CGRect(x: self.origin.x, y: flippedY, width: self.width, height: self.height)
    }
}
