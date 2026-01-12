#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Icon size
let size: CGFloat = 1024

// Create a bitmap context
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create context")
    exit(1)
}

// Flip coordinates (Core Graphics is bottom-left origin)
context.translateBy(x: 0, y: size)
context.scaleBy(x: 1, y: -1)

// Helper to create colors
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: a)
}

// Draw rounded rectangle clip path
let cornerRadius = size * 0.2237
let rect = CGRect(x: 0, y: 0, width: size, height: size)
let clipPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
context.addPath(clipPath)
context.clip()

// Dark background
context.setFillColor(rgb(0.08, 0.08, 0.12))
context.fill(rect)

// Subtle warm glow at bottom right (behind alarm)
let glowColors = [
    rgb(1.0, 0.5, 0.2, 0.3),
    rgb(1.0, 0.5, 0.2, 0.1),
    rgb(1.0, 0.5, 0.2, 0.0)
] as CFArray
let glowLocations: [CGFloat] = [0.0, 0.5, 1.0]
if let glowGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: glowLocations) {
    context.drawRadialGradient(
        glowGradient,
        startCenter: CGPoint(x: size * 0.62, y: size * 0.55),
        startRadius: 0,
        endCenter: CGPoint(x: size * 0.62, y: size * 0.55),
        endRadius: size * 0.4,
        options: []
    )
}

// Subtle blue glow behind bird
let blueGlowColors = [
    rgb(0.3, 0.6, 0.9, 0.2),
    rgb(0.3, 0.6, 0.9, 0.05),
    rgb(0.3, 0.6, 0.9, 0.0)
] as CFArray
if let blueGlowGradient = CGGradient(colorsSpace: colorSpace, colors: blueGlowColors, locations: glowLocations) {
    context.drawRadialGradient(
        blueGlowGradient,
        startCenter: CGPoint(x: size * 0.35, y: size * 0.4),
        startRadius: 0,
        endCenter: CGPoint(x: size * 0.35, y: size * 0.4),
        endRadius: size * 0.35,
        options: []
    )
}

// ============ ALARM CLOCK ============
let clockCenterX = size * 0.62
let clockCenterY = size * 0.55
let clockRadius = size * 0.22

// Orange color for clock
let orangeColor = rgb(1.0, 0.55, 0.1)
let darkOrangeColor = rgb(0.9, 0.4, 0.05)

// Clock body (main circle)
context.saveGState()
context.setFillColor(orangeColor)
context.fillEllipse(in: CGRect(
    x: clockCenterX - clockRadius,
    y: clockCenterY - clockRadius,
    width: clockRadius * 2,
    height: clockRadius * 2
))
context.restoreGState()

// Single bell on top right
let bellRadius = clockRadius * 0.18
let bellX = clockCenterX + clockRadius * 0.5
let bellY = clockCenterY - clockRadius * 0.75
context.setFillColor(orangeColor)
context.fillEllipse(in: CGRect(
    x: bellX - bellRadius,
    y: bellY - bellRadius,
    width: bellRadius * 2,
    height: bellRadius * 2
))

// Bell stem
context.setStrokeColor(orangeColor)
context.setLineWidth(size * 0.025)
context.setLineCap(.round)
context.move(to: CGPoint(x: clockCenterX + clockRadius * 0.25, y: clockCenterY - clockRadius * 0.85))
context.addLine(to: CGPoint(x: bellX, y: bellY))
context.strokePath()

// Hammer/striker
let hammerX = clockCenterX + clockRadius * 0.75
let hammerY = clockCenterY - clockRadius * 0.5
context.setFillColor(orangeColor)
context.fillEllipse(in: CGRect(
    x: hammerX - size * 0.02,
    y: hammerY - size * 0.02,
    width: size * 0.04,
    height: size * 0.04
))
context.setLineWidth(size * 0.015)
context.move(to: CGPoint(x: bellX, y: bellY + bellRadius * 0.5))
context.addLine(to: CGPoint(x: hammerX, y: hammerY))
context.strokePath()

// Striker lines (vibration)
context.setStrokeColor(orangeColor)
context.setLineWidth(size * 0.01)
for i in 0..<3 {
    let offsetX = CGFloat(i + 1) * size * 0.025
    let lineLength = size * 0.03
    context.move(to: CGPoint(x: hammerX + offsetX, y: hammerY - lineLength/2))
    context.addLine(to: CGPoint(x: hammerX + offsetX, y: hammerY + lineLength/2))
    context.strokePath()
}

// Clock legs
let legLength = clockRadius * 0.25
let legWidth = size * 0.03

