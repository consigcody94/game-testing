#!/bin/bash
#
# SIGNAL LOST - Complete Build Pipeline
# Builds all assets and exports the game
#
# Usage:
#   ./build_all.sh [textures|models|audio|build|all]
#
# Improvements:
# - Better error handling with specific messages
# - Colored output for better visibility
# - Timing for each step
# - Dependency verification
#

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_step() {
    echo -e "${YELLOW}[$1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_deps() {
    print_step "CHECK" "Verifying dependencies..."

    local missing=0

    if ! command -v python3 &>/dev/null; then
        print_error "python3 is required but not installed"
        missing=1
    else
        print_success "python3 found: $(python3 --version 2>&1)"
    fi

    if ! command -v blender &>/dev/null; then
        print_error "blender is required but not installed"
        missing=1
    else
        print_success "blender found: $(blender --version 2>&1 | head -1)"
    fi

    if ! command -v sox &>/dev/null; then
        echo -e "${YELLOW}[WARN]${NC} sox not found - audio generation will be skipped"
    else
        print_success "sox found: $(sox --version 2>&1 | head -1)"
    fi

    # Check Python packages
    if ! python3 -c "import PIL, numpy" 2>/dev/null; then
        print_step "INSTALL" "Installing required Python packages..."
        pip3 install pillow numpy scipy --break-system-packages -q 2>/dev/null || \
        pip3 install pillow numpy scipy -q 2>/dev/null || \
        pip install pillow numpy scipy -q
    fi
    print_success "Python packages OK"

    if [ $missing -eq 1 ]; then
        print_error "Missing required dependencies. Please install them first."
        exit 1
    fi

    echo ""
}

# Generate textures
gen_textures() {
    print_step "1/4" "Generating textures..."
    local start=$(date +%s)

    python3 tools/generate_textures.py -o assets/textures -s 1024

    local end=$(date +%s)
    print_success "Textures generated in $((end-start))s"
}

# Generate models
gen_models() {
    print_step "2/4" "Generating 3D models..."
    local start=$(date +%s)

    blender --background --python tools/generate_models.py 2>&1 | grep -E "^\s+\[|Exported|complete"

    local end=$(date +%s)
    print_success "Models generated in $((end-start))s"
}

# Generate audio
gen_audio() {
    print_step "3/4" "Generating audio..."
    local start=$(date +%s)

    if command -v sox &>/dev/null; then
        chmod +x tools/generate_audio.sh
        bash tools/generate_audio.sh assets/audio
    else
        echo -e "${YELLOW}  Skipped (sox not installed)${NC}"
    fi

    local end=$(date +%s)
    print_success "Audio generated in $((end-start))s"
}

# Build game
build_game() {
    print_step "4/4" "Building game..."

    if ! command -v godot &>/dev/null; then
        echo -e "${YELLOW}  Skipped (godot not installed)${NC}"
        echo "  To build, install Godot 4.2+ and run:"
        echo "    godot --headless --export-release \"Linux\" builds/linux/signal_lost.x86_64"
        return
    fi

    mkdir -p builds/linux builds/windows

    echo "  Importing resources..."
    godot --headless --import 2>/dev/null || true

    echo "  Exporting Linux build..."
    godot --headless --export-release "Linux" builds/linux/signal_lost.x86_64 2>/dev/null || \
        echo -e "${YELLOW}  Linux export skipped (no export template)${NC}"

    echo "  Exporting Windows build..."
    godot --headless --export-release "Windows" builds/windows/signal_lost.exe 2>/dev/null || \
        echo -e "${YELLOW}  Windows export skipped (no export template)${NC}"

    print_success "Build process completed"
}

# Print usage
usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  textures  Generate PBR textures only"
    echo "  models    Generate 3D models only"
    echo "  audio     Generate audio assets only"
    echo "  build     Export game builds only"
    echo "  all       Run complete pipeline (default)"
    echo ""
    echo "Examples:"
    echo "  $0              # Run everything"
    echo "  $0 textures     # Generate only textures"
    echo "  $0 models       # Generate only 3D models"
}

# Main entry point
main() {
    local START=$(date +%s)

    print_header "SIGNAL LOST - Build Pipeline"

    check_deps

    case "${1:-all}" in
        textures)
            gen_textures
            ;;
        models)
            gen_models
            ;;
        audio)
            gen_audio
            ;;
        build)
            build_game
            ;;
        all)
            gen_textures
            gen_models
            gen_audio
            build_game
            ;;
        -h|--help|help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown command: $1"
            usage
            exit 1
            ;;
    esac

    local END=$(date +%s)

    print_header "Build Complete!"
    echo "  Total time: $((END-START)) seconds"
    echo "  Output: $PROJECT_DIR/assets/"
    echo ""
}

main "$@"
