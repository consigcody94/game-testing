#!/usr/bin/env python3
"""
Procedural PBR Texture Generator for SIGNAL LOST
Generates: albedo, normal, roughness, metallic, ambient occlusion

Improvements:
- Added ice texture generation
- Better error handling and logging
- Progress indicators
- Configurable via command line
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import argparse
import os
import sys


class TextureGenerator:
    """Generate procedural textures with PBR maps"""

    def __init__(self, size=1024, seed=None):
        self.size = size
        if seed is not None:
            np.random.seed(seed)

    def noise(self, scale=50, octaves=6):
        """Generate multi-octave Perlin-like noise"""
        result = np.zeros((self.size, self.size))

        for octave in range(octaves):
            freq = 2 ** octave
            amp = 0.5 ** octave
            # Calculate grid size, avoiding division by zero
            divisor = max(1, scale // max(1, freq))
            grid_size = max(4, min(self.size, self.size // divisor))

            # Generate random grid
            grid = np.random.rand(grid_size + 1, grid_size + 1)

            # Bilinear upscale
            try:
                from scipy.ndimage import zoom
                factor = self.size / grid_size
                layer = zoom(grid, factor, order=1)[:self.size, :self.size]
            except ImportError:
                # Fallback without scipy
                layer = np.repeat(np.repeat(grid, self.size // grid_size, axis=0),
                                  self.size // grid_size, axis=1)[:self.size, :self.size]
            result += layer * amp

        # Normalize to 0-1
        result = (result - result.min()) / (result.max() - result.min() + 1e-8)
        return result

    def scratches(self, count=100):
        """Generate scratch pattern for worn surfaces"""
        img = Image.new('L', (self.size, self.size), 0)
        draw = ImageDraw.Draw(img)

        for _ in range(count):
            x1 = np.random.randint(0, self.size)
            y1 = np.random.randint(0, self.size)
            length = np.random.randint(20, 200)
            angle = np.random.uniform(0, 2 * np.pi)
            x2 = int(x1 + length * np.cos(angle))
            y2 = int(y1 + length * np.sin(angle))
            intensity = np.random.randint(50, 150)
            draw.line([(x1, y1), (x2, y2)], fill=intensity, width=np.random.randint(1, 3))

        return np.array(img) / 255.0

    def spots(self, count=30, size_range=(20, 100)):
        """Generate circular spots (rust, stains, ice patches)"""
        img = Image.new('L', (self.size, self.size), 0)
        draw = ImageDraw.Draw(img)

        for _ in range(count):
            x = np.random.randint(0, self.size)
            y = np.random.randint(0, self.size)
            r = np.random.randint(*size_range)
            intensity = np.random.randint(100, 255)
            draw.ellipse([x-r, y-r, x+r, y+r], fill=intensity)

        img = img.filter(ImageFilter.GaussianBlur(radius=15))
        return np.array(img) / 255.0

    def cracks(self, count=15, branching=3):
        """Generate crack patterns for ice and concrete"""
        img = Image.new('L', (self.size, self.size), 0)
        draw = ImageDraw.Draw(img)

        def draw_crack(x, y, angle, length, depth):
            if depth <= 0 or length < 5:
                return

            x2 = int(x + length * np.cos(angle))
            y2 = int(y + length * np.sin(angle))
            intensity = 150 + depth * 30
            draw.line([(x, y), (x2, y2)], fill=min(255, intensity), width=max(1, depth))

            # Branch occasionally
            if np.random.random() < 0.3:
                branch_angle = angle + np.random.uniform(-0.8, 0.8)
                draw_crack(x2, y2, branch_angle, length * 0.6, depth - 1)

            # Continue main crack with slight deviation
            new_angle = angle + np.random.uniform(-0.3, 0.3)
            draw_crack(x2, y2, new_angle, length * 0.85, depth - 1)

        for _ in range(count):
            x = np.random.randint(0, self.size)
            y = np.random.randint(0, self.size)
            angle = np.random.uniform(0, 2 * np.pi)
            draw_crack(x, y, angle, np.random.randint(50, 150), branching)

        return np.array(img) / 255.0

    def height_to_normal(self, height_map, strength=1.0):
        """Convert height map to normal map using Sobel-like gradients"""
        h = height_map.astype(np.float32)

        # Compute gradients
        dx = np.zeros_like(h)
        dy = np.zeros_like(h)
        dx[:, 1:-1] = (h[:, 2:] - h[:, :-2]) / 2.0
        dy[1:-1, :] = (h[2:, :] - h[:-2, :]) / 2.0

        # Scale gradients
        dx *= strength
        dy *= strength

        # Build normal vectors
        normal = np.zeros((self.size, self.size, 3), dtype=np.float32)
        normal[:, :, 0] = -dx
        normal[:, :, 1] = -dy
        normal[:, :, 2] = 1.0

        # Normalize
        length = np.sqrt(np.sum(normal ** 2, axis=2, keepdims=True))
        normal = normal / (length + 1e-8)

        # Convert from [-1,1] to [0,255] (128 = neutral)
        normal = ((normal + 1.0) * 0.5 * 255).astype(np.uint8)
        return normal

    def colorize(self, value_map, color_dark, color_light):
        """Apply color gradient to grayscale map"""
        c1 = np.array(color_dark, dtype=np.float32)
        c2 = np.array(color_light, dtype=np.float32)

        result = np.zeros((self.size, self.size, 3), dtype=np.float32)
        for i in range(3):
            result[:, :, i] = value_map * c2[i] + (1 - value_map) * c1[i]

        return result.astype(np.uint8)


def generate_rusted_metal(output_dir, size=1024, seed=42):
    """Generate complete rusted metal PBR texture set"""
    os.makedirs(output_dir, exist_ok=True)
    gen = TextureGenerator(size, seed)

    print(f"  Generating rusted metal textures ({size}x{size})...")

    # Generate layers
    base = gen.noise(scale=100, octaves=4)
    detail = gen.noise(scale=30, octaves=6)
    scratches = gen.scratches(count=150)
    rust = gen.spots(count=40, size_range=(20, 100))

    # ALBEDO
    albedo = gen.colorize(base * 0.3 + detail * 0.2, (100, 105, 115), (140, 145, 155))
    rust_color = gen.colorize(rust, (60, 40, 25), (180, 100, 50))

    # Blend rust onto metal
    for i in range(3):
        albedo[:, :, i] = (albedo[:, :, i] * (1 - rust * 0.7) +
                          rust_color[:, :, i] * rust * 0.7).astype(np.uint8)

    # Darken scratches
    for i in range(3):
        albedo[:, :, i] = (albedo[:, :, i] * (1 - scratches * 0.3)).astype(np.uint8)

    Image.fromarray(albedo).save(f"{output_dir}/albedo.png")

    # NORMAL
    height = base * 0.3 + detail * 0.5 + scratches * 0.2
    normal = gen.height_to_normal(height, strength=2.0)
    Image.fromarray(normal).save(f"{output_dir}/normal.png")

    # ROUGHNESS
    roughness = np.ones((size, size)) * 0.4
    roughness += rust * 0.4
    roughness -= scratches * 0.15
    roughness += detail * 0.1
    roughness = np.clip(roughness, 0, 1)
    Image.fromarray((roughness * 255).astype(np.uint8)).save(f"{output_dir}/roughness.png")

    # METALLIC
    metallic = np.ones((size, size)) * 0.95
    metallic -= rust * 0.9
    metallic = np.clip(metallic, 0, 1)
    Image.fromarray((metallic * 255).astype(np.uint8)).save(f"{output_dir}/metallic.png")

    # AO
    ao = 1.0 - height * 0.3
    ao = np.clip(ao, 0.5, 1.0)
    Image.fromarray((ao * 255).astype(np.uint8)).save(f"{output_dir}/ao.png")

    print(f"    Saved to {output_dir}/")


def generate_concrete(output_dir, size=1024, seed=123):
    """Generate concrete PBR texture set"""
    os.makedirs(output_dir, exist_ok=True)
    gen = TextureGenerator(size, seed)

    print(f"  Generating concrete textures ({size}x{size})...")

    base = gen.noise(scale=150, octaves=3)
    detail = gen.noise(scale=30, octaves=6)
    cracks = gen.scratches(count=30)
    stains = gen.spots(count=20, size_range=(50, 150))

    # ALBEDO
    albedo = gen.colorize(base * 0.5 + detail * 0.3, (130, 130, 125), (175, 175, 170))
    for i in range(3):
        albedo[:, :, i] = (albedo[:, :, i] * (1 - stains * 0.25)).astype(np.uint8)
    Image.fromarray(albedo).save(f"{output_dir}/albedo.png")

    # NORMAL
    height = base * 0.2 + detail * 0.4 + cracks * 0.4
    normal = gen.height_to_normal(height, strength=1.5)
    Image.fromarray(normal).save(f"{output_dir}/normal.png")

    # ROUGHNESS (concrete is rough)
    roughness = np.ones((size, size)) * 0.75 + detail * 0.15
    roughness = np.clip(roughness, 0, 1)
    Image.fromarray((roughness * 255).astype(np.uint8)).save(f"{output_dir}/roughness.png")

    # METALLIC (zero for concrete)
    Image.fromarray(np.zeros((size, size), dtype=np.uint8)).save(f"{output_dir}/metallic.png")

    # AO
    ao = 1.0 - cracks * 0.4 - stains * 0.15
    ao = np.clip(ao, 0.4, 1.0)
    Image.fromarray((ao * 255).astype(np.uint8)).save(f"{output_dir}/ao.png")

    print(f"    Saved to {output_dir}/")


def generate_snow(output_dir, size=1024, seed=456):
    """Generate snow PBR texture set"""
    os.makedirs(output_dir, exist_ok=True)
    gen = TextureGenerator(size, seed)

    print(f"  Generating snow textures ({size}x{size})...")

    base = gen.noise(scale=80, octaves=4)
    sparkle = gen.noise(scale=10, octaves=2)
    drift = gen.noise(scale=200, octaves=2)

    # ALBEDO (white with subtle blue in shadows)
    albedo = gen.colorize(base * 0.2 + sparkle * 0.1, (225, 230, 245), (250, 252, 255))
    shadow = drift * 0.15
    albedo[:, :, 0] = (albedo[:, :, 0] * (1 - shadow * 0.1)).astype(np.uint8)
    albedo[:, :, 1] = (albedo[:, :, 1] * (1 - shadow * 0.05)).astype(np.uint8)
    Image.fromarray(albedo).save(f"{output_dir}/albedo.png")

    # NORMAL
    height = base * 0.3 + drift * 0.5
    normal = gen.height_to_normal(height, strength=0.8)
    Image.fromarray(normal).save(f"{output_dir}/normal.png")

    # ROUGHNESS
    roughness = 0.5 + base * 0.3 - sparkle * 0.2
    roughness = np.clip(roughness, 0.3, 0.85)
    Image.fromarray((roughness * 255).astype(np.uint8)).save(f"{output_dir}/roughness.png")

    # METALLIC
    Image.fromarray(np.zeros((size, size), dtype=np.uint8)).save(f"{output_dir}/metallic.png")

    # AO
    ao = 1.0 - drift * 0.15
    ao = np.clip(ao, 0.7, 1.0)
    Image.fromarray((ao * 255).astype(np.uint8)).save(f"{output_dir}/ao.png")

    print(f"    Saved to {output_dir}/")


def generate_ice(output_dir, size=1024, seed=789):
    """Generate glacier ice PBR texture set (IMPROVEMENT: Added this texture type)"""
    os.makedirs(output_dir, exist_ok=True)
    gen = TextureGenerator(size, seed)

    print(f"  Generating ice textures ({size}x{size})...")

    base = gen.noise(scale=120, octaves=3)
    detail = gen.noise(scale=40, octaves=5)
    cracks = gen.cracks(count=20, branching=4)
    bubbles = gen.spots(count=80, size_range=(3, 15))

    # ALBEDO (blue-tinted translucent ice)
    # Ice has a characteristic blue-cyan color
    albedo = gen.colorize(base * 0.4 + detail * 0.3, (160, 200, 220), (200, 235, 250))

    # Add darker cracks
    for i in range(3):
        crack_darkness = cracks * 0.4
        albedo[:, :, i] = (albedo[:, :, i] * (1 - crack_darkness)).astype(np.uint8)

    # Brighten bubble areas slightly
    for i in range(3):
        albedo[:, :, i] = np.clip(albedo[:, :, i] + bubbles * 30, 0, 255).astype(np.uint8)

    Image.fromarray(albedo).save(f"{output_dir}/albedo.png")

    # NORMAL (cracks should be visible)
    height = base * 0.2 + detail * 0.3 + cracks * 0.5
    normal = gen.height_to_normal(height, strength=1.8)
    Image.fromarray(normal).save(f"{output_dir}/normal.png")

    # ROUGHNESS (ice is generally smooth but cracks are rough)
    roughness = np.ones((size, size)) * 0.15
    roughness += cracks * 0.5
    roughness += detail * 0.1
    roughness = np.clip(roughness, 0.05, 0.7)
    Image.fromarray((roughness * 255).astype(np.uint8)).save(f"{output_dir}/roughness.png")

    # METALLIC (ice is not metallic but has high specular)
    Image.fromarray(np.zeros((size, size), dtype=np.uint8)).save(f"{output_dir}/metallic.png")

    # AO (cracks should be darker)
    ao = 1.0 - cracks * 0.5 - detail * 0.1
    ao = np.clip(ao, 0.3, 1.0)
    Image.fromarray((ao * 255).astype(np.uint8)).save(f"{output_dir}/ao.png")

    print(f"    Saved to {output_dir}/")


def generate_screen_static(output_dir, size=512, seed=321):
    """Generate CRT static texture"""
    os.makedirs(output_dir, exist_ok=True)
    np.random.seed(seed)

    print(f"  Generating screen static ({size}x{size})...")

    # Random noise
    static = np.random.rand(size, size)

    # Scanlines
    scanlines = np.zeros((size, size))
    scanlines[::2, :] = 0.15

    combined = np.clip(static * 0.85 + scanlines, 0, 1)

    # Green CRT tint (classic terminal look)
    rgb = np.zeros((size, size, 3), dtype=np.uint8)
    rgb[:, :, 0] = (combined * 40).astype(np.uint8)
    rgb[:, :, 1] = (combined * 255).astype(np.uint8)
    rgb[:, :, 2] = (combined * 60).astype(np.uint8)

    Image.fromarray(rgb).save(f"{output_dir}/static.png")
    print(f"    Saved to {output_dir}/")


def generate_from_albedo(albedo_path, output_dir, strength=1.0):
    """Generate PBR maps from existing albedo texture"""
    os.makedirs(output_dir, exist_ok=True)

    print(f"  Generating PBR maps from {albedo_path}...")

    try:
        img = Image.open(albedo_path).convert('RGB')
    except Exception as e:
        print(f"    ERROR: Could not load image: {e}")
        return False

    size = img.size[0]
    arr = np.array(img)

    # Convert to grayscale for height estimation
    gray = np.mean(arr, axis=2) / 255.0

    gen = TextureGenerator(size)

    # NORMAL from luminance
    normal = gen.height_to_normal(gray, strength=strength)
    Image.fromarray(normal).save(f"{output_dir}/normal.png")

    # ROUGHNESS (darker = rougher assumption)
    roughness = 1.0 - gray * 0.5
    roughness = np.clip(roughness, 0.2, 0.9)
    Image.fromarray((roughness * 255).astype(np.uint8)).save(f"{output_dir}/roughness.png")

    # METALLIC (assume non-metallic by default)
    Image.fromarray(np.zeros((size, size), dtype=np.uint8)).save(f"{output_dir}/metallic.png")

    # AO from local contrast
    blurred = np.array(Image.fromarray((gray * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(radius=size//32))) / 255.0
    ao = 0.5 + (gray - blurred) * 2
    ao = np.clip(ao, 0.3, 1.0)
    Image.fromarray((ao * 255).astype(np.uint8)).save(f"{output_dir}/ao.png")

    print(f"    Saved to {output_dir}/")
    return True


def main():
    parser = argparse.ArgumentParser(
        description='Generate PBR textures for SIGNAL LOST',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 generate_textures.py --output assets/textures --size 1024
  python3 generate_textures.py --type metal --size 2048
  python3 generate_textures.py --from-albedo input.png --output output_dir
        """
    )
    parser.add_argument('--output', '-o', default='assets/textures',
                        help='Output directory (default: assets/textures)')
    parser.add_argument('--size', '-s', type=int, default=1024,
                        help='Texture size in pixels (default: 1024)')
    parser.add_argument('--type', '-t',
                        choices=['all', 'metal', 'concrete', 'snow', 'ice', 'static'],
                        default='all', help='Texture type to generate (default: all)')
    parser.add_argument('--seed', type=int, default=42,
                        help='Random seed for reproducibility (default: 42)')
    parser.add_argument('--from-albedo', metavar='PATH',
                        help='Generate PBR maps from existing albedo texture')

    args = parser.parse_args()

    if args.from_albedo:
        success = generate_from_albedo(args.from_albedo, args.output)
        sys.exit(0 if success else 1)

    print(f"\n{'='*50}")
    print(f"  SIGNAL LOST - Texture Generator")
    print(f"  Size: {args.size}x{args.size} | Seed: {args.seed}")
    print(f"{'='*50}\n")

    if args.type in ['all', 'metal']:
        generate_rusted_metal(f"{args.output}/metal_panel", args.size, args.seed)

    if args.type in ['all', 'concrete']:
        generate_concrete(f"{args.output}/concrete", args.size, args.seed + 1)

    if args.type in ['all', 'snow']:
        generate_snow(f"{args.output}/snow", args.size, args.seed + 2)

    if args.type in ['all', 'ice']:
        generate_ice(f"{args.output}/ice", args.size, args.seed + 3)

    if args.type in ['all', 'static']:
        generate_screen_static(f"{args.output}/screen_static", 512, args.seed + 4)

    print(f"\n{'='*50}")
    print(f"  Texture generation complete!")
    print(f"{'='*50}\n")


if __name__ == "__main__":
    main()
