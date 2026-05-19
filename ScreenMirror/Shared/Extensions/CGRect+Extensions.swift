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

    /// Returns the rect scaled by the screen's backing scale factor.
    func toPhysicalPixels(backingScaleFactor: CGFloat) -> CGRect {
        return CGRect(
            x: self.origin.x * backingScaleFactor,
            y: self.origin.y * backingScaleFactor,
            width: self.width * backingScaleFactor,
            height: self.height * backingScaleFactor
        )
    }

    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