// Left leg
context.setStrokeColor(orangeColor)
context.setLineWidth(legWidth)
context.setLineCap(.round)
context.move(to: CGPoint(x: clockCenterX - clockRadius * 0.5, y: clockCenterY + clockRadius * 0.85))
context.addLine(to: CGPoint(x: clockCenterX - clockRadius * 0.65, y: clockCenterY + clockRadius + legLength))
context.strokePath()

// Right leg
context.move(to: CGPoint(x: clockCenterX + clockRadius * 0.5, y: clockCenterY + clockRadius * 0.85))
context.addLine(to: CGPoint(x: clockCenterX + clockRadius * 0.65, y: clockCenterY + clockRadius + legLength))
context.strokePath()

// Clock face (dark inner circle)
let faceRadius = clockRadius * 0.75
context.setFillColor(rgb(0.12, 0.1, 0.08))
context.fillEllipse(in: CGRect(
    x: clockCenterX - faceRadius,
    y: clockCenterY - faceRadius,
    width: faceRadius * 2,
    height: faceRadius * 2
))

// Clock hands
context.setStrokeColor(orangeColor)
context.setLineCap(.round)

// Hour hand (pointing down-left)
context.setLineWidth(size * 0.025)
context.move(to: CGPoint(x: clockCenterX, y: clockCenterY))
context.addLine(to: CGPoint(x: clockCenterX - faceRadius * 0.35, y: clockCenterY + faceRadius * 0.35))
context.strokePath()

// Minute hand (pointing up)
context.setLineWidth(size * 0.018)
context.move(to: CGPoint(x: clockCenterX, y: clockCenterY))
context.addLine(to: CGPoint(x: clockCenterX, y: clockCenterY - faceRadius * 0.55))
context.strokePath()

// Center dot
context.setFillColor(orangeColor)
context.fillEllipse(in: CGRect(
    x: clockCenterX - size * 0.02,
    y: clockCenterY - size * 0.02,
    width: size * 0.04,
    height: size * 0.04
))

// ============ ELEGANT SONGBIRD ============
let birdColor = rgb(0.35, 0.6, 0.9)
let lightBirdColor = rgb(0.5, 0.7, 0.95)
let darkBirdColor = rgb(0.2, 0.4, 0.7)

context.saveGState()

// Bird positioning - graceful pose facing the clock
let birdCenterX = size * 0.30
let birdCenterY = size * 0.45

// Elegant curved body - teardrop shape
context.setFillColor(birdColor)
context.move(to: CGPoint(x: birdCenterX + size * 0.08, y: birdCenterY - size * 0.02))
context.addCurve(
    to: CGPoint(x: birdCenterX - size * 0.06, y: birdCenterY + size * 0.08),
    control1: CGPoint(x: birdCenterX + size * 0.06, y: birdCenterY + size * 0.06),
    control2: CGPoint(x: birdCenterX, y: birdCenterY + size * 0.1)
)
context.addCurve(
    to: CGPoint(x: birdCenterX - size * 0.04, y: birdCenterY - size * 0.06),
    control1: CGPoint(x: birdCenterX - size * 0.1, y: birdCenterY + size * 0.04),
    control2: CGPoint(x: birdCenterX - size * 0.08, y: birdCenterY - size * 0.04)
)
context.addCurve(
    to: CGPoint(x: birdCenterX + size * 0.08, y: birdCenterY - size * 0.02),
    control1: CGPoint(x: birdCenterX, y: birdCenterY - size * 0.08),
    control2: CGPoint(x: birdCenterX + size * 0.06, y: birdCenterY - size * 0.06)
)
context.fillPath()

// Lighter breast/belly highlight
context.setFillColor(lightBirdColor)
context.move(to: CGPoint(x: birdCenterX + size * 0.06, y: birdCenterY))
context.addCurve(
    to: CGPoint(x: birdCenterX - size * 0.02, y: birdCenterY + size * 0.06),
    control1: CGPoint(x: birdCenterX + size * 0.04, y: birdCenterY + size * 0.04),
    control2: CGPoint(x: birdCenterX + size * 0.01, y: birdCenterY + size * 0.06)
)
context.addCurve(
    to: CGPoint(x: birdCenterX + size * 0.06, y: birdCenterY),
    control1: CGPoint(x: birdCenterX - size * 0.01, y: birdCenterY + size * 0.02),
    control2: CGPoint(x: birdCenterX + size * 0.03, y: birdCenterY)
)
context.fillPath()

// Graceful head with curved neck
let headX = birdCenterX + size * 0.1
let headY = birdCenterY - size * 0.08
let headRadius = size * 0.055

context.setFillColor(birdColor)
context.fillEllipse(in: CGRect(
    x: headX - headRadius,
    y: headY - headRadius,
    width: headRadius * 2,
    height: headRadius * 2
))

