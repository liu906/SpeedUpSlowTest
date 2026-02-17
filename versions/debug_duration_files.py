#!/usr/bin/env python3
"""
Debug script to check duration data files for specific projects.
"""

import pandas as pd
from pathlib import Path

def check_project(project_name):
    """Check duration data for a specific project."""
    project_path = Path.cwd() / project_name
    duration_file = project_path / 'duration_data.csv'

    print(f"\n{'='*60}")
    print(f"PROJECT: {project_name}")
    print(f"{'='*60}")

    if not duration_file.exists():
        print(f"❌ File does not exist: {duration_file}")
        return

    print(f"✓ File exists: {duration_file}")
    print(f"  File size: {duration_file.stat().st_size} bytes")

    try:
        df = pd.read_csv(duration_file)
        print(f"\n📊 Data Summary:")
        print(f"  Total rows: {len(df)}")
        print(f"  Columns: {df.columns.tolist()}")

        if 'version' in df.columns:
            print(f"\n  Version counts:")
            for version, count in df['version'].value_counts().items():
                print(f"    '{version}': {count} rows")

            # Check for whitespace issues
            unique_versions = df['version'].unique()
            print(f"\n  Unique version values (with repr):")
            for ver in unique_versions:
                print(f"    {repr(ver)} (len={len(str(ver))})")

            # Calculate stats for each version
            for version in ['before', 'after']:
                version_df = df[df['version'] == version]
                if not version_df.empty and 'total_test_time' in df.columns:
                    avg_time = version_df['total_test_time'].mean()
                    print(f"\n  '{version}' total_test_time:")
                    print(f"    Average: {avg_time}")
                    print(f"    Min: {version_df['total_test_time'].min()}")
                    print(f"    Max: {version_df['total_test_time'].max()}")
                    print(f"    Count: {len(version_df)}")
                else:
                    if not version_df.empty:
                        print(f"\n  '{version}': {len(version_df)} rows (but no 'total_test_time' column)")
                    else:
                        print(f"\n  '{version}': NO DATA FOUND")
        else:
            print(f"\n  ❌ No 'version' column found!")
            print(f"  Available columns: {df.columns.tolist()}")

    except Exception as e:
        print(f"\n❌ Error reading file: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    projects = ['BuffaLogs_400', 'core_60348']

    for project in projects:
        check_project(project)

    print(f"\n{'='*60}")
