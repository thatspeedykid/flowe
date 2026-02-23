"""
Generates flo.ico — run before PyInstaller.
Requires: pip install pillow
"""
import math

try:
    from PIL import Image, ImageDraw

    sizes = [16, 32, 48, 64, 128, 256]
    imgs = []

    for sz in sizes:
        img = Image.new("RGBA", (sz, sz), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        m = max(1, sz // 16)

        # Dark circle with lime outline
        d.ellipse(
            [m, m, sz - m, sz - m],
            fill=(15, 15, 15, 255),
            outline=(200, 245, 96, 255),
            width=max(1, sz // 18),
        )

        # Rising wave line
        steps = max(6, sz // 6)
        pts = []
        for i in range(steps + 1):
            x = m * 3 + int((sz - m * 6) * i / steps)
            wave = math.sin(i / steps * math.pi) * (sz * 0.12)
            y = int(sz * 0.65 - (i / steps) * sz * 0.32 - wave)
            pts.append((x, y))

        lw = max(1, sz // 18)
        for j in range(len(pts) - 1):
            d.line([pts[j], pts[j + 1]], fill=(200, 245, 96, 255), width=lw)

        # Dot at peak
        ex, ey = pts[-1]
        r = max(2, sz // 12)
        d.ellipse([ex - r, ey - r, ex + r, ey + r], fill=(200, 245, 96, 255))
        r2 = max(1, sz // 24)
        d.ellipse([ex - r2, ey - r2, ex + r2, ey + r2], fill=(15, 15, 15, 255))

        imgs.append(img)

    imgs[0].save(
        "flo.ico",
        format="ICO",
        sizes=[(s, s) for s in sizes],
        append_images=imgs[1:],
    )
    print("  [OK] flo.ico generated")

except ImportError:
    print("  [WARN] pillow not installed - building without icon")
    print("         pip install pillow  to add icon next time")
except Exception as e:
    print(f"  [WARN] icon skipped: {e}")
