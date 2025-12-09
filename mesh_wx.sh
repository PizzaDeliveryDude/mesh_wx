#!/bin/bash

# this script sends a weather report to your local mesh using weather data from api.openweathermap.org
# openweathermap.org has free basic API access, which this script is using
# this script runs on a raspberry pi and has a Seed Studio L1 Wio plugged in via USB
# scheduling is handled by cron and sent on a non-default channel to avoid spamming the mesh

# script setup
echo $(clear)
echo $'****************************************'
echo $' script setup'
echo $'****************************************\n'

# set current runtime variable
#TIME=$(date +"%Y-%m-%d %H:%M:%S")
TIME=$(date +"%H:%M:%S")
echo $TIME

# set JSON file path and/or name
JSON_Path=$'temp_mesh_wx_openweatherapi.json'
echo $JSON_Path

# openweathermap.org API key
APIKey=$'0f902b4043b55cd835b969d545a4e045'
echo $APIKey

# openweathermap.org city id
CityId=$'5125771'
echo $CityId

# set meshtastic channel to send weather report to
# please send to non default channel to avoid spamming the mesh
CHANNEL=2
echo $Channel

echo $'\n****************************************'
echo $' get weather via api.openweathermap.org'
echo $'****************************************\n'

# get weather from openweatherapi
declare -i HTTPCode=$(curl --write-out "%{http_code}\n" "http://api.openweathermap.org/data/2.5/weather?id=$CityId&units=imperial&appid=$APIKey" --output $JSON_Path --silent)
if ((HTTPCode = 200)); then
	echo $'HTTPCode: '$HTTPCode$' - successful api execution'
else
	echo $'HTTPCode: '$HTTPCode$' - unsuccessful api execution'
fi
echo $'\n****************************************'
echo $' raw weather data'
echo $'****************************************\n'

CoordLon=$(cat $JSON_Path | jq -r .coord.lat)
echo $'CoordLon: '$CoordLon
CoordLat=$(cat $JSON_Path | jq -r .coord.lon)
echo $'CoordLat: '$CoordLat

WeatherMain=$(cat $JSON_Path | jq -r .weather)
echo $'WeatherMain: '$WeatherMain

MainTemp=$(cat $JSON_Path | jq -r .main.temp)
echo $'MainTemp: '$MainTemp

MainFeelsLike=$(cat $JSON_Path | jq -r .main.feels_like)
echo $'MainFeelsLike: '$MainFeelsLike

MainTempMin=$(cat $JSON_Path | jq -r .main.temp_min)
echo $'MainTempMin: '$MainTempMin

MainTempMax=$(cat $JSON_Path | jq -r .main.temp_max)
echo $'MainTempMax: '$MainTempMax

MainPressure=$(cat $JSON_Path | jq -r .main.pressure)
echo $'MainPressure: '$MainPressure

MainHumidity=$(cat $JSON_Path | jq -r .main.humidity)
echo $'MainHumidity: '$MainHumidity

MainSeaLevel=$(cat $JSON_Path | jq -r .main.sea_level)
echo $'MainSeaLevel: '$MainSeaLevel

MainGroundLevel=$(cat $JSON_Path | jq -r .main.grnd_level)
echo $'MainGroundLevel: '$MainGroundLevel

Visibility=$(cat $JSON_Path | jq -r .visibility)
echo $'Visibility: '$Visibility

WindSpeed=$(cat $JSON_Path | jq -r .wind.speed)
echo $'WindSpeed: '$WindSpeed

WindDeg=$(cat $JSON_Path | jq -r .wind.deg)
echo $'WindDeg: '$WindDeg

WindGust=$(cat $JSON_Path | jq -r .wind.gust)
echo $'WindGust: '$WindGust

Clouds=$(cat $JSON_Path | jq -r .clouds.all)
echo $'Clouds: '$Clouds

#RainOneHour=$(cat $JSON_Path | jq -r .rain.1h)
#echo $'RainOneHour: '$RainOneHour

#SnowOneHour=$(cat $JSON_Path | jq -r .snow.1h)
#echo $'SnowOneHour: '$SnowOneHour

APICallTime=$(cat $JSON_Path | jq -r .dt)
echo $'dt: '$APICallTime

SysCountry=$(cat $JSON_Path | jq -r .sys.country)
echo $'SysCountry: '$SysCountry

