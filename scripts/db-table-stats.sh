#!/bin/bash

# Output file for report
REPORT_FILE="docs/database-analysis-report.txt"

# Create temp file for collecting data
TEMP_DATA=$(mktemp)

# Function to format size in bytes to human readable
format_bytes() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt $((1024 * 1024)) ]; then
        awk -v b="$bytes" 'BEGIN {printf "%.1fKB", b/1024}'
    elif [ "$bytes" -lt $((1024 * 1024 * 1024)) ]; then
        awk -v b="$bytes" 'BEGIN {printf "%.1fMB", b/1024/1024}'
    else
        awk -v b="$bytes" 'BEGIN {printf "%.2fGB", b/1024/1024/1024}'
    fi
}

# Initialize counters
total_databases=0
total_tables=0

# Check if postgres container is running
if docker compose ps postgres --status running --format json 2>/dev/null | grep -q "postgres"; then
    echo "========================================"
    echo "POSTGRESQL"
    echo "========================================"
    echo ""

    # Get list of databases, excluding system databases
    databases=$(docker compose exec -T postgres psql -U postgres -t -c "
        SELECT datname
        FROM pg_database
        WHERE datistemplate = false
        AND datname NOT IN ('postgres')
        ORDER BY datname;
    " | tr -d ' ')

    for db in $databases; do
        # Skip empty lines
        [ -z "$db" ] && continue

        # Get the database owner/user (assuming convention {service}_user)
        user=$(echo "$db" | sed 's/_db$/_user/')

        # Check if user exists, skip if not
        user_exists=$(docker compose exec -T postgres psql -U postgres -t -c "SELECT 1 FROM pg_roles WHERE rolname='$user'" 2>/dev/null | tr -d ' ')
        if [ "$user_exists" != "1" ]; then
            echo "Skipping $db (user $user does not exist)"
            echo ""
            continue
        fi

        total_databases=$((total_databases + 1))

        echo "================================================"
        echo "Database: $db"
        echo "================================================"

        # Get table data for report and display
        docker compose exec -T postgres psql -U "$user" -d "$db" -t -c "
            SELECT
                '$db' || '|' || tablename || '|' ||
                pg_total_relation_size(schemaname||'.'||tablename) || '|' ||
                (xpath('/row/cnt/text()', xml_count))[1]::text::int || '|postgres'
            FROM (
                SELECT
                    table_schema AS schemaname,
                    table_name AS tablename,
                    query_to_xml(format('SELECT count(*) AS cnt FROM %I.%I', table_schema, table_name), false, true, '') AS xml_count
                FROM information_schema.tables
                WHERE table_schema = 'public'
            ) AS subquery
            ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
        " 2>/dev/null | grep -v '^$' >> "$TEMP_DATA"

        # Display detailed info
        docker compose exec -T postgres psql -U "$user" -d "$db" -c "
            SELECT
                schemaname,
                tablename,
                pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
                pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
                pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS indexes_size,
                (SELECT count(*) FROM information_schema.columns WHERE table_schema = schemaname AND table_name = tablename) AS columns,
                (xpath('/row/cnt/text()', xml_count))[1]::text::int AS row_count
            FROM (
                SELECT
                    table_schema AS schemaname,
                    table_name AS tablename,
                    query_to_xml(format('SELECT count(*) AS cnt FROM %I.%I', table_schema, table_name), false, true, '') AS xml_count
                FROM information_schema.tables
                WHERE table_schema = 'public'
            ) AS subquery
            ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
        "

        echo ""
    done
fi

# Check if mysql container is running
if docker compose ps mysql --status running --format json 2>/dev/null | grep -q "mysql"; then
    echo "========================================"
    echo "MYSQL"
    echo "========================================"
    echo ""

    # Get list of databases, excluding system databases
    databases=$(docker compose exec -T mysql mysql -u root -N -e "
        SELECT schema_name
        FROM information_schema.schemata
        WHERE schema_name NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
        ORDER BY schema_name;
    ")

    for db in $databases; do
        # Skip empty lines
        [ -z "$db" ] && continue

        total_databases=$((total_databases + 1))

        echo "================================================"
        echo "Database: $db"
        echo "================================================"

        # Get table data for report
        docker compose exec -T mysql mysql -u root "$db" -N -e "
            SELECT
                CONCAT('$db', '|', table_name, '|', (data_length + index_length), '|', table_rows, '|mysql')
            FROM information_schema.tables
            WHERE table_schema = '$db'
            ORDER BY (data_length + index_length) DESC;
        " >> "$TEMP_DATA"

        # Display detailed info
        docker compose exec -T mysql mysql -u root "$db" -e "
            SELECT
                table_name AS 'Table',
                table_rows AS 'Rows',
                CONCAT(ROUND(data_length / 1024 / 1024, 2), ' MB') AS 'Table Size',
                CONCAT(ROUND(index_length / 1024 / 1024, 2), ' MB') AS 'Index Size',
                CONCAT(ROUND((data_length + index_length) / 1024 / 1024, 2), ' MB') AS 'Total Size'
            FROM information_schema.tables
            WHERE table_schema = '$db'
            ORDER BY (data_length + index_length) DESC;
        "

        echo ""
    done
fi

# Generate report
if [ -s "$TEMP_DATA" ]; then
    {
        echo "==================================================================="
        echo "Database Table Analysis Report"
        echo "Generated: $(date +%m/%d/%Y)"
        echo "Total databases: $total_databases"

        # Count total tables
        total_tables=$(wc -l < "$TEMP_DATA" | tr -d ' ')
        echo "Total tables: $total_tables"
        echo "==================================================================="
        echo ""

        # Table header
        printf "%-30s | %-30s | %-12s | %-12s | %-8s\n" "Database" "Table" "Size" "Rows" "Engine"
        printf "%-30s-+-%-30s-+-%-12s-+-%-12s-+-%-8s\n" "------------------------------" "------------------------------" "------------" "------------" "--------"

        # Sort by size (field 3) and format output
        while IFS='|' read -r database table size_bytes rows engine; do
            # Clean up whitespace
            database=$(echo "$database" | tr -d ' ')
            table=$(echo "$table" | tr -d ' ')
            size_bytes=$(echo "$size_bytes" | tr -d ' ')
            rows=$(echo "$rows" | tr -d ' ')
            engine=$(echo "$engine" | tr -d ' ')

            # Format size
            size_human=$(format_bytes "$size_bytes")

            # Format rows with thousands separator
            rows_formatted=$(printf "%'d" "$rows" 2>/dev/null || echo "$rows")

            # Truncate long names
            if [ ${#database} -gt 30 ]; then
                database="${database:0:27}..."
            fi
            if [ ${#table} -gt 30 ]; then
                table="${table:0:27}..."
            fi

            printf "%-30s | %-30s | %-12s | %-12s | %-8s\n" "$database" "$table" "$size_human" "$rows_formatted" "$engine"
        done < <(sort -t'|' -k3 -rn "$TEMP_DATA")

        echo ""
        echo "Report generated by: db-table-stats.sh"
    } > "$REPORT_FILE"

    echo "========================================"
    echo "Report saved to: $REPORT_FILE"
    echo "========================================"
fi

# Cleanup
rm -f "$TEMP_DATA"
