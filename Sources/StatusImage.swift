import AppKit

func totalStatusImage(text: String, breakdown: TimeBreakdown?) -> NSImage {
    let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    let textSize = (text as NSString).size(withAttributes: [.font: font])
    let width = max(66, ceil(textSize.width) + 12)
    let image = NSImage(size: NSSize(width: width, height: 22), flipped: false) { rect in
        (text as NSString).draw(at: NSPoint(x: (rect.width - textSize.width) / 2, y: 6),
            withAttributes: [.font: font, .foregroundColor: NSColor.labelColor])
        let bar = NSRect(x: 5, y: 2, width: rect.width - 10, height: 3)
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: bar, xRadius: 1.5, yRadius: 1.5).addClip()
        if let breakdown {
            NSColor.systemGreen.setFill()
            bar.fill()
            NSColor.systemRed.setFill()
            NSRect(x: bar.minX, y: bar.minY, width: bar.width * breakdown.usedFraction, height: bar.height).fill()
        } else {
            NSColor.tertiaryLabelColor.setFill()
            bar.fill()
        }
        NSGraphicsContext.restoreGraphicsState()
        return true
    }
    image.isTemplate = false
    return image
}
