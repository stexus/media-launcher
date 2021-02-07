#!/usr/bin/env python3

import sys
from pathlib import Path
import subprocess
import json

#given a media name

#check if saved list exists, then read everything into a dictionary (i.e name to ep #)
#if not, create a new file and import everything from media_dir at 0
#media_list = Path.home() / '.medialist'
medialist = Path.home() / '.medialist.json'
selected = sys.argv[1]
curr_dir = Path(sys.argv[2]) / selected


def get_ep_number(title):
    try:
        with medialist.open(mode='r') as jr:
            data = json.load(jr)
            return data[selected]
    except:
        #create .medialist in Path.home()
        medialist.touch()
        with medialist.open(mode='w') as jw:
            # starts at 0; never been opened and complete episode
            json.dump({selected: 0}, jw)
            return 1

def get_ep_title(ep):
    #prioritize upper levels when finding
    mkvs = list(curr_dir.glob('**/*.mkv'))
    #opening next episode
    return mkvs[int(ep)]

ep = get_ep_number(selected)
title = get_ep_title(ep)
subprocess.run([f'mpv \"{title}\"'], cwd=f'/mnt/misc-ssd/Anime/{selected}/', shell=True)






