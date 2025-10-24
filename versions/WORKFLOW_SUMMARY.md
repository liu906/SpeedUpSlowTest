# Slow Test Optimization Experiment - Workflow Summary

## Project Overview

This project measures and compares energy consumption and execution time of slow tests before and after optimization. The workflow supports multiple projects with different testing setups (Docker-based and Python virtual environment-based).

---

## Directory Structure

```
versions/
├── WORKFLOW_SUMMARY.md                    # This file
├── run_tests_generic.sh                   # Generic test runner for Docker-based projects
├── run_tests_venv_generic.sh             # Generic test runner for venv-based projects
├── parse_results_generic.py              # Generic parser for test results
├── visualize_results_generic.py          # Generic visualization script
│
├── <project_name>/                        # Each project has its own directory
│   ├── test_config.sh                    # Project-specific configuration
│   ├── test_results.log                  # Generated: Combined test logs (before/after)
│   ├── energy_data.csv                   # Generated: Extracted energy measurements
│   ├── duration_data.csv                 # Generated: Extracted test durations
│   ├── comparison_violin_plots.png       # Generated: Visualization
│   ├── before/                           # Code before optimization
│   │   ├── .venv/                       # Auto-created virtual environment (venv projects)
│   │   ├── docker-compose.yml           # Docker configuration (Docker projects)
│   │   └── ... (project files)
│   └── after/                            # Code after optimization
│       ├── .venv/                       # Auto-created virtual environment (venv projects)
│       ├── docker-compose.yml           # Docker configuration (Docker projects)
│       └── ... (project files)
```

---

## Workflow Steps

### 1. **Setup: Create test_config.sh**

Each project requires a `test_config.sh` file that defines:

#### For Docker-based projects (use `run_tests_generic.sh`):
```bash
#!/bin/bash
# Test configuration for <project_name>

# Test command to run inside Docker container (without energibridge prefix)
TEST_COMMAND="docker compose exec <container> pytest <test_path> --durations=0"

# Optional: Setup command to run after containers are up (e.g., install dependencies)
SETUP_COMMAND="docker compose exec <container> pip install pytest pytest-django"

# Optional: Wait time in seconds after docker compose up
WAIT_TIME=10

# Optional: Project name
PROJECT_NAME="<project_name>"
```

**Example projects:** BuffaLogs_400, ai-platform_325

#### For Python venv-based projects (use `run_tests_venv_generic.sh`):
```bash
#!/bin/bash
# Test configuration for <project_name>

# Test command to run (without energibridge prefix)
TEST_COMMAND="pytest <test_path> --durations=0"

# Virtual environment path (relative to before/after directories)
VENV_PATH=".venv"

# Optional: Setup command to run after activating venv
SETUP_COMMAND="pip install pytest && pip install -e ."

# Optional: Wait time in seconds before starting tests
# WAIT_TIME=2

# Optional: Project name
PROJECT_NAME="<project_name>"
```

**Example projects:** autosubmit_2367, bilby_986

---

### 2. **Run Tests**

#### For Docker-based projects:
```bash
./run_tests_generic.sh <project_name> [number_of_runs]

# Example:
./run_tests_generic.sh BuffaLogs_400 10
```

**What it does:**
- Reads configuration from `<project_name>/test_config.sh`
- For each version (before/after):
  - Builds Docker containers (`docker compose build`)
  - Starts containers (`docker compose up -d`)
  - Waits for containers to be ready
  - Runs setup commands (e.g., install dependencies)
  - Executes tests N times with `energibridge` for energy measurement
  - Shuts down containers (`docker compose down -v`)
- Logs all output to `<project_name>/test_results.log`

#### For Python venv-based projects:
```bash
./run_tests_venv_generic.sh <project_name> [number_of_runs]

# Example:
./run_tests_venv_generic.sh bilby_986 10
```

**What it does:**
- Reads configuration from `<project_name>/test_config.sh`
- For each version (before/after):
  - Auto-creates virtual environment if not exists
  - Installs dependencies from `requirements.txt` or `pyproject.toml`
  - Activates virtual environment
  - Runs setup commands (e.g., `pip install pytest`)
  - Executes tests N times with `energibridge` for energy measurement
  - Deactivates virtual environment
- Logs all output to `<project_name>/test_results.log`

**Default number of runs:** 10 (if not specified)

---

### 3. **Parse Results**

```bash
python3 parse_results_generic.py <project_name>

# Example:
python3 parse_results_generic.py bilby_986
```

**What it does:**
- Reads `<project_name>/test_results.log`
- Extracts energy consumption data (joules, watts, execution time)
- Extracts test duration data from pytest output
- Saves structured data to:
  - `<project_name>/energy_data.csv`
  - `<project_name>/duration_data.csv`
- Displays summary statistics:
  - Average energy consumption (before/after)
  - Energy improvement percentage
  - Average test duration (before/after)
  - Time improvement percentage

