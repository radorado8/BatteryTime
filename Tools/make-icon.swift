import AppKit

// Deterministic, editable native artwork; no third-party assets.
let size = 1024
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
let tile = NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 202, yRadius: 202)
NSGradient(starting: NSColor(calibratedRed: 0.08, green: 0.21, blue: 0.31, alpha: 1), ending: NSColor(calibratedRed: 0.025, green: 0.065, blue: 0.13, alpha: 1))!.draw(in: tile, angle: -90)
let body = NSBezierPath(roundedRect: NSRect(x: 210, y: 380, width: 550, height: 300), xRadius: 66, yRadius: 66)
NSColor(calibratedWhite: 0.94, alpha: 1).setStroke()
body.lineWidth = 28
body.stroke()
NSColor(calibratedWhite: 0.94, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 783, y: 470, width: 37, height: 116), xRadius: 15, yRadius: 15).fill()
let fill = NSBezierPath(roundedRect: NSRect(x: 244, y: 414, width: 350, height: 232), xRadius: 35, yRadius: 35)
NSGradient(starting: NSColor(calibratedRed: 0.22, green: 0.94, blue: 0.73, alpha: 1), ending: NSColor(calibratedRed: 0.05, green: 0.64, blue: 0.64, alpha: 1))!.draw(in: fill, angle: -30)
// Clock overlaps the lower-right battery corner, visible even at small sizes.
let clock = NSBezierPath(ovalIn: NSRect(x: 520, y: 223, width: 302, height: 302))
NSColor(calibratedRed: 0.04, green: 0.10, blue: 0.18, alpha: 1).setFill()
clock.fill()
NSColor.white.setStroke()
clock.lineWidth = 24
clock.stroke()
let hands = NSBezierPath()
hands.move(to: NSPoint(x: 671, y: 466))
hands.line(to: NSPoint(x: 671, y: 374))
hands.line(to: NSPoint(x: 735, y: 332))
hands.lineWidth = 25
hands.lineCapStyle = .round
hands.lineJoinStyle = .round
hands.stroke()
NSGraphicsContext.restoreGraphicsState()
let destination = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Assets/AppIcon.png"
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination))
