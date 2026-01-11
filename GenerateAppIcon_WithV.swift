#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MARK: - App Icon Generator for Vitaly (With "V" Variant)

/// Alternative version with minimalist "V" symbol in center

let iconSize: CGFloat = 1024.0
let outputPath = "/Users/tonsaj/Workspace/iOSHealth/iOSHealth/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon_V.png"

// Vitaly Brand Colors
let primaryColor = CGColor(red: 0.95, green: 0.45, blue: 0.25, alpha: 1.0)
let secondaryColor = CGColor(red: 0.98, green: 0.6, blue: 0.45, alpha: 1.0)
let tertiaryColor = CGColor(red: 1.0, green: 0.78, blue: 0.65, alpha: 1.0)
let backgroundDark = CGColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0)

func createAppIconWithV() {
    let size = CGSize(width: iconSize, height: iconSize)
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    guard let context = CGContext(
        data: nil,
        width: Int(iconSize),
        height: Int(iconSize),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        print("Failed to create graphics context")
        return
    }

    let center = CGPoint(x: iconSize / 2, y: iconSize / 2)

    // Background
    context.setFillColor(backgroundDark)
    context.fill(CGRect(origin: .zero, size: size))

    let gradientColors = [
        CGColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1.0),
        backgroundDark
    ] as CFArray

    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0]) {
        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: iconSize * 0.7,
            options: []
        )
    }

    // Sunburst
    let numberOfRays = 24
    let innerRadius = iconSize * 0.15
    let outerRadius = iconSize * 0.48
    let shortRayRadius = iconSize * 0.38

    for i in 0..<numberOfRays {
        let angle = CGFloat(i) * (2 * .pi / CGFloat(numberOfRays))
        let isLongRay = i % 2 == 0
        let rayLength = isLongRay ? outerRadius : shortRayRadius
        let rayWidth = isLongRay ? iconSize * 0.045 : iconSize * 0.035
        let angleOffset = rayWidth / (innerRadius * 2)

        let leftAngle = angle - angleOffset
        let rightAngle = angle + angleOffset

        let innerLeft = CGPoint(
            x: center.x + innerRadius * cos(leftAngle),
            y: center.y + innerRadius * sin(leftAngle)
        )
        let innerRight = CGPoint(
            x: center.x + innerRadius * cos(rightAngle),
            y: center.y + innerRadius * sin(rightAngle)
        )
        let outerLeft = CGPoint(
            x: center.x + rayLength * cos(leftAngle),
            y: center.y + rayLength * sin(leftAngle)
        )
        let outerRight = CGPoint(
            x: center.x + rayLength * cos(rightAngle),
            y: center.y + rayLength * sin(rightAngle)
        )

        let progress = CGFloat(i) / CGFloat(numberOfRays)
        let rayColor: CGColor
        if progress < 0.33 {
            rayColor = primaryColor
        } else if progress < 0.66 {
            rayColor = secondaryColor
        } else {
            rayColor = tertiaryColor
        }

        context.setFillColor(rayColor)
        context.beginPath()
        context.move(to: innerLeft)
        context.addLine(to: outerLeft)
        context.addLine(to: outerRight)
        context.addLine(to: innerRight)
        context.closePath()
        context.fillPath()
    }

    // Center Circle
    let centerRadius = innerRadius * 0.95
    let circleGradientColors = [primaryColor, secondaryColor, tertiaryColor] as CFArray

    if let circleGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: circleGradientColors,
        locations: [0.0, 0.5, 1.0]
    ) {
        context.saveGState()
        context.addEllipse(in: CGRect(
            x: center.x - centerRadius,
            y: center.y - centerRadius,
            width: centerRadius * 2,
            height: centerRadius * 2
        ))
        context.clip()

        context.drawLinearGradient(
            circleGradient,
            start: CGPoint(x: center.x - centerRadius, y: center.y - centerRadius),
            end: CGPoint(x: center.x + centerRadius, y: center.y + centerRadius),
            options: []
        )
        context.restoreGState()
    }

    // Inner glow
    context.setFillColor(CGColor(red: 1.0, green: 0.9, blue: 0.8, alpha: 0.3))
    let glowRadius = centerRadius * 0.6
    context.fillEllipse(in: CGRect(
        x: center.x - glowRadius,
        y: center.y - glowRadius,
        width: glowRadius * 2,
        height: glowRadius * 2
    ))

    // Minimalist "V" Symbol
    context.setStrokeColor(backgroundDark)
    context.setLineWidth(iconSize * 0.024)
    context.setLineCap(.round)
    context.setLineJoin(.round)

    let vHeight = centerRadius * 0.75
    let vWidth = centerRadius * 0.65
    let vTop = center.y - vHeight * 0.25
    let vBottom = center.y + vHeight * 0.5

    context.beginPath()
    context.move(to: CGPoint(x: center.x - vWidth * 0.5, y: vTop))
    context.addLine(to: CGPoint(x: center.x, y: vBottom))
    context.addLine(to: CGPoint(x: center.x + vWidth * 0.5, y: vTop))
    context.strokePath()

    // Save Icon
    guard let image = context.makeImage() else {
        print("Failed to create image from context")
        return
    }

    let url = URL(fileURLWithPath: outputPath)

    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        print("Failed to create image destination")
        return
    }

    CGImageDestinationAddImage(destination, image, nil)

    if CGImageDestinationFinalize(destination) {
        print("✓ App icon with 'V' successfully generated at: \(outputPath)")
    } else {
        print("Failed to write image to file")
    }
}

createAppIconWithV()
