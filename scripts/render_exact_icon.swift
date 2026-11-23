import Cocoa

let svgContent = """
<svg viewBox="0 0 1024 1024" width="1024" height="1024" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bgGrad1" x1="0" y1="0" x2="1024" y2="1024" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#2c221e"/>
      <stop offset="50%" stop-color="#1c1816"/>
      <stop offset="100%" stop-color="#12100f"/>
    </linearGradient>
    <linearGradient id="terracotta" x1="360" y1="360" x2="700" y2="700" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#f2a68d"/>
      <stop offset="100%" stop-color="#cc785c"/>
    </linearGradient>
    <filter id="glow1" x="100" y="100" width="824" height="824" filterUnits="userSpaceOnUse">
      <feGaussianBlur stdDeviation="28" result="blur"/>
      <feComposite in="SourceGraphic" in2="blur" operator="over"/>
    </filter>
  </defs>

  <!-- Full Bleed Background for iOS App Store -->
  <rect width="1024" height="1024" fill="url(#bgGrad1)"/>

  <!-- Subtle inner ambient rim -->
  <rect x="24" y="24" width="976" height="976" rx="220" stroke="#44352f" stroke-width="8" opacity="0.35"/>

  <!-- Anillo exterior de película con perforaciones -->
  <circle cx="512" cy="512" r="360" stroke="#cc785c" stroke-width="26" stroke-dasharray="52 38" opacity="0.5"/>

  <!-- Carrete interior biselado -->
  <circle cx="512" cy="512" r="260" stroke="#f2a68d" stroke-width="16" fill="#1c1816" opacity="0.95"/>

  <!-- Botón Play Central Estilizado con Resplandor -->
  <g filter="url(#glow1)">
    <path d="M440 360 L660 512 L440 664 Z" fill="url(#terracotta)" stroke="#ffffff" stroke-width="12" stroke-linejoin="round"/>
  </g>

  <!-- Destello de IA Superior Derecho (4 puntas) -->
  <path d="M690 290 L708 220 L726 290 L796 308 L726 326 L708 396 L690 326 L620 308 Z" fill="#ffcca8"/>

  <!-- Nodos Neuronales Conectados -->
  <circle cx="310" cy="380" r="24" fill="#cc785c"/>
  <circle cx="310" cy="644" r="24" fill="#cc785c"/>
  <circle cx="512" cy="740" r="24" fill="#cc785c"/>
  <line x1="310" y1="380" x2="410" y2="450" stroke="#cc785c" stroke-width="12" stroke-dasharray="12 12"/>
  <line x1="310" y1="644" x2="410" y2="574" stroke="#cc785c" stroke-width="12" stroke-dasharray="12 12"/>
</svg>
"""

guard let svgData = svgContent.data(using: .utf8),
      let svgImage = NSImage(data: svgData) else {
    print("Error parsing SVG")
    exit(1)
}

let targetSize = NSSize(width: 1024, height: 1024)
let outputImage = NSImage(size: targetSize)

outputImage.lockFocus()
svgImage.draw(in: NSRect(origin: .zero, size: targetSize))
outputImage.unlockFocus()

guard let tiffData = outputImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Error encoding PNG")
    exit(1)
}

let targetPath = "/Users/wacko87/Desktop/Creacion Apps en Xcode/ReelMind/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
do {
    try pngData.write(to: URL(fileURLWithPath: targetPath))
    print("✅ Successfully generated exact ReelMind AppIcon at:", targetPath)
} catch {
    print("Error writing file:", error)
    exit(1)
}
