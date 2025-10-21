import re
import csv

def parse_benchmark_log(log_file_path, output_csv_path):
    """
    解析benchmark测试日志，提取能耗数据
    
    参数:
        log_file_path: 输入日志文件路径
        output_csv_path: 输出CSV文件路径
    """
    results = []
    current_stage = None  # 'BEFORE' 或 'AFTER'
    current_run = None
    
    # 正则表达式模式
    stage_pattern = r'--- (BEFORE|AFTER) - Run (\d+) ---'
    energy_pattern = r'Energy consumption in joules: ([\d.]+) for ([\d.]+) sec of execution\.'
    
    with open(log_file_path, 'r', encoding='utf-8') as f:
        for line in f:
            # 检查是否是阶段和运行次数标记行
            stage_match = re.search(stage_pattern, line)
            if stage_match:
                current_stage = stage_match.group(1)
                current_run = stage_match.group(2)
                continue
            
            # 检查是否是能耗数据行
            energy_match = re.search(energy_pattern, line)
            if energy_match:
                joules = float(energy_match.group(1))
                seconds = float(energy_match.group(2))
                
                if current_stage and current_run:
                    results.append({
                        'stage': current_stage,
                        'run': current_run,
                        'joules': joules,
                        'seconds': seconds
                    })
    
    # 写入CSV文件
    with open(output_csv_path, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['stage', 'run', 'joules', 'seconds']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        writer.writerows(results)
    
    print(f"成功提取 {len(results)} 条记录")
    print(f"结果已保存到: {output_csv_path}")
    
    # 打印预览
    if results:
        print("\n数据预览:")
        print(f"{'Stage':<10} {'Run':<5} {'Joules':<15} {'Seconds':<10}")
        print("-" * 45)
        for r in results[:5]:
            print(f"{r['stage']:<10} {r['run']:<5} {r['joules']:<15.2f} {r['seconds']:<10.4f}")
        if len(results) > 5:
            print(f"... 还有 {len(results) - 5} 条记录")

if __name__ == "__main__":
    # 使用示例
    input_file = "./benchmark_log_20251021_181022.txt"  # 输入日志文件名
    output_file = "./energy_results.csv"  # 输出CSV文件名
    
    parse_benchmark_log(input_file, output_file)