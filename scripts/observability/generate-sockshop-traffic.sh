#!/bin/bash

################################################################################
# SCRIPT: generate-sockshop-traffic.sh
#
# TRAFFIC GENERATOR (Observability Helper)
#
# DESCRIPTION:
#   A synthetic workload generator for the Sock Shop microservices demo.
#   It simulates light but repeated user-like storefront activity by calling
#   several application endpoints in a continuous loop.
#
# WHY THIS MATTERS FOR OBSERVABILITY:
#   1. Metric Generation:
#      Creates ongoing HTTP traffic so Prometheus can scrape a steady stream of
#      RED-style signals (Requests, Errors, Duration) from the storefront path.
#   2. Dashboard Validation:
#      Makes Grafana panels easier to validate because namespace / workload
#      activity becomes visible without manual browser clicking.
#   3. Session Simulation:
#      Reuses a cookie jar so repeated requests behave more like one browser
#      session instead of isolated stateless calls.
#   4. Repeatable Verification:
#      Provides a simple and reproducible helper for observability checks during
#      manual verification, reruns, and later automation.
#   5. Flexible Test Data Source:
#      Supports either:
#      - preset built-in product IDs / category tags
#      - live discovery of product IDs / category tags from the target system
#
# FEATURES:
#   - Supports both target environments:
#     - dev
#     - prod
#   - Supports both data source modes:
#     - live
#     - preset
#   - Can run interactively or from CLI arguments
#   - Prints a readable request table with:
#     - host
#     - endpoint
#     - parameter
#     - HTTP status
#     - latency (total end-to-end request time in seconds)
#   - Randomizes product-detail and category-tag requests
#   - Fails fast on missing dependencies or unusable live data
#
# LIVE DATA DISCOVERY:
#   Live discovery in this helper uses the Sock Shop JSON API endpoints for:
#   - ${BASE_URL}/catalogue  -> product IDs
#   - ${BASE_URL}/tags       -> category tags
#   - ${BASE_URL}/catalogue  -> fallback source for tags if /tags is empty/unusable
#
#   The JSON extraction is implemented with jq filters.
#
# LATENCY INTERPRETATION:
#   - The displayed latency in seconds is curl's full request end-to-end time 
#     (from this script's point of view)
#   - It includes the complete client-side request path, such as connect/TLS,
#     server processing, and response transfer.
#   - It does not isolate backend-only processing time.
#   - In this helper, it is a useful synthetic observability signal for:
#     reachability, responsiveness, spikes, and trend comparison over time.
#
# SCRIPT USAGE:
#
#   1. DIRECT MODE - CLI arguments for target env (dev|prod) + data source mode(live|preset):
#      ./generate-sockshop-traffic.sh dev live
#      ./generate-sockshop-traffic.sh prod preset
#
#   2. INTERACTIVE MODE - prompt-driven:
#      ./generate-sockshop-traffic.sh
#
#   Terminate with Ctrl+C.
################################################################################

# Store and reuse session cookies in a temporary local file  
# so repeated requests behave more like one browser session.
COOKIE_JAR=/tmp/sockshop-cookies.txt

# Declare + populate the targets dictionary
declare -A targets

targets=(
    ["home"]="/"
    ["categories"]="/category.html"
    ["basket"]="/basket.html"
    ["detail"]="/detail.html"
    ["category"]="/category.html"
)

# Array of preset product IDs
detail_ids=(
    "id=3395a43e-2d88-40de-b95f-e00e1502085b"
    "id=510a0d7e-8e83-4193-b483-e27e09ddc34d"
    "id=808a2de1-1aaa-4c25-a9b9-6612e8f29a38"
    "id=03fef6ac-1896-4ce8-bd69-b798f85c6e0b"
    "id=819e1fbf-8b7e-4f6d-811f-693534916a8b"
    "id=a0a4f044-b040-410d-8ead-4de0446aec7e"
)

# Array of preset category tags
category_tags=(
    "tags=blue"
    "tags=brown"
    "tags=green"
    "tags=large"
    "tags=short"
    "tags=toes"
    "tags=magic"
    "tags=formal"
    "tags=smelly"
) 

