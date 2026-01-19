#!/bin/bash

# usage examples
# Griffith Observatory, Los Angles, CA
# mesh_wx.sh 34.11 -118.30 -8 0 "Griffith Observatory"
# Washington Monument, Washington DC
# mesh_wx.sh 38.88 -77.03 -5 0 "Washington DC"
# Central Park New York City
# mesh_wx.sh 40.78 -73.96 -5 0 "Central Park"

# global variables
LAT="${1:-40.78}"
LON="${2:--73.96}"
DIR="mesh_wx"
PREFIX=$DIR
UA="PizaDude"
CHANNEL="${3:-10}"
SENT_FROM="${4:-Central Park}"
MAX_LOGS_TO_KEEP="7"

# functions
logger()
{
  Day=$(date '+%Y-%m-%d')
  local log_file="${1:-$DIR/log/${PREFIX}_${Day}.log}"

  # Ensure directory exists
  mkdir -p -- "$(dirname -- "$log_file")"

  # Read stdin line-by-line and append timestamped lines to the log file.
  # The '|| [ -n "$line" ]' ensures the last line is handled even if it doesn't end with a newline.
  while IFS= read -r line || [ -n "$line" ]; do
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$line" >> "$log_file"
  done

  # remove old logs
  find "${DIR}/log" -maxdepth 1 -name "${PREFIX}_*.log" -type f \
      | xargs -r ls -t \
      | tail -n +$((MAX_LOGS_TO_KEEP + 1)) \
      | xargs -r rm --
}
check_dependencies()
{
  printf "dependencies() started" | logger

  # check if curl is installed
  if command -v curl >/dev/null 2>&1 ; then
      printf "curl found" | logger
  else
      printf "curl not found" | logger
  fi

  # check if jq is installed
  if command -v jq >/dev/null 2>&1 ; then
      printf "jq found" | logger
  else
      printf "jq not found" | logger
  fi

  printf "dependencies() ended" | logger
}
send_message_to_mesh()
{
  printf "send_message_to_mesh() started" | logger

  local TIMESTAMP=$(date '+%H:%M:%S')
  printf "Channel: $CHANNEL" | logger
  MessageBody="$1"
  MessageBody+=$'\n'"📍$SENT_FROM $TIMESTAMP"
  #MessageBody+=$'\n'"$LAT,$LON"
  printf "Message Body: $MessageBody" | logger

  # check how long the message is
  local MessageBodyLength=${#MessageBody}
  printf "Message Body Length: $MessageBodyLength" | logger

  printf "python voo-doo" | logger
  #python -m venv ~/src/venv && source ~/src/venv/bin/activate;
  python3 -m venv meshtastic_venv && source meshtastic_venv/bin/activate;
  #source meshtastic_venv/bin/activate;

  printf "meshtastic cli" | logger
  meshtastic --ch-index $CHANNEL --sendtext "$MessageBody" | logger

  printf "send_message_to_mesh() ended" | logger
}

# copilot wrote this
# converts degrees celsius to fahrenheit
c_to_f() {
  local input="${1:-}"

  if [[ -z $input ]]; then
    echo "Usage: c_to_f <temp[C]>" >&2
    return 1
  fi

  # normalize: remove degree symbols and whitespace, strip trailing 'c' or 'C'
  local s="${input//°/}"
  s="${s//º/}"
  s="${s//[[:space:]]/}"
  s="${s%c}"
  s="${s%C}"

  # validate numeric (allow optional sign and decimal point)
  if ! [[ $s =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
    echo "Invalid temperature: $input" >&2
    return 2
  fi

  # compute and round to nearest whole degree using awk's formatting
  local f
  f=$(awk -v c="$s" 'BEGIN { printf "%.0f", c * 9/5 + 32 }')

  #printf "%s°F\n" "$f"
  printf "%s" "$f"
}
# copilot wrote this
# usage:
#   wind_dir_name <degrees>
wind_dir_name() {
  if [[ -z "$1" ]]; then
  {
	deg=0
	printf "Wind Direction Degree: Null" | logger
  }
  else
  {
	deg=${1}
	printf "Wind Direction Degree: Totally Not Null - $1" | logger
  }
  fi
  #convert to int
  deg=$(printf "%.0f" $deg)

  # validate integer input
  if ! [[ "$deg" =~ ^-?[0-9]+$ ]]; then
    #printf 'wind_dir_name Invalid input: not an integer\n' >&2
    printf 'wind_dir_name Invalid input: not an integer\n' | logger
    return 1
  fi

  # normalize to 0..359
  deg=$(( (deg % 360 + 360) % 360 ))

  # use tenths of degrees to avoid floating point (0..3590)
  local deg10=$((deg * 10))

  if   (( deg10 >= 3375 || deg10 < 225 )); then printf 'N'
  elif (( deg10 >= 225  && deg10 <  675 )); then printf 'NE'
  elif (( deg10 >= 675  && deg10 < 1125 )); then printf 'E'
  elif (( deg10 >= 1125 && deg10 < 1575 )); then printf 'SE'
  elif (( deg10 >= 1575 && deg10 < 2025 )); then printf 'S'
  elif (( deg10 >= 2025 && deg10 < 2475 )); then printf 'SW'
  elif (( deg10 >= 2475 && deg10 < 2925 )); then printf 'W'
  elif (( deg10 >= 2925 && deg10 < 3375 )); then printf 'NW'
  else
    # should never happen
    printf 'Unknown\n' >&2
    return 2
  fi
}
# copilot wrote this
# Function: kph_to_mph <kilometers_per_hour>
# - Converts kilometers/hour to miles/hour
# - Rounds to the nearest whole number
# - If input is empty or numeric 0, prints "calm"
kph_to_mph() {
  local kph="$1"

  # If no argument provided or empty
  if [[ -z "$kph" ]]; then
    printf 'calm'
    return 0
  fi

  # Normalize common forms of zero (0, 0.0, 0.00)
  # And validate numeric input (allow optional leading - for completeness)
  if ! [[ "$kph" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
    # non-numeric input -> treat as calm per safety (change if you prefer an error)
    printf 'calm'
    return 0
  fi

  # If numeric value is exactly zero -> calm
  # Use awk to check numeric value (handles decimals)
  if awk -v v="$kph" 'BEGIN { if (v+0 == 0) exit 0; exit 1 }'; then
    printf 'calm'
    return 0
  fi

  # Convert KPH to MPH (1 mile = 1.609344 km) and round to nearest whole number
  local mph
  mph=$(awk -v k="$kph" 'BEGIN { printf "%.0f", k / 1.609344 }')

  printf '%s mph' "$mph"
}

# Examples:
# echo "$(kph_to_mph 100)"   # -> 62
# echo "$(kph_to_mph 0)"     # -> calm
# echo "$(kph_to_mph 5.5)"   # -> 3
# echo "$(kph_to_mph)"       # -> calm
metadata()
{
  printf "metadata() started" | logger

  # basic variables
  local TODAYS_DATE=$(date '+%Y-%m-%d')
  local FILE="metadata.json"
  local JSON=$DIR"/"$FILE

  # log all of the variables
  printf "DIR: $DIR" | logger
  printf "FILE: $FILE" | logger
  printf "JSON: $JSON" | logger
  printf "LAT: $LAT" | logger
  printf "LON: $LON" | logger
  printf "UA: $UA" | logger

  # build URL (coords as LAT,LON)
  local COORDS="${LAT},${LON}"
  printf "COORDS: $COORDS" | logger

  # api.weather.gov
  local URL="https://api.weather.gov/points/$COORDS"
  printf "URL: $URL" | logger

  # get data
  curl -H "Accept: application/geo+json" -H "User-Agent: ${UA}" --silent $URL > $JSON | logger

  # ensure json is valid
  jq empty $JSON | logger

  # json data
  ForecastURL=$(jq -r .properties.forecast $JSON)
  printf "JSON Data ForecastURL: $ForecastURL" | logger

  ForecastHourlyURL=$(jq -r .properties.forecastHourly $JSON)
  printf "JSON Data ForecastHourlyURL: $ForecastHourlyURL" | logger

  ObservationStationsURL=$(jq -r .properties.observationStations $JSON)
  printf "JSON Data ObservationsStationsURL: $ObservationStationsURL" | logger

  local FILE="station.json"
  local JSON=$DIR"/"$FILE
  curl -H "Accept: application/geo+json" -H "User-Agent: ${UA}" --silent $ObservationStationsURL > $JSON | logger

  # ensure json is valid
  jq empty $JSON | logger

  StationID=$(jq -r .features[0].properties.stationIdentifier $JSON)
  printf "JSON Data StationID: $StationID" | logger

  LatestObservationsURL="https://api.weather.gov/stations/${StationID}/observations/latest?require_qc=false"
  local FILE="latest_observations.json"
  local JSON=$DIR"/"$FILE
  curl -H "Accept: application/geo+json" -H "User-Agent: ${UA}" --silent $LatestObservationsURL > $JSON | logger

  # ensure json is valid
  jq empty $JSON | logger

  local FILE="forecast.json"
  local JSON=$DIR"/"$FILE
  curl -H "Accept: application/geo+json" -H "User-Agent: ${UA}" --silent $ForecastURL > $JSON | logger

  # ensure json is valid
  jq empty $JSON | logger

  local FILE="hourly_forecast.json"
  local JSON=$DIR"/"$FILE
  curl -H "Accept: application/geo+json" -H "User-Agent: ${UA}" --silent $ForecastHourlyURL > $JSON | logger

  # ensure json is valid
  jq empty $JSON | logger

  printf "metadata() ended" | logger
}
latest_observations()
{
  printf "latest_observations() started" | logger

  # basic variables
  local FILE="latest_observations.json"
  local JSON=$DIR"/"$FILE

  Id=$(jq -r .id $JSON)
  printf "Id: $Id" | logger

  Latitude=$(jq -r .geometry.coordinates[1] $JSON)
  printf "Latitude: $Latitude" | logger

  Longitude=$(jq -r .geometry.coordinates[0] $JSON)
  printf "Longitude: $Longitude" | logger

  StationId=$(jq -r .properties.stationId $JSON)
  printf "StationId: $StationId" | logger

  StationName=$(jq -r .properties.stationName $JSON)
  printf "Station Name: $StationName" | logger

  TextDescription=$(jq -r .properties.textDescription $JSON)
  printf "Text Description: $TextDescription" | logger

  TemperatureC=$(jq -r .properties.temperature.value $JSON)
  TemperatureF=$(c_to_f $(echo "$TemperatureC" | bc))
  printf "Temperature (°C): $TemperatureC Converted Temperature (°F): $TemperatureF" | logger

  DewpointC=$(jq -r .properties.dewpoint.value $JSON)
  DewpointF=$(c_to_f $(echo "$DewpointC" | bc))
  printf "Dewpoint (°C): $DewpointC Converted Dewpoint (°F): $DewpointF" | logger

  WindDirection=$(jq -r .properties.windDirection.value $JSON)
  WindDirectionName=$(wind_dir_name $WindDirection)
  printf "Wind Direction(°): $WindDirection Wind Direction Name: $WindDirectionName" | logger

  WindSpeedKPH=$(jq -r .properties.windSpeed.value $JSON)
  WindSpeedMPH=$(kph_to_mph $WindSpeedKPH)
  printf "Wind Speed kph: $WindSpeedKPH Wind Speed mph: $WindSpeedMPH" | logger

  WindGust=$(jq -r .properties.windGust.value $JSON)
  printf "Wind Gust: $WindGust" | logger

  Pressure=$(jq -r .properties.barometricPressure.value $JSON)
  printf "Pressure: $Pressure" | logger

  SeaLevelPressure=$(jq -r .properties.seaLevelPressure.value $JSON)
  printf "Sea Level Pressure: $SeaLevelPressure" | logger

  Visibility=$(jq -r .properties.visibility.value $JSON)
  printf "Visibility: $Visibility" | logger

  PrecipLastHour=$(jq -r .properties.precipitationLastHour.value $JSON)
  printf "Precip Last Hour: $PrecipLastHour" | logger

  RelHumidity=$(jq -r .properties.relativeHumidity.value $JSON)
  printf "Relative Humidity: $RelHumidity" | logger

  WindChill=$(jq -r .properties.WindChill.value $JSON)
  printf "Wind Chill: $WindChill" | logger

  HeatIndex=$(jq -r .properties.heatIndex.value $JSON)
  printf "Heat Index: $HeatIndex" | logger

  CloudLayers=$(jq -r .properties.cloudLayers[0].base.value $JSON)
  printf "Cloud Layers: $CloudLayers" | logger

  MessageBody="Latest Observations"
  MessageBody+=$'\nConditions:'$TextDescription
  MessageBody+=$'\nTemp:'$TemperatureF"°F"
  MessageBody+=$'\nDewpoint:'$DewpointF"°F"
  if [ "$WindSpeedMPH" != "calm" ]; then
        MessageBody+=$'\nWind:'$WindDirectionName" "$WindSpeedMPH
  else
        MessageBody+=$'\nWind:'$WindSpeedMPH
  fi
  #MessageBody+=$'\n'$Latitude","$Longitude

  # check how long the message is
  MessageBodyLength=${#MessageBody}
  printf "Message Body Length: $MessageBodyLength" | logger

  # send latest observations
  send_message_to_mesh "$MessageBody"

  printf "latest_observations() ended" | logger
}
LogBegin=$(date '+%Y-%m-%d %H:%M:%S')
printf "+------------------------------------+" | logger
printf "| BEGIN $LogBegin          |" | logger
printf "+------------------------------------+" | logger

printf "DIR: $DIR" | logger
printf "PREFIX: $PREFIX" | logger
printf "UA: $UA" | logger
printf "CHANNEL: $CHANNEL" | logger
printf "SENT_FROM: $SENT_FROM" | logger
printf "MAX_LOGS_TO_KEEP: $MAX_LOGS_TO_KEEP" | logger

metadata
latest_observations

LogEnd=$(date '+%Y-%m-%d %H:%M:%S')
printf "+------------------------------------+" | logger
printf "|   END $LogEnd          |" | logger
printf "+------------------------------------+" | logger
