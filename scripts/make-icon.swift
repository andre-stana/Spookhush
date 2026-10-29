// Draws the Spookhush app icon at 1024 px: a Halloween night scene under a street lamp,
// with autumn leaves and embers falling onto a leaf drift where a glowing Jack-o'-lantern rests.
// Usage: swift scripts/make-icon.swift <output.png>
import AppKit
import CoreGraphics

let size: CGFloat = 1024
let inset: CGFloat = 100
let body = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func squircle(in rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    let n: CGFloat = 5
    let a = rect.width / 2, b = rect.height / 2
    for step in 0...720 {
        let t = CGFloat(step) / 720 * 2 * .pi
        let c = cos(t), s = sin(t)
        let x = rect.midX + a * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n)
        let y = rect.midY + b * (s < 0 ? -1 : 1) * pow(abs(s), 2 / n)
        if step == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()
    return path
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let outline = squircle(in: body)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: color(0x000000, 0.45))
ctx.addPath(outline)
ctx.setFillColor(color(0x120917))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(outline)
ctx.clip()

let night = CGGradient(colorsSpace: space, colors: [color(0x21112b), color(0x130b18), color(0x0b060d)] as CFArray, locations: [0, 0.55, 1])!
ctx.drawLinearGradient(night, start: CGPoint(x: 0, y: body.maxY), end: CGPoint(x: 0, y: body.minY), options: [])

let lamp = CGPoint(x: body.midX, y: body.maxY - 150)
let halo = CGGradient(colorsSpace: space, colors: [color(0xff8e2b, 0.48), color(0xff5e14, 0.16), color(0xff5e14, 0)] as CFArray,
                      locations: [0, 0.42, 1])!
ctx.drawRadialGradient(halo, startCenter: lamp, startRadius: 0, endCenter: lamp, endRadius: 450, options: [])