// Curved neck connecting head to body
context.setFillColor(birdColor)
context.move(to: CGPoint(x: birdCenterX + size * 0.04, y: birdCenterY - size * 0.05))
context.addCurve(
    to: CGPoint(x: headX - headRadius * 0.5, y: headY + headRadius * 0.3),
    control1: CGPoint(x: birdCenterX + size * 0.06, y: birdCenterY - size * 0.06),
    control2: CGPoint(x: birdCenterX + size * 0.07, y: birdCenterY - size * 0.06)
)
context.addLine(to: CGPoint(x: headX - headRadius * 0.3, y: headY + headRadius * 0.6))
context.addCurve(
    to: CGPoint(x: birdCenterX + size * 0.06, y: birdCenterY - size * 0.02),
    control1: CGPoint(x: birdCenterX + size * 0.08, y: birdCenterY - size * 0.03),
    control2: CGPoint(x: birdCenterX + size * 0.07, y: birdCenterY - size * 0.02)
)
context.fillPath()

// Small elegant beak - short and delicate
let beakStartX = headX + headRadius * 0.7
let beakStartY = headY + headRadius * 0.1
context.setFillColor(rgb(1.0, 0.7, 0.3)) // Golden/orange beak
context.move(to: CGPoint(x: beakStartX, y: beakStartY - size * 0.008))
context.addLine(to: CGPoint(x: beakStartX + size * 0.04, y: beakStartY + size * 0.002))
context.addLine(to: CGPoint(x: beakStartX, y: beakStartY + size * 0.012))
context.closePath()
context.fillPath()

// Elegant eye
context.setFillColor(rgb(0.1, 0.1, 0.1))
let eyeSize = size * 0.016
context.fillEllipse(in: CGRect(
    x: headX + headRadius * 0.2 - eyeSize/2,
    y: headY - headRadius * 0.1 - eyeSize/2,
    width: eyeSize,
    height: eyeSize
))
// Eye highlight
context.setFillColor(rgb(1.0, 1.0, 1.0))
context.fillEllipse(in: CGRect(
    x: headX + headRadius * 0.25 - eyeSize * 0.2,
    y: headY - headRadius * 0.2 - eyeSize * 0.2,
    width: eyeSize * 0.4,
    height: eyeSize * 0.4
))

// Large flowing wing - sweeping gracefully upward and back
let wingBaseX = birdCenterX - size * 0.01
let wingBaseY = birdCenterY - size * 0.02

// Main wing shape - large and flowing
context.setFillColor(birdColor)
context.move(to: CGPoint(x: wingBaseX, y: wingBaseY))
// Sweep up and back in a graceful arc
context.addCurve(
    to: CGPoint(x: wingBaseX - size * 0.28, y: wingBaseY - size * 0.18),
    control1: CGPoint(x: wingBaseX - size * 0.08, y: wingBaseY - size * 0.12),
    control2: CGPoint(x: wingBaseX - size * 0.18, y: wingBaseY - size * 0.2)
)
// Wing tip curves
context.addCurve(
    to: CGPoint(x: wingBaseX - size * 0.32, y: wingBaseY - size * 0.08),
    control1: CGPoint(x: wingBaseX - size * 0.32, y: wingBaseY - size * 0.16),
    control2: CGPoint(x: wingBaseX - size * 0.34, y: wingBaseY - size * 0.12)
)
// Lower edge flows back to body
context.addCurve(
    to: CGPoint(x: wingBaseX - size * 0.08, y: wingBaseY + size * 0.06),
    control1: CGPoint(x: wingBaseX - size * 0.28, y: wingBaseY - size * 0.02),
    control2: CGPoint(x: wingBaseX - size * 0.18, y: wingBaseY + size * 0.04)
)
context.addCurve(
    to: CGPoint(x: wingBaseX, y: wingBaseY),
    control1: CGPoint(x: wingBaseX - size * 0.04, y: wingBaseY + size * 0.04),
    control2: CGPoint(x: wingBaseX - size * 0.01, y: wingBaseY + size * 0.02)
)
context.fillPath()

// Darker inner wing layer for depth
context.setFillColor(darkBirdColor)
context.move(to: CGPoint(x: wingBaseX - size * 0.02, y: wingBaseY + size * 0.01))
context.addCurve(
    to: CGPoint(x: wingBaseX - size * 0.22, y: wingBaseY - size * 0.1),
    control1: CGPoint(x: wingBaseX - size * 0.06, y: wingBaseY - size * 0.06),
    control2: CGPoint(x: wingBaseX - size * 0.14, y: wingBaseY - size * 0.12)
)
context.addCurve(
    to: CGPoint(x: wingBaseX - size * 0.06, y: wingBaseY + size * 0.05),
    control1: CGPoint(x: wingBaseX - size * 0.18, y: wingBaseY - size * 0.04),
    control2: CGPoint(x: wingBaseX - size * 0.12, y: wingBaseY + size * 0.02)
)
context.closePath()
context.fillPath()

