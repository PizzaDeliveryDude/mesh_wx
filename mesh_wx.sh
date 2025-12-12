#!/bin/bash

# this script sends a weather report to your local mesh using weather data from api.openweathermap.org
# openweathermap.org has free basic API access, which this script is using
# this script runs on a raspberry pi and has a Seed Studio L1 Wio plugged in via USB
# scheduling is handled by cron and sent on a non-default channel to avoid spamming the mesh

# script setup
LOG_FILE="mesh_wx/mesh_wx.log"

BeginLog=$(date '+%Y-%m-%d %H:%M:%S')

echo "" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
echo $'\n****************************************' >> "$LOG_FILE"
echo "["$BeginLog"] Begin Log Entry" >> "$LOG_FILE"
echo $'****************************************' >> "$LOG_FILE"

echo $'\n****************************************' >> "$LOG_FILE"
echo $' dependancy check' >> "$LOG_FILE"
echo $'****************************************' >> "$LOG_FILE"

# Source - https://stackoverflow.com/a
# Posted by hek2mgl
# Retrieved 2025-12-09, License - CC BY-SA 3.0

#if command -v curl >/dev/null 2>&1 ; then
#	echo "curl found"
#	#echo "version: $(curl --version)"
#else
#	echo "curl not found"
#	exit 1
#fi
#if command -v jq >/dev/null 2>&1 ; then
#	echo "jq found"
#	#echo "version: $(jq --version)"
#else
#	echo "jq not found"
#	exit 2
#fi
#if command -v meshtastic >/dev/null 2>&1 ; then
#	echo "meshtastic found"
#	#echo "version: $(meshtastic --version)"
#else
#	echo "meshtastic not found"
#	exit 3
#fi

# need to check for USB disconnects
echo $'\n****************************************' >> "$LOG_FILE"
echo $' check for USB disconects' >> "$LOG_FILE"
echo $'****************************************' >> "$LOG_FILE"

# TBD

echo $'\n****************************************' >> "$LOG_FILE"
echo $' script setup' >> "$LOG_FILE"
echo $'****************************************' >> "$LOG_FILE"

# set JSON file path and/or name
JSON_FileName="mesh_wx/mesh_wx.json"
JSON_Path=$JSON_FileName
echo $'temp JSON location: '$JSON_Path >> "$LOG_FILE"

# openweathermap.org API key
source mesh_wx/.env
echo $'APIKey: '$APIKey >> "$LOG_FILE"

# openweathermap.org city id
echo $'CityId: '$CityId >> "$LOG_FILE"

# openweathermap.org api url
OpenWeatherMapUrl=$'http://api.openweathermap.org/data/2.5/weather?id='$CityId$'&units=imperial&appid='$APIKey
echo $'OpenWeatherMapUrl: '$OpenWeatherMapUrl >> "$LOG_FILE"

# set meshtastic channel to send weather report to
# please send to non default channel to avoid spamming the mesh
Channel=2
echo $'Meshtastic Channel: '$Channel >> "$LOG_FILE"

echo $'\n****************************************' >> "$LOG_FILE"
echo $' get weather via api.openweathermap.org' >> "$LOG_FILE"
echo $'****************************************\n' >> "$LOG_FILE"

# get weather from openweatherapi
HTTPCode=$(curl --write-out "%{http_code}\n" "$OpenWeatherMapUrl" --output $JSON_Path --silent)

if ((HTTPCode==200)); then
	echo $'HTTPCode: '$HTTPCode$' - if 200, Ok, successful api execution' >> "$LOG_FILE"
else
	echo $'HTTPCode: '$HTTPCode$' - if not 200, Not Ok, unsuccessful api execution' >> "$LOG_FILE"
fi

echo $'\n****************************************' >> "$LOG_FILE"
echo $' raw weather data' >> "$LOG_FILE"
echo $'****************************************\n' >> "$LOG_FILE"

CoordLon=$(cat $JSON_Path | jq -r .coord.lon)
echo $'CoordLon: '$CoordLon >> "$LOG_FILE"
CoordLat=$(cat $JSON_Path | jq -r .coord.lat)
echo $'CoordLat: '$CoordLat >> "$LOG_FILE"

WeatherMain=$(cat $JSON_Path | jq -r .weather[0].main)
echo $'WeatherMain: '$WeatherMain >> "$LOG_FILE"

MainTemp=$(cat $JSON_Path | jq -r .main.temp)
echo $'MainTemp: '$MainTemp >> "$LOG_FILE"

MainFeelsLike=$(cat $JSON_Path | jq -r .main.feels_like)
echo $'MainFeelsLike: '$MainFeelsLike >> "$LOG_FILE"

MainTempMin=$(cat $JSON_Path | jq -r .main.temp_min)
echo $'MainTempMin: '$MainTempMin >> "$LOG_FILE"

MainTempMax=$(cat $JSON_Path | jq -r .main.temp_max)
echo $'MainTempMax: '$MainTempMax >> "$LOG_FILE"

