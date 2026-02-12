from collections import Counter
import matplotlib.pyplot as plt
import csv
import os

# Get the directory where this script is located
script_dir = os.path.dirname(os.path.abspath(__file__))

# Read data from CSV file
csv_file = os.path.join(script_dir, "test_level_classification.csv")
categories_col2 = []

with open(csv_file, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        if row['Category']:  # Skip empty rows
            categories_col2.append(row['Category'])

# First pie chart data (original hardcoded data)
categories = [
    "CI pipeline optimization",
    "Test Scheduling optimization",
    "Test Scheduling optimization",
    "Test Scheduling optimization",
    "Test Scheduling optimization",
    "UUT optimization",
    "Test scheduling optimization",
    "CI pipeline optimization",
    "CI pipeline optimization",
    "Test Scheduling optimization",
    "CI pipeline optimization",
    "Test code optimization",
    "CI pipeline optimization",
    "CI pipeline optimization",
    "Test code optimization",
    "Test code optimization",
    "Test infrastructure optimization",
    "Test infrastructure optimization",
    "CI pipeline optimization",
    "Test code optimization",
    "Test code optimization",
    "Test code optimization",
    "CI pipeline optimization",
    "CI pipeline optimization",
    "Test code optimization",
    "Test code optimization",
    "CI pipeline optimization",
    "Test code optimization",
    "Test code optimization",
    "Test infrastructure optimization",
    "Test code optimization",
    "CI pipeline optimization",
    "Test infrastructure optimization",
    "Test code optimization",
    "Test scheduling optimization",
    "Test code optimization",
    "Test code optimization",
    "Test code optimization",
    "CI pipeline optimization",
    "CI pipeline optimization",
    "UUT optimization",
    "Test code optimization",
    "Test code optimization",
    "UUT optimization",
    "UUT optimization",
    "Test code optimization",
    "Test code optimization",
    "UUT optimization",
    "UUT optimization",
    "Test code optimization",
    "CI pipeline optimization",
    "CI pipeline optimization",
    "Test code optimization",
    "Test infrastructure optimization",
    "UUT optimization",
    "Test code optimization",
    "Test code optimization",
    "Test code optimization",
    "Test code optimization",
    "Test scheduling optimization",
    "CI pipeline optimization",
    "Test code optimization",
    "Test code optimization",
    "CI pipeline optimization",
    "UUT optimization",
    "Test scheduling optimization",
    "Test infrastructure optimization",
    "Test code optimization",
    "CI pipeline optimization",
    "Test code optimization",
    "Test code optimization",
    "Test code optimization",
    "CI pipeline optimization",
    "Test infrastructure optimization",
    "UUT optimization",
    "UUT optimization",
    "CI pipeline optimization",
    "CI pipeline optimization",
    "CI pipeline optimization",
    "UUT optimization",
    "Test code optimization",
    "Test code optimization",
    "Test infrastructure optimization",
    "Test code optimization",
    "Test scheduling optimization",
    "Test infrastructure optimization",
    "CI pipeline optimization",
    "CI pipeline optimization",
    "UUT optimization",
    "Test code optimization",
    "Test code optimization",
    "Test code optimization",
    "Test infrastructure optimization",
    "Test infrastructure optimization",
    "CI pipeline optimization",
    "Test code optimization",
    "Test code optimization",
    "Test code optimization",
    "Test code optimization",
    "Test code optimization",
    "CI pipeline optimization",
    "CI pipeline optimization",
    "CI pipeline optimization",
    "Test infrastructure optimization",
    "Test scheduling optimization",
    "Test infrastructure optimization",
    "Test infrastructure optimization",
    "CI pipeline optimization",
    "Test code optimization",
    "Test code optimization",
    "Test code optimization",
    "Test code optimization",
    "CI pipeline optimization",
    "UUT optimization",
    "Test code optimization",
    "Test infrastructure optimization",
    "Test code optimization",
    "UUT optimization",
    "CI pipeline optimization",
    "CI pipeline optimization",
    "CI pipeline optimization",
    "Test infrastructure optimization",
    "CI pipeline optimization",
    "Test code optimization",
    "CI pipeline optimization",
    "Test scheduling optimization",
    "Test code optimization"
]

# Normalize category names (fix inconsistent capitalization)
categories = [cat.replace("Test Scheduling optimization", "Test scheduling optimization") for cat in categories]

counts = Counter(categories)
labels = list(counts.keys())
sizes = list(counts.values())

# Use serif font for academic papers (Times-like)
plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.serif'] = ['Times New Roman', 'DejaVu Serif', 'Liberation Serif']
plt.rcParams['font.size'] = 8  # Base font size for conference papers

# Professional color scheme (colorblind-friendly)
colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b']

# Sort by size for better visualization
sorted_data = sorted(zip(labels, sizes), key=lambda x: x[1], reverse=True)
labels, sizes = zip(*sorted_data)

# Adjust figure size for two-column format (typically 3.5 inches wide)
fig, ax = plt.subplots(figsize=(3, 3))

# Create pie chart with improved styling
wedges, texts, autotexts = ax.pie(
    sizes,
    labels=None,  # Move labels to legend for cleaner look
    autopct='%1.1f%%',
    startangle=90,
    colors=colors,
    textprops={'fontsize': 10, 'weight': 'bold'},
    pctdistance=0.75,
    wedgeprops={'linewidth': 0.5, 'edgecolor': 'white'}
)

# Make percentage text white for better contrast
for autotext in autotexts:
    autotext.set_color('white')
    autotext.set_fontsize(10)
    autotext.set_weight('bold')

# Add legend with abbreviated labels to save space
label_abbrev = {
    'Test code optimization': 'Test Code',
    'CI pipeline optimization': 'CI Pipeline',
    'Test infrastructure optimization': 'Test Infrastructure',
    'UUT optimization': 'UUT',
    'Test scheduling optimization': 'Test Scheduling'
}

legend_labels = [f"{label_abbrev.get(label, label)} ({size})"
                 for label, size in zip(labels, sizes)]

ax.legend(
    legend_labels,
    loc='center left',
    bbox_to_anchor=(1, 0.5),
    fontsize=16,
    frameon=False
)

ax.axis('equal')

# Remove margins completely
fig.subplots_adjust(left=0, right=1, top=1, bottom=0)

# Save with high DPI for print quality - bbox_inches='tight' will crop to content
out_path = os.path.join(script_dir, "..", "img", "rq1_ratio_pie.png")
plt.savefig(out_path, dpi=300, bbox_inches='tight', pad_inches=0.01, format='png')
print(f"Saved pie chart to: {out_path}")

# Also save as PDF for LaTeX (vector format, better quality)
out_path_pdf = os.path.join(script_dir, "..", "img", "rq1_ratio_pie.pdf")
plt.savefig(out_path_pdf, bbox_inches='tight', pad_inches=0.01, format='pdf')
print(f"Saved PDF version to: {out_path_pdf}")

# Create second pie chart for Category column from CSV
print("\nCreating second pie chart for Category column...")

counts2 = Counter(categories_col2)
labels2 = list(counts2.keys())
sizes2 = list(counts2.values())

# Sort by size for better visualization
sorted_data2 = sorted(zip(labels2, sizes2), key=lambda x: x[1], reverse=True)
labels2, sizes2 = zip(*sorted_data2)

# Set Times New Roman font for the second chart
plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.serif'] = ['Times New Roman', 'DejaVu Serif', 'Liberation Serif']

# Create new figure for second pie chart - larger to accommodate many legend items
fig2, ax2 = plt.subplots(figsize=(5, 5))

# Professional color scheme (colorblind-friendly) - extended palette if needed
colors2 = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf']

# Create pie chart with improved styling - larger font size for readability
wedges2, texts2, autotexts2 = ax2.pie(
    sizes2,
    labels=None,
    autopct='%1.1f%%',
    startangle=90,
    colors=colors2[:len(labels2)],
    textprops={'fontsize': 14, 'weight': 'bold'},
    pctdistance=0.75,
    wedgeprops={'linewidth': 0.5, 'edgecolor': 'white'}
)

# Make percentage text white for better contrast
for autotext in autotexts2:
    autotext.set_color('white')
    autotext.set_fontsize(18)
    autotext.set_weight('bold')

# Add legend with counts - larger font size for readability with 8 items
legend_labels2 = [f"{label} ({size})" for label, size in zip(labels2, sizes2)]

ax2.legend(
    legend_labels2,
    loc='center left',
    bbox_to_anchor=(0.95, 0.5),
    fontsize=22,
    frameon=False
)

ax2.axis('equal')

# Remove margins completely
fig2.subplots_adjust(left=0, right=1, top=1, bottom=0)

# Save with high DPI for print quality - bbox_inches='tight' will crop to content
out_path2 = os.path.join(script_dir, "..", "img", "rq1_category_pie.png")
plt.savefig(out_path2, dpi=300, bbox_inches='tight', pad_inches=0.01, format='png')
print(f"Saved second pie chart to: {out_path2}")

# Also save as PDF for LaTeX (vector format, better quality)
out_path2_pdf = os.path.join(script_dir, "..", "img", "rq1_category_pie.pdf")
plt.savefig(out_path2_pdf, bbox_inches='tight', pad_inches=0.01, format='pdf')
print(f"Saved PDF version to: {out_path2_pdf}")
