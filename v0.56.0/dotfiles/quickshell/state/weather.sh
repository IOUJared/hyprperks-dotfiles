#!/usr/bin/env bash

set -euo pipefail

location="${1:-}"
if [[ -z "$location" || "$location" == "None" ]]; then
  location=$(curl --fail --silent --show-error --location --max-time 15 https://ipinfo.io/city)
fi

encoded_location=$(jq -rn --arg value "$location" '$value | @uri')
geocoding=$(curl --fail --silent --show-error --location --max-time 15 --retry 2 \
  "https://geocoding-api.open-meteo.com/v1/search?name=${encoded_location}&count=1&language=en&format=json")

IFS=$'\t' read -r latitude longitude resolved_location timezone < <(
  jq -er '[.results[0].latitude, .results[0].longitude, .results[0].name, .results[0].timezone] | @tsv' <<<"$geocoding"
)

forecast=$(curl --fail --silent --show-error --location --max-time 15 --retry 2 --get \
  --data-urlencode "latitude=$latitude" \
  --data-urlencode "longitude=$longitude" \
  --data-urlencode "current=temperature_2m,apparent_temperature,precipitation,weather_code" \
  --data-urlencode "temperature_unit=fahrenheit" \
  --data-urlencode "timezone=$timezone" \
  https://api.open-meteo.com/v1/forecast)

jq -er --arg location "$resolved_location" '
  def description($code):
    if $code == 0 then "Clear"
    elif $code == 1 or $code == 2 then "Partly cloudy"
    elif $code == 3 then "Overcast"
    elif $code == 45 or $code == 48 then "Fog"
    elif $code >= 51 and $code <= 57 then "Drizzle"
    elif ($code >= 61 and $code <= 67) or ($code >= 80 and $code <= 82) then "Rain"
    elif ($code >= 71 and $code <= 77) or $code == 85 or $code == 86 then "Snow"
    elif $code >= 95 and $code <= 99 then "Thunderstorm"
    else "Unknown"
    end;
  .current as $current
  | [
      "",
      (($current.temperature_2m | round | tostring) + "°F"),
      description($current.weather_code),
      (($current.apparent_temperature | round | tostring) + "°F"),
      "",
      (($current.precipitation | tostring) + " mm"),
      $location
    ]
  | join("|")
' <<<"$forecast"