SysSunrise=$(cat $JSON_Path | jq -r .sys.sunrise)
echo $'SysSunrise: '$SysSunrise

SysSunset=$(cat $JSON_Path | jq -r .sys.sunset)
echo $'SysSunset: '$SysSunset

TimeZone=$(cat $JSON_Path | jq -r .timezone)
echo $'TimeZone: '$TimeZone

ID=$(cat $JSON_Path | jq -r .id)
echo $'ID: '$ID

Name=$(cat $JSON_Path | jq -r .name)
echo $'Name: '$Name

echo $'\n****************************************'
echo $' human readable weather data'
echo $'****************************************\n'
CoordLon=$CoordLon$'°N'
echo $'CoordLon: '$CoordLon

CoordLat=$CoordLat$'°W'
echo $'CoordLat: '$CoordLat

echo $'WeatherMain: '$WeatherMain

MainTemp=${MainTemp%.*}$'°F' # strip decimal, should round instead
echo $'MainTemp: '$MainTemp

MainFeelsLike=${MainFeelsLike%.*}$'°F' # strip decimal, should round instead
echo $'MainFeelsLike: '$MainFeelsLike

MainTempMin=${MainTempMin%.*}$'°F'
echo $'MainTempMin: '$MainTempMin

MainTempMax=${MainTempMax%.*}$'°F' # strip decimal, should round instead
echo $'MainTempMax: '$MainTempMax

MainPressure=$MainPressure$' hPa'
echo $'MainPressure: '$MainPressure

MainHumidity=$MainHumidity$'%'
echo $'MainHumidity: '$MainHumidity

MainSeaLevel=$MainSeaLevel$' hPa'
echo $'MainSeaLevel: '$MainSeaLevel

MainGroundLevel=$MainGroundLevel$' hPa'
echo $'MainGroundLevel: '$MainGroundLevel

declare -i Visibility=$((Visibility))
Visibility=Visibility/1000
VisibilityString=$Visibility$' km'
echo $'VisibilityString: '$VisibilityString

WindSpeed=$WindSpeed$' mph'
echo $'WindSpeed: '$WindSpeed

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
echo $"WindDegName: "$WindDegName

WindGust=$WindGust$' mph'
echo $'WindGust: '$WindGust

Clouds=$Clouds$'%'
echo $'Clouds: '$Clouds

APICallTime=$(date -d@$APICallTime)
echo $'APICallTime: '$APICallTime

echo $'Country: '$SysCountry

SysSunrise=$(date -d@$SysSunrise)
echo $'Sunrise: '$SysSunrise

SysSunset=$(date -d@$SysSunset)
echo $'Sunrise: '$SysSunset

declare -i TimeZoneHours=$((TimeZone/3600))
echo $'TimeZone: '$TimeZoneHours$' hours'

echo $'ID: '$ID

echo $'Name: '$Name

echo $'\n****************************************'
echo $' weather report body'
echo $'****************************************\n'

WxReport=$Name$' Weather'
WxReport+=$'\n('$CoordLon$','$CoordLat$')'
WxReport+=$'\n'$TIME
#WxReport+=$'\nConditions: '$WeatherMain
WxReport+=$'\nTemp: '$MainTemp
WxReport+=$'\nFeels Like: '$MainFeelsLike
#WxReport+=$'\nLow: '$MainTempMin
#WxReport+=$'\nHigh: '$MainTempMax
#WxReport+=$'\nPressure: '$MainPressure
#WxReport+=$'\nHumidity: '$MainHumidity
#WxReport+=$'\nMainSeaLevel: '$MainSeaLevel
#WxReport+=$'\nMainGroundLevel: '$MainGroundLevel
#WxReport+=$'\nVisibility: '$VisibilityString
WxReport+=$'\nWind: '$WindDegName$' '$WindSpeed
WxReport+=$'\nWind Gust: '$WindGust
#WxReport+=$'\nClouds: '$Clouds
#WxReport+=$'\nSunrise: '$SysSunrise
#WxReport+=$'\nSunset: '$SysSunset
WxReport+=$'\nSent from Midtown East'

echo "$WxReport"

echo $'\n****************************************'
echo $' meshtastic'
echo $'****************************************\n'
python -m venv ~/src/venv && source ~/src/venv/bin/activate 
meshtastic --ch-index $CHANNEL --sendtext "$WxReport"
