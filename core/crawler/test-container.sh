#!/bin/sh
# Test script to run inside the crawler container

echo "Testing Simplified Crawler CLI inside container..."
echo "================================================"

# Function to run command and check result
run_test() {
    echo "\n→ Testing: $1"
    if eval "$2"; then
        echo "✓ Passed"
        return 0
    else
        echo "✗ Failed"
        return 1
    fi
}

# Reset state first
echo "\nResetting crawler state..."
npm run cli -- reset

# Test 1: Queue command
run_test "Queue command" "npm run cli -- queue | grep 'Queue Status'"

# Test 2: Add URL command
run_test "Add URL command" "npm run cli -- add --url http://test.zoo | grep 'Added URL to queue'"

# Test 3: Check queue shows the URL
run_test "Queue after add" "npm run cli -- queue | grep 'Pending: 1'"

# Test 4: Workers command
run_test "Workers command" "npm run cli -- workers"

# Test 5: Recover command
run_test "Recover command" "npm run cli -- recover | grep -E 'No stale URLs found|Recovered'"

# Test 6: Cleanup command
run_test "Cleanup command" "npm run cli -- cleanup | grep -E 'No dead workers found|Cleaned up'"

# Test 7: Reset command
run_test "Reset command" "npm run cli -- reset | grep 'Crawler queue reset'"

# Test 8: Final queue check
run_test "Final queue" "npm run cli -- queue | grep 'Pending: 0'"

echo "\n================================================"
echo "All tests completed!"