MainPressure=$(cat $JSON_Path | jq -r .main.pressure)
echo $'MainPressure: '$MainPressure >> "$LOG_FILE"

MainHumidity=$(cat $JSON_Path | jq -r .main.humidity)
echo $'MainHumidity: '$MainHumidity >> "$LOG_FILE"

MainSeaLevel=$(cat $JSON_Path | jq -r .main.sea_level)
echo $'MainSeaLevel: '$MainSeaLevel >> "$LOG_FILE"

MainGroundLevel=$(cat $JSON_Path | jq -r .main.grnd_level)
echo $'MainGroundLevel: '$MainGroundLevel >> "$LOG_FILE"

Visibility=$(cat $JSON_Path | jq -r .visibility)
echo $'Visibility: '$Visibility >> "$LOG_FILE"

WindSpeed=$(cat $JSON_Path | jq -r .wind.speed)
echo $'WindSpeed: '$WindSpeed >> "$LOG_FILE"

WindDeg=$(cat $JSON_Path | jq -r .wind.deg)
echo $'WindDeg: '$WindDeg >> "$LOG_FILE"

#WindGust=$(cat $JSON_Path | jq -r '.wind.gust // "Calm"') #I do not know but grok says to handle nulls using jq -r '.wind.gust // "calm"'
WindGust=$(cat $JSON_Path | jq -r .wind.gust)
echo $'WindGust: '$WindGust >> "$LOG_FILE"

Clouds=$(cat $JSON_Path | jq -r .clouds.all)
echo $'Clouds: '$Clouds >> "$LOG_FILE"

#RainOneHour=$(cat $JSON_Path | jq -r .rain."1h")
#echo $'RainOneHour: '$RainOneHour

#SnowOneHour=$(cat $JSON_Path | jq -r .snow."1h")
#echo $'SnowOneHour: '$SnowOneHour

APICallTime=$(cat $JSON_Path | jq -r .dt)
echo $'dt: '$APICallTime >> "$LOG_FILE"

SysCountry=$(cat $JSON_Path | jq -r .sys.country)
echo $'SysCountry: '$SysCountry >> "$LOG_FILE"

SysSunrise=$(cat $JSON_Path | jq -r .sys.sunrise)
echo $'SysSunrise: '$SysSunrise >> "$LOG_FILE"

SysSunset=$(cat $JSON_Path | jq -r .sys.sunset)
echo $'SysSunset: '$SysSunset >> "$LOG_FILE"

TimeZone=$(cat $JSON_Path | jq -r .timezone)
echo $'TimeZone: '$TimeZone >> "$LOG_FILE"

ID=$(cat $JSON_Path | jq -r .id)
echo $'ID: '$ID >> "$LOG_FILE"

Name=$(cat $JSON_Path | jq -r .name)
echo $'Name: '$Name >> "$LOG_FILE"

echo $'\n****************************************' >> "$LOG_FILE"
echo $' human readable weather data' >> "$LOG_FILE"
echo $'****************************************\n' >> "$LOG_FILE"

CoordLon=$(printf %2.2f $CoordLon)
CoordLon=$CoordLon$'°W'
echo $'CoordLon: '$CoordLon >> "$LOG_FILE"

CoordLat=$(printf %2.2f $CoordLat)
CoordLat=$CoordLat$'°N'
echo $'CoordLat: '$CoordLat >> "$LOG_FILE"

echo $'WeatherMain: '$WeatherMain >> "$LOG_FILE"

MainTemp=${MainTemp%.*}$'°F' # strip decimal, should round instead
echo $'MainTemp: '$MainTemp >> "$LOG_FILE"

MainFeelsLike=${MainFeelsLike%.*}$'°F' # strip decimal, should round instead
echo $'MainFeelsLike: '$MainFeelsLike >> "$LOG_FILE"

MainTempMin=${MainTempMin%.*}$'°F' # strip decimal, should round instead
echo $'MainTempMin: '$MainTempMin >> "$LOG_FILE"

MainTempMax=${MainTempMax%.*}$'°F' # strip decimal, should round instead
echo $'MainTempMax: '$MainTempMax >> "$LOG_FILE"

MainPressure=$MainPressure$'hPa'
echo $'MainPressure: '$MainPressure >> "$LOG_FILE"

MainHumidity=$MainHumidity$'%'
echo $'MainHumidity: '$MainHumidity >> "$LOG_FILE"

MainSeaLevel=$MainSeaLevel$'hPa'
echo $'MainSeaLevel: '$MainSeaLevel >> "$LOG_FILE"

MainGroundLevel=$MainGroundLevel$'hPa'
echo $'MainGroundLevel: '$MainGroundLevel >> "$LOG_FILE"

declare -i Visibility=$((Visibility))
Visibility=Visibility/1000
VisibilityString=$Visibility$'km'
echo $'VisibilityString: '$VisibilityString >> "$LOG_FILE"

