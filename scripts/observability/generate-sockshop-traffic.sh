#!/bin/bash

################################################################################
# SCRIPT: generate-sockshop-traffic.sh
# 
# TRAFFIC GENERATOR (Observability Helper)
# 
# DESCRIPTION:
#   A synthetic workload generator for the Sock Shop microservices demo.
#   It simulates user behavior by hitting various storefront endpoints (Home,
#   Category, Detail, Basket) in a continuous loop.
#
# WHY THIS MATTERS FOR OBSERVABILITY:
#   1. Metric Generation: Ensures Prometheus has a constant stream of RED 
#      metrics (Requests, Errors, Duration) to scrape from the frontend.
#   2. Dashboard Validation: Provides live data to verify Grafana dashboards
#      and Alertmanager rules without requiring manual browser clicks.
#   3. Session Simulation: Uses a Cookie Jar to simulate stateful browser 
#      behavior, affecting service-side caching and session management.
#
# USAGE:
#   1. DIRECT MODE (CLI Argument):
#      ./generate-sockshop-traffic.sh dev
#      (Starts traffic immediately for the specified environment)
#
#   2. INTERACTIVE MODE (Prompt):
#      ./generate-sockshop-traffic.sh
#      (If no argument is passed, follow prompts to specify 'dev' or 'prod' environment)
#
#   Terminate with Ctrl+C.
################################################################################

# Traffic Generator (Observability Helper): 
# Generates some light repeated storefront traffic on a choosen sock-shop live environment 
# until stopped with Ctrl+C - so that Prometheus + Grafana got something to chew on 

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

detail_ids=(
    "id=3395a43e-2d88-40de-b95f-e00e1502085b"
    "id=510a0d7e-8e83-4193-b483-e27e09ddc34d"
    "id=808a2de1-1aaa-4c25-a9b9-6612e8f29a38"
    "id=03fef6ac-1896-4ce8-bd69-b798f85c6e0b"
    "id=819e1fbf-8b7e-4f6d-811f-693534916a8b"
    "id=a0a4f044-b040-410d-8ead-4de0446aec7e"
)

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

sockshop_env=$1

# Check if environment is passed as an argument, otherwise prompt for it
if [[ -z "$sockshop_env" ]]; then
    read -p "DEFINE TARGET ENVIRONMENT\nPlease define the target sock-shop environment you want to spam with some traffic ('dev' or 'prod'): " sockshop_env 
    echo ""
fi

# Normalize to lowercase for comparison
sockshop_env_normalized="${sockshop_env,,}"

if [[ "${sockshop_env_normalized}" == "dev" || "${sockshop_env_normalized}" == "prod" ]]; then
    echo "--- Generating traffic on the sock-shop '$sockshop_env' environment ---"
    echo "Calling different targets on "https://${sockshop_env_normalized}-sockshop.cdco.dev":"
    echo "(hit Ctrl+C to exit)"
    echo ""
else
    echo "Unknown sock-shop-environment '$sockshop_env'. Available environments are 'dev' or 'prod'."
    exit 1
    echo "ERROR: Unknown sock-shop-environment '$sockshop_env'."
    echo "Usage: $0 [dev|prod]"
    exit 1    
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
  # -w = print the formatted table row with HTTP status and total request time
  curl -fsS -A "Mozilla/5.0" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
    -o /dev/null \
    -w "$(printf '| %-25s | %-10s | %-40s | ' "${sockshop_env_normalized}-sockshop.cdco.dev" "$endpoint" "$param")%{http_code}    | %{time_total} |\n" \
    "https://${sockshop_env_normalized}-sockshop.cdco.dev${full_path}"   
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