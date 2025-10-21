#! /usr/bin/env sh
# Exit in case of error
set -e
set -x

docker compose build
docker compose down -v --remove-orphans # Remove possibly previous broken stacks left hanging after an error
docker compose up -d

# 循环次数
LOOP_COUNT=5

# 创建日志目录
mkdir -p logs

# 生成带时间戳的日志文件名
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="logs/test_responses_${TIMESTAMP}.log"

echo "Logging to: $LOG_FILE"

for i in $(seq 1 $LOOP_COUNT); do
    echo "=== Run $i of $LOOP_COUNT ===" | tee -a "$LOG_FILE"
    sleep 5
    energibridge --summary docker compose exec backend python -m pytest app/tests/api/routes/test_responses.py --durations=0 2>&1 | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
done

docker compose down -v --remove-orphans

echo "Test completed. Log saved to: $LOG_FILE"