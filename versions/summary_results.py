#!/usr/bin/env python3
"""
汇总所有项目的测试结果，生成表格展示
"""

import pandas as pd
import re
from pathlib import Path

def parse_summary_from_log(log_file):
    """从日志文件中提取汇总信息"""
    with open(log_file, 'r') as f:
        content = f.read()

    data = {}

    # 提取能量数据
    energy_before = re.search(r'Average energy \(before\): ([\d.]+) J', content)
    energy_after = re.search(r'Average energy \(after_careful_mock\): ([\d.]+) J', content)
    energy_reduction = re.search(r'Energy reduction: ([\d.]+)%', content)
    energy_saved = re.search(r'Energy saved: ([\d.]+) J', content)

    if energy_before and energy_after:
        data['energy_before'] = float(energy_before.group(1))
        data['energy_after'] = float(energy_after.group(1))
        data['energy_reduction'] = float(energy_reduction.group(1)) if energy_reduction else 0
        data['energy_saved'] = float(energy_saved.group(1)) if energy_saved else 0

    # 提取测试时长数据
    duration_before = re.search(r'Average test duration \(before\): ([\d.]+)s', content)
    duration_after = re.search(r'Average test duration \(after_careful_mock\): ([\d.]+)s', content)
    total_time_before = re.search(r'Average total test time \(before\): ([\d.]+)s', content)
    total_time_after = re.search(r'Average total test time \(after_careful_mock\): ([\d.]+)s', content)
    time_reduction = re.search(r'Total test time reduction: ([\d.]+)%', content)
    speed_ratio = re.search(r'Total test speed ratio: ([\d.]+)x faster', content)

    if duration_before and duration_after:
        data['duration_before'] = float(duration_before.group(1))
        data['duration_after'] = float(duration_after.group(1))

    if total_time_before and total_time_after:
        data['total_time_before'] = float(total_time_before.group(1))
        data['total_time_after'] = float(total_time_after.group(1))
        data['time_reduction'] = float(time_reduction.group(1)) if time_reduction else 0
        data['speed_ratio'] = float(speed_ratio.group(1)) if speed_ratio else 0

    # 提取测试数量
    test_entries = re.search(r'before version: (\d+) entries', content)
    if test_entries:
        data['test_count'] = int(test_entries.group(1))

    return data

def main():
    projects = [
        'pyjelly_235',
        'ert_11206',
        'autosubmit_2367',
        'blueprints_691',
        'ophyd-async_316',
        'quant-mind_58',
        'nipoppy_697'
    ]

    results = []

    for project in projects:
        log_file = Path(f'/data/SpeedUpSlowTest/versions/{project}/test_results_only_mock_part.log')

        if not log_file.exists():
            print(f"⚠️ 跳过 {project}: 日志文件不存在")
            continue

        try:
            data = parse_summary_from_log(log_file)
            data['project'] = project
            results.append(data)
        except Exception as e:
            print(f"⚠️ 解析 {project} 时出错: {e}")

    if not results:
        print("没有找到有效的结果数据")
        return

    df = pd.DataFrame(results)

    # 按项目名称排序
    df = df.sort_values('project')

    print("\n" + "="*120)
    print("测试结果汇总 - Duration (测试时长)")
    print("="*120)

    duration_cols = ['project', 'test_count', 'total_time_before', 'total_time_after',
                     'time_reduction', 'speed_ratio']

    if all(col in df.columns for col in duration_cols):
        duration_df = df[duration_cols].copy()
        duration_df.columns = ['项目', '测试数量', '优化前总时长(s)', '优化后总时长(s)',
                               '时间减少(%)', '加速倍数(x)']

        print(duration_df.to_string(index=False))

        # 计算总和
        print("\n" + "-"*120)
        print(f"总计: 优化前总时长 {df['total_time_before'].sum():.2f}s, "
              f"优化后总时长 {df['total_time_after'].sum():.2f}s, "
              f"平均加速倍数 {df['speed_ratio'].mean():.2f}x")

    print("\n" + "="*120)
    print("测试结果汇总 - Energy Consumption (能耗)")
    print("="*120)

    energy_cols = ['project', 'test_count', 'energy_before', 'energy_after',
                   'energy_reduction', 'energy_saved']

    if all(col in df.columns for col in energy_cols):
        energy_df = df[energy_cols].copy()
        energy_df.columns = ['项目', '测试数量', '优化前能耗(J)', '优化后能耗(J)',
                            '能耗减少(%)', '节省能耗(J)']

        print(energy_df.to_string(index=False))

        # 计算总和
        print("\n" + "-"*120)
        print(f"总计: 优化前总能耗 {df['energy_before'].sum():.2f}J, "
              f"优化后总能耗 {df['energy_after'].sum():.2f}J, "
              f"总节省能耗 {df['energy_saved'].sum():.2f}J, "
              f"平均能耗减少 {df['energy_reduction'].mean():.2f}%")

    print("\n" + "="*120)

    # 保存为CSV
    output_file = '/data/SpeedUpSlowTest/versions/summary_all_projects.csv'
    df.to_csv(output_file, index=False)
    print(f"\n✅ 详细数据已保存至: {output_file}")

    # 生成Markdown表格
    md_file = '/data/SpeedUpSlowTest/versions/summary_all_projects.md'
    with open(md_file, 'w') as f:
        f.write("# 测试优化结果汇总\n\n")
        f.write("## 测试时长优化结果\n\n")
        if all(col in df.columns for col in duration_cols):
            f.write(duration_df.to_markdown(index=False))
            f.write(f"\n\n**总计**: 优化前总时长 {df['total_time_before'].sum():.2f}s, "
                   f"优化后总时长 {df['total_time_after'].sum():.2f}s, "
                   f"平均加速倍数 {df['speed_ratio'].mean():.2f}x\n\n")

        f.write("## 能耗优化结果\n\n")
        if all(col in df.columns for col in energy_cols):
            f.write(energy_df.to_markdown(index=False))
            f.write(f"\n\n**总计**: 优化前总能耗 {df['energy_before'].sum():.2f}J, "
                   f"优化后总能耗 {df['energy_after'].sum():.2f}J, "
                   f"总节省能耗 {df['energy_saved'].sum():.2f}J, "
                   f"平均能耗减少 {df['energy_reduction'].mean():.2f}%\n")

    print(f"✅ Markdown报告已保存至: {md_file}")

if __name__ == '__main__':
    main()
