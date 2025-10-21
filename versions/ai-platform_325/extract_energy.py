import os
import re
import csv
from pathlib import Path
from datetime import datetime

def get_latest_txt_file(folder_path):
    """获取指定文件夹下最新的log文件"""
    logs_path = Path(folder_path) / "logs"
    
    if not logs_path.exists():
        print(f"警告: {logs_path} 不存在")
        return None
    
    txt_files = list(logs_path.glob("*.log"))
    
    if not txt_files:
        print(f"警告: {logs_path} logs 文件夹下没有找到任何 .log 文件")
        return None
    
    # 按修改时间排序，获取最新的文件
    latest_file = max(txt_files, key=lambda f: f.stat().st_mtime)
    return latest_file

def extract_energy_data(file_path):
    """从文件中提取能耗数据"""
    pattern = r"Energy consumption in joules:\s*([\d.]+)\s*for\s*([\d.]+)\s*sec of execution\."
    
    energy_data = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            matches = re.findall(pattern, content)
            
            for match in matches:
                energy = float(match[0])
                runtime = float(match[1])
                energy_data.append((energy, runtime))
    
    except Exception as e:
        print(f"读取文件 {file_path} 时出错: {e}")
    
    return energy_data

def main():
    # 定义文件夹路径
    folders = ["before", "after"]
    
    # 准备CSV数据
    csv_data = []
    
    for folder in folders:
        # 获取最新的txt文件
        latest_file = get_latest_txt_file(folder)
        
        if latest_file is None:
            continue
        
        print(f"处理 {folder} 文件夹的文件: {latest_file}")
        
        # 提取能耗数据
        energy_data = extract_energy_data(latest_file)
        
        # 添加到CSV数据中
        for run_num, (energy, runtime) in enumerate(energy_data, start=1):
            csv_data.append({
                'folder': folder,
                'run': run_num,
                'energy_joules': energy,
                'runtime_sec': runtime
            })
        
        print(f"  找到 {len(energy_data)} 条能耗记录")
    
    # 写入CSV文件
    if csv_data:
        output_file = "energy_consumption_results.csv"
        
        with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['folder', 'run', 'energy_joules', 'runtime_sec']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            writer.writeheader()
            writer.writerows(csv_data)
        
        print(f"\n成功! 数据已保存到 {output_file}")
        print(f"共提取 {len(csv_data)} 条记录")
    else:
        print("\n未找到任何能耗数据")

if __name__ == "__main__":
    main()