#######################################
# Prints an error message to stderr and exits the script with a non-zero status.
#
# Arguments:
#   $* - The full error message to print.
#
# Outputs:
#   Writes the formatted error message to stderr.
#
# Exits:
#   1
#######################################
die() {
    echo "ERROR: $*" >&2
    exit 1
}

#######################################
# Verifies that a required external command is available in PATH.
# Aborts the script immediately if the command is missing.
#
# Arguments:
#   $1 - The command name to check (for example: curl, jq).
#
# Exits:
#   1 if the required command is not available.
#######################################
require_cmd() {
    # command -v = shell builtin (checks whether a command can be found in PATH)
    # "$1"       = the command name passed into this helper function
    # >/dev/null = discard normal output because only success/failure matters here
    # 2>&1       = redirect stderr to the same target as stdout (/dev/null)
    # ||         = if the command check fails, execute die() immediately    
    command -v "$1" >/dev/null 2>&1 || die "Required command '$1' not found - please make sure to install '$1' before running this script!"
}

#######################################
# Ensures that the script will use the built-in fallback / preset data sets 
# for product IDs and category tags.
#
# Globals:
#   detail_ids      (Array of preset product IDs)
#   category_tags   (Array of preset category tags)
#
# Outputs:
#   Prints a short status summary showing that preset data is being used
#   and how many preset items are available.
#######################################
load_preset_data(){
    echo "- Using built-in preset product IDs and category tags."
    echo "- Imported ${#detail_ids[@]} product IDs from preset data."
    echo "- Imported ${#category_tags[@]} category tags from preset data."
    echo ""    
}

#######################################
# Selects and prepares the active data source for product IDs and category tags.
# Depending on the chosen mode, it either:
# - loads live data from the target environment
# - or keeps the built-in preset fallback data
#
# Arguments:
#   $1 - Data source mode ("live" or "preset").
#######################################
prepare_data_source() {
    local data_mode=$1  

    if [[ "$data_mode" == "live" ]]; then
        load_live_data
    else
        load_preset_data
    fi
}

