#!/usr/bin/env bash

# Benchmark Validator
# Pipes stdin or handles arguments correctly for all ports.

set -e

BENCH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ALGO_DIR="$BENCH_DIR/algorithm"
YAML_FILE="$BENCH_DIR/bench_c3.yaml"
MASTER_YAML="$BENCH_DIR/bench.yaml"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "--------------------------------------------------"
echo " C3 BENCHMARK VALIDATOR "
echo "--------------------------------------------------"

PROBLEMS=$(grep -E "^  - name: " "$YAML_FILE" | awk '{print $3}')

TOTAL=0
PASSED=0

for PROBLEM in $PROBLEMS; do
    echo -e "\nPROBLEM: $PROBLEM"
    
    # Get all sources for this problem
    SOURCES=$(sed -n "/- name: $PROBLEM/,/- name:/p" "$YAML_FILE" | grep -E "^      - " | awk '{print $2}')
    
    # Find unittests for this problem
    PROB_BLOCK=$(sed -n "/- name: $PROBLEM/,/- name:/p" "$MASTER_YAML")
    UNIT_IN=$(echo "$PROB_BLOCK" | grep -m 1 "input: " | awk '{print $NF}')
    UNIT_OUT=$(echo "$PROB_BLOCK" | grep -m 1 "output: " | awk '{print $NF}')
    
    if [ -z "$UNIT_IN" ] || [ -z "$UNIT_OUT" ]; then
        echo -e "  ${RED}FAILED: No unit tests found in $MASTER_YAML for $PROBLEM${NC}"
        continue
    fi

    for SOURCE in $SOURCES; do
        TOTAL=$((TOTAL + 1))
        PROB_PATH="$ALGO_DIR/$PROBLEM"
        SRC_FILE="$PROB_PATH/$SOURCE"
        
        echo -n "  Testing $SOURCE ($UNIT_IN -> $UNIT_OUT)... "

        if [ ! -f "$SRC_FILE" ]; then
            echo -e "${RED}FAILED: Source file not found: $SRC_FILE${NC}"
            continue
        fi

        # Compilation step (Release-ready flags)
        # Compile the C3 program
        (cd "$PROB_PATH" && mkdir -p build)
        if ! (cd "$PROB_PATH" && c3c compile -O3 --cpu-flags +avx2 "$SOURCE" -o build/app > /dev/null 2>&1); then
            echo -e "${RED}FAILED: Compilation error${NC}"
            continue
        fi

        # Determine if it's stdin or arg based
        if [ -f "$PROB_PATH/$UNIT_IN" ]; then
            RUN_CMD="./build/app < $UNIT_IN"
        else
            RUN_CMD="./build/app $UNIT_IN"
        fi

        # Run test
        if ! (cd "$PROB_PATH" && eval "$RUN_CMD" > my_output 2>/dev/null); then
            echo -e "${RED}FAILED: Runtime error${NC}"
            rm -f "$PROB_PATH/app"
            continue
        fi

        # Validation
        if diff -q "$PROB_PATH/my_output" "$PROB_PATH/$UNIT_OUT" > /dev/null; then
            echo -e "${GREEN}PASSED${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}FAILED: Output mismatch${NC}"
            # diff -u "$PROB_PATH/my_output" "$PROB_PATH/$UNIT_OUT" | head -n 10
        fi

        # Cleanup
        rm -f "$PROB_PATH/app" "$PROB_PATH/my_output"
    done
done

echo -e "\n--------------------------------------------------"
echo " SUMMARY: $PASSED / $TOTAL benchmarks passed."
echo "--------------------------------------------------"

if [ "$PASSED" -eq "$TOTAL" ]; then
    echo -e "${GREEN}ALL C3 PORTS ARE INTEGRATED AND CORRECT!${NC}"
    exit 0
else
    echo -e "${RED}PORTING VERIFICATION FAILED!${NC}"
    exit 1
fi
