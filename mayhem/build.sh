#!/usr/bin/env bash
#
# mayhem/build.sh — build SpvGenTwo's fuzz targets + test suite.
#
# Targets:
#   /mayhem/SpvGenTwoDisassembler      sanitized disassembler CLI (file-input target)
#   /mayhem/fuzz_stringLength          libFuzzer harness over spvgentwo::stringLength
#   /mayhem/fuzz_stringLength-standalone  run-once reproducer for the harness
# Test suite (normal flags, built here so test.sh only runs it):
#   /mayhem/build-tests/SpvGenTwoTests (Catch2), registered with ctest
set -euo pipefail

[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer}"
: "${DEBUG_FLAGS:=-g -gdwarf-3}"
: "${CC:=clang}" ; : "${CXX:=clang++}" ; : "${LIB_FUZZING_ENGINE:=-fsanitize=fuzzer}"
: "${MAYHEM_JOBS:=$(nproc)}"
: "${COVERAGE_FLAGS=}"
export SANITIZER_FLAGS DEBUG_FLAGS CC CXX LIB_FUZZING_ENGINE MAYHEM_JOBS COVERAGE_FLAGS

cd "$SRC"

# Offline FetchContent sources (pre-cloned by mayhem/Dockerfile at the pinned tags).
FC=/opt/fetchcontent

# 1) Sanitized project build: the disassembler CLI, instrumented with ASan+UBSan + DWARF-3.
cmake -B build \
  -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_C_FLAGS="$SANITIZER_FLAGS $DEBUG_FLAGS" \
  -DCMAKE_CXX_FLAGS="$SANITIZER_FLAGS $DEBUG_FLAGS" \
  -DCMAKE_EXE_LINKER_FLAGS="$SANITIZER_FLAGS" \
  -DSPVGENTWO_BUILD_DISASSEMBLER=TRUE
cmake --build build -j"$MAYHEM_JOBS" --target SpvGenTwoDisassembler
cp build/SpvGenTwoDisassembler "$SRC/SpvGenTwoDisassembler"

# 2) libFuzzer harness (header-only stringLength — no lib to link) + standalone reproducer.
$CXX $SANITIZER_FLAGS $DEBUG_FLAGS $LIB_FUZZING_ENGINE -std=c++17 \
  -I"$SRC/lib/include/spvgentwo" \
  "$SRC/mayhem/fuzz_stringLength.cpp" -o "$SRC/fuzz_stringLength"
$CC $SANITIZER_FLAGS $DEBUG_FLAGS -c "$STANDALONE_FUZZ_MAIN" -o /tmp/standalone_main.o
$CXX $SANITIZER_FLAGS $DEBUG_FLAGS -std=c++17 \
  -I"$SRC/lib/include/spvgentwo" \
  "$SRC/mayhem/fuzz_stringLength.cpp" /tmp/standalone_main.o -o "$SRC/fuzz_stringLength-standalone"

# 3) Upstream Catch2 test suite, normal flags, air-gapped via pre-fetched FetchContent trees.
cmake -B build-tests \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="$COVERAGE_FLAGS" -DCMAKE_CXX_FLAGS="$COVERAGE_FLAGS" \
  -DSPVGENTWO_BUILD_TESTS=TRUE \
  -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
  -DFETCHCONTENT_SOURCE_DIR_CATCH2="$FC/catch2" \
  -DFETCHCONTENT_SOURCE_DIR_SPIRV-HEADERS="$FC/spirv-headers" \
  -DFETCHCONTENT_SOURCE_DIR_SPIRV-TOOLS="$FC/spirv-tools"
cmake --build build-tests -j"$MAYHEM_JOBS" --target SpvGenTwoTests

echo "build.sh: done"