**Output example:**
```
Energy data extracted:
  Before version: 10 entries
  After version: 10 entries
  Average energy (before): 119.01 J
  Average energy (after): 63.98 J
  Energy improvement: 46.24%

Test duration data extracted:
  Before version: 20 entries
  After version: 20 entries
  Average test duration (before): 1.261s
  Average test duration (after): 0.208s
  Time improvement: 83.47%
```

---

### 4. **Visualize Results**

```bash
python3 visualize_results_generic.py <project_name>

# Example:
python3 visualize_results_generic.py bilby_986
```

**What it does:**
- Reads CSV files from step 3
- Generates violin plots comparing:
  - Energy consumption (before vs after)
  - Test execution time (before vs after)
- Saves visualization to `<project_name>/comparison_violin_plots.png`
- Displays detailed summary statistics

---

## Complete Workflow Example

```bash
# 1. Run tests (10 iterations by default)
./run_tests_venv_generic.sh bilby_986

# 2. Parse the results
python3 parse_results_generic.py bilby_986

# 3. Visualize the data
python3 visualize_results_generic.py bilby_986

# View the generated plot
open bilby_986/comparison_violin_plots.png
```

---

## Key Features

### 1. **Generic Scripts**
- Two generic test runners for different project types
- One parser works for all projects
- One visualizer works for all projects
- Reduces code duplication across projects

### 2. **Automated Environment Setup**
- **Docker projects:** Auto-builds and manages containers
- **Venv projects:** Auto-creates virtual environments and installs dependencies
- No manual setup required after initial `test_config.sh` creation

### 3. **Energy Measurement**
- Uses `energibridge` for accurate energy consumption tracking
- Captures:
  - Total energy in joules
  - Execution time in seconds
  - Average power in watts

### 4. **Comprehensive Logging**
- Single unified log file per project
- Contains both before and after test runs
- Includes timestamps and run numbers
- Compatible with parser for automated extraction

### 5. **Statistical Analysis**
- Calculates averages, min, max for energy and time
- Computes improvement percentages
- Provides visual comparison via violin plots

---

## Supported Project Types

### Type 1: Docker-based Projects
**Projects:** BuffaLogs_400, ai-platform_325

**Requirements:**
- `docker-compose.yml` in before/after directories
- Docker containers that can execute tests

**Test Runner:** `run_tests_generic.sh`

---

### Type 2: Python Virtual Environment Projects
**Projects:** autosubmit_2367, bilby_986

**Requirements:**
- Python project with `requirements.txt` or `pyproject.toml`
- Tests runnable via pytest

**Test Runner:** `run_tests_venv_generic.sh`

---

## Configuration Reference

### Required Variables in test_config.sh:
- `TEST_COMMAND` - The test command to execute
- `VENV_PATH` - (venv projects only) Path to virtual environment

### Optional Variables:
- `SETUP_COMMAND` - Commands to run during setup
- `WAIT_TIME` - Seconds to wait before starting tests
- `PROJECT_NAME` - Descriptive project name

---

## Output Files

### 1. `test_results.log`
- Raw output from all test runs
- Used by parser to extract data
- Format compatible with both test runner types

### 2. `energy_data.csv`
Columns: `version, run_number, energy_joules, execution_time_sec, average_power_watts`

### 3. `duration_data.csv`
Columns: `version, test_name, duration`

### 4. `comparison_violin_plots.png`
- Visual comparison of before/after
- Two subplots: Energy and Time
- Shows distribution with violin plots

---

## Benefits of This Workflow

1. **Reproducibility:** Automated scripts ensure consistent measurements
2. **Scalability:** Easy to add new projects with just a config file
3. **Accuracy:** Uses energibridge for hardware-level energy measurements
4. **Comprehensive:** Captures both energy and performance metrics
5. **Visual:** Clear visualization of improvements
6. **Flexible:** Supports multiple project types and configurations

---

## Adding a New Project

1. Create project directory structure:
   ```bash
   mkdir -p <project_name>/before
   mkdir -p <project_name>/after
   ```

2. Copy before/after code into respective directories

3. Create `<project_name>/test_config.sh` based on project type

4. Run the workflow:
   ```bash
   ./run_tests_generic.sh <project_name>         # For Docker projects
   # OR
   ./run_tests_venv_generic.sh <project_name>    # For venv projects

   python3 parse_results_generic.py <project_name>
   python3 visualize_results_generic.py <project_name>
   ```

---

## Example Results Summary (bilby_986)

```
Energy improvement: 46.24%
  Before: 119.01 J (avg)
  After:   63.98 J (avg)

Time improvement: 83.47%
  Before: 1.261s (avg per test)
  After:  0.208s (avg per test)
```

This demonstrates the effectiveness of the optimization, showing significant improvements in both energy consumption and execution time.
