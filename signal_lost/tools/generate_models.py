#!/usr/bin/env python3
"""
Blender Headless Model Generator for SIGNAL LOST
Run: blender --background --python tools/generate_models.py

Improvements:
- Added radio equipment model
- Added filing cabinet model
- Better UV unwrapping with margin control
- Added command line argument support
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


def uv_unwrap(obj, island_margin=0.02):
    """Smart UV unwrap object with configurable margin"""
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(island_margin=island_margin)
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
    """Scientific instrument control panel with buttons and switches"""
    # Main body
    bpy.ops.mesh.primitive_cube_add(size=1)
    panel = bpy.context.active_object
    panel.name = "ControlPanel"
    panel.scale = (1.2, 0.3, 0.8)
    apply_transforms(panel)

    # Bevel edges for realism
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

    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    for obj in buttons + [screen]:
        obj.select_set(True)
    panel.select_set(True)
    bpy.context.view_layer.objects.active = panel
    bpy.ops.object.join()

    uv_unwrap(panel)
    return panel


def create_computer_terminal():
    """Retro CRT computer terminal - 1970s/80s aesthetic"""
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

    # CRT screen (slightly recessed)
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

    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [bezel, screen, keyboard]:
        obj.select_set(True)
    monitor.select_set(True)
    bpy.context.view_layer.objects.active = monitor
    bpy.ops.object.join()

    uv_unwrap(monitor)
    return monitor


def create_anemometer():
    """Wind speed measurement device with rotating cups"""
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

        # Cup (hemisphere-like)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.08, segments=12, ring_count=6)
        cup = bpy.context.active_object
        cup.location = (0.4 * math.cos(angle), 0.4 * math.sin(angle), 1.5)
        cup.scale.x = 0.5
        apply_transforms(cup)
        parts.append(cup)

    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    pole.select_set(True)
    bpy.context.view_layer.objects.active = pole
    bpy.ops.object.join()

    uv_unwrap(pole)
    return pole


def create_thermometer_shelter():
    """Stevenson screen / instrument shelter for weather measurements"""
    # Main box
    bpy.ops.mesh.primitive_cube_add(size=1)
    box = bpy.context.active_object
    box.name = "ThermometerShelter"
    box.scale = (0.6, 0.6, 0.8)
    box.location.z = 1.2
    apply_transforms(box)

    # Make hollow using solidify
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

    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    box.select_set(True)
    bpy.context.view_layer.objects.active = box
    bpy.ops.object.join()

    uv_unwrap(box)
    return box


def create_door():
    """Industrial door with frame and handle"""
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

    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    panel.select_set(True)
    handle.select_set(True)
    frame.select_set(True)
    bpy.context.view_layer.objects.active = frame
    bpy.ops.object.join()

    uv_unwrap(frame)
    return frame


def create_desk():
    """Simple metal desk"""
    # Top surface
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

    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    for leg in legs:
        leg.select_set(True)
    top.select_set(True)
    bpy.context.view_layer.objects.active = top
    bpy.ops.object.join()

    uv_unwrap(top)
    return top


def create_chair():
    """Office/swivel chair"""
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

    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    seat.select_set(True)
    bpy.context.view_layer.objects.active = seat
    bpy.ops.object.join()

    uv_unwrap(seat)
    return seat


def create_weather_station_building():
    """Main building structure - Arctic research station"""
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

    # Windows (3 on front side)
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

    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    building.select_set(True)
    bpy.context.view_layer.objects.active = building
    bpy.ops.object.join()

    uv_unwrap(building, island_margin=0.01)
    return building


def create_radio_equipment():
    """IMPROVEMENT: Radio transmitter/receiver unit"""
    # Main chassis
    bpy.ops.mesh.primitive_cube_add(size=1)
    radio = bpy.context.active_object
    radio.name = "RadioEquipment"
    radio.scale = (0.8, 0.4, 0.5)
    apply_transforms(radio)

    # Frequency display
    bpy.ops.mesh.primitive_cube_add(size=1)
    display = bpy.context.active_object
    display.scale = (0.3, 0.02, 0.1)
    display.location = (0.15, -0.19, 0.15)
    apply_transforms(display)

    # Tuning knobs
    parts = [display]
    for i in range(2):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.04)
        knob = bpy.context.active_object
        knob.location = (-0.25 + i * 0.2, -0.2, -0.1)
        knob.rotation_euler = (math.pi/2, 0, 0)
        apply_transforms(knob)
        parts.append(knob)

    # Antenna mount
    bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=0.3)
    antenna = bpy.context.active_object
    antenna.location = (0.35, 0, 0.4)
    apply_transforms(antenna)
    parts.append(antenna)

    # Speaker grille (simplified as cube)
    bpy.ops.mesh.primitive_cube_add(size=1)
    grille = bpy.context.active_object
    grille.scale = (0.2, 0.02, 0.2)
    grille.location = (-0.2, -0.19, 0.1)
    apply_transforms(grille)
    parts.append(grille)

    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    radio.select_set(True)
    bpy.context.view_layer.objects.active = radio
    bpy.ops.object.join()

    uv_unwrap(radio)
    return radio


def create_filing_cabinet():
    """IMPROVEMENT: Metal filing cabinet for documents"""
    # Main body
    bpy.ops.mesh.primitive_cube_add(size=1)
    cabinet = bpy.context.active_object
    cabinet.name = "FilingCabinet"
    cabinet.scale = (0.5, 0.6, 1.3)
    cabinet.location.z = 0.65
    apply_transforms(cabinet)

    # Drawers (3 drawers)
    parts = []
    for i in range(3):
        # Drawer front
        bpy.ops.mesh.primitive_cube_add(size=1)
        drawer = bpy.context.active_object
        drawer.scale = (0.48, 0.02, 0.38)
        drawer.location = (0, -0.29, 0.25 + i * 0.42)
        apply_transforms(drawer)
        parts.append(drawer)

        # Drawer handle
        bpy.ops.mesh.primitive_cube_add(size=1)
        handle = bpy.context.active_object
        handle.scale = (0.12, 0.02, 0.02)
        handle.location = (0, -0.32, 0.25 + i * 0.42)
        apply_transforms(handle)
        parts.append(handle)

    # Join all parts
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    cabinet.select_set(True)
    bpy.context.view_layer.objects.active = cabinet
    bpy.ops.object.join()

    uv_unwrap(cabinet)
    return cabinet


def main():
    # Parse command line arguments (after --)
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []

    # Default output directory
    output_dir = "assets/models"

    # Check for custom output path
    for i, arg in enumerate(argv):
        if arg in ["--output", "-o"] and i + 1 < len(argv):
            output_dir = argv[i + 1]

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
        ("radio_equipment", create_radio_equipment),
        ("filing_cabinet", create_filing_cabinet),
    ]

    print("\n" + "=" * 50)
    print("  SIGNAL LOST - 3D Model Generator")
    print("=" * 50 + "\n")

    for i, (name, func) in enumerate(models):
        print(f"  [{i+1}/{len(models)}] Generating {name}...")
        clear_scene()
        obj = func()
        export_glb(obj, f"{output_dir}/{name}.glb")

    print("\n" + "=" * 50)
    print("  Model generation complete!")
    print(f"  Output: {output_dir}/")
    print("=" * 50 + "\n")


if __name__ == "__main__":
    main()