for layer in 0..<30 {
    let spread = 220 + CGFloat(layer) * 7
    let beam = CGMutablePath()
    beam.move(to: CGPoint(x: lamp.x - 20, y: lamp.y))
    beam.addLine(to: CGPoint(x: lamp.x + 20, y: lamp.y))
    beam.addLine(to: CGPoint(x: lamp.x + spread, y: body.minY))
    beam.addLine(to: CGPoint(x: lamp.x - spread, y: body.minY))
    beam.closeSubpath()
    ctx.saveGState()
    ctx.addPath(beam)
    ctx.clip()
    let light = CGGradient(colorsSpace: space, colors: [color(0xff9d3b, 0.020), color(0xff5500, 0.002)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(light, start: CGPoint(x: 0, y: lamp.y), end: CGPoint(x: 0, y: body.minY), options: [])
    ctx.restoreGState()
}

let arm = CGRect(x: lamp.x, y: body.maxY - 118, width: body.maxX - lamp.x, height: 7)
ctx.setFillColor(color(0x2b1e28))
ctx.fill(arm)
let head = CGMutablePath()
head.move(to: CGPoint(x: lamp.x - 54, y: lamp.y + 2))
head.addLine(to: CGPoint(x: lamp.x + 54, y: lamp.y + 2))
head.addLine(to: CGPoint(x: lamp.x + 26, y: lamp.y + 46))
head.addLine(to: CGPoint(x: lamp.x - 26, y: lamp.y + 46))
head.closeSubpath()
ctx.setFillColor(color(0x241922))
ctx.addPath(head)
ctx.fillPath()
let bulbGlow = CGGradient(colorsSpace: space, colors: [color(0xffe699, 0.95), color(0xff801a, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(bulbGlow, startCenter: CGPoint(x: lamp.x, y: lamp.y), startRadius: 0,
                       endCenter: CGPoint(x: lamp.x, y: lamp.y), endRadius: 78, options: [])
ctx.setFillColor(color(0xfff0b8))
ctx.fillEllipse(in: CGRect(x: lamp.x - 34, y: lamp.y - 6, width: 68, height: 14))

// Falling autumn leaves & glowing embers
let leaves: [(CGFloat, CGFloat, CGFloat, CGFloat, UInt32)] = [
    (-130, 520, 14, 0.5, 0xf25c19), (45, 590, 10, -0.4, 0xffaa1d), (155, 470, 16, 0.8, 0xd92b2b),
    (-45, 420, 12, -0.7, 0xf27405), (95, 360, 17, 0.3, 0xff9914), (-175, 330, 13, 1.1, 0xc9221e),
    (200, 300, 11, -0.5, 0xf25c19), (-95, 260, 15, 0.2, 0xffb733), (25, 240, 9, -0.9, 0xe84a15),
    (245, 410, 9, 0.6, 0xb84dff), (-230, 470, 8, -0.3, 0xff801a), (130, 560, 8, 0.4, 0xffcc4d),
]
for (dx, height, radius, angle, hex) in leaves {
    let center = CGPoint(x: body.midX + dx, y: body.minY + height)
    let glow = CGGradient(colorsSpace: space, colors: [color(hex, 0.95), color(hex, 0.55), color(hex, 0)] as CFArray,
                          locations: [0, 0.4, 1])!
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y)
    ctx.rotate(by: angle)
    ctx.scaleBy(x: 1.35, y: 0.78)
    ctx.drawRadialGradient(glow, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: radius * 1.6, options: [])
    ctx.restoreGState()
}

// Autumn leaf drift at bottom
let drift = CGMutablePath()
drift.move(to: CGPoint(x: body.minX - 10, y: body.minY - 10))
drift.addLine(to: CGPoint(x: body.minX - 10, y: body.minY + 196))
drift.addCurve(to: CGPoint(x: body.minX + 300, y: body.minY + 172),
               control1: CGPoint(x: body.minX + 90, y: body.minY + 214), control2: CGPoint(x: body.minX + 200, y: body.minY + 160))
drift.addCurve(to: CGPoint(x: body.minX + 560, y: body.minY + 214),
               control1: CGPoint(x: body.minX + 400, y: body.minY + 184), control2: CGPoint(x: body.minX + 470, y: body.minY + 222))
drift.addCurve(to: CGPoint(x: body.maxX + 10, y: body.minY + 168),
               control1: CGPoint(x: body.minX + 660, y: body.minY + 206), control2: CGPoint(x: body.minX + 740, y: body.minY + 160))
drift.addLine(to: CGPoint(x: body.maxX + 10, y: body.minY - 10))
drift.closeSubpath()
ctx.saveGState()
ctx.addPath(drift)
ctx.clip()
let pool = CGPoint(x: body.midX, y: body.minY + 135)
let leafGrad = CGGradient(colorsSpace: space, colors: [color(0xe85d1a), color(0x9e2b16), color(0x471821), color(0x1f0d18)] as CFArray,
                          locations: [0, 0.35, 0.72, 1])!
ctx.drawRadialGradient(leafGrad, startCenter: pool, startRadius: 0, endCenter: pool, endRadius: 520, options: [.drawsAfterEndLocation])
let crust = CGGradient(colorsSpace: space, colors: [color(0xffae33, 0.28), color(0xffae33, 0)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(crust, start: CGPoint(x: 0, y: body.minY + 220), end: CGPoint(x: 0, y: body.minY + 120), options: [])
ctx.restoreGState()

// Glowing Jack-o'-lantern nestled in the drift
let px = body.midX + 35
let py = body.minY + 195
let pumpkinHalo = CGGradient(colorsSpace: space, colors: [color(0xff991f, 0.65), color(0xff5500, 0.18), color(0xff5500, 0)] as CFArray,
                             locations: [0, 0.45, 1])!
ctx.drawRadialGradient(pumpkinHalo, startCenter: CGPoint(x: px, y: py), startRadius: 0, endCenter: CGPoint(x: px, y: py), endRadius: 190, options: [])

// Pumpkin stem
ctx.saveGState()
ctx.setFillColor(color(0x3a4f22))
let stem = CGMutablePath()
stem.move(to: CGPoint(x: px - 12, y: py + 58))
stem.addQuadCurve(to: CGPoint(x: px + 16, y: py + 92), control: CGPoint(x: px - 4, y: py + 84))
stem.addLine(to: CGPoint(x: px + 26, y: py + 82))
stem.addQuadCurve(to: CGPoint(x: px + 10, y: py + 55), control: CGPoint(x: px + 12, y: py + 72))
stem.closeSubpath()
ctx.addPath(stem)
ctx.fillPath()

// Pumpkin body lobes
for (offsetX, widthScale, hex) in [(-42.0, 0.75, 0xc44108 as UInt32), (42.0, 0.75, 0xc44108), (-22.0, 0.88, 0xe0530c), (22.0, 0.88, 0xe0530c), (0.0, 1.0, 0xf56314)] {
    let w = 96.0 * CGFloat(widthScale)
    let h: CGFloat = 126.0
    let lobeRect = CGRect(x: px + CGFloat(offsetX) - w / 2, y: py - h / 2, width: w, height: h)
    ctx.setFillColor(color(hex))
    ctx.fillEllipse(in: lobeRect)
}

// Carved glowing eyes & grin
ctx.setFillColor(color(0xfff08a))
let faces = CGMutablePath()
// Left eye
faces.move(to: CGPoint(x: px - 44, y: py + 6))
faces.addLine(to: CGPoint(x: px - 24, y: py + 34))
faces.addLine(to: CGPoint(x: px - 10, y: py + 6))
faces.closeSubpath()
// Right eye
faces.move(to: CGPoint(x: px + 10, y: py + 6))
faces.addLine(to: CGPoint(x: px + 24, y: py + 34))
faces.addLine(to: CGPoint(x: px + 44, y: py + 6))
faces.closeSubpath()
// Jagged grin
faces.move(to: CGPoint(x: px - 48, y: py - 14))
faces.addLine(to: CGPoint(x: px - 24, y: py - 24))
faces.addLine(to: CGPoint(x: px - 16, y: py - 14))
faces.addLine(to: CGPoint(x: px, y: py - 26))
faces.addLine(to: CGPoint(x: px + 16, y: py - 14))
faces.addLine(to: CGPoint(x: px + 24, y: py - 24))
faces.addLine(to: CGPoint(x: px + 48, y: py - 14))
faces.addQuadCurve(to: CGPoint(x: px, y: py - 46), control: CGPoint(x: px + 28, y: py - 44))
faces.addQuadCurve(to: CGPoint(x: px - 48, y: py - 14), control: CGPoint(x: px - 28, y: py - 44))
faces.closeSubpath()
ctx.addPath(faces)
ctx.fillPath()
ctx.restoreGState()

ctx.restoreGState()

ctx.saveGState()
ctx.addPath(outline)
ctx.setStrokeColor(color(0xff9933, 0.14))
ctx.setLineWidth(3)
ctx.strokePath()
ctx.restoreGState()

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
