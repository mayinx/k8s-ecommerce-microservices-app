# Optional helper: 
# Generate light repeated storefront traffic (https://prod-sockshop.cdco.dev) until stopped with Ctrl+C.

# Store and reuse session cookies in a temporary local file so repeated requests behave more like one browser session.
COOKIE_JAR=/tmp/sockshop-cookies.txt

while true; do
  echo "------------ $(date '+%H:%M:%S') ------------"

  # Call the Sock Shop storefront endpoints repeatedly to generate visible recent workload activity for the Grafana dashboards.

  # -f = fail on HTTP errors (for example 404 / 500)
  # -s = silent mode (hide normal progress meter)
  # -S = still show an error message if a request fails
  # -A = send a browser-like User-Agent string
  # --cookie = send cookies from the cookie jar file
  # --cookie-jar = update/write cookies back to the cookie jar file
  # -o /dev/null = discard the response body
  # -w = print only the chosen result info here, especially the HTTP status code
  curl -fsS -A "Mozilla/5.0" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
    -o /dev/null -w "[prod-sockshop.cdco.dev] home:    %{http_code}\n" \
    https://prod-sockshop.cdco.dev/

  curl -fsS -A "Mozilla/5.0" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
    -o /dev/null -w "[prod-sockshop.cdco.dev] category:%{http_code}\n" \
    https://prod-sockshop.cdco.dev/category.html

  curl -fsS -A "Mozilla/5.0" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
    -o /dev/null -w "[prod-sockshop.cdco.dev] basket:  %{http_code}\n" \
    https://prod-sockshop.cdco.dev/basket.html

  curl -fsS -A "Mozilla/5.0" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
    -o /dev/null -w "[prod-sockshop.cdco.dev] detail:  %{http_code}\n" \
    "https://prod-sockshop.cdco.dev/detail.html?id=3395a43e-2d88-40de-b95f-e00e1502085b"

  curl -fsS -A "Mozilla/5.0" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" \
    -o /dev/null -w "[prod-sockshop.cdco.dev] formal:  %{http_code}\n" \
    "https://prod-sockshop.cdco.dev/category.html?tags=formal"

  sleep 1
done