#!/bin/bash

# 设置项目路径
PROJECT_ROOT="."
BEFORE_DIR="${PROJECT_ROOT}/before/scripts"
AFTER_DIR="${PROJECT_ROOT}/after/scripts"

# 设置测量次数
NUM_RUNS=5

# 创建结果文件
BEFORE_RESULTS="before_results.txt"
AFTER_RESULTS="after_results.txt"

# 清空之前的结果文件
> "$BEFORE_RESULTS"
> "$AFTER_RESULTS"

echo "开始能耗测量（交替测量模式）..."
echo "================================"

# 交替测量 before 和 after
for i in $(seq 1 $NUM_RUNS); do
    echo "轮次 $i/$NUM_RUNS"
    echo "  测量 before..."
    cd "$BEFORE_DIR" || exit 1
    
    # 运行命令并捕获最后一行
    result=$(energibridge --summary bash test.sh 2>&1 | tail -n 1)
    
    # 保存结果
    echo "$result" >> "../../$BEFORE_RESULTS"
    
    cd - > /dev/null
    
    echo "  测量 after..."
    cd "$AFTER_DIR" || exit 1
    
    # 运行命令并捕获最后一行
    result=$(energibridge --summary bash test.sh 2>&1 | tail -n 1)
    
    # 保存结果
    echo "$result" >> "../../$AFTER_RESULTS"
    
    cd - > /dev/null
    
    echo "  ✓ 轮次 $i 完成"
    echo "--------------------------------"
done

echo "================================"
echo "测量完成！"
echo ""
echo "Before 结果已保存到: $BEFORE_RESULTS"
echo "After 结果已保存到: $AFTER_RESULTS"
echo ""
echo "--- Before 结果预览 ---"
head -n 3 "$BEFORE_RESULTS"
echo "..."
echo ""
echo "--- After 结果预览 ---"
head -n 3 "$AFTER_RESULTS"
echo "..."
