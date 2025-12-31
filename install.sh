#!/bin/bash

BUILD_DIR="build"
DEFAULT_JOBS=12
ENABLE_MCC=OFF
ENABLE_NVCC=OFF
ENABLE_DEBUG=OFF
ENABLE_CUBRIDGE=OFF

# Function to print usage information
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -R       : Rebuild (clean build directory and rebuild)"
    echo "  -j N     : Number of parallel jobs for make (default: j12)"
    echo "  -h       : Display this help message"
    echo "  -m       : Enable MCC Compiler (default: OFF)"
    echo "  -n       : Enable NVCC Compiler (default: OFF), Cannot enable both MCC and NVCC at the same time"
    echo "  -d       : Enable Debug Mode (default: OFF)"
    exit 1
}

# Process command line arguments
while getopts "Rj:nmxdh" opt; do
    case $opt in
        R)
            REBUILD=true
            ;;
        j)
            JOBS=$OPTARG
            ;;
        m)
            ENABLE_MCC=ON
            ;;
        n)
            ENABLE_NVCC=ON
            ;;
        d)
            ENABLE_DEBUG=ON
            ;;
        x)
            ENABLE_NVCC=OFF
            ENABLE_MCC=OFF
            ENABLE_CUBRIDGE=ON
            ;;
        h)
            print_usage
            ;;
        *)
            print_usage
            ;;
    esac
done

if [ -z "$JOBS" ]; then
    JOBS=$DEFAULT_JOBS
fi

# Check if the build directory exists, if not, create it
if [ ! -d "$BUILD_DIR" ]; then
    echo "Creating '$BUILD_DIR' directory..."
    mkdir "$BUILD_DIR"
    cd "$BUILD_DIR"
    if [ "$ENABLE_CUBRIDGE" = "ON" ]; then
        cmake_maca .. "-DENABLE_CUBRIDGE=ON" "-DENABLE_DEBUG=$ENABLE_DEBUG" "-DTEST_ON_METAX=ON"
    else
        cmake .. "-DENABLE_MCC=$ENABLE_MCC" "-DENABLE_DEBUG=$ENABLE_DEBUG" "-DENABLE_NVCC=$ENABLE_NVCC"
    fi
    cd ..
fi

# Navigate to build directory
cd "$BUILD_DIR"

# If REBUILD is true, clean build directory and rebuild
if [ ! -f "Makefile" ] || [ "$REBUILD" = true ]; then
    if [ "$ENABLE_CUBRIDGE" = "ON" ]; then
        cmake_maca .. "-DENABLE_CUBRIDGE=ON" "-DENABLE_DEBUG=$ENABLE_DEBUG" "-DTEST_ON_METAX=ON"
        make_maca "-j$JOBS"
    else
        cmake .. "-DENABLE_MCC=$ENABLE_MCC" "-DENABLE_DEBUG=$ENABLE_DEBUG" "-DENABLE_NVCC=$ENABLE_NVCC"
        make "-j$JOBS"
    fi
else
    if [ "$ENABLE_CUBRIDGE" = "ON" ]; then
        make_maca "-j$JOBS"
    else
        make "-j$JOBS"
    fi
fi

echo "Build completed."