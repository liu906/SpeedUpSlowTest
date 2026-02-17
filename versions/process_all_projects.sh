#!/bin/bash

# Script to process all projects with test_results.log files

echo "Finding projects with test_results.log files..."

# Find all directories containing test_results.log
for project_dir in */; do
    # Remove trailing slash
    project_name="${project_dir%/}"

    # Check if test_results.log exists in this directory
    if [ -f "${project_name}/test_results.log" ]; then
        echo ""
        echo "================================================"
        echo "Processing project: ${project_name}"
        echo "================================================"

        # Run parse command
        echo "Running parse_results_generic_optimized.py for ${project_name}..."
        python3 parse_results_generic_optimized.py "${project_name}"

        if [ $? -eq 0 ]; then
            echo "Parse completed successfully for ${project_name}"
        else
            echo "ERROR: Parse failed for ${project_name}"
        fi

        # Run visualize command
        echo "Running visualize_results_generic.py for ${project_name}..."
        python3 visualize_results_generic.py "${project_name}"

        if [ $? -eq 0 ]; then
            echo "Visualization completed successfully for ${project_name}"
        else
            echo "ERROR: Visualization failed for ${project_name}"
        fi
    fi
done

echo ""
echo "================================================"
echo "All projects processed!"
echo "================================================"
