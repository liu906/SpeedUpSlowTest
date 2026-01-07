# System Pipeline Documentation: Energy-Aware Slow Test Optimization

## Overview

This system provides an automated pipeline for evaluating the effectiveness of "slow test" fixes in open-source projects by measuring energy consumption, execution time, and test coverage preservation. The pipeline supports comparison between original implementations, developer fixes, and Claude Code-generated mock-based optimizations.

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Phase 1: Data Collection](#phase-1-data-collection)
3. [Phase 2: Version Management](#phase-2-version-management)
4. [Phase 3: Mock Implementation](#phase-3-mock-implementation)
5. [Phase 4: Energy Measurement](#phase-4-energy-measurement)
6. [Phase 5: Coverage Verification](#phase-5-coverage-verification)
7. [Phase 6: Statistical Analysis](#phase-6-statistical-analysis)
8. [Phase 7: Multi-Project Aggregation](#phase-7-multi-project-aggregation)
9. [Configuration System](#configuration-system)
10. [Output Artifacts](#output-artifacts)
11. [Workflow Examples](#workflow-examples)

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SYSTEM PIPELINE                              │
└─────────────────────────────────────────────────────────────────────┘

PHASE 1: GitHub Data Collection
    │
    ├─→ fetch_slow_tests_gql.py (GraphQL queries)
    │       └─→ slow_test_issues.csv
    │
    └─→ Manual PR Selection
            └─→ ListOptTestItself-batch*.txt

PHASE 2: Version Management
    │
    └─→ pr_versions.py
            └─→ versions/{project}_{pr}/before/
            └─→ versions/{project}_{pr}/after/

PHASE 3: Mock Implementation (Claude Code)
    │
    ├─→ prompt_template_mock_speedup_short.md (guidelines)
    │
    └─→ Manual/Semi-Automated Mocking
            └─→ versions/{project}_{pr}/after_careful_mock/

PHASE 4: Energy Measurement (N=10 runs)
    │
    ├─→ run_tests_venv_generic.sh
    │       └─→ test_results_{suffix}.log
    │
    └─→ parse_results_generic_optimized.py
            ├─→ energy_data_{suffix}.csv
            ├─→ duration_data_{suffix}.csv
            ├─→ execution_time_data_{suffix}.csv
            └─→ comparison_violin_plots_{suffix}.png

PHASE 5: Coverage Verification (1 run)
    │
    ├─→ run_tests_venv_generic_coverage.sh
    │       └─→ coverage_{version}_{suffix}.json
    │
    └─→ compare_coverage.py
            └─→ coverage_comparison_{suffix}.txt

PHASE 6: Statistical Analysis
    │
    └─→ summarize_projects.py
            ├─→ project_summary_{suffix}.csv
            └─→ energy_violin_plot_{suffix}.png

PHASE 7: Multi-Project Aggregation
    │
    └─→ summarize_coverage_results.py
            └─→ coverage_summary.csv
```

---

## Phase 1: Data Collection

### Purpose
Identify GitHub projects with Pull Requests that fix slow tests.

### Tools

#### [fetch_slow_tests_gql.py](fetch_slow_tests_gql.py)
GraphQL-based GitHub issue searcher.

**Key Features:**
- Searches for issues with keywords: "slow test", "flaky test", etc.
- Filters by: closed status, linked PRs, minimum stars, comment count
- Outputs comprehensive metadata to CSV

**Usage:**
```bash
python fetch_slow_tests_gql.py --token YOUR_GITHUB_TOKEN
```

**Output:** [slow_test_issues.csv](slow_test_issues.csv)
- Columns: `repo_name`, `issue_number`, `issue_title`, `created_at`, `closed_at`, `pr_numbers`, `stars`, `comment_count`

#### [fetch_fixed_slow_tests_gql.py](fetch_fixed_slow_tests_gql.py)
Enhanced version with date-based sharding to bypass GitHub's 1000-result API limit.

**Features:**
- Time window-based queries
- Rate limiting protection
- Deduplication across queries
- Star count filtering

**Usage:**
```bash
python fetch_fixed_slow_tests_gql.py \
    --token YOUR_TOKEN \
    --min-stars 100 \
    --start-date 2020-01-01 \
    --end-date 2024-12-31
```

### Manual PR Selection

Create batch files with PR URLs (one per line):

**Example: [ListOptTestItself-batch1.txt](ListOptTestItself-batch1.txt)**
```
https://github.com/owner/repo1/pull/123
https://github.com/owner/repo2/pull/456
```

---

## Phase 2: Version Management

### Purpose
Download and manage "before" (PR base) and "after" (PR merge) versions of projects.

### Tool: [pr_versions.py](pr_versions.py)

**Core Functions:**

#### `get_pr_versions(repo, pr_number)`
Downloads both versions of a PR:
- **Before version**: Base commit SHA (state before PR)
- **After version**: Merge commit SHA (state after PR merged)

**Directory Structure Created:**
```
versions/
└── {repo_name}_{pr_number}/
    ├── before/          # Original code before PR
    └── after/           # Original code after PR
```

#### `smart_copy_tree(src, dst, preserve_patterns)`
Intelligent directory copying that:
- Preserves user-created files (e.g., `after_careful_mock/`, `test_config_*.sh`)
- Avoids overwriting manual work during updates
- Handles symbolic links properly

#### `process_prs_file(file_path)`
Batch processes PRs from a text file.

**Usage:**
```bash
python pr_versions.py --file ListOptTestItself-batch1.txt
```

**Features:**
- Deduplication (skips already downloaded projects)
- Rate limiting (configurable sleep between requests)
- Error recovery (continues on failures)

---

## Phase 3: Mock Implementation

### Purpose
Apply mocking strategies to slow tests to speed them up while preserving test effectiveness.

### Guidelines: [prompt_template_mock_speedup_short.md](prompt_template_mock_speedup_short.md)

**Core Principles:**

✅ **What to Mock:**
- External network calls (HTTP requests, API calls)
- Database operations (queries, connections)
- File I/O operations (read/write large files)
- Subprocess calls (shell commands, external programs)
- Time-consuming setup/teardown (data generation)

❌ **What NOT to Mock:**
- Internal business logic
- Algorithm implementations
- Verification/assertion logic
- Core functionality being tested

**Quality Metrics:**
- Target: 0-10% coverage loss maximum
- Speedup: Significant reduction in execution time
- Energy: Measurable reduction in joules consumed

### Process

**Manual/Semi-Automated:**
1. Analyze slow tests in `versions/{project}/before/`
2. Apply prompt template guidelines using Claude Code
3. Create `versions/{project}/after_careful_mock/` directory
4. Implement mocks carefully to preserve test intent
5. Create configuration file: `test_config_{suffix}.sh`

**Directory Structure After Mocking:**
```
versions/{project}_{pr}/
├── before/                  # Original (slow)
├── after/                   # Developer's fix
└── after_careful_mock/      # Claude Code mocked version
```

---

## Phase 4: Energy Measurement

### Purpose
Measure energy consumption and execution time across N runs for statistical significance.

### Tools

#### [run_tests_venv_generic.sh](versions/run_tests_venv_generic.sh)
Main test runner for Python virtual environment projects.

**Workflow:**
1. Load project configuration from `test_config_{suffix}.sh`
2. Create/activate Python virtual environment
3. Install dependencies via pip or UV
4. Run tests N times (default: 10) with energibridge
5. Log all output to `test_results_{suffix}.log`

**Key Parameters:**
- `PROJECT_NAME`: e.g., "vulnerablecode_490"
- `NUM_RUNS`: Number of test repetitions (default: 10)
- `VERSION`: "before", "after", or "after_careful_mock"
- `SUFFIX`: Configuration identifier (e.g., "only_mock_part")

**Usage:**
```bash
bash versions/run_tests_venv_generic.sh \
    vulnerablecode_490 \
    10 \
    before \
    only_mock_part
```

**Energibridge Integration:**
```bash
energibridge --summary --quiet -- pytest test_file.py::TestClass::test_method
```

Captures:
- Total energy (joules)
- Average power (watts)
- Execution time (seconds)

#### [run_tests_generic.sh](versions/run_tests_generic.sh)
Extended version supporting Docker-based projects.

**Additional Features:**
- Docker Compose support
- Container-based test execution
- Volume mounting for test results

**Usage for Docker:**
```bash
bash versions/run_tests_generic.sh \
    docker_project_123 \
    10 \
    before \
    docker_config
```

#### Orchestration: [run_all_projects_energy_coverage.sh](versions/run_all_projects_energy_coverage.sh)

Automates the complete workflow for multiple projects:

```bash
for project in "${PROJECTS[@]}"; do
    # Step 1: Energy measurement (10 runs)
    bash run_tests_venv_generic.sh $project 10 before $SUFFIX
    bash run_tests_venv_generic.sh $project 10 after $SUFFIX

    # Step 2: Parse results
    python3 parse_results_generic_optimized.py $project $SUFFIX

    # Step 3: Coverage collection (1 run)
    bash run_tests_venv_generic_coverage.sh $project 1 before $SUFFIX
    bash run_tests_venv_generic_coverage.sh $project 1 after $SUFFIX

    # Step 4: Compare coverage
    python3 compare_coverage.py $project $SUFFIX

    sleep 30  # Cool-down between projects
done
```

### Output: [test_results_{suffix}.log](versions/vulnerablecode_490/test_results_only_mock_part.log)

**Example Log Entry:**
```
=== Run 1/10 for before ===
energibridge: 45.23J 12.34W 3.67s
pytest: ===== test session starts =====
collected 5 items
test_file.py::test_one PASSED
test_file.py::test_two PASSED
===== 2 passed in 3.45s =====
```

---

## Phase 5: Coverage Verification

### Purpose
Ensure mocking/optimization does not significantly harm test effectiveness.

### Tool: [run_tests_venv_generic_coverage.sh](versions/run_tests_venv_generic_coverage.sh)

**Workflow:**
1. Load project configuration
2. Activate virtual environment
3. Run tests **without energibridge** (to avoid interference)
4. Use `coverage run --branch` instead of direct pytest
5. Generate coverage reports in JSON and HTML formats

**Usage:**
```bash
bash versions/run_tests_venv_generic_coverage.sh \
    vulnerablecode_490 \
    1 \
    before \
    only_mock_part
```

**Coverage Command:**
```bash
coverage run --branch -m pytest test_file.py::TestClass::test_method
coverage json -o coverage_before_only_mock_part.json
coverage html -d htmlcov_before_only_mock_part/
```

**Handles:**
- Parallel coverage files (`.coverage.*`)
- Dynamically generated code
- Symlinked source directories

### Analysis: [compare_coverage.py](versions/compare_coverage.py)

**Compares coverage between versions:**

```bash
python compare_coverage.py vulnerablecode_490 only_mock_part
```

**Output: [coverage_comparison_{suffix}.txt](versions/vulnerablecode_490/coverage_comparison_only_mock_part.txt)**

```
=== Coverage Comparison: vulnerablecode_490 (only_mock_part) ===

Overall Coverage:
  Before: 87.5% line coverage, 82.3% branch coverage
  After:  86.8% line coverage, 81.7% branch coverage
  Change: -0.7% lines, -0.6% branches

Files with Significant Changes (>5%):
  - src/utils/network.py: 95% → 45% (mocked HTTP calls)

Status: ACCEPTABLE (< 10% coverage loss)
```

**Metrics Tracked:**
- Overall line coverage percentage
- Overall branch coverage percentage
- Per-file coverage breakdown
- Significant changes (>5% threshold)

---

## Phase 6: Statistical Analysis

### Purpose
Parse raw logs, extract metrics, apply outlier filtering, and visualize results.

### Tool: [parse_results_generic_optimized.py](versions/parse_results_generic_optimized.py)

**Workflow:**
1. Parse `test_results_{suffix}.log` for both "before" and "after" versions
2. Extract energy, duration, and execution time data
3. Calculate speedup ratios and energy reduction percentages
4. Generate CSV files and violin plots

**Usage:**
```bash
python parse_results_generic_optimized.py vulnerablecode_490 only_mock_part
```

**Parsing Capabilities:**
- ANSI color code handling
- Flexible regex patterns for various pytest formats
- Energibridge output extraction
- Individual test duration parsing

**Outputs:**

#### [energy_data_{suffix}.csv](versions/vulnerablecode_490/energy_data_only_mock_part.csv)
```csv
run,version,energy_joules,power_watts,execution_time_seconds
1,before,45.23,12.34,3.67
1,after,28.45,11.23,2.53
...
```

#### [duration_data_{suffix}.csv](versions/vulnerablecode_490/duration_data_only_mock_part.csv)
```csv
run,version,test_name,duration_seconds
1,before,test_integration.py::test_api,2.45
1,after,test_integration.py::test_api,0.87
...
```

#### [execution_time_data_{suffix}.csv](versions/vulnerablecode_490/execution_time_data_only_mock_part.csv)
```csv
run,version,execution_time_seconds
1,before,3.67
1,after,2.53
...
```

#### [comparison_violin_plots_{suffix}.png](versions/vulnerablecode_490/comparison_violin_plots_only_mock_part.png)
Visual comparison of distributions for:
- Energy consumption (joules)
- Total test duration (seconds)
- Energibridge execution time (seconds)

### Visualization: [visualize_results_generic.py](versions/visualize_results_generic.py)

Creates violin plots using matplotlib/seaborn showing:
- Distribution of measurements across N runs
- Before vs. after comparison
- Median, quartiles, and outliers

---

## Phase 7: Multi-Project Aggregation

### Purpose
Aggregate results across multiple projects to identify trends and overall effectiveness.

### Tools

#### [summarize_projects.py](versions/summarize_projects.py)

**Workflow:**
1. Scan `versions/` directory for all projects
2. Load CSV files for each project
3. **Apply IQR outlier filtering** to remove anomalies
4. Calculate aggregate statistics
5. Generate summary CSV and visualizations

**Usage:**
```bash
python summarize_projects.py only_mock_part
```

**IQR Outlier Filtering:**
```python
Q1 = data.quantile(0.25)
Q3 = data.quantile(0.75)
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR
filtered_data = data[(data >= lower_bound) & (data <= upper_bound)]
```

**Output: [project_summary_{suffix}.csv](versions/project_summary_only_mock_part.csv)**
```csv
project,avg_energy_before,avg_energy_after,energy_reduction_%,avg_speedup_ratio,coverage_change_%
vulnerablecode_490,45.23,28.45,37.1%,1.45x,-0.7%
BazBOM_33,67.89,42.31,37.7%,1.60x,-2.3%
...
```

**Aggregate Metrics:**
- Average energy reduction across projects
- Average speedup ratio
- Coverage preservation rate
- Project rankings

**Visualization:**
- Multi-project violin plots
- Energy reduction comparison
- Speedup ratio distribution

#### [summarize_coverage_results.py](versions/summarize_coverage_results.py)

**Workflow:**
1. Parse all `coverage_comparison_{suffix}.txt` files
2. Extract coverage metrics and status
3. Generate summary table and CSV

**Usage:**
```bash
python summarize_coverage_results.py only_mock_part
```

**Output: [coverage_summary.csv](coverage_summary.csv)**
```csv
project,before_line_%,after_line_%,line_change_%,before_branch_%,after_branch_%,branch_change_%,status
vulnerablecode_490,87.5,86.8,-0.7,82.3,81.7,-0.6,ACCEPTABLE
BazBOM_33,92.1,91.8,-0.3,88.5,88.2,-0.3,ACCEPTABLE
...
```

**Status Categories:**
- `IDENTICAL`: No coverage change
- `IMPROVED`: Coverage increased
- `ACCEPTABLE`: Coverage decreased <10%
- `DEGRADED`: Coverage decreased >10%

---

## Configuration System

### Project-Specific Configuration: [test_config_{suffix}.sh](versions/vulnerablecode_490/test_config_only_mock_part.sh)

**Template:**
```bash
#!/bin/bash

# Test command to execute
TEST_COMMAND="pytest tools/supplychain/tests/test_enrichment.py::TestEnrichment::test_slow_api_call --durations=0 -v"

# Virtual environment path
VENV_PATH=".venv"

# Setup command for dependencies
SETUP_COMMAND=".venv/bin/pip install -q -e ."

# Optional: Wait time before tests (seconds)
WAIT_TIME=5

# Optional: Use UV package manager
USE_UV=false

# Optional: Use Docker
USE_DOCKER=false

# Optional: Custom Python version
PYTHON_VERSION="python3.11"
```

**Suffix Categories:**
- `only_mock_part`: Mock specific external dependencies
- `test_suite`: Run entire test suite
- `integration`: Integration test configuration
- `docker_config`: Docker-based projects

### Batch Configuration Files

#### [run_mockable_projects.sh](versions/run_mockable_projects.sh)
Lists projects where mocking was successfully applied:
```bash
PROJECTS=(
    "vulnerablecode_490"
    "BazBOM_33"
    "blueprints_691"
    ...
)
SUFFIX="only_mock_part"
```

#### [run_unknown_projects.sh](versions/run_unknown_projects.sh)
Projects requiring further investigation or special handling.

---

## Output Artifacts

### Directory Structure

```
/data/SpeedUpSlowTest/
├── slow_test_issues.csv                    # Phase 1: GitHub data
├── ListOptTestItself-batch*.txt            # Phase 1: PR selection
│
├── versions/                                # Phase 2-7: All project data
│   ├── {project}_{pr}/
│   │   ├── before/                         # Original before PR
│   │   ├── after/                          # Original after PR
│   │   ├── after_careful_mock/             # Mocked version
│   │   │
│   │   ├── test_config_{suffix}.sh         # Configuration
│   │   │
│   │   ├── test_results_{suffix}.log       # Raw energy logs
│   │   │
│   │   ├── energy_data_{suffix}.csv        # Parsed energy data
│   │   ├── duration_data_{suffix}.csv      # Parsed duration data
│   │   ├── execution_time_data_{suffix}.csv
│   │   ├── comparison_violin_plots_{suffix}.png
│   │   │
│   │   ├── coverage_before_{suffix}.json   # Coverage reports
│   │   ├── coverage_after_{suffix}.json
│   │   ├── htmlcov_before_{suffix}/
│   │   ├── htmlcov_after_{suffix}/
│   │   └── coverage_comparison_{suffix}.txt
│   │
│   ├── project_summary_{suffix}.csv        # Multi-project summary
│   ├── energy_violin_plot_{suffix}.png
│   └── coverage_summary.csv
│
├── prompt_template_mock_speedup_short.md   # Mocking guidelines
├── pr_versions.py                          # Version management
├── fetch_slow_tests_gql.py                 # GitHub data collection
├── run_tests_venv_generic.sh               # Energy measurement
├── run_tests_venv_generic_coverage.sh      # Coverage collection
├── parse_results_generic_optimized.py      # Statistical parsing
├── compare_coverage.py                     # Coverage comparison
├── summarize_projects.py                   # Multi-project analysis
└── summarize_coverage_results.py           # Coverage aggregation
```

### Key Output Files

| File | Purpose | Phase |
|------|---------|-------|
| `slow_test_issues.csv` | GitHub PRs metadata | 1 |
| `test_results_{suffix}.log` | Raw energy measurements | 4 |
| `energy_data_{suffix}.csv` | Parsed energy metrics | 6 |
| `coverage_comparison_{suffix}.txt` | Coverage analysis | 5 |
| `project_summary_{suffix}.csv` | Multi-project statistics | 7 |
| `coverage_summary.csv` | Multi-project coverage | 7 |

---

## Workflow Examples

### Example 1: Single Project Complete Workflow

```bash
# Step 1: Download PR versions
python pr_versions.py --repo "nexB/vulnerablecode" --pr 490

# Step 2: Apply mocking manually using Claude Code
# (Follow prompt_template_mock_speedup_short.md)
# Create: versions/vulnerablecode_490/after_careful_mock/
# Create: versions/vulnerablecode_490/test_config_only_mock_part.sh

# Step 3: Energy measurement (10 runs)
bash versions/run_tests_venv_generic.sh \
    vulnerablecode_490 10 before only_mock_part

bash versions/run_tests_venv_generic.sh \
    vulnerablecode_490 10 after_careful_mock only_mock_part

# Step 4: Parse energy results
python versions/parse_results_generic_optimized.py \
    vulnerablecode_490 only_mock_part

# Step 5: Coverage verification
bash versions/run_tests_venv_generic_coverage.sh \
    vulnerablecode_490 1 before only_mock_part

bash versions/run_tests_venv_generic_coverage.sh \
    vulnerablecode_490 1 after_careful_mock only_mock_part

# Step 6: Compare coverage
python versions/compare_coverage.py \
    vulnerablecode_490 only_mock_part

# Review outputs:
# - versions/vulnerablecode_490/comparison_violin_plots_only_mock_part.png
# - versions/vulnerablecode_490/coverage_comparison_only_mock_part.txt
```

### Example 2: Batch Processing Multiple Projects

```bash
# Step 1: Create batch file
cat > ListOptTestItself-batch3.txt << EOF
https://github.com/nexB/vulnerablecode/pull/490
https://github.com/owner/repo2/pull/123
https://github.com/owner/repo3/pull/456
EOF

# Step 2: Download all projects
python pr_versions.py --file ListOptTestItself-batch3.txt

# Step 3: Apply mocking to each project
# (Manual process using Claude Code)

# Step 4: Configure batch runner
# Edit run_mockable_projects.sh to add new projects

# Step 5: Run all projects
bash versions/run_all_projects_energy_coverage.sh

# Step 6: Generate multi-project summary
python versions/summarize_projects.py only_mock_part
python versions/summarize_coverage_results.py only_mock_part

# Review outputs:
# - versions/project_summary_only_mock_part.csv
# - coverage_summary.csv
```

### Example 3: Re-run Analysis with Different Parameters

```bash
# Re-parse with different outlier filtering
python versions/parse_results_generic_optimized.py \
    vulnerablecode_490 only_mock_part

# Re-run energy measurement with more runs
bash versions/run_tests_venv_generic.sh \
    vulnerablecode_490 20 after_careful_mock only_mock_part

# Re-analyze coverage with different thresholds
python versions/compare_coverage.py \
    vulnerablecode_490 only_mock_part
```

---

## Key Design Patterns

### 1. Suffix-Based Configuration
All scripts support `{suffix}` parameter for different test configurations:
- Enables multiple experiment types per project
- Isolates configurations (e.g., "only_mock_part" vs "test_suite")
- Prevents file conflicts

### 2. Parallel Execution Design
Scripts handle "before" and "after" versions sequentially:
- Ensures fair comparison (same system state)
- Prevents resource contention
- Enables statistical analysis

### 3. Outlier Filtering (IQR Method)
Removes statistical outliers from energy measurements:
```python
Q1 = data.quantile(0.25)
Q3 = data.quantile(0.75)
IQR = Q3 - Q1
filtered_data = data[(data >= Q1 - 1.5*IQR) & (data <= Q3 + 1.5*IQR)]
```

### 4. Smart Preservation
`smart_copy_tree()` preserves user-created files during updates:
- Avoids overwriting manual work
- Enables iterative improvements
- Supports version updates

### 5. Error Handling
Coverage scripts handle edge cases:
- Dynamically generated code (excluded from analysis)
- Parallel coverage files (combined automatically)
- Missing source files (symlink resolution)

### 6. Energibridge Integration
All energy measurements use consistent format:
```bash
energibridge --summary --quiet -- <test_command>
```
- `--summary`: Condensed output (energy, power, time)
- `--quiet`: Suppress detailed trace data
- Captures stdout/stderr for test output

---

## Statistical Analysis Notes

### Metrics Collected

**Energy Metrics:**
- Total energy (joules)
- Average power (watts)
- Execution time (seconds)

**Performance Metrics:**
- Individual test durations
- Total test suite duration
- Speedup ratio (before/after)

**Coverage Metrics:**
- Line coverage percentage
- Branch coverage percentage
- Per-file coverage breakdown
- Coverage change (absolute and relative)

### Statistical Significance

**N=10 runs** provides:
- Reliable mean/median estimates
- Distribution visualization
- Outlier detection capability
- Confidence in speedup measurements

**IQR filtering** removes:
- System anomalies (background processes)
- Measurement errors
- Initialization overhead (first run effects)

### Acceptance Criteria

**Energy/Performance:**
- Speedup ratio > 1.2x (20% improvement)
- Energy reduction > 15%

**Coverage:**
- Coverage loss < 10% (acceptable threshold)
- No critical paths unmocked

---

## Troubleshooting

### Common Issues

**Issue 1: Energibridge not found**
```bash
# Install energibridge
cargo install energibridge

# Verify installation
energibridge --version
```

**Issue 2: Coverage files not generated**
```bash
# Check if coverage is installed in venv
.venv/bin/pip install coverage

# Verify coverage command
.venv/bin/coverage --version
```

**Issue 3: Tests fail in mocked version**
```bash
# Check test_config_{suffix}.sh for correct TEST_COMMAND
cat versions/{project}/test_config_{suffix}.sh

# Run tests manually to debug
cd versions/{project}/after_careful_mock/
source .venv/bin/activate
pytest <test_command>
```

**Issue 4: Permission errors with energibridge**
```bash
# Run with sudo if needed
sudo energibridge --summary --quiet -- pytest ...

# Or fix permissions
sudo chown -R $USER:$USER /data/SpeedUpSlowTest/versions/
```

---

## Future Enhancements

### Potential Improvements

1. **Automated Mocking**: Use LLM API to automate mock generation
2. **Web Dashboard**: Real-time visualization of results
3. **CI/CD Integration**: Automated PR analysis on GitHub Actions
4. **Database Backend**: Store results in PostgreSQL/SQLite
5. **Advanced Statistics**: Hypothesis testing, p-values, effect sizes
6. **Energy Profiling**: Per-function energy attribution
7. **Cost Analysis**: Cloud compute cost estimation
8. **Reproducibility**: Docker containers for exact environment replication

---

## References

### External Tools
- **Energibridge**: https://github.com/energibridge/energibridge
- **Coverage.py**: https://coverage.readthedocs.io/
- **Pytest**: https://docs.pytest.org/
- **GitHub GraphQL API**: https://docs.github.com/en/graphql

### Internal Documentation
- [prompt_template_mock_speedup_short.md](prompt_template_mock_speedup_short.md) - Mocking guidelines
- [versions/run_tests_venv_generic.sh](versions/run_tests_venv_generic.sh) - Test runner
- [versions/compare_coverage.py](versions/compare_coverage.py) - Coverage comparison

---

## Contact & Maintenance

**System Owner**: Research Team
**Last Updated**: 2026-01-07
**Version**: 1.0

For issues or questions, refer to individual script documentation or project maintainers.
