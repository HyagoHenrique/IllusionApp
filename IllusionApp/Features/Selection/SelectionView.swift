import SwiftUI

@MainActor
struct SelectionView: View {
    let onSelection: @MainActor (CGRect) -> Void
    let onCancel: @MainActor () -> Void

    @State private var startPoint: CGPoint?
    @State private var currentPoint: CGPoint?
    @State private var isDragging = false

    private var selectionRect: CGRect? {
        guard let start = startPoint, let current = currentPoint else { return nil }
        return CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { ctx, size in
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.4)))

                    if let rect = selectionRect, rect.width > 2, rect.height > 2 {
                        ctx.blendMode = .clear
                        ctx.fill(Path(rect), with: .color(.white))
                    }
                }
                .ignoresSafeArea()

                if let rect = selectionRect, rect.width > 2, rect.height > 2 {
                    Rectangle()
                        .stroke(Color.white, lineWidth: 1.5)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)

                    Text("\(Int(rect.width)) × \(Int(rect.height))")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 4))
                        .position(x: rect.midX, y: max(rect.minY - 20, 16))
                }

                if !isDragging {
                    VStack(spacing: 8) {
                        Text("Drag to select a region to mirror")
                            .font(.system(size: 14, weight: .medium))
                        Text("Press Esc to cancel")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 4, coordinateSpace: .local)
                    .onChanged { value in
                        if startPoint == nil { startPoint = value.startLocation }
                        currentPoint = value.location
                        isDragging = true
                    }
                    .onEnded { _ in
                        if let rect = selectionRect, rect.width > 10, rect.height > 10 {
                            onSelection(rect)
                        }
                        reset()
                    }
            )
            .onKeyPress(.escape) {
                onCancel()
                return .handled
            }
            .onHover { inside in
                if inside {
                    NSCursor.crosshair.push()
                } else if NSCursor.current == NSCursor.crosshair {
                    NSCursor.pop()
                }
            }
        }
    }

    private func reset() {
        startPoint = nil
        currentPoint = nil
        isDragging = false
    }
}
