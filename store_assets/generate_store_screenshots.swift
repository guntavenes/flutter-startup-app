import AppKit

struct Slide {
    let output: String
    let screenshot: String
    let title: String
    let subtitle: String
    let cropTop: CGFloat
}

let slides = [
    Slide(output: "store_assets/screenshots/01_planla.png", screenshot: "/tmp/ceyizim-home-light.png", title: "Çeyizini birlikte\nkolayca planla", subtitle: "Ücretsiz • Ortak liste • Anlık senkronizasyon", cropTop: 0),
    Slide(output: "store_assets/screenshots/02_detay.png", screenshot: "/var/folders/6t/2s7tj71s4sd4b5j_y1s22yzr0000gn/T/codex-clipboard-1ed7be3e-f578-4d19-a16a-fd913fb80ed1.png", title: "Her ürünün detayı\ntek bir yerde", subtitle: "Fiyat, hedef tarih, marka ve satın alma durumu", cropTop: 0),
    Slide(output: "store_assets/screenshots/03_butce.png", screenshot: "/tmp/ceyizim-home-light.png", title: "Bütçeni anında gör\nkontrolü kaybetme", subtitle: "Toplam harcama ve kalan ürünler her an yanında", cropTop: 250),
]

let canvasSize = NSSize(width: 1320, height: 2868)
let titleFont = NSFont.systemFont(ofSize: 82, weight: .heavy)
let subtitleFont = NSFont.systemFont(ofSize: 34, weight: .semibold)
let titleColor = NSColor(calibratedRed: 0.24, green: 0.10, blue: 0.17, alpha: 1)
let subtitleColor = NSColor(calibratedRed: 0.55, green: 0.36, blue: 0.45, alpha: 1)

for slide in slides {
    guard let source = NSImage(contentsOfFile: slide.screenshot) else {
        fputs("Görsel okunamadı: \(slide.screenshot)\n", stderr)
        exit(1)
    }
    let canvas = NSImage(size: canvasSize)
    canvas.lockFocusFlipped(true)
    let bounds = NSRect(origin: .zero, size: canvasSize)
    NSGradient(colors: [
        NSColor(calibratedRed: 1.0, green: 0.94, blue: 0.97, alpha: 1),
        NSColor(calibratedRed: 1.0, green: 0.99, blue: 0.97, alpha: 1),
    ])!.draw(in: bounds, angle: -90)

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineSpacing = 5
    (slide.title as NSString).draw(
        in: NSRect(x: 70, y: 105, width: 1180, height: 220),
        withAttributes: [.font: titleFont, .foregroundColor: titleColor, .paragraphStyle: paragraph]
    )
    (slide.subtitle as NSString).draw(
        in: NSRect(x: 80, y: 350, width: 1160, height: 60),
        withAttributes: [.font: subtitleFont, .foregroundColor: subtitleColor, .paragraphStyle: paragraph]
    )

    let phoneRect = NSRect(x: 85, y: 500, width: 1150, height: 2500)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.16)
    shadow.shadowBlurRadius = 35
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    NSColor.white.setFill()
    NSBezierPath(roundedRect: phoneRect, xRadius: 58, yRadius: 58).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: phoneRect, xRadius: 58, yRadius: 58).addClip()
    let ratio = phoneRect.width / source.size.width
    let drawnHeight = source.size.height * ratio
    source.draw(
        in: NSRect(x: phoneRect.minX, y: phoneRect.minY - slide.cropTop, width: phoneRect.width, height: drawnHeight),
        from: .zero,
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )
    NSGraphicsContext.restoreGraphicsState()
    canvas.unlockFocus()

    guard let tiff = canvas.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        exit(1)
    }
    try png.write(to: URL(fileURLWithPath: slide.output))
}
