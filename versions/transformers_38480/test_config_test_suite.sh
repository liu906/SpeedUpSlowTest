#!/bin/bash
# Test configuration for transformers_38480
# This file is sourced by run_tests_venv_generic.sh

# Test command to run (without energibridge prefix)
# PR #38480 testing: Run ALBERT model tests that were optimized
# This PR reduces the test model size to improve test execution speed
# Target the specific test file that was modified
TEST_COMMAND="python -m pytest tests/models/albert/test_modeling_albert.py -v --durations=0 -x"

# Virtual environment path (relative to the version directory: before/ or after/)
VENV_PATH=".venv"

# Optional: Setup command to run AFTER venv creation and activation
# This project uses setup.py for installation
# Install with minimal dependencies for testing
# PyTorch is required for these tests (ALBERT modeling tests)
SETUP_COMMAND="python -m pip install --upgrade pip && python -m pip install -e '.[torch,testing]' --no-cache-dir"

# Flag to indicate this is NOT a uv-based project
USE_UV="false"

# Optional: Python version (project supports Python 3.9+)
PYTHON_VERSION="python3"

# Optional: Additional project-specific variables
PROJECT_NAME="transformers_38480"

# Note: PR #38480 optimizes ALBERT test model size for faster testing
# The PR title: "[Tests] Reduced model size for albert-test model"
#
# Performance Impact:
# - BEFORE: test_model_outputs_equivalence took 2.78s (slowest test)
# - AFTER: test_model_outputs_equivalence took 2.72s (slowest test)
# - IMPROVEMENT: ~1-2 seconds reduction overall on Linux CI runners (excluding pipeline tests)
#
# The optimization is achieved by reducing model parameters, not algorithmic changes
# This means the speedup comes from less computation during test execution
#
# Changes made in PR #38480:
# 1. Reduced test model parameter counts significantly
# 2. Maintained functional test coverage with smaller model
# 3. Improved memory footprint and execution speed
#
# Files changed in PR #38480:
#
# SOURCE/TEST FILE (1 file):
#
# 1. tests/models/albert/test_modeling_albert.py (MODIFIED - test model optimization)
#    Changes made to AlbertModelTester __init__ parameters:
#
#    Parameter reductions:
#    - vocab_size: 99 → 32 (67% reduction)
#      * Vocabulary size for tokenization
#      * Smaller vocab = smaller embedding table
#
#    - embedding_size: 16 → 8 (50% reduction)
#      * Dimensionality of token embeddings
#      * Directly impacts memory and computation
#
#    - hidden_size: 36 → 12 (67% reduction)
#      * Size of hidden layers in the transformer
#      * Major impact on model size and speed
#      * Affects all attention and feedforward computations
#
#    - num_attention_heads: 6 → 4 (33% reduction)
#      * Number of attention heads in multi-head attention
#      * Fewer heads = less parallel attention computation
#
#    - intermediate_size: 37 → 16 (57% reduction)
#      * Size of feedforward intermediate layer
#      * Directly impacts feedforward network computation
#
#    - max_position_embeddings: 512 → 8 (98% reduction!)
#      * Maximum sequence length the model can handle
#      * Dramatic reduction for test purposes
#      * Tests use short sequences anyway
#
#    - type_vocab_size: 16 → 2 (87% reduction)
#      * Number of token type IDs (for segment embeddings)
#      * Most tests only need 2 types
#
#    Configuration additions:
#    - Added explicit vocab_size parameter to get_config()
#      * Ensures consistency across test configurations
#
#    - Added inner_group_num=1 parameter
#      * ALBERT-specific parameter for layer grouping
#      * Simplifies test model architecture
#
# What is ALBERT?
# ALBERT (A Lite BERT) is a transformer model that uses:
# - Cross-layer parameter sharing (reduces parameters)
# - Factorized embedding parameterization (reduces embedding size)
# - Inter-sentence coherence loss (improved pre-training)
#
# ALBERT is already a "lite" version of BERT, but the test model was still
# too large for fast testing. This PR makes the test model even smaller.
#
# Why this optimization matters:
# Model tests in transformers library run on every PR and commit.
# The test suite includes:
# - Configuration tests
# - Forward pass tests
# - Backward pass tests
# - Pipeline integration tests
# - Equivalence tests
# - FX tracing tests (PyTorch JIT compilation)
#
# Each test creates model instances, performs forward/backward passes,
# and validates outputs. Smaller models mean:
# - Faster model instantiation
# - Less memory allocation
# - Faster forward/backward passes
# - Quicker gradient computation
# - Reduced CI/CD time
#
# Performance analysis from PR:
# BEFORE (with larger test model):
# - test_model_outputs_equivalence: 2.78s
# - test_torch_fx: 1.29s
# - test_torch_fx_output_loss: 0.87s
# Total for these 3 tests: 4.94s
#
# AFTER (with smaller test model):
# - test_model_outputs_equivalence: 2.72s
# - test_pipeline_feature_extraction: 0.83s
# - test_pipeline_feature_extraction_fp16: 0.76s
# Total for these 3 tests: 4.31s
#
# Improvement: ~0.6s for top 3 tests (12% faster)
# Overall improvement: 1-2 seconds across all tests (~2-4% faster)
#
# Note: The speedup seems modest, but:
# 1. This is per test run (adds up over many CI runs)
# 2. Memory footprint reduction is also valuable
# 3. Sets precedent for optimizing other model tests
# 4. Every second saved in CI = cost savings
#
# Test execution details:
# The test file includes multiple test classes:
# - AlbertModelTest: Core model functionality
# - AlbertForPreTrainingTest: Pre-training tasks
# - AlbertForMaskedLMTest: Masked language modeling
# - AlbertForSequenceClassificationTest: Text classification
# - AlbertForTokenClassificationTest: Token tagging
# - AlbertForQuestionAnsweringTest: QA tasks
# - AlbertForMultipleChoiceTest: Multiple choice tasks
#
# Each test class inherits from ModelTesterMixin which provides:
# - test_save_load: Model serialization
# - test_model_outputs: Output validation
# - test_hidden_states_output: Intermediate outputs
# - test_attention_outputs: Attention weights
# - test_gradient_checkpointing: Memory optimization
# - test_torch_fx: PyTorch JIT tracing
# - And many more...
#
# All these tests now run faster with the reduced model size!
#
# Model parameter calculation:
# BEFORE:
# - Embedding params: (vocab_size * embedding_size) + (max_pos * embedding_size)
#   = (99 * 16) + (512 * 16) = 1,584 + 8,192 = 9,776
# - Hidden layers: (hidden_size * hidden_size * num_attention_heads) * num_layers
#   = (36 * 36 * 6) * 2 = 15,552
# - Feedforward: (hidden_size * intermediate_size) * num_layers
#   = (36 * 37) * 2 = 2,664
# Approximate total: ~28,000 parameters
#
# AFTER:
# - Embedding params: (32 * 8) + (8 * 8) = 256 + 64 = 320
# - Hidden layers: (12 * 12 * 4) * 2 = 1,152
# - Feedforward: (12 * 16) * 2 = 384
# Approximate total: ~1,900 parameters
#
# Parameter reduction: ~93% fewer parameters!
# This directly translates to faster computation.
#
# How to run tests:
# 1. Run all ALBERT tests:
#    pytest tests/models/albert/test_modeling_albert.py -v
#
# 2. Run specific test:
#    pytest tests/models/albert/test_modeling_albert.py::AlbertModelTest::test_model_outputs -v
#
# 3. Run with durations to see slowest tests:
#    pytest tests/models/albert/test_modeling_albert.py --durations=10
#
# 4. Run with timing for each test:
#    pytest tests/models/albert/test_modeling_albert.py -v --durations=0
#
# Project structure:
# transformers/
# ├── src/transformers/           # Main library code
# │   └── models/albert/          # ALBERT model implementation
# ├── tests/                      # Test suite
# │   └── models/albert/          # ALBERT-specific tests
# │       ├── test_modeling_albert.py      (THIS PR - PyTorch)
# │       ├── test_modeling_tf_albert.py   (TensorFlow)
# │       ├── test_modeling_flax_albert.py (Flax/JAX)
# │       └── test_tokenization_albert.py  (Tokenizer)
# └── pyproject.toml              # Project configuration
#
# Test dependencies:
# From pyproject.toml [tool.pytest.ini_options]:
# - pytest for test framework
# - pytest markers for test categorization:
#   * flash_attn_test: Flash attention tests
#   * bitsandbytes: Quantization tests
#   * generate: Generation tests
# - doctest support for markdown files
# - asyncio support for async tests
#
# Installation options:
# pip install transformers[torch]          # PyTorch only
# pip install transformers[torch,testing]  # PyTorch + test deps
# pip install -e .[torch,testing]          # Editable install for development
#
# Why editable install (-e)?
# For benchmarking before/after, we need to:
# 1. Install before/ version in before/.venv
# 2. Install after/ version in after/.venv
# 3. Run tests in each environment
# 4. Compare execution times
#
# The -e flag installs in "development mode" which:
# - Links to source directory instead of copying
# - Allows import of modified code
# - Faster installation (no copy overhead)
#
# Test execution flow:
# 1. pytest discovers test_modeling_albert.py
# 2. Collects all test classes and methods
# 3. For each test:
#    a. Instantiate AlbertModelTester with parameters
#    b. Call prepare_config_and_inputs() to create test data
#    c. Create model with AlbertConfig
#    d. Run forward pass
#    e. Validate outputs
#    f. Clean up
# 4. Report timing and results
#
# With smaller model parameters, steps 3c-3e are faster!
#
# Common test patterns in transformers:
# - ModelTesterMixin: Base test functionality
# - ConfigTester: Configuration validation
# - PipelineTesterMixin: Pipeline integration
# - @slow: Mark slow tests (skip in fast CI)
# - @require_torch: Only run if PyTorch available
# - torch_device: Run on CPU/GPU as available
#
# Pytest configuration (pyproject.toml):
# - addopts: "--doctest-glob='**/*.md'"
# - doctest_optionflags: NUMBER NORMALIZE_WHITESPACE ELLIPSIS
# - log_cli: 1 (show logs during test)
# - log_cli_level: WARNING (log level)
#
# CI/CD context:
# The transformers project uses:
# - CircleCI for continuous integration
# - GitHub Actions for additional checks
# - Multiple Python versions (3.9+)
# - Multiple frameworks (PyTorch, TensorFlow, Flax)
# - Multiple platforms (Linux, macOS, Windows)
#
# Every PR triggers thousands of tests across all combinations.
# Saving 1-2 seconds per test run multiplies across:
# - Different Python versions
# - Different frameworks
# - Different platforms
# - Multiple commits per PR
# - Multiple PRs per day
#
# Result: Significant CI time and cost savings!
#
# Related optimizations discussed in PR:
# The contributor mentioned exploring similar optimizations for:
# - Other BERT variants
# - Other transformer models
# - Other test suites
#
# This PR establishes a pattern that can be replicated.
#
# Key learning:
# Test models don't need to be production-sized!
# They just need to be:
# - Large enough to catch bugs
# - Small enough to run quickly
# - Representative of the model architecture
#
# This PR finds the right balance for ALBERT tests.
#
# Expected benchmark results:
# Running the test command will show:
# - Individual test execution times
# - Slowest tests at the end (--durations=0)
# - Total execution time
#
# Compare:
# - before/: ~2.78s for slowest test
# - after/: ~2.72s for slowest test
# - Overall: 1-2s faster total execution
#
# Note: The speedup is modest but consistent. The real value is:
# 1. Reduced memory usage (93% fewer parameters)
# 2. Faster model instantiation
# 3. Better CI resource utilization
# 4. Template for other model optimizations
#
# Alternative testing approaches:
# If you want to see more dramatic differences:
# 1. Run with multiple iterations
# 2. Run full test suite (not just one file)
# 3. Run on resource-constrained hardware
# 4. Measure memory usage, not just time
#
# Memory profiling:
# import memory_profiler
# @profile
# def test_model():
#     # test code here
#
# Run with: python -m memory_profiler test_file.py
#
# This would show the 93% parameter reduction more clearly!
#
# Summary:
# This PR optimizes ALBERT test model by reducing parameters by 93%.
# The speedup is modest (1-2s, ~2-4%) but the memory reduction is significant.
# Tests remain functionally equivalent while running faster.
# The change demonstrates good testing practices: use minimal models for tests.
