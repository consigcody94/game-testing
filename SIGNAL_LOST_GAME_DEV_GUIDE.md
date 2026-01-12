# SIGNAL LOST: Complete CLI Game Development Guide

> **Purpose**: Everything an AI coding agent needs to build a complete 3D survival horror game entirely from the command line. No GUI tools. All assets generated via CLI/API including AI image generation.

---

## TABLE OF CONTENTS

1. [Game Overview](#1-game-overview)
2. [Project Structure](#2-project-structure)
3. [Environment Setup](#3-environment-setup)
4. [AI Image Generation for Textures](#4-ai-image-generation-for-textures)
5. [Procedural Texture Generation](#5-procedural-texture-generation-python)
6. [3D Model Generation](#6-3d-model-generation-blender-cli)
7. [Audio Generation](#7-audio-generation)
8. [Godot Project Configuration](#8-godot-project-configuration)
9. [Game Scripts](#9-game-scripts-gdscript)
10. [Scene Files](#10-scene-files)
11. [Shaders](#11-shaders)
12. [Build and Export](#12-build-and-export)
13. [Complete Build Script](#13-complete-build-script)
14. [Asset Prompt Library](#14-asset-prompt-library)

---

## 1. GAME OVERVIEW

### Concept

**SIGNAL LOST** - A first-person survival horror game. You're a remote technician investigating an abandoned Arctic weather station (ASOS-style) transmitting anomalous data. The instruments behave strangely. Something is wrong.

### Core Mechanics

- First-person exploration with head bob
- Flashlight with battery management
- Interact with weather instruments and computer terminals
- Environmental storytelling through data logs
- Atmospheric horror (tension-based, no combat)
- Paranormal anomaly events (flickering lights, radio bursts, temperature drops)

### Visual Style

- Isolated Arctic environment
- Industrial/scientific equipment aesthetic
- Cold color palette: blues, grays, white
- Heavy fog and limited visibility
- Flickering lights, CRT static on screens
- 1970s-80s NASA/NOAA equipment aesthetic

### Technical Specs

| Specification | Value |
|--------------|-------|
| Resolution | 1920x1080 |
| Texture Size | 1024x1024 (props), 2048x2048 (environment) |
| Polycount | 500-5000 tris per object |
| Target FPS | 60 |
| Engine | Godot 4.2+ |
| Render | Forward+ |

---

## 2. PROJECT STRUCTURE

```
signal_lost/
├── project.godot                 # Godot project file
├── default_env.tres              # Environment resource
├── export_presets.cfg            # Build configurations
│
├── assets/
│   ├── textures/
│   │   ├── metal_panel/
│   │   │   ├── albedo.png
│   │   │   ├── normal.png
│   │   │   ├── roughness.png
│   │   │   ├── metallic.png
│   │   │   └── ao.png
│   │   ├── concrete/
│   │   ├── ice/
│   │   ├── snow/
│   │   └── screen_static/
│   │
│   ├── models/
│   │   ├── weather_station.glb
│   │   ├── anemometer.glb
│   │   ├── thermometer_shelter.glb
│   │   ├── control_panel.glb
│   │   ├── computer_terminal.glb
│   │   ├── desk.glb
│   │   ├── chair.glb
│   │   └── door.glb
│   │
│   ├── audio/
│   │   ├── ambience/
│   │   │   ├── wind_loop.ogg
│   │   │   ├── metal_creak.ogg
│   │   │   └── electronic_hum.ogg
│   │   ├── sfx/
│   │   │   ├── footstep_snow.ogg
│   │   │   ├── footstep_metal.ogg
│   │   │   ├── door_open.ogg
│   │   │   ├── switch_click.ogg
│   │   │   └── radio_static.ogg
│   │   └── music/
│   │       └── tension_drone.ogg
│   │
│   ├── shaders/
│   │   ├── snow_ground.gdshader
│   │   ├── screen_static.gdshader
│   │   └── frost_overlay.gdshader
│   │
│   └── fonts/
│       └── terminal.ttf
│
├── scenes/
│   ├── main.tscn
│   ├── player/
│   │   └── player.tscn
│   ├── environment/
│   │   ├── weather_station.tscn
│   │   └── terrain.tscn
│   ├── props/
│   │   ├── control_panel.tscn
│   │   ├── computer_terminal.tscn
│   │   └── door.tscn
│   └── ui/
│       ├── hud.tscn
│       └── terminal_screen.tscn
│
├── scripts/
│   ├── player/
│   │   ├── player_controller.gd
│   │   ├── camera_controller.gd
│   │   └── flashlight.gd
│   ├── interaction/
│   │   ├── interactable.gd
│   │   ├── door.gd
│   │   └── terminal.gd
│   ├── systems/
│   │   ├── game_manager.gd
│   │   ├── audio_manager.gd
│   │   └── save_system.gd
│   └── environment/
│       ├── weather_effects.gd
│       └── anomaly_controller.gd
│
└── tools/
    ├── generate_textures.py
    ├── generate_models.py
    ├── generate_audio.sh
    └── build_all.sh
```

---

## 3. ENVIRONMENT SETUP

### Install Dependencies (Ubuntu/Debian)

```bash
#!/bin/bash
# install_deps.sh - Install all required tools

# System update
sudo apt update && sudo apt upgrade -y

# Python 3 and pip
sudo apt install -y python3 python3-pip python3-venv

# Python packages for texture generation
pip install pillow numpy scipy requests --break-system-packages

# Blender for 3D model generation (headless capable)
sudo apt install -y blender

# Audio tools
sudo apt install -y ffmpeg sox libsox-fmt-all

# Download Godot 4.2 (headless for CI, or standard for local)
GODOT_VERSION="4.2.1"
wget "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
unzip "Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
sudo mv "Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot
chmod +x /usr/local/bin/godot

# Verify installations
echo "=== Checking installations ==="
python3 --version
blender --version
godot --version 2>/dev/null || echo "Godot installed (run 'godot' to verify)"
ffmpeg -version | head -1
sox --version
```

---

## 4. AI IMAGE GENERATION FOR TEXTURES

### Hugging Face Dynamic Space API

The agent can generate textures using AI image generation through the Hugging Face MCP tools.

#### Available Spaces

| Space ID | Use Case | Speed |
|----------|----------|-------|
| `evalstate/flux1_schnell` | Fast iteration, testing | Fast |
| `mcp-tools/FLUX.1-Krea-dev` | High quality final assets | Medium |
| `mcp-tools/Qwen-Image` | Text on textures | Medium |
| `mcp-tools/Qwen-Image-Fast` | Quality + speed balance | Fast |

#### How to Generate Textures

**Step 1**: Call the dynamic_space tool with invoke operation:

```json
{
  "operation": "invoke",
  "space_name": "evalstate/flux1_schnell",
  "parameters": "{\"prompt\": \"YOUR_TEXTURE_PROMPT_HERE\", \"width\": 1024, \"height\": 1024, \"seed\": 42}"
}
```

**Step 2**: The tool returns an image URL. Download it:

```bash
curl -o assets/textures/metal_panel/albedo.png "RETURNED_IMAGE_URL"
```

**Step 3**: Generate derivative maps (normal, roughness, etc.) using the procedural Python script in Section 5.

#### Texture Prompt Templates

**CRITICAL PROMPT STRUCTURE**: For seamless game textures, always include:
- "seamless tileable texture"
- Material description
- "top-down view"
- "flat even lighting"
- "PBR game texture"
- Resolution (1024x1024 or 2048x2048)

**Metal Surfaces**:
```
seamless tileable texture of [DESCRIPTION] metal, [CONDITION], industrial, top-down view, flat even lighting, PBR game texture 1024x1024
```

Examples:
- `seamless tileable texture of brushed aluminum control panel, clean with subtle scratches, scientific equipment, top-down view, flat even lighting, PBR game texture 1024x1024`
- `seamless tileable texture of rusted corroded steel plate with rivets, orange rust and flaking gray paint, industrial decay, top-down view, flat even lighting, PBR game texture 1024x1024`
- `seamless tileable texture of painted metal wall, gray industrial paint with chips and wear marks, top-down view, flat even lighting, PBR game texture 1024x1024`

**Concrete**:
```
seamless tileable texture of [DESCRIPTION] concrete, [CONDITION], top-down view, flat even lighting, PBR game texture 1024x1024
```

Examples:
- `seamless tileable texture of smooth poured concrete floor, light gray, minimal cracks, industrial building, top-down view, flat even lighting, PBR game texture 1024x1024`
- `seamless tileable texture of cracked weathered concrete, stains and damage, abandoned building, top-down view, flat even lighting, PBR game texture 1024x1024`

**Snow and Ice**:
```
seamless tileable texture of [DESCRIPTION] snow/ice, arctic environment, top-down view, flat even lighting, PBR game texture 1024x1024
```

Examples:
- `seamless tileable texture of fresh powder snow, white with subtle blue shadows, arctic ground, top-down view, flat even lighting, PBR game texture 1024x1024`
- `seamless tileable texture of packed icy snow with footprint impressions, dirty gray-white, arctic base camp, top-down view, flat even lighting, PBR game texture 1024x1024`
- `seamless tileable texture of clear blue glacier ice, cracks and air bubbles visible, frozen surface, top-down view, flat even lighting, PBR game texture 1024x1024`

**Wood**:
```
seamless tileable texture of [DESCRIPTION] wood, [CONDITION], top-down view, flat even lighting, PBR game texture 1024x1024
```

Examples:
- `seamless tileable texture of old wooden desk surface, dark stained oak with scratches and rings, vintage office furniture, top-down view, flat even lighting, PBR game texture 1024x1024`
- `seamless tileable texture of weathered wooden planks, gray aged wood with gaps between boards, outdoor decking, top-down view, flat even lighting, PBR game texture 1024x1024`

---

## 5. PROCEDURAL TEXTURE GENERATION (PYTHON)

When AI generation isn't available, or for generating derivative PBR maps (normal, roughness, metallic, AO) from an albedo texture:

### tools/generate_textures.py

```python
#!/usr/bin/env python3
"""
Procedural PBR Texture Generator
Generates: albedo, normal, roughness, metallic, ambient occlusion
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import argparse
import os


class TextureGenerator:
    """Generate procedural textures with PBR maps"""
    
    def __init__(self, size=1024, seed=None):
        self.size = size
        if seed is not None:
            np.random.seed(seed)
    
    def noise(self, scale=50, octaves=6):
        """Generate multi-octave noise"""
        result = np.zeros((self.size, self.size))
        
        for octave in range(octaves):
            freq = 2 ** octave
            amp = 0.5 ** octave
            grid_size = max(4, self.size // (scale // max(1, freq)))
            
            # Generate random grid
            grid = np.random.rand(grid_size + 1, grid_size + 1)
            
            # Bilinear upscale
            from scipy.ndimage import zoom
            factor = self.size / grid_size
            layer = zoom(grid, factor, order=1)[:self.size, :self.size]
            result += layer * amp
        
        # Normalize to 0-1
        result = (result - result.min()) / (result.max() - result.min() + 1e-8)
        return result
    
    def scratches(self, count=100):
        """Generate scratch pattern"""
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
        """Generate circular spots (rust, stains)"""
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
    
    def height_to_normal(self, height_map, strength=1.0):
        """Convert height map to normal map"""
        h = height_map.astype(np.float32)
        
        # Compute gradients using Sobel-like approach
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
        
        # Convert from [-1,1] to [0,255] (128 = zero)
        normal = ((normal + 1.0) * 0.5 * 255).astype(np.uint8)
        return normal
    
    def colorize(self, value_map, color_dark, color_light):
        """Apply color gradient to grayscale"""
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
    
    print(f"  Saved to {output_dir}/")


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
    
    print(f"  Saved to {output_dir}/")


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
    
    print(f"  Saved to {output_dir}/")


def generate_screen_static(output_dir, size=512, seed=789):
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
    
    # Green CRT tint
    rgb = np.zeros((size, size, 3), dtype=np.uint8)
    rgb[:, :, 0] = (combined * 40).astype(np.uint8)
    rgb[:, :, 1] = (combined * 255).astype(np.uint8)
    rgb[:, :, 2] = (combined * 60).astype(np.uint8)
    
    Image.fromarray(rgb).save(f"{output_dir}/static.png")
    print(f"  Saved to {output_dir}/")


def generate_from_albedo(albedo_path, output_dir, strength=1.0):
    """Generate PBR maps from existing albedo texture"""
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"  Generating PBR maps from {albedo_path}...")
    
    img = Image.open(albedo_path).convert('RGB')
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
    
    print(f"  Saved to {output_dir}/")


def main():
    parser = argparse.ArgumentParser(description='Generate PBR textures')
    parser.add_argument('--output', '-o', default='assets/textures', help='Output directory')
    parser.add_argument('--size', '-s', type=int, default=1024, help='Texture size')
    parser.add_argument('--type', '-t', choices=['all', 'metal', 'concrete', 'snow', 'static'],
                        default='all', help='Texture type')
    parser.add_argument('--seed', type=int, default=42, help='Random seed')
    parser.add_argument('--from-albedo', help='Generate PBR maps from existing albedo')
    
    args = parser.parse_args()
    
    if args.from_albedo:
        generate_from_albedo(args.from_albedo, args.output)
        return
    
    print(f"Generating textures (size={args.size}, seed={args.seed})...\n")
    
    if args.type in ['all', 'metal']:
        generate_rusted_metal(f"{args.output}/metal_panel", args.size, args.seed)
    
    if args.type in ['all', 'concrete']:
        generate_concrete(f"{args.output}/concrete", args.size, args.seed + 1)
    
    if args.type in ['all', 'snow']:
        generate_snow(f"{args.output}/snow", args.size, args.seed + 2)
    
    if args.type in ['all', 'static']:
        generate_screen_static(f"{args.output}/screen_static", 512, args.seed + 3)
    
    print("\n✓ Texture generation complete!")


if __name__ == "__main__":
    main()
```

### CLI Usage

```bash
# Generate all texture types
python3 tools/generate_textures.py --output assets/textures --size 1024

# Generate only metal
python3 tools/generate_textures.py --type metal --size 2048

# Generate PBR maps from AI-generated albedo
python3 tools/generate_textures.py --from-albedo assets/textures/metal_panel/albedo.png --output assets/textures/metal_panel
```

---

## 6. 3D MODEL GENERATION (BLENDER CLI)

Blender runs headless via Python scripts. No GUI needed.

### tools/generate_models.py

```python
#!/usr/bin/env python3
"""
Blender Headless Model Generator
Run: blender --background --python tools/generate_models.py
"""

import bpy
import bmesh
import math
import os
import sys

# Clear default scene
bpy.ops.wm.read_factory_settings(use_empty=True)


def apply_transforms(obj):
    """Apply all transforms to object"""
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.select_set(False)


def uv_unwrap(obj):
    """Smart UV unwrap object"""
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(island_margin=0.02)
    bpy.ops.object.mode_set(mode='OBJECT')


def export_glb(obj, filepath):
    """Export object as GLB"""
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        use_selection=True,
        export_format='GLB',
        export_apply=True
    )
    print(f"    Exported: {filepath}")


def clear_scene():
    """Delete all objects in scene"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()


def create_control_panel():
    """Scientific instrument control panel"""
    # Main body
    bpy.ops.mesh.primitive_cube_add(size=1)
    panel = bpy.context.active_object
    panel.name = "ControlPanel"
    panel.scale = (1.2, 0.3, 0.8)
    apply_transforms(panel)
    
    # Bevel edges
    bpy.ops.object.modifier_add(type='BEVEL')
    panel.modifiers["Bevel"].width = 0.02
    panel.modifiers["Bevel"].segments = 2
    bpy.ops.object.modifier_apply(modifier="Bevel")
    
    # Screen recess
    bpy.ops.mesh.primitive_cube_add(size=1)
    screen = bpy.context.active_object
    screen.name = "Screen"
    screen.scale = (0.5, 0.05, 0.3)
    screen.location = (0, -0.13, 0.15)
    apply_transforms(screen)
    
    # Buttons (2 rows x 5)
    buttons = []
    for row in range(2):
        for col in range(5):
            bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=0.02)
            btn = bpy.context.active_object
            btn.location = (-0.4 + col * 0.15, -0.14, -0.15 + row * 0.12)
            btn.rotation_euler = (math.pi/2, 0, 0)
            buttons.append(btn)
    
    # Toggle switches
    for i in range(3):
        bpy.ops.mesh.primitive_cube_add(size=1)
        switch = bpy.context.active_object
        switch.scale = (0.02, 0.02, 0.05)
        switch.location = (0.35 + i * 0.08, -0.14, 0)
        apply_transforms(switch)
        buttons.append(switch)
    
    # Join all
    bpy.ops.object.select_all(action='DESELECT')
    for obj in buttons + [screen]:
        obj.select_set(True)
    panel.select_set(True)
    bpy.context.view_layer.objects.active = panel
    bpy.ops.object.join()
    
    uv_unwrap(panel)
    return panel


def create_computer_terminal():
    """Retro CRT computer terminal"""
    # Monitor body
    bpy.ops.mesh.primitive_cube_add(size=1)
    monitor = bpy.context.active_object
    monitor.name = "Terminal"
    monitor.scale = (0.6, 0.5, 0.5)
    apply_transforms(monitor)
    
    # Screen bezel
    bpy.ops.mesh.primitive_cube_add(size=1)
    bezel = bpy.context.active_object
    bezel.scale = (0.5, 0.05, 0.4)
    bezel.location = (0, -0.23, 0.03)
    apply_transforms(bezel)
    
    # CRT screen
    bpy.ops.mesh.primitive_cube_add(size=1)
    screen = bpy.context.active_object
    screen.scale = (0.45, 0.02, 0.35)
    screen.location = (0, -0.26, 0.03)
    apply_transforms(screen)
    
    # Keyboard
    bpy.ops.mesh.primitive_cube_add(size=1)
    keyboard = bpy.context.active_object
    keyboard.scale = (0.5, 0.25, 0.04)
    keyboard.location = (0, -0.55, -0.2)
    keyboard.rotation_euler = (0.2, 0, 0)
    apply_transforms(keyboard)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [bezel, screen, keyboard]:
        obj.select_set(True)
    monitor.select_set(True)
    bpy.context.view_layer.objects.active = monitor
    bpy.ops.object.join()
    
    uv_unwrap(monitor)
    return monitor


def create_anemometer():
    """Wind speed measurement device"""
    # Central pole
    bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=1.5)
    pole = bpy.context.active_object
    pole.name = "Anemometer"
    pole.location.z = 0.75
    apply_transforms(pole)
    
    # Hub
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.1)
    hub = bpy.context.active_object
    hub.location = (0, 0, 1.5)
    apply_transforms(hub)
    
    # 3 arms with cups
    parts = [hub]
    for i in range(3):
        angle = i * (2 * math.pi / 3)
        
        # Arm
        bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=0.4)
        arm = bpy.context.active_object
        arm.rotation_euler = (0, math.pi/2, angle)
        arm.location = (0.2 * math.cos(angle), 0.2 * math.sin(angle), 1.5)
        apply_transforms(arm)
        parts.append(arm)
        
        # Cup
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.08, segments=12, ring_count=6)
        cup = bpy.context.active_object
        cup.location = (0.4 * math.cos(angle), 0.4 * math.sin(angle), 1.5)
        cup.scale.x = 0.5
        apply_transforms(cup)
        parts.append(cup)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    pole.select_set(True)
    bpy.context.view_layer.objects.active = pole
    bpy.ops.object.join()
    
    uv_unwrap(pole)
    return pole


def create_thermometer_shelter():
    """Stevenson screen / instrument shelter"""
    # Main box
    bpy.ops.mesh.primitive_cube_add(size=1)
    box = bpy.context.active_object
    box.name = "ThermometerShelter"
    box.scale = (0.6, 0.6, 0.8)
    box.location.z = 1.2
    apply_transforms(box)
    
    # Make hollow
    bpy.ops.object.modifier_add(type='SOLIDIFY')
    box.modifiers["Solidify"].thickness = 0.03
    bpy.ops.object.modifier_apply(modifier="Solidify")
    
    # 4 legs
    parts = []
    for x in [-0.25, 0.25]:
        for y in [-0.25, 0.25]:
            bpy.ops.mesh.primitive_cube_add(size=1)
            leg = bpy.context.active_object
            leg.scale = (0.05, 0.05, 0.8)
            leg.location = (x, y, 0.4)
            apply_transforms(leg)
            parts.append(leg)
    
    # Roof
    bpy.ops.mesh.primitive_cube_add(size=1)
    roof = bpy.context.active_object
    roof.scale = (0.7, 0.7, 0.05)
    roof.location = (0, 0, 1.65)
    apply_transforms(roof)
    parts.append(roof)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    box.select_set(True)
    bpy.context.view_layer.objects.active = box
    bpy.ops.object.join()
    
    uv_unwrap(box)
    return box


def create_door():
    """Door with frame"""
    # Frame
    bpy.ops.mesh.primitive_cube_add(size=1)
    frame = bpy.context.active_object
    frame.name = "Door"
    frame.scale = (1.0, 0.15, 2.2)
    frame.location.z = 1.1
    apply_transforms(frame)
    
    # Door panel
    bpy.ops.mesh.primitive_cube_add(size=1)
    panel = bpy.context.active_object
    panel.scale = (0.9, 0.05, 2.0)
    panel.location = (0, -0.06, 1.0)
    apply_transforms(panel)
    
    # Handle
    bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=0.15)
    handle = bpy.context.active_object
    handle.location = (0.35, -0.12, 1.0)
    handle.rotation_euler = (math.pi/2, 0, 0)
    apply_transforms(handle)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    panel.select_set(True)
    handle.select_set(True)
    frame.select_set(True)
    bpy.context.view_layer.objects.active = frame
    bpy.ops.object.join()
    
    uv_unwrap(frame)
    return frame


def create_desk():
    """Simple desk"""
    # Top
    bpy.ops.mesh.primitive_cube_add(size=1)
    top = bpy.context.active_object
    top.name = "Desk"
    top.scale = (1.5, 0.8, 0.05)
    top.location.z = 0.75
    apply_transforms(top)
    
    # Legs
    legs = []
    positions = [(-0.65, -0.3), (-0.65, 0.3), (0.65, -0.3), (0.65, 0.3)]
    for x, y in positions:
        bpy.ops.mesh.primitive_cube_add(size=1)
        leg = bpy.context.active_object
        leg.scale = (0.05, 0.05, 0.72)
        leg.location = (x, y, 0.36)
        apply_transforms(leg)
        legs.append(leg)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for leg in legs:
        leg.select_set(True)
    top.select_set(True)
    bpy.context.view_layer.objects.active = top
    bpy.ops.object.join()
    
    uv_unwrap(top)
    return top


def create_chair():
    """Office chair"""
    # Seat
    bpy.ops.mesh.primitive_cube_add(size=1)
    seat = bpy.context.active_object
    seat.name = "Chair"
    seat.scale = (0.5, 0.5, 0.08)
    seat.location.z = 0.5
    apply_transforms(seat)
    
    # Back
    bpy.ops.mesh.primitive_cube_add(size=1)
    back = bpy.context.active_object
    back.scale = (0.5, 0.05, 0.5)
    back.location = (0, 0.22, 0.8)
    apply_transforms(back)
    
    # Pole
    bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.45)
    pole = bpy.context.active_object
    pole.location = (0, 0, 0.25)
    apply_transforms(pole)
    
    # 5-star base
    parts = [back, pole]
    for i in range(5):
        angle = i * (2 * math.pi / 5)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=0.35)
        arm = bpy.context.active_object
        arm.rotation_euler = (0, math.pi/2, angle)
        arm.location = (0.15 * math.cos(angle), 0.15 * math.sin(angle), 0.03)
        apply_transforms(arm)
        parts.append(arm)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    seat.select_set(True)
    bpy.context.view_layer.objects.active = seat
    bpy.ops.object.join()
    
    uv_unwrap(seat)
    return seat


def create_weather_station_building():
    """Main building structure"""
    # Main body
    bpy.ops.mesh.primitive_cube_add(size=1)
    building = bpy.context.active_object
    building.name = "WeatherStation"
    building.scale = (8, 6, 3)
    building.location.z = 1.5
    apply_transforms(building)
    
    # Roof
    bpy.ops.mesh.primitive_cube_add(size=1)
    roof = bpy.context.active_object
    roof.scale = (8.5, 6.5, 0.3)
    roof.location = (0, 0, 3.15)
    apply_transforms(roof)
    
    # Windows
    parts = [roof]
    for i in range(3):
        bpy.ops.mesh.primitive_cube_add(size=1)
        window = bpy.context.active_object
        window.scale = (1.2, 0.1, 1.0)
        window.location = (-3 + i * 3, -3.05, 1.8)
        apply_transforms(window)
        parts.append(window)
    
    # Door frame
    bpy.ops.mesh.primitive_cube_add(size=1)
    door = bpy.context.active_object
    door.scale = (1.2, 0.2, 2.2)
    door.location = (0, -3.0, 1.1)
    apply_transforms(door)
    parts.append(door)
    
    # Join
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    building.select_set(True)
    bpy.context.view_layer.objects.active = building
    bpy.ops.object.join()
    
    uv_unwrap(building)
    return building


def main():
    output_dir = "assets/models"
    os.makedirs(output_dir, exist_ok=True)
    
    models = [
        ("control_panel", create_control_panel),
        ("computer_terminal", create_computer_terminal),
        ("anemometer", create_anemometer),
        ("thermometer_shelter", create_thermometer_shelter),
        ("door", create_door),
        ("desk", create_desk),
        ("chair", create_chair),
        ("weather_station", create_weather_station_building),
    ]
    
    print("Generating 3D models...\n")
    
    for i, (name, func) in enumerate(models):
        print(f"  [{i+1}/{len(models)}] {name}")
        clear_scene()
        obj = func()
        export_glb(obj, f"{output_dir}/{name}.glb")
    
    print("\n✓ Model generation complete!")


if __name__ == "__main__":
    main()
```

### CLI Usage

```bash
# Generate all models
blender --background --python tools/generate_models.py

# With custom output
blender --background --python tools/generate_models.py -- --output custom/path
```

---

## 7. AUDIO GENERATION

### tools/generate_audio.sh

```bash
#!/bin/bash
# Generate procedural audio assets using sox

set -e

OUTPUT="assets/audio"
mkdir -p "$OUTPUT/ambience" "$OUTPUT/sfx" "$OUTPUT/music"

echo "Generating audio assets..."

# === AMBIENCE ===

echo "  [1/9] Wind loop..."
sox -n "$OUTPUT/ambience/wind_loop.ogg" \
    synth 30 brownnoise \
    lowpass 400 highpass 50 \
    tremolo 0.5 30 \
    fade 0.5 30 0.5 \
    repeat 2

echo "  [2/9] Metal creak..."
sox -n "$OUTPUT/ambience/metal_creak.ogg" \
    synth 2 sine 80-200 \
    bend 0.5,300,0.5 \
    overdrive 20 reverb 50 \
    fade 0.1 2 0.3

echo "  [3/9] Electronic hum..."
sox -n "$OUTPUT/ambience/electronic_hum.ogg" \
    synth 10 sine 60 sine 120 sine 180 \
    remix - lowpass 500 \
    fade 0.5 10 0.5

# === SFX ===

echo "  [4/9] Footstep snow..."
sox -n "$OUTPUT/sfx/footstep_snow.ogg" \
    synth 0.15 pinknoise \
    lowpass 2000 highpass 200 \
    fade 0.01 0.15 0.05

echo "  [5/9] Footstep metal..."
sox -n "$OUTPUT/sfx/footstep_metal.ogg" \
    synth 0.1 sine 200 synth 0.1 noise \
    remix - highpass 500 \
    fade 0 0.1 0.08

echo "  [6/9] Door open..."
sox -n "$OUTPUT/sfx/door_open.ogg" \
    synth 0.8 sine 100-300 \
    bend 0,200,0.5 \
    overdrive 10 reverb 30 \
    fade 0.05 0.8 0.2

echo "  [7/9] Switch click..."
sox -n "$OUTPUT/sfx/switch_click.ogg" \
    synth 0.02 square 1000 \
    fade 0 0.02 0.01

echo "  [8/9] Radio static..."
sox -n "$OUTPUT/sfx/radio_static.ogg" \
    synth 5 whitenoise \
    lowpass 8000 highpass 100 \
    tremolo 20 80 \
    fade 0.1 5 0.1

# === MUSIC ===

echo "  [9/9] Tension drone..."
sox -n "$OUTPUT/music/tension_drone.ogg" \
    synth 60 sine 55 sine 82.5 sine 110 \
    remix - tremolo 0.1 20 reverb 70 \
    fade 2 60 2

echo ""
echo "✓ Audio generation complete!"
```

### CLI Usage

```bash
chmod +x tools/generate_audio.sh
./tools/generate_audio.sh
```

---

## 8. GODOT PROJECT CONFIGURATION

### project.godot

```ini
config_version=5

[application]
config/name="Signal Lost"
config/description="Survival horror in an abandoned Arctic weather station"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.2", "Forward Plus")

[autoload]
GameManager="*res://scripts/systems/game_manager.gd"
AudioManager="*res://scripts/systems/audio_manager.gd"

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"

[input]
move_forward={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":87,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
move_back={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":83,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":65,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":68,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
interact={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":69,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
flashlight={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":70,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
pause={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194305,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
sprint={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194325,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}

[layer_names]
3d_physics/layer_1="World"
3d_physics/layer_2="Player"
3d_physics/layer_3="Interactable"

[rendering]
renderer/rendering_method="forward_plus"
anti_aliasing/quality/msaa_3d=2
environment/defaults/default_clear_color=Color(0.02, 0.03, 0.05, 1)
```

### default_env.tres

```
[gd_resource type="Environment" format=3]

[resource]
background_mode = 1
background_color = Color(0.03, 0.05, 0.08, 1)
ambient_light_source = 2
ambient_light_color = Color(0.12, 0.15, 0.22, 1)
ambient_light_energy = 0.25

fog_enabled = true
fog_light_color = Color(0.5, 0.55, 0.65, 1)
fog_density = 0.015
fog_height = 8.0
fog_height_density = 0.1

volumetric_fog_enabled = true
volumetric_fog_density = 0.025
volumetric_fog_albedo = Color(0.6, 0.65, 0.75, 1)

ssao_enabled = true
ssao_radius = 2.0
ssao_intensity = 2.5

glow_enabled = true
glow_intensity = 0.4
glow_bloom = 0.15
```

---

## 9. GAME SCRIPTS (GDSCRIPT)

### scripts/player/player_controller.gd

```gdscript
extends CharacterBody3D

@export_group("Movement")
@export var walk_speed := 4.0
@export var sprint_speed := 7.0
@export var acceleration := 10.0
@export var deceleration := 12.0

@export_group("Mouse")
@export var mouse_sensitivity := 0.002
@export var max_pitch := 89.0

@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay

var current_speed := walk_speed
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    flashlight.visible = false


func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera.rotate_x(-event.relative.y * mouse_sensitivity)
        camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-max_pitch), deg_to_rad(max_pitch))
    
    if event.is_action_pressed("pause"):
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    
    if event.is_action_pressed("flashlight"):
        flashlight.visible = !flashlight.visible
        AudioManager.play_sfx("switch_click")
    
    if event.is_action_pressed("interact"):
        _try_interact()


func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    
    current_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
    
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    if direction:
        velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
        velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, deceleration * delta)
        velocity.z = move_toward(velocity.z, 0, deceleration * delta)
    
    move_and_slide()


func _try_interact() -> void:
    if interaction_ray.is_colliding():
        var collider = interaction_ray.get_collider()
        if collider.has_method("interact"):
            collider.interact(self)
```

### scripts/interaction/interactable.gd

```gdscript
class_name Interactable
extends StaticBody3D

@export var interaction_text := "Interact"
@export var one_shot := false

var has_been_used := false
signal interacted(player)


func _ready() -> void:
    add_to_group("interactable")
    collision_layer = 4


func get_interaction_text() -> String:
    return interaction_text


func interact(player: Node) -> void:
    if one_shot and has_been_used:
        return
    has_been_used = true
    _on_interact(player)
    interacted.emit(player)


func _on_interact(_player: Node) -> void:
    pass  # Override in child classes
```

### scripts/interaction/door.gd

```gdscript
extends Interactable

@export var open_angle := 90.0
@export var open_speed := 2.0
@export var locked := false

var is_open := false
var target_rotation := 0.0
var initial_rotation: float


func _ready() -> void:
    super._ready()
    initial_rotation = rotation.y
    interaction_text = "Locked" if locked else "Open Door"


func _process(delta: float) -> void:
    rotation.y = lerp_angle(rotation.y, target_rotation, open_speed * delta)


func _on_interact(_player: Node) -> void:
    if locked:
        AudioManager.play_sfx("door_locked")
        return
    
    is_open = !is_open
    target_rotation = initial_rotation + deg_to_rad(open_angle if is_open else 0)
    interaction_text = "Close Door" if is_open else "Open Door"
    AudioManager.play_sfx("door_open")
```

### scripts/interaction/terminal.gd

```gdscript
extends Interactable

@export var terminal_id := ""
@export_multiline var log_entries: Array[String] = []

var current_entry := 0


func _ready() -> void:
    super._ready()
    interaction_text = "Access Terminal"


func _on_interact(_player: Node) -> void:
    GameManager.open_terminal(self)


func get_current_log() -> String:
    if log_entries.is_empty():
        return "NO DATA AVAILABLE"
    return log_entries[current_entry]


func next_entry() -> void:
    current_entry = (current_entry + 1) % log_entries.size()


func previous_entry() -> void:
    current_entry -= 1
    if current_entry < 0:
        current_entry = log_entries.size() - 1
```

### scripts/systems/game_manager.gd

```gdscript
extends Node

signal prompt_changed(text: String, visible: bool)
signal terminal_opened(terminal: Node)
signal terminal_closed

var inventory: Array[String] = []
var discovered_logs: Array[String] = []
var game_flags: Dictionary = {}


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func show_interaction_prompt(text: String) -> void:
    prompt_changed.emit(text, true)


func hide_interaction_prompt() -> void:
    prompt_changed.emit("", false)


func has_item(item_id: String) -> bool:
    return item_id in inventory


func add_item(item_id: String) -> void:
    if not has_item(item_id):
        inventory.append(item_id)


func set_flag(flag: String, value: bool = true) -> void:
    game_flags[flag] = value


func get_flag(flag: String) -> bool:
    return game_flags.get(flag, false)


func open_terminal(terminal: Node) -> void:
    terminal_opened.emit(terminal)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    get_tree().paused = true


func close_terminal() -> void:
    terminal_closed.emit()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    get_tree().paused = false
```

### scripts/systems/audio_manager.gd

```gdscript
extends Node

const SFX_PATH := "res://assets/audio/sfx/"
const AMBIENCE_PATH := "res://assets/audio/ambience/"

var sfx_cache: Dictionary = {}
var ambience_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
    _preload_sfx("switch_click")
    _preload_sfx("door_open")
    _preload_sfx("footstep_snow")
    _preload_sfx("footstep_metal")
    _preload_sfx("radio_static")


func _preload_sfx(name: String) -> void:
    var path = SFX_PATH + name + ".ogg"
    if ResourceLoader.exists(path):
        sfx_cache[name] = load(path)


func play_sfx(name: String, volume_db: float = 0.0) -> void:
    var stream = sfx_cache.get(name)
    if not stream:
        var path = SFX_PATH + name + ".ogg"
        if ResourceLoader.exists(path):
            stream = load(path)
            sfx_cache[name] = stream
    
    if stream:
        var player = AudioStreamPlayer.new()
        player.stream = stream
        player.volume_db = volume_db
        add_child(player)
        player.play()
        player.finished.connect(player.queue_free)


func start_ambience(name: String, fade_time: float = 2.0) -> void:
    var path = AMBIENCE_PATH + name + ".ogg"
    if ResourceLoader.exists(path):
        var player = AudioStreamPlayer.new()
        player.stream = load(path)
        player.volume_db = -80
        add_child(player)
        player.play()
        ambience_players.append(player)
        
        var tween = create_tween()
        tween.tween_property(player, "volume_db", 0.0, fade_time)


func stop_all_ambience(fade_time: float = 2.0) -> void:
    for player in ambience_players:
        var tween = create_tween()
        tween.tween_property(player, "volume_db", -80.0, fade_time)
        tween.tween_callback(player.queue_free)
    ambience_players.clear()
```

### scripts/environment/anomaly_controller.gd

```gdscript
extends Node

signal anomaly_started(type: String)
signal anomaly_ended(type: String)

@export var min_interval := 30.0
@export var max_interval := 120.0

var timer := 0.0
var next_time := 0.0


func _ready() -> void:
    randomize()
    _schedule_next()


func _process(delta: float) -> void:
    timer += delta
    if timer >= next_time:
        _trigger_random()
        _schedule_next()


func _schedule_next() -> void:
    timer = 0.0
    next_time = randf_range(min_interval, max_interval)


func _trigger_random() -> void:
    var types = ["flicker", "static", "cold"]
    var chosen = types[randi() % types.size()]
    
    match chosen:
        "flicker":
            await _flicker_lights()
        "static":
            await _radio_burst()
        "cold":
            await _temperature_drop()


func _flicker_lights() -> void:
    anomaly_started.emit("flicker")
    var lights = get_tree().get_nodes_in_group("flickerable")
    
    for i in range(randi_range(3, 8)):
        for light in lights:
            light.visible = randf() > 0.5
        await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
    
    for light in lights:
        light.visible = true
    anomaly_ended.emit("flicker")


func _radio_burst() -> void:
    anomaly_started.emit("static")
    AudioManager.play_sfx("radio_static")
    await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
    anomaly_ended.emit("static")


func _temperature_drop() -> void:
    anomaly_started.emit("cold")
    # Trigger frost overlay shader
    await get_tree().create_timer(8.0).timeout
    anomaly_ended.emit("cold")
```

---

## 10. SCENE FILES

### scenes/main.tscn

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/environment/anomaly_controller.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="2"]
[ext_resource type="Environment" path="res://default_env.tres" id="3"]

[node name="Main" type="Node3D"]

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = ExtResource("3")

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.866, -0.433, 0.25, 0, 0.5, 0.866, -0.5, -0.75, 0.433, 10, 20, 10)
light_color = Color(0.7, 0.75, 0.9, 1)
light_energy = 0.2
shadow_enabled = true

[node name="Player" parent="." instance=ExtResource("2")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 5)

[node name="AnomalyController" type="Node" parent="."]
script = ExtResource("1")

[node name="Ground" type="CSGBox3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)
use_collision = true
size = Vector3(100, 1, 100)
```

### scenes/player/player.tscn

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/player/player_controller.gd" id="1"]

[sub_resource type="CapsuleShape3D" id="1"]
radius = 0.35
height = 1.8

[node name="Player" type="CharacterBody3D"]
collision_layer = 2
script = ExtResource("1")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)
shape = SubResource("1")

[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.6, 0)
current = true
fov = 75.0

[node name="Flashlight" type="SpotLight3D" parent="Camera3D"]
light_color = Color(1, 0.95, 0.85, 1)
light_energy = 2.0
spot_range = 20.0
spot_angle = 30.0

[node name="InteractionRay" type="RayCast3D" parent="Camera3D"]
target_position = Vector3(0, 0, -3)
collision_mask = 4
```

---

## 11. SHADERS

### assets/shaders/screen_static.gdshader

```glsl
shader_type spatial;
render_mode unshaded;

uniform sampler2D noise_texture;
uniform float speed : hint_range(0.0, 50.0) = 15.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.8;
uniform vec3 tint : source_color = vec3(0.2, 1.0, 0.3);

void fragment() {
    vec2 uv = UV;
    uv.y += TIME * speed;
    
    float noise = texture(noise_texture, fract(uv)).r;
    float scanline = sin(UV.y * 800.0) * 0.04 + 1.0;
    
    vec3 color = tint * noise * scanline * intensity;
    ALBEDO = color;
    EMISSION = color * 2.0;
}
```

### assets/shaders/frost_overlay.gdshader

```glsl
shader_type canvas_item;

uniform float frost_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D frost_texture;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
    vec4 screen = texture(screen_texture, SCREEN_UV);
    vec4 frost = texture(frost_texture, UV);
    
    float edge_frost = pow(length(UV - 0.5) * 1.5, 2.0);
    float frost_mask = clamp(edge_frost * frost_amount + frost.r * frost_amount * 0.5, 0.0, 1.0);
    
    vec3 frost_color = vec3(0.8, 0.85, 0.95);
    COLOR.rgb = mix(screen.rgb, frost_color, frost_mask);
    COLOR.a = 1.0;
}
```

### assets/shaders/snow_ground.gdshader

```glsl
shader_type spatial;

uniform sampler2D albedo_texture : source_color;
uniform sampler2D normal_texture : hint_normal;
uniform sampler2D roughness_texture;
uniform float snow_sparkle : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    ALBEDO = texture(albedo_texture, UV).rgb;
    NORMAL_MAP = texture(normal_texture, UV).rgb;
    ROUGHNESS = texture(roughness_texture, UV).r;
    
    // Sparkle effect
    float sparkle = fract(sin(dot(UV * 100.0, vec2(12.9898, 78.233))) * 43758.5453);
    sparkle = step(0.98, sparkle) * snow_sparkle;
    EMISSION = vec3(sparkle);
}
```

---

## 12. BUILD AND EXPORT

### export_presets.cfg

```ini
[preset.0]
name="Linux"
platform="Linux/X11"
runnable=true
export_filter="all_resources"
export_path="builds/linux/signal_lost.x86_64"

[preset.0.options]
binary_format/embed_pck=true

[preset.1]
name="Windows"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
export_path="builds/windows/signal_lost.exe"

[preset.1.options]
binary_format/embed_pck=true
binary_format/architecture="x86_64"
```

### CLI Export Commands

```bash
# Import resources first
godot --headless --import

# Export Linux
godot --headless --export-release "Linux" builds/linux/signal_lost.x86_64

# Export Windows
godot --headless --export-release "Windows" builds/windows/signal_lost.exe
```

---

## 13. COMPLETE BUILD SCRIPT

### tools/build_all.sh

```bash
#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "========================================"
echo "  SIGNAL LOST - Complete Build Pipeline"
echo "========================================"

# Check dependencies
check_deps() {
    echo "[CHECK] Dependencies..."
    command -v python3 >/dev/null || { echo "ERROR: python3 required"; exit 1; }
    command -v blender >/dev/null || { echo "ERROR: blender required"; exit 1; }
    command -v godot >/dev/null || { echo "ERROR: godot required"; exit 1; }
    
    python3 -c "import PIL, numpy, scipy" 2>/dev/null || {
        echo "Installing Python packages..."
        pip install pillow numpy scipy --break-system-packages -q
    }
    echo "[CHECK] OK"
}

# Generate textures
gen_textures() {
    echo ""
    echo "[1/4] Generating textures..."
    python3 tools/generate_textures.py -o assets/textures -s 1024
}

# Generate models
gen_models() {
    echo ""
    echo "[2/4] Generating 3D models..."
    blender --background --python tools/generate_models.py
}

# Generate audio
gen_audio() {
    echo ""
    echo "[3/4] Generating audio..."
    if command -v sox >/dev/null; then
        bash tools/generate_audio.sh
    else
        echo "  Skipped (sox not installed)"
    fi
}

# Build game
build_game() {
    echo ""
    echo "[4/4] Building game..."
    mkdir -p builds/linux builds/windows
    
    godot --headless --import 2>/dev/null || true
    godot --headless --export-release "Linux" builds/linux/signal_lost.x86_64 2>/dev/null || true
    godot --headless --export-release "Windows" builds/windows/signal_lost.exe 2>/dev/null || true
}

# Main
main() {
    START=$(date +%s)
    
    check_deps
    
    case "${1:-all}" in
        textures) gen_textures ;;
        models) gen_models ;;
        audio) gen_audio ;;
        build) build_game ;;
        all)
            gen_textures
            gen_models
            gen_audio
            build_game
            ;;
        *)
            echo "Usage: $0 [textures|models|audio|build|all]"
            exit 1
            ;;
    esac
    
    END=$(date +%s)
    echo ""
    echo "========================================"
    echo "  Complete in $((END-START))s"
    echo "========================================"
}

main "$@"
```

---

## 14. ASSET PROMPT LIBRARY

Quick reference for AI image generation prompts:

### Metals

```
# Clean brushed aluminum
seamless tileable texture of brushed aluminum metal surface, clean industrial, subtle linear scratches, top-down view, flat even lighting, PBR game texture 1024x1024

# Heavy rust
seamless tileable texture of heavily corroded rusted steel, orange-brown rust eating through gray metal, industrial decay, top-down view, flat even lighting, PBR game texture 1024x1024

# Painted metal wall
seamless tileable texture of painted metal industrial wall, gray-green paint with chips and scratches exposing metal underneath, top-down view, flat even lighting, PBR game texture 1024x1024

# Riveted metal plate
seamless tileable texture of riveted steel plate, rows of rivets on gray metal, industrial construction, top-down view, flat even lighting, PBR game texture 1024x1024
```

### Surfaces

```
# Concrete floor
seamless tileable texture of poured concrete floor, light gray with subtle cracks and stains, industrial warehouse, top-down view, flat even lighting, PBR game texture 1024x1024

# Snow ground
seamless tileable texture of packed arctic snow, white with subtle blue shadows, wind-swept texture, top-down view, flat even lighting, PBR game texture 1024x1024

# Glacier ice
seamless tileable texture of blue glacier ice surface, cracks and trapped air bubbles visible, frozen, top-down view, flat even lighting, PBR game texture 1024x1024

# Wooden planks
seamless tileable texture of weathered wooden floor planks, gray aged wood with gaps between boards, top-down view, flat even lighting, PBR game texture 1024x1024
```

### Equipment

```
# Control panel surface
seamless tileable texture of scientific instrument panel surface, brushed metal with button holes and switch cutouts, 1970s NASA aesthetic, top-down view, flat even lighting, PBR game texture 1024x1024

# CRT screen bezel
seamless tileable texture of beige plastic computer bezel, vintage 1980s computer housing, slight yellowing, top-down view, flat even lighting, PBR game texture 1024x1024

# Rubber flooring
seamless tileable texture of black industrial rubber flooring, raised circular pattern for grip, workshop floor, top-down view, flat even lighting, PBR game texture 1024x1024
```

---

## QUICK START

```bash
# 1. Clone/create project structure
mkdir signal_lost && cd signal_lost

# 2. Create all directories
mkdir -p assets/{textures,models,audio,shaders,fonts}
mkdir -p scenes/{player,environment,props,ui}
mkdir -p scripts/{player,interaction,systems,environment}
mkdir -p tools builds

# 3. Copy all files from this guide to their locations

# 4. Run complete build
chmod +x tools/build_all.sh
./tools/build_all.sh all

# 5. Play!
./builds/linux/signal_lost.x86_64
```

---

*End of Guide*
