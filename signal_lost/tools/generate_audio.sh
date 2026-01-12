#!/bin/bash
#
# SIGNAL LOST - Procedural Audio Generator
# Generate game audio assets using sox
#
# Improvements:
# - Added door_locked sound effect
# - Added heartbeat effect for tension
# - Added more atmospheric sounds
# - Better organization and logging
#

set -e

OUTPUT="${1:-assets/audio}"
mkdir -p "$OUTPUT/ambience" "$OUTPUT/sfx" "$OUTPUT/music"

echo ""
echo "=================================================="
echo "  SIGNAL LOST - Audio Generator"
echo "=================================================="
echo ""

TOTAL=12
CURRENT=0

progress() {
    CURRENT=$((CURRENT + 1))
    echo "  [$CURRENT/$TOTAL] $1..."
}

# === AMBIENCE ===

progress "Wind loop (arctic exterior)"
sox -n "$OUTPUT/ambience/wind_loop.ogg" \
    synth 30 brownnoise \
    lowpass 400 highpass 50 \
    tremolo 0.5 30 \
    fade 0.5 30 0.5 \
    repeat 2

progress "Metal creak (building stress)"
sox -n "$OUTPUT/ambience/metal_creak.ogg" \
    synth 2 sine 80-200 \
    bend 0.5,300,0.5 \
    overdrive 20 reverb 50 \
    fade 0.1 2 0.3

progress "Electronic hum (equipment)"
sox -n "$OUTPUT/ambience/electronic_hum.ogg" \
    synth 10 sine 60 sine 120 sine 180 \
    remix - lowpass 500 \
    fade 0.5 10 0.5

# === SFX ===

progress "Footstep snow"
sox -n "$OUTPUT/sfx/footstep_snow.ogg" \
    synth 0.15 pinknoise \
    lowpass 2000 highpass 200 \
    fade 0.01 0.15 0.05

progress "Footstep metal"
sox -n "$OUTPUT/sfx/footstep_metal.ogg" \
    synth 0.1 sine 200 synth 0.1 noise \
    remix - highpass 500 \
    fade 0 0.1 0.08

progress "Door open"
sox -n "$OUTPUT/sfx/door_open.ogg" \
    synth 0.8 sine 100-300 \
    bend 0,200,0.5 \
    overdrive 10 reverb 30 \
    fade 0.05 0.8 0.2

progress "Door locked (IMPROVEMENT: new sound)"
sox -n "$OUTPUT/sfx/door_locked.ogg" \
    synth 0.15 square 150 synth 0.15 square 100 \
    remix - \
    fade 0 0.15 0.05

progress "Switch click"
sox -n "$OUTPUT/sfx/switch_click.ogg" \
    synth 0.02 square 1000 \
    fade 0 0.02 0.01

progress "Radio static"
sox -n "$OUTPUT/sfx/radio_static.ogg" \
    synth 5 whitenoise \
    lowpass 8000 highpass 100 \
    tremolo 20 80 \
    fade 0.1 5 0.1

# === MUSIC / ATMOSPHERE ===

progress "Tension drone (main theme)"
sox -n "$OUTPUT/music/tension_drone.ogg" \
    synth 60 sine 55 sine 82.5 sine 110 \
    remix - tremolo 0.1 20 reverb 70 \
    fade 2 60 2

progress "Heartbeat (IMPROVEMENT: tension effect)"
sox -n "$OUTPUT/sfx/heartbeat.ogg" \
    synth 0.12 sine 60 synth 0.08 sine 50 \
    remix - \
    delay 0 0.15 \
    reverb 20 \
    fade 0.02 0.4 0.1 \
    repeat 4

progress "Distant rumble (IMPROVEMENT: ambience)"
sox -n "$OUTPUT/ambience/distant_rumble.ogg" \
    synth 8 brownnoise \
    lowpass 100 \
    tremolo 0.3 50 \
    reverb 80 \
    fade 1 8 1

echo ""
echo "=================================================="
echo "  Audio generation complete!"
echo "  Output: $OUTPUT/"
echo "=================================================="
echo ""
