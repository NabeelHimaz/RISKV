#!/bin/bash

# This script runs ONLY the top-level CPU test (verify.cpp)
# Usage: ./doit.sh

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
TEST_FOLDER=$(realpath "$SCRIPT_DIR/tests")
RTL_FOLDER=$(realpath "$SCRIPT_DIR/../rtl")
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

# Variables
passes=0
fails=0

# --- CHANGE: Force file to be ONLY verify.cpp ---
file="${TEST_FOLDER}/verify.cpp"
files=("$file")
# -----------------------------------------------

cd $SCRIPT_DIR

# Wipe previous test output
rm -rf test_out/*

# Iterate through files (now just verify.cpp)
for file in "${files[@]}"; do
    # Name is hardcoded for verify.cpp
    name="top"

    echo "--------------------------------"
    echo "Running Top-Level CPU Test: $name"
    echo "--------------------------------"

    # Gather all RTL subdirectories
    rtl_dirs=($(find "$RTL_FOLDER" -type d))

    # Build -y arguments
    y_args=()
    for d in "${rtl_dirs[@]}"; do
        y_args+=(-y "$d")
    done

    # Translate Verilog -> C++
    verilator -Wall --trace \
                 -cc ${RTL_FOLDER}/${name}.sv \
                 --exe ${file} \
                 "${y_args[@]}" \
                 --prefix "Vdut" \
                 -o Vdut \
                 -LDFLAGS "-lgtest -lgtest_main -lpthread" \
                 # 2>&1 >/dev/null || { echo "${RED}Verilator compilation failed!${RESET}"; exit 1; }


    # Build C++ project
    make -j -C obj_dir/ -f Vdut.mk >/dev/null || { echo "${RED}C++ compilation failed!${RESET}"; exit 1; }

    # Run executable
    ./obj_dir/Vdut

    # Check if the test succeeded or not
    if [ $? -eq 0 ]; then
        ((passes++))
        echo "${GREEN}Test passed!${RESET}"
    else
        ((fails++))
        echo "${RED}Test failed!${RESET}"
    fi

    # Move waveform file
    if [ -f "waveform.vcd" ]; then
        test_basename=$(basename "$file" .cpp)
        mkdir -p test_out/${test_basename}
        mv waveform.vcd test_out/${test_basename}/
        echo "${GREEN}Waveform saved to test_out/${test_basename}/waveform.vcd${RESET}"
    fi

done

# Save obj_dir
mv obj_dir test_out/ 2>/dev/null

if [ $fails -eq 0 ]; then
    echo "${GREEN}CPU Top-Level Test Passed.${RESET}"
    exit 0
else
    echo "${RED}CPU Top-Level Test Failed.${RESET}"
    exit 1
fi