WindSpeed=${WindSpeed%.*}$'mph'
echo $'WindSpeed: '$WindSpeed >> "$LOG_FILE"

declare -i WindDegInt=$WindDeg
WindDegName=$'-'
if ((WindDegInt >= 0 && WindDegInt <=23)); then
	WindDegName=$'N ↑'
elif ((WindDegInt >= 24 && WindDegInt <=68)); then
	WindDegName=$'NE ↗'
elif ((WindDegInt >= 69 && WindDegInt <=113)); then
	WindDegName=$'E →'
elif ((WindDegInt >= 114 && WindDegInt <=158)); then
	WindDegName=$'SE ↘'
elif ((WindDegInt >= 159 && WindDegInt <=203)); then
	WindDegName=$'S ↓'
elif ((WindDegInt >= 204 && WindDegInt <=248)); then
	WindDegName=$'SW ↙'
elif ((WindDegInt >= 249 && WindDegInt <=293)); then
	WindDegName=$'W ←'
elif ((WindDegInt >= 294 && WindDegInt <=336)); then
	WindDegName=$'NW ↖'
elif ((WindDegInt >= 337 && WindDegInt <=360)); then
	WindDegName=$'N ↑'
else
	WindDegname=$'Unknown ?'
fi
echo $"WindDegName: "$WindDegName >> "$LOG_FILE"

WindGust=${WindGust%.*}$'mph'
echo $'WindGust: '$WindGust >> "$LOG_FILE"

Clouds=$Clouds$'%'
echo $'Clouds: '$Clouds >> "$LOG_FILE"

APICallTime=$(date -d@$APICallTime)
echo $'APICallTime: '$APICallTime >> "$LOG_FILE"

echo $'Country: '$SysCountry >> "$LOG_FILE"

SysSunrise=$(date -d@$SysSunrise)
echo $'Sunrise: '$SysSunrise >> "$LOG_FILE"

SysSunset=$(date -d@$SysSunset)
echo $'Sunrise: '$SysSunset >> "$LOG_FILE"

declare -i TimeZoneHours=$((TimeZone/3600))
echo $'TimeZone: '$TimeZoneHours$' hours' >> "$LOG_FILE"

echo $'ID: '$ID >> "$LOG_FILE"

echo $'Name: '$Name >> "$LOG_FILE"

# set current time
TIME=$(date +"%H:%M:%S") #time
echo $'Time: '$TIME >> "$LOG_FILE"

echo $'\n****************************************' >> "$LOG_FILE"
echo $' weather report body' >> "$LOG_FILE"
echo $'****************************************\n' >> "$LOG_FILE"

WxReport=$Name$' mesh_wx'
WxReport+=$'\n('$CoordLat$','$CoordLon$')'
WxReport+=$'\n'$TIME
WxReport+=$'\nConditions:'$WeatherMain
WxReport+=$'\nTemp:'$MainTemp
WxReport+=$'\nFeels:'$MainFeelsLike
#WxReport+=$'\nLow:'$MainTempMin
#WxReport+=$'\nHigh:'$MainTempMax
#WxReport+=$'\nPressure:'$MainPressure
#WxReport+=$'\nHumidity:'$MainHumidity
#WxReport+=$'\nMainSeaLevel:'$MainSeaLevel
#WxReport+=$'\nMainGroundLevel:'$MainGroundLevel
#WxReport+=$'\nVisibility:'$VisibilityString
WxReport+=$'\nWind:'$WindDegName$''$WindSpeed
WxReport+=$'\nGust:'$WindGust
#WxReport+=$'\nClouds:'$Clouds
#WxReport+=$'\nSunrise:'$SysSunrise
#WxReport+=$'\nSunset:'$SysSunset
WxReport+=$'\n📍Midtown East'

echo "$WxReport" >> "$LOG_FILE"

MessageLength=$(expr length "$WxReport")
echo $'\nMessage Length: '$MessageLength >> "$LOG_FILE"
if (($MessageLength<220)); then
	echo $'Message Length Ok' >> "$LOG_FILE"
else
	echo $'Message Length Not Ok, reduce message below 220!' >> "$LOG_FILE"
fi

echo $'\n****************************************' >> "$LOG_FILE"
echo $' meshtastic' >> "$LOG_FILE"
echo $'****************************************\n' >> "$LOG_FILE"

python -m venv ~/src/venv && source ~/src/venv/bin/activate;

meshtastic --ch-index $Channel --sendtext "$WxReport">/dev/null 2>&1

EndLog=$(date '+%Y-%m-%d %H:%M:%S')
echo "["$BeginLog"] Begin Log Entry" >> "$LOG_FILE"
echo $'****************************************' >> "$LOG_FILE"
echo "["$EndLog"] End Log Entry" >> "$LOG_FILE"
echo $'****************************************' >> "$LOG_FILE"

#exit 0