#######################################
# Fetches live product IDs and category tags from the selected Sock Shop
# target environment using the relevant Sock Shop JSON API endpoints and 
# overwrites the default preset arrays with that data.
#
# Data sources (JSON):
#   - ${BASE_URL}/catalogue  -> product IDs
#   - ${BASE_URL}/tags       -> category tags
#   - ${BASE_URL}/catalogue  -> fallback source for tags if /tags is unusable
#
# Globals:
#   BASE_URL         (Base URL of the selected target environment)
#   detail_ids       (Array overwritten with discovered live product IDs)
#   category_tags    (Array overwritten with discovered live category tags)
#
# Requirements:
#   - curl
#   - jq
#
# Outputs:
#   Prints progress and import counts.
#
# Exits:
#   1 if live fetching fails or returns no usable IDs / tags.
#######################################
load_live_data(){
    require_cmd curl
    require_cmd jq

    local catalogue_json=""
    local tags_json=""

    echo "- Fetching live product data from ${BASE_URL}/catalogue ..."
    catalogue_json="$(curl -fsS "${BASE_URL}/catalogue")" \
        || die "Failed to fetch product catalogue from ${BASE_URL}/catalogue"

    # Read all product IDs from the live /catalogue JSON payload into the Bash array "detail_ids".
    #
    # mapfile     = Bash builtin - reads stdin line by line into an array
    # -t          = strip the trailing newline from each imported line
    # detail_ids  = target array that will receive the fetched product IDs
    # < <(...)    = process substitution:
    #               run the command in (...) and feed its stdout into mapfile as input
    #
    # jq          = lightweight command-line JSON processor
    # -r          = raw output mode:
    #               print plain text instead of JSON-quoted strings
    #
    # Filter breakdown:
    # '.[].id | "id=\(.)"'
    #   .[]        = iterate over each object in the top-level JSON array
    #   .id        = extract the "id" field from each product object
    #   "id=\(.)"  = format each value as id=<value>
    #                so it can later be appended directly to the detail page query string
    #
    # <<< "$catalogue_json" = here-string:
    #                         pass the content of the Bash variable to jq via stdin
    mapfile -t detail_ids < <(
        jq -r '.[].id | "id=\(.)"' <<< "$catalogue_json"
    )

    if [[ ${#detail_ids[@]} -eq 0 ]]; then
        die "Live discovery returned 0 product IDs from ${BASE_URL}/catalogue"
    fi

    echo "- Fetching live tag data from ${BASE_URL}/tags ..."
    if tags_json="$(curl -fsS "${BASE_URL}/tags" 2>/dev/null)"; then
        mapfile -t category_tags < <(
            jq -r '.tags[]? | "tags=\(.)"' <<< "$tags_json"
        )
    fi

    if [[ ${#category_tags[@]} -eq 0 ]]; then
        echo "- No usable tags returned by /tags. Falling back to tags derived from /catalogue ..."
        mapfile -t category_tags < <(
            jq -r '.[].tag[]? | "tags=\(.)"' <<< "$catalogue_json" | sort -u
        )
    fi

    if [[ ${#category_tags[@]} -eq 0 ]]; then        
        die "Live discovery returned 0 category tags from /tags and /catalogue"
    fi

    echo "- Imported ${#detail_ids[@]} product IDs from live catalogue data."
    echo "- Imported ${#category_tags[@]} category tags from live data."
    echo ""
}


sockshop_env=$1
data_mode=$2

echo "(1) DEFINE TARGET ENVIRONMENT (dev|prod)" 
# Check if environment is passed as an argument, otherwise prompt for it
if [[ -z "$sockshop_env" ]]; then
    read -p "- Please define the target sock-shop environment ('dev' or 'prod'): " sockshop_env 
    echo "- Target sock-shop environment from selection: '$sockshop_env'" 
    echo ""
else
    echo "- Preset target sock-shop environment from args: '$sockshop_env'" 
    echo ""    
fi

# Normalize to lowercase for comparison
sockshop_env_normalized="${sockshop_env,,}"

if [[ "${sockshop_env_normalized}" != "dev" && "${sockshop_env_normalized}" != "prod" ]]; then
    die "Unknown sock-shop environment '$sockshop_env'. Available environments are 'dev' or 'prod'."    
fi

BASE_URL="https://${sockshop_env_normalized}-sockshop.cdco.dev"

echo "(2) DEFINE DATA SOURCE MODE (live|preset)" 
# Check if data_mode is passed as an argument, otherwise prompt for it
if [[ -z "$data_mode" ]]; then
    read -p "- Use live-discovered products and categories from the actual target env, or the built-in preset lists (which could be stale) ? ('live' or 'preset'): " data_mode
    echo "- Data source mode from selection: '$data_mode'" 
    echo ""
else
    echo "- Preset data source mode from args: '$data_mode'" 
    echo ""      
fi

# Normalize for comparison
data_mode_normalized="${data_mode,,}"

if [[ "${data_mode_normalized}" == "live" || "${data_mode_normalized}" == "preset" ]]; then
    echo "Configuration complete."
    echo "- Target environment: '$sockshop_env_normalized'"
    echo "- Data source mode: '$data_mode_normalized'"
    echo "- Preparing '$data_mode_normalized' data source ..."
    echo ""

    prepare_data_source "$data_mode"    

    read -p "Press [Enter] to start traffic - or [Ctrl+C] to exit..."
    echo ""
    echo ""
    echo ""
    echo "--- Generating traffic on the sock-shop '$sockshop_env' environment using '$data_mode' data for product IDs + category tags ---"
    echo "Calling different targets on ${BASE_URL}:"
    echo "(hit [Ctrl+C] to exit)"
    echo ""
else
    die "Unknown data source mode '$data_mode'. Available data source modes are 'live' or 'preset'."  
fi




#######################################
# Calls a given Sock Shop storefront endpoint and prints the formatted 
# table row including the Host, Endpoint, Param, Status, and Latency.
#
# Arguments:
#   $1 - The full URL path (e.g., "/detail.html?id=123")
#   $2 - The endpoint name (e.g., "detail")
#   $3 - The parameter used (e.g., "id=123", or "-")
#######################################
call_endpoint() {
  local full_path="$1"
  local endpoint="$2"
  local param="$3"

  # -f = fail on HTTP errors (for example 404 / 500)
  # -s = silent mode (hide normal progress meter)
  # -S = still show an error message if a request fails
  # -A = send a browser-like User-Agent string
  # --cookie = send cookies from the cookie jar file
  # --cookie-jar = update/write cookies back to the cookie jar file
  # -o /dev/null = discard the response body
  # -w = write-out format string:
  #      print the formatted table row after the request finishes
  # %{http_code}  = final HTTP status code
  # %{time_total} = total end-to-end request time in seconds  
  curl -fsS -A "Mozilla/5.0" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
    -o /dev/null \
    -w "$(printf '| %-25s | %-10s | %-40s | ' "${sockshop_env_normalized}-sockshop.cdco.dev" "$endpoint" "$param")%{http_code}    | %{time_total} |\n" \
    "${BASE_URL}${full_path}"   
}


#######################################
# Generates a complete URL path by appending random parameters 
# based on the target endpoint type.
#
# Globals:
#   detail_ids     (Array of product IDs)
#   category_tags  (Array of category tags)
# Arguments:
#   $1 - The base path (e.g., "/detail.html")
#   $2 - The endpoint name (e.g., "detail" or "category")
# Outputs:
#   Writes the fully constructed path string to stdout.
#######################################
get_path_and_param() {
    local base_path="$1" 
    local endpoint="$2"

    case "$endpoint" in 
        "detail")
            # random id
            random_ids_index=$(( RANDOM % ${#detail_ids[@]} ))
            random_id="${detail_ids[$random_ids_index]}"
            echo ${base_path}?${random_id} ${random_id}  
            ;;
        "category")
            # random category tag
            random_tags_index=$(( RANDOM % ${#category_tags[@]} ))
            random_tag="${category_tags[$random_tags_index]}"
            echo ${base_path}?${random_tag} ${random_tag}
            ;;   
        *)
            # Catch all for all endpoints without random params:
            # Echo the base path + a simple dash for the param
            # echo "$base_path"
            echo "$base_path -"
            ;;        
    esac
}

while true; do
    # Print the Table Header 
    printf "|---------------------------+------------+------------------------------------------+--------+----------|\n"
    printf "|                                           --- %s ---                                            |\n" "$(date '+%H:%M:%S')"
    printf "|---------------------------+------------+------------------------------------------+--------+----------|\n"
    printf "| %-25s | %-10s | %-40s | %-6s | %-8s |\n" "Host" "Endpoint" "Param" "Status" "Latency"
    printf "|---------------------------+------------+------------------------------------------+--------+----------|\n"


    # Call the Sock Shop storefront endpoints repeatedly to generate visible recent workload activity for the Grafana dashboards.
    for endpoint in "${!targets[@]}"; do
        # 1. Grab the base path
        base_path="${targets[$endpoint]}"

        # 2. Get the full path and param (in case we have random params available) 
        #    
        #-------------------------------------------------------------------------------
        # FYI: Regarding that "bash way of receiving multiple return values": 
        #
        # 1. $(get_path_and_param ...) executes and echoes: "/path?id=123 id=123"
        # 2. <<< (Here-String) feeds that string into the 'read' command's stdin.
        # 3. 'read' splits the string at the first space (the default IFS delimiter).
        # 4. The 1st word is assigned to $full_path, the 2nd word to $param.
        # 5. -r ensures backslashes in URLs are treated literally (raw mode).
        #-------------------------------------------------------------------------------
        read -r full_path param <<< "$(get_path_and_param "${base_path}" "$endpoint")" 

        # 3. Hit the endpoint and report the results in the table
        call_endpoint "$full_path" "$endpoint" "$param" 
    done 

  sleep 1
done