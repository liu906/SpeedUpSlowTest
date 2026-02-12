#!/usr/bin/env python3
"""
RQ2 Script: Analyze project data for time and energy reduction.

This script:
1. Reads the all_projects_summary.csv file
2. Re-orders projects by non-case sensitive alphabetical order
3. Writes the re-ordered CSV to rq2 folder
4. Creates a scatter plot with time reduction (x) vs energy reduction (y)
5. Outputs the chart as PNG and PDF to img/ folder
"""

import pandas as pd
import matplotlib.pyplot as plt
from adjustText import adjust_text
import numpy as np
from scipy import stats
import os
import sys


def main():
    # Define paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)

    input_csv = os.path.join(project_root, "versions", "all_projects_summary.csv")
    output_csv = os.path.join(script_dir, "all_projects_summary_sorted.csv")
    img_dir = os.path.join(project_root, "img")

    # Ensure img directory exists
    os.makedirs(img_dir, exist_ok=True)

    # Read the CSV file
    print(f"Reading input file: {input_csv}")
    df = pd.read_csv(input_csv)

    # Sort by project_name (case-insensitive)
    df_sorted = df.sort_values(by='project_name', key=lambda x: x.str.lower())

    # Write the sorted CSV
    print(f"Writing sorted CSV to: {output_csv}")
    df_sorted.to_csv(output_csv, index=False)

    # Calculate time reduction and energy reduction ratios
    # time reduction = before / after (higher means more reduction)
    # energy reduction = before / after (higher means more reduction)
    df_sorted['time_reduction'] = df_sorted['total_test_time_before_avg'] / df_sorted['total_test_time_after_avg']
    df_sorted['energy_reduction'] = df_sorted['energy_before_avg'] / df_sorted['energy_after_avg']

    # Filter to only include projects with time reduction < 30
    df_filtered = df_sorted[df_sorted['time_reduction'] < 30].copy()

    # Create the scatter plot
    fig, ax = plt.subplots(figsize=(10, 8))

    ax.scatter(df_filtered['time_reduction'], df_filtered['energy_reduction'],
               s=80, alpha=0.7, edgecolors='black', linewidth=0.5)

    # Add project labels using adjustText to avoid overlaps
    texts = []
    for idx, row in df_filtered.iterrows():
        texts.append(ax.text(row['time_reduction'], row['energy_reduction'],
                             row['project_name'], fontsize=15, alpha=0.8))

    # Set logarithmic scale for x-axis (base 2)
    ax.set_xscale('log', base=2)

    # Set labels and title
    ax.set_xlabel('Time Reduction (Before / After) - Log₂ Scale', fontsize=22)
    ax.set_ylabel('Energy Reduction (Before / After)', fontsize=22)
    ax.set_title('Time Reduction vs Energy Reduction by Project', fontsize=22)

    # Add linear regression line (fit on log2-transformed x)
    x = df_filtered['time_reduction'].values
    y = df_filtered['energy_reduction'].values
    log2_x = np.log2(x)
    slope, intercept, r_value, p_value, std_err = stats.linregress(log2_x, y)
    x_line = np.logspace(np.log2(x.min()), np.log2(x.max()), 100, base=2)
    y_line = slope * np.log2(x_line) + intercept
    ax.plot(x_line, y_line, 'r--', alpha=0.7,
            label=f'Linear regression (R²={r_value**2:.3f})')
    ax.legend(fontsize=20)

    print(f"\nLinear regression results (log2-transformed x):")
    print(f"  Slope: {slope:.4f}")
    print(f"  Intercept: {intercept:.4f}")
    print(f"  R²: {r_value**2:.4f}")
    print(f"  p-value: {p_value:.4e}")

    # Add grid for better readability
    ax.grid(True, alpha=0.3)

    # Add Pearson r in the corner (moved down to avoid legend)
    ax.text(0.05, 0.85, f'Pearson r = {r_value:.3f}', transform=ax.transAxes,
            fontsize=22, verticalalignment='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

    # Adjust text positions to avoid overlaps
    adjust_text(texts, ax=ax, arrowprops=dict(arrowstyle='-', color='gray', alpha=0.5))

    plt.tight_layout()

    # Save as PNG and PDF
    png_path = os.path.join(img_dir, "rq2_time_energy_reduction.png")
    pdf_path = os.path.join(img_dir, "rq2_time_energy_reduction.pdf")

    print(f"Saving chart as PNG: {png_path}")
    fig.savefig(png_path, dpi=300, bbox_inches='tight')

    print(f"Saving chart as PDF: {pdf_path}")
    fig.savefig(pdf_path, bbox_inches='tight')

    plt.close()

    # ==================== Plot 2: Time Delta vs Energy Delta ====================
    # Calculate deltas (before - after)
    df_sorted['time_delta'] = df_sorted['total_test_time_before_avg'] - df_sorted['total_test_time_after_avg']
    df_sorted['energy_delta'] = df_sorted['energy_before_avg'] - df_sorted['energy_after_avg']

    fig2, ax2 = plt.subplots(figsize=(10, 8))

    ax2.scatter(df_sorted['time_delta'], df_sorted['energy_delta'],
                s=80, alpha=0.7, edgecolors='black', linewidth=0.5)

    # Add project labels using adjustText to avoid overlaps
    texts2 = []
    for idx, row in df_sorted.iterrows():
        texts2.append(ax2.text(row['time_delta'], row['energy_delta'],
                               row['project_name'], fontsize=15, alpha=0.8))

    # Set labels and title
    ax2.set_xlabel('Time Delta (Before - After) [seconds]', fontsize=22)
    ax2.set_ylabel('Energy Delta (Before - After) [Joules]', fontsize=22)
    ax2.set_title('Time Delta vs Energy Delta by Project', fontsize=22)

    # Add linear regression line
    x2 = df_sorted['time_delta'].values
    y2 = df_sorted['energy_delta'].values
    slope2, intercept2, r_value2, p_value2, std_err2 = stats.linregress(x2, y2)
    x2_line = np.linspace(x2.min(), x2.max(), 100)
    y2_line = slope2 * x2_line + intercept2
    ax2.plot(x2_line, y2_line, 'r--', alpha=0.7,
             label=f'Linear regression (R²={r_value2**2:.3f})')
    ax2.legend(fontsize=20)

    print(f"\nPlot 2 - Time Delta vs Energy Delta:")
    print(f"  Slope: {slope2:.4f}")
    print(f"  Intercept: {intercept2:.4f}")
    print(f"  R²: {r_value2**2:.4f}")
    print(f"  p-value: {p_value2:.4e}")

    ax2.grid(True, alpha=0.3)

    # Add Pearson r in the corner (moved down to avoid legend)
    ax2.text(0.05, 0.85, f'Pearson r = {r_value2:.3f}', transform=ax2.transAxes,
             fontsize=22, verticalalignment='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

    adjust_text(texts2, ax=ax2, arrowprops=dict(arrowstyle='-', color='gray', alpha=0.5))
    plt.tight_layout()

    # Save as PNG and PDF
    png_path2 = os.path.join(img_dir, "rq2_time_energy_delta.png")
    pdf_path2 = os.path.join(img_dir, "rq2_time_energy_delta.pdf")

    print(f"Saving chart as PNG: {png_path2}")
    fig2.savefig(png_path2, dpi=300, bbox_inches='tight')

    print(f"Saving chart as PDF: {pdf_path2}")
    fig2.savefig(pdf_path2, bbox_inches='tight')

    plt.close()

    # ==================== Plot 3: Time Improvement % vs Energy Improvement % ====================
    fig3, ax3 = plt.subplots(figsize=(10, 8))

    ax3.scatter(df_sorted['total_test_time_improvement_pct'], df_sorted['energy_improvement_pct'],
                s=80, alpha=0.7, edgecolors='black', linewidth=0.5)

    # Add project labels using adjustText to avoid overlaps
    texts3 = []
    for idx, row in df_sorted.iterrows():
        texts3.append(ax3.text(row['total_test_time_improvement_pct'], row['energy_improvement_pct'],
                               row['project_name'], fontsize=15, alpha=0.8))

    # Set labels and title
    ax3.set_xlabel('Time Improvement (%)', fontsize=22)
    ax3.set_ylabel('Energy Improvement (%)', fontsize=22)
    ax3.set_title('Time Improvement % vs Energy Improvement % by Project', fontsize=22)

    # Add linear regression line
    x3 = df_sorted['total_test_time_improvement_pct'].values
    y3 = df_sorted['energy_improvement_pct'].values
    slope3, intercept3, r_value3, p_value3, std_err3 = stats.linregress(x3, y3)
    x3_line = np.linspace(x3.min(), x3.max(), 100)
    y3_line = slope3 * x3_line + intercept3
    ax3.plot(x3_line, y3_line, 'r--', alpha=0.7,
             label=f'Linear regression (R²={r_value3**2:.3f})')
    ax3.legend(fontsize=20)

    print(f"\nPlot 3 - Time Improvement % vs Energy Improvement %:")
    print(f"  Slope: {slope3:.4f}")
    print(f"  Intercept: {intercept3:.4f}")
    print(f"  R²: {r_value3**2:.4f}")
    print(f"  p-value: {p_value3:.4e}")

    ax3.grid(True, alpha=0.3)

    # Add Pearson r in the corner (moved down to avoid legend)
    ax3.text(0.05, 0.85, f'Pearson r = {r_value3:.3f}', transform=ax3.transAxes,
             fontsize=22, verticalalignment='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

    adjust_text(texts3, ax=ax3, arrowprops=dict(arrowstyle='-', color='gray', alpha=0.5))
    plt.tight_layout()

    # Save as PNG and PDF
    png_path3 = os.path.join(img_dir, "rq2_time_energy_improvement_pct.png")
    pdf_path3 = os.path.join(img_dir, "rq2_time_energy_improvement_pct.pdf")

    print(f"Saving chart as PNG: {png_path3}")
    fig3.savefig(png_path3, dpi=300, bbox_inches='tight')

    print(f"Saving chart as PDF: {pdf_path3}")
    fig3.savefig(pdf_path3, bbox_inches='tight')

    plt.close()

    print("\nDone!")
    print(f"\nSummary statistics:")
    print(f"  Time reduction range: {df_sorted['time_reduction'].min():.2f} - {df_sorted['time_reduction'].max():.2f}")
    print(f"  Energy reduction range: {df_sorted['energy_reduction'].min():.2f} - {df_sorted['energy_reduction'].max():.2f}")


if __name__ == "__main__":
    main()
