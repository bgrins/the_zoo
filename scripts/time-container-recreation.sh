#!/bin/bash
# Time individual container recreation to identify slow containers

# Get list of all services with all profiles
services=$(docker compose --profile '*' config --services)

echo "=== Timing individual container recreation ==="
echo ""

start_total=$(node -e "console.log(Date.now())")

# Create a temp file to store results
results_file=$(mktemp)

for service in $services; do
  start=$(node -e "console.log(Date.now())")
  docker compose up -d --no-start --force-recreate "$service" > /dev/null 2>&1
  end=$(node -e "console.log(Date.now())")
  duration=$((end - start))
  echo "$duration $service" >> "$results_file"
done

end_total=$(node -e "console.log(Date.now())")
total_duration=$((end_total - start_total))

# Sort by duration (slowest first) and format output
sort -rn "$results_file" | while read -r duration service; do
  printf "%-30s %6d ms\n" "$service" "$duration"
done

# Clean up temp file
rm "$results_file"

echo ""
echo "Total time: $total_duration ms"
