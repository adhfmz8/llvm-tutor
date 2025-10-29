#!/bin/bash

set -e

# --- Configuration ---
LLVM_INSTALL_DIR="/opt/homebrew/opt/llvm"

# --- Build the project ---
echo "--- Configuring and building the project ---"
mkdir -p build
cd build
cmake -DLT_LLVM_INSTALL_DIR=${LLVM_INSTALL_DIR} ..
cmake --build .
cd ..

# --- Prepare for tests ---
echo -e "\n--- Preparing output directory ---"
mkdir -p outputs

# --- Run SimpleLICM Pass ---
echo -e "\n--- Running SimpleLICM pass on matmul_canonical.ll ---"
opt -load-pass-plugin ./build/lib/libSimpleLICM.dylib \
                -passes=simple-licm -S \
                -o outputs/matmul_licm.ll \
                test-inputs/matmul-canonical.ll
echo "SimpleLICM pass finished. Output is in outputs/matmul_licm.ll"

# --- Run IVE Pass ---
echo -e "\n--- Running DerivedInductionVar pass on test-derived-iv.ll ---"
opt -load-pass-plugin ./build/lib/libDerivedInductionVars.dylib \
                -passes='loop-simplify,derived-iv' -S \
                -o outputs/test-derived-iv.ll.optimized \
                test-inputs/test-derived-iv.ll
echo "DerivedInductionVar pass finished. Output is in outputs/test-derived-iv.ll.optimized"

echo -e "\n--- All tests completed successfully! ---"