#!/bin/bash

echo "Running utils.zoo tests..."
echo "=========================="

# Run tests with coverage
python -m coverage run test_app.py

# Display coverage report
echo -e "\nCoverage Report:"
echo "================"
python -m coverage report -m

# Run pytest for better output (optional)
echo -e "\nRunning with pytest:"
echo "===================="
python -m pytest test_app.py -v