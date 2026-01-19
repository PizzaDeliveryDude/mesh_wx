# mesh_wx.sh

## What is it?

It is a crude way to send NOAA current conditions via Meshtastic.

## How do I use it?

### meshtasticd

### make sure the bash script is executable:

sudo chmod +x mesh_wx/mesh_wx.sh

### cron - your lat and lon should match "where are you transmitting from?"

crontab -e

#### syntax
mesh_wx.sh [lat] [lon] [timezone offset] [mshtastic channel number] [where are you transmitting from?]

08 * * * * bash /path/to/mesh_wx/mesh_wx.sh 40.78 -73.96 -5 0 "Central Park"
