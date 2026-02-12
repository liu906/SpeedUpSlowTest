#!/usr/bin/env python3
"""Collect project statistics for LaTeX table."""

import os
import subprocess
from pathlib import Path

# Project metadata
projects = {
    # Mockable projects
    'pyjelly_235': {
        'name': 'pyjelly',
        'domain': 'Scientific Computing',
        'pr': '235',
        'strategy': 'Mock-based'
    },
    'ert_11206': {
        'name': 'ert',
        'domain': 'Scientific Computing',
        'pr': '11206',
        'strategy': 'Mock-based'
    },
    'autosubmit_2367': {
        'name': 'autosubmit',
        'domain': 'Workflow Management',
        'pr': '2367',
        'strategy': 'Mock-based'
    },
    'blueprints_691': {
        'name': 'blueprints',
        'domain': 'Web Framework',
        'pr': '691',
        'strategy': 'Mock-based'
    },
    'ophyd-async_316': {
        'name': 'ophyd-async',
        'domain': 'Scientific Computing',
        'pr': '316',
        'strategy': 'Mock-based'
    },
    'quant-mind_58': {
        'name': 'quant-mind',
        'domain': 'ML/Finance',
        'pr': '58',
        'strategy': 'Mock-based'
    },
    'nipoppy_697': {
        'name': 'nipoppy',
        'domain': 'Data Processing',
        'pr': '697',
        'strategy': 'Mock-based'
    },
    'vulnerablecode_490': {
        'name': 'vulnerablecode',
        'domain': 'Security',
        'pr': '490',
        'strategy': 'Mock-based'
    },
    'SDV_2158': {
        'name': 'SDV',
        'domain': 'Machine Learning',
        'pr': '2158',
        'strategy': 'Mock-based'
    },
    'BazBOM_33': {
        'name': 'BazBOM',
        'domain': 'Data Management',
        'pr': '33',
        'strategy': 'Mock-based'
    },
    # Unknown strategy projects
    'python-dts-calibration_197': {
        'name': 'python-dts-calibration',
        'domain': 'Scientific Computing',
        'pr': '197',
        'strategy': 'Non-mock'
    },
    'opensearch-build_595': {
        'name': 'opensearch-build',
        'domain': 'Build Infrastructure',
        'pr': '595',
        'strategy': 'Non-mock'
    },
    'pydicom_1636': {
        'name': 'pydicom',
        'domain': 'Medical Imaging',
        'pr': '1636',
        'strategy': 'Non-mock'
    },
    'roms-tools_107': {
        'name': 'roms-tools',
        'domain': 'Scientific Computing',
        'pr': '107',
        'strategy': 'Non-mock'
    },
    'armi_1737': {
        'name': 'armi',
        'domain': 'Scientific Computing',
        'pr': '1737',
        'strategy': 'Non-mock'
    },
    'BuffaLogs_399': {
        'name': 'BuffaLogs',
        'domain': 'Monitoring',
        'pr': '399',
        'strategy': 'Non-mock'
    },
    'detection-rules_2626': {
        'name': 'detection-rules',
        'domain': 'Security',
        'pr': '2626',
        'strategy': 'Non-mock'
    },
    'lightning-thunder_2077': {
        'name': 'lightning-thunder',
        'domain': 'Machine Learning',
        'pr': '2077',
        'strategy': 'Non-mock'
    },
    'patientMatcher_262': {
        'name': 'patientMatcher',
        'domain': 'Healthcare',
        'pr': '262',
        'strategy': 'Non-mock'
    },
    'dfm_tools_976': {
        'name': r'dfm\_tools',
        'domain': 'Scientific Computing',
        'pr': '976',
        'strategy': 'Non-mock'
    }
}

def count_loc(project_dir):
    """Count lines of code excluding tests and virtual environments."""
    try:
        result = subprocess.run(
            f"find {project_dir} -name '*.py' -not -path '*/.venv/*' -not -path '*/venv/*' "
            f"-not -path '*/__pycache__/*' -not -path '*/test*' -not -path '*/tests/*' | "
            f"xargs wc -l 2>/dev/null | tail -1",
            shell=True,
            capture_output=True,
            text=True
        )
        if result.stdout:
            loc = int(result.stdout.strip().split()[0])
            return round(loc / 1000, 1)  # Return KLOC
    except:
        pass
    return None

def count_tests(project_dir):
    """Count test files."""
    try:
        result = subprocess.run(
            f"find {project_dir} -name 'test*.py' -o -name '*test.py' | wc -l",
            shell=True,
            capture_output=True,
            text=True
        )
        if result.stdout:
            return int(result.stdout.strip())
    except:
        pass
    return None

def main():
    versions_dir = Path('/data/SpeedUpSlowTest/versions')

    print("\\begin{table*}[t]")
    print("\\centering")
    print("\\caption{Overview of the 20 studied projects with slow test issues}")
    print("\\label{tab:studied-projects}")
    print("\\begin{tabular}{llcccrr}")
    print("\\toprule")
    print("\\textbf{Project} & \\textbf{Domain} & \\textbf{PR} & \\textbf{Fix Strategy} & \\textbf{KLOC} & \\textbf{\\#Tests} \\\\")
    print("\\midrule")

    # Process mockable projects first
    print("\\multicolumn{6}{l}{\\textit{Mockable Projects (Fixed by Developers with Mock-based Strategies)}} \\\\")
    for proj_id, metadata in projects.items():
        if metadata['strategy'] == 'Mock-based':
            project_dir = versions_dir / proj_id / 'before'
            if project_dir.exists():
                kloc = count_loc(project_dir)
                num_tests = count_tests(project_dir)

                print(f"{metadata['name']} & {metadata['domain']} & \\#{metadata['pr']} & "
                      f"{metadata['strategy']} & {kloc if kloc else 'N/A'} & {num_tests if num_tests else 'N/A'} \\\\")

    print("\\midrule")
    print("\\multicolumn{6}{l}{\\textit{Unknown Strategy Projects (Fixed by Developers with Non-mock Strategies)}} \\\\")
    for proj_id, metadata in projects.items():
        if metadata['strategy'] == 'Non-mock':
            project_dir = versions_dir / proj_id / 'before'
            if project_dir.exists():
                kloc = count_loc(project_dir)
                num_tests = count_tests(project_dir)

                print(f"{metadata['name']} & {metadata['domain']} & \\#{metadata['pr']} & "
                      f"{metadata['strategy']} & {kloc if kloc else 'N/A'} & {num_tests if num_tests else 'N/A'} \\\\")

    print("\\bottomrule")
    print("\\end{tabular}")
    print("\\end{table*}")

if __name__ == '__main__':
    main()