// Flowing feather details on wing
context.setStrokeColor(lightBirdColor)
context.setLineWidth(size * 0.008)
context.setLineCap(.round)

// Primary flight feathers - long flowing curves
for i in 0..<5 {
    let offset = CGFloat(i) * size * 0.04
    let startX = wingBaseX - size * 0.06 - offset * 0.3
    let startY = wingBaseY - size * 0.02 - offset * 0.2

    context.move(to: CGPoint(x: startX, y: startY))
    context.addCurve(
        to: CGPoint(x: startX - size * 0.12, y: startY - size * 0.06 + offset * 0.15),
        control1: CGPoint(x: startX - size * 0.04, y: startY - size * 0.04),
        control2: CGPoint(x: startX - size * 0.08, y: startY - size * 0.06)
    )
    context.strokePath()
}

// Secondary feathers - shorter, more curved
context.setStrokeColor(rgb(0.4, 0.65, 0.92))
context.setLineWidth(size * 0.006)
for i in 0..<4 {
    let offset = CGFloat(i) * size * 0.025
    context.move(to: CGPoint(x: wingBaseX - size * 0.04 - offset, y: wingBaseY + size * 0.02 + offset * 0.3))
    context.addQuadCurve(
        to: CGPoint(x: wingBaseX - size * 0.14 - offset * 0.5, y: wingBaseY - size * 0.01 + offset * 0.2),
        control: CGPoint(x: wingBaseX - size * 0.1 - offset * 0.3, y: wingBaseY - size * 0.02 + offset * 0.2)
    )
    context.strokePath()
}

// Elegant flowing tail feathers
context.setFillColor(birdColor)
let tailX = birdCenterX - size * 0.08
let tailY = birdCenterY + size * 0.06

// Main tail feather (longest, flowing curve)
context.move(to: CGPoint(x: tailX, y: tailY))
context.addCurve(
    to: CGPoint(x: tailX - size * 0.14, y: tailY + size * 0.16),
    control1: CGPoint(x: tailX - size * 0.04, y: tailY + size * 0.08),
    control2: CGPoint(x: tailX - size * 0.1, y: tailY + size * 0.14)
)
context.addCurve(
    to: CGPoint(x: tailX - size * 0.02, y: tailY + size * 0.04),
    control1: CGPoint(x: tailX - size * 0.1, y: tailY + size * 0.12),
    control2: CGPoint(x: tailX - size * 0.04, y: tailY + size * 0.06)
)
context.closePath()
context.fillPath()

// Second tail feather
context.move(to: CGPoint(x: tailX + size * 0.01, y: tailY - size * 0.01))
context.addCurve(
    to: CGPoint(x: tailX - size * 0.1, y: tailY + size * 0.12),
    control1: CGPoint(x: tailX - size * 0.02, y: tailY + size * 0.05),
    control2: CGPoint(x: tailX - size * 0.06, y: tailY + size * 0.1)
)
context.addCurve(
    to: CGPoint(x: tailX + size * 0.01, y: tailY + size * 0.02),
    control1: CGPoint(x: tailX - size * 0.06, y: tailY + size * 0.08),
    control2: CGPoint(x: tailX - size * 0.02, y: tailY + size * 0.04)
)
context.closePath()
context.fillPath()

// Small crest/tuft on head for elegance
context.setFillColor(birdColor)
context.move(to: CGPoint(x: headX - headRadius * 0.3, y: headY - headRadius * 0.8))
context.addCurve(
    to: CGPoint(x: headX - headRadius * 0.6, y: headY - headRadius * 1.3),
    control1: CGPoint(x: headX - headRadius * 0.3, y: headY - headRadius * 1.1),
    control2: CGPoint(x: headX - headRadius * 0.4, y: headY - headRadius * 1.3)
)
context.addCurve(
    to: CGPoint(x: headX - headRadius * 0.5, y: headY - headRadius * 0.6),
    control1: CGPoint(x: headX - headRadius * 0.6, y: headY - headRadius * 1.0),
    control2: CGPoint(x: headX - headRadius * 0.5, y: headY - headRadius * 0.8)
)
context.closePath()
context.fillPath()

context.restoreGState()

// Create image from context
guard let cgImage = context.makeImage() else {
    print("Failed to create image")
    exit(1)
}

// Save to file (in current directory)
let outputPath = FileManager.default.currentDirectoryPath + "/AppIcon.png"
let url = URL(fileURLWithPath: outputPath)

guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    print("Failed to create image destination")
    exit(1)
}

CGImageDestinationAddImage(destination, cgImage, nil)

if CGImageDestinationFinalize(destination) {
    print("✓ Icon saved to: \(outputPath)")
} else {
    print("Failed to save image")
    exit(1)
}
