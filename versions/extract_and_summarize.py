#!/usr/bin/env python3
"""
Helper script to extract project names from run_unknown_projects.sh and generate summary.

Usage: python3 extract_and_summarize.py [--suffix <log_suffix>] [--output <output_file>]
Example: python3 extract_and_summarize.py --suffix only_mock_part

This script:
1. Parses run_unknown_projects.sh to extract project names
2. Calls summarize_projects.py with the extracted project list
"""

import re
import subprocess
import sys
from pathlib import Path


def extract_projects_from_script(script_path):
    """Extract project names from the run script."""
    projects = []

    # Regex patterns to match project invocations
    # Matches: bash run_tests_venv_generic.sh <project_name> $REPEAT ...
    # Matches: bash ./run_tests_generic.sh <project_name>/ $REPEAT ...
    pattern1 = re.compile(r'bash\s+run_tests_venv_generic\.sh\s+(\S+)\s+\$REPEAT')
    pattern2 = re.compile(r'bash\s+\./run_tests_generic\.sh\s+(\S+)/\s+\$REPEAT')

    with open(script_path, 'r') as f:
        for line in f:
            # Skip commented lines
            if line.strip().startswith('#'):
                continue

            # Try both patterns
            match = pattern1.search(line) or pattern2.search(line)
            if match:
                project = match.group(1)
                if project not in projects:
                    projects.append(project)

    return projects


def main():
    # Parse arguments
    log_suffix = None
    output_file = None

    i = 1
    while i < len(sys.argv):
        arg = sys.argv[i]
        if arg == '--suffix':
            if i + 1 < len(sys.argv):
                log_suffix = sys.argv[i + 1]
                i += 2
            else:
                print("Error: --suffix requires an argument")
                sys.exit(1)
        elif arg == '--output':
            if i + 1 < len(sys.argv):
                output_file = sys.argv[i + 1]
                i += 2
            else:
                print("Error: --output requires an argument")
                sys.exit(1)
        else:
            print(f"Unknown argument: {arg}")
            sys.exit(1)

    # Find run_unknown_projects.sh
    script_dir = Path(__file__).parent
    run_script = script_dir / "run_unknown_projects.sh"

    if not run_script.exists():
        print(f"Error: {run_script} not found")
        sys.exit(1)

    # Extract project names
    print("Extracting project names from run_unknown_projects.sh...")
    projects = extract_projects_from_script(run_script)

    if not projects:
        print("Error: No projects found in the script")
        sys.exit(1)

    print(f"Found {len(projects)} projects:")
    for project in projects:
        print(f"  - {project}")
    print()

    # Build command for summarize_projects.py
    cmd = ["python3", str(script_dir / "summarize_projects.py")] + projects

    if log_suffix:
        cmd.extend(["--suffix", log_suffix])
    if output_file:
        cmd.extend(["--output", output_file])

    # Run summarize_projects.py
    print("Running summarize_projects.py...")
    print("-" * 60)
    result = subprocess.run(cmd)

    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
