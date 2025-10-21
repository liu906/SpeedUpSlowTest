#!/bin/bash

RUNS=${1:-5}
BASE_DIR="$(pwd)"
TEST_COMMAND="energibridge --summary python -m pytest test/unit/test_expid.py --durations=0"
LOG_FILE="benchmark_log_$(date +%Y%m%d_%H%M%S).txt"

echo "Starting benchmark with $RUNS iterations..."
echo "Log file: $LOG_FILE"
echo ""

# 所有输出都重定向到日志文件
{
    echo "==========================================="
    echo "Benchmark Test Log"
    echo "Started at: $(date)"
    echo "Total runs: $RUNS"
    echo "==========================================="
    echo ""

    for i in $(seq 1 $RUNS); do
        echo "========================================="
        echo "Iteration $i of $RUNS"
        echo "========================================="
        
        # BEFORE
        echo ""
        echo "--- BEFORE - Run $i ---"
        echo "Time: $(date)"
        cd "$BASE_DIR/before" || exit 1
        source .venv/bin/activate
        $TEST_COMMAND
        echo ""
        echo "Sleeping 5 seconds..."
        sleep 5
        
        # AFTER
        echo ""
        echo "--- AFTER - Run $i ---"
        echo "Time: $(date)"
        cd "$BASE_DIR/after" || exit 1
        $TEST_COMMAND
        echo ""
        echo "Sleeping 5 seconds..."
        sleep 5
        
        echo "✓ Completed iteration $i of $RUNS"
        echo ""
    done

    cd "$BASE_DIR"
    echo "==========================================="
    echo "All tests completed at: $(date)"
    echo "==========================================="
    
} > "$LOG_FILE" 2>&1 &

# 获取后台进程 PID
BG_PID=$!

# 实时显示日志文件内容
tail -f "$LOG_FILE" &
TAIL_PID=$!

# 等待测试完成
wait $BG_PID

# 停止 tail
kill $TAIL_PID 2>/dev/null

echo ""
echo "All tests completed!"
echo "Results saved to: $LOG_FILE"