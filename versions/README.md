# Generic Test Runner for Multiple Projects

This directory contains reusable scripts for running tests, measuring energy consumption, and visualizing results across multiple project versions.

## Directory Structure

```
versions/
├── run_tests_generic.sh           # Generic test runner
├── parse_results_generic.py       # Generic result parser
├── visualize_results_generic.py   # Generic visualization script
├── README.md                       # This file
├── BuffaLogs_399/
│   ├── test_config.sh             # Project-specific configuration
│   ├── before/                    # Before version
│   ├── after/                     # After version
│   ├── test_results.log           # Generated log file
│   ├── energy_data.csv            # Generated energy data
│   ├── duration_data.csv          # Generated duration data
│   └── comparison_violin_plots.png # Generated visualization
├── BuffaLogs_400/
│   └── test_config.sh
└── BuffaLogs_405/
    └── test_config.sh
```

## Quick Start

### 1. Configure Your Project

Each project needs a `test_config.sh` file in its root directory. Example:

```bash
#!/bin/bash
# Test configuration for YourProject

# Test command to run (without energibridge prefix)
TEST_COMMAND="docker compose exec container_name ./command --flags"

# Optional: Wait time in seconds after docker compose up
WAIT_TIME=10

# Optional: Additional project-specific variables
PROJECT_NAME="YourProject"
```

### 2. Run Tests

```bash
# Run tests with default 10 iterations
./run_tests_generic.sh BuffaLogs_399

# Run tests with custom iterations
./run_tests_generic.sh BuffaLogs_399 20
```

This will:
- Start Docker containers in the `before/` directory
- Run tests N times with energy measurement
- Stop Docker containers
- Repeat for the `after/` directory
- Save all output to `test_results.log`

### 3. Parse Results

```bash
python3 parse_results_generic.py BuffaLogs_399
```

This will:
- Parse the log file
- Extract energy consumption data → `energy_data.csv`
- Extract test duration data → `duration_data.csv`
- Print summary statistics

### 4. Visualize Results

```bash
python3 visualize_results_generic.py BuffaLogs_399
```

This will:
- Load the CSV data
- Print summary statistics
- Generate violin plots → `comparison_violin_plots.png`

## Complete Workflow Example

```bash
# For BuffaLogs_399
./run_tests_generic.sh BuffaLogs_399 10
python3 parse_results_generic.py BuffaLogs_399
python3 visualize_results_generic.py BuffaLogs_399

# For BuffaLogs_400
./run_tests_generic.sh BuffaLogs_400 10
python3 parse_results_generic.py BuffaLogs_400
python3 visualize_results_generic.py BuffaLogs_400

# For BuffaLogs_405
./run_tests_generic.sh BuffaLogs_405 10
python3 parse_results_generic.py BuffaLogs_405
python3 visualize_results_generic.py BuffaLogs_405
```

## Requirements

### System Requirements
- Docker and Docker Compose
- energibridge tool installed
- Python 3.x

### Python Dependencies
```bash
pip install matplotlib seaborn
```

## Adding a New Project

1. Create the project directory structure:
   ```
   versions/YourProject/
   ├── before/
   └── after/
   ```

2. Create `test_config.sh`:
   ```bash
   cd versions/YourProject
   cat > test_config.sh << 'EOF'
   #!/bin/bash
   TEST_COMMAND="your test command here"
   WAIT_TIME=10
   PROJECT_NAME="YourProject"
   EOF
   chmod +x test_config.sh
   ```

3. Run the scripts:
   ```bash
   cd versions
   ./run_tests_generic.sh YourProject 10
   python3 parse_results_generic.py YourProject
   python3 visualize_results_generic.py YourProject
   ```

## Configuration Options

### test_config.sh Variables

- **TEST_COMMAND** (required): The test command to run, without the `energibridge` prefix
  - Example: `docker compose exec buffalogs ./manage.py test module.tests --durations=0`

- **WAIT_TIME** (optional): Seconds to wait after `docker compose up -d` for containers to be ready
  - Default: Not set (no wait)
  - Example: `WAIT_TIME=10`

- **PROJECT_NAME** (optional): Human-readable project name for display
  - Default: Directory name
  - Example: `PROJECT_NAME="BuffaLogs Issue #399"`

## Output Files

After running the complete workflow, each project directory will contain:

- **test_results.log**: Complete log of all test runs with energy measurements
- **energy_data.csv**: Energy consumption data with columns:
  - version, run_number, energy_joules, execution_time_sec, average_power_watts
- **duration_data.csv**: Test duration data with columns:
  - version, run_number, test_name, test_path, duration_sec, total_test_time
- **comparison_violin_plots.png**: Violin plots comparing before/after versions

## Troubleshooting

### Docker Container Conflicts
If you get "container name already in use" errors:
```bash
cd project/before  # or after
docker compose down -v
```

### energibridge Not Found
Install energibridge or modify the script to remove energy measurement:
```bash
# In test_config.sh, you can modify TEST_COMMAND to not use energibridge
# But you'll need to edit run_tests_generic.sh line that uses energibridge
```

### No Data in CSV Files
Check `test_results.log` to ensure:
1. Tests are actually running
2. Energy data is being reported
3. Test duration information is present

## Legacy Scripts

The project-specific scripts in BuffaLogs_399 are kept for reference:
- `run_tests.sh` (old, project-specific version)
- `parse_test_results.py` (old, project-specific version)
- `visualize_results.py` (old, project-specific version)

These are now replaced by the generic versions at the versions/ level.
