#!/usr/bin/env python
#
# Simple piece of code to generate stream files for XBMC
# from a certain provider

import json
import requests
import re

filerepo = "/storage/TV_Streams/"
baseurl = "http://www..com/tv/"
apiurl = baseurl + "api/"
tvgroup = "UK LIVE TV"

r = requests.get(apiurl + "init")
initval = r.json()

r = requests.get(apiurl + "channels?session_key=" + initval['session_key'])
channels = r.json()
print "Total number of channels to scan: " + str(len(channels))
print "Directory: " + filerepo

for index in range(len(channels)):
    r = requests.get(baseurl + "channel/info/" + channels[index]['id'])
    info = r.json()

    for stream in range(len(info['data']['streams'])):
        #HD Channels include a server-side timeout. Using SD meanwhile :D
        if ("SD" in info['data']['streams'][stream]['name']) and \
                tvgroup in info['data']['group']:
            #All fields: print info['data']
            streamurl = info['data']['streams'][stream]['url']
            chtitle = channels[index]['title']
            chtitle = re.sub('[.!,;/]', '', chtitle)
            filename = chtitle + ".strm"

            print "Creating " + filename
            with open(filerepo + filename, "w") as f:
                f.write(streamurl)
