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

def get_ep(title):
    data = {}
    try: 
        with medialist.open(mode='r') as r:
            data = json.load(r)
        return data[selected]
    except Exception as e:
        print(e)
        with medialist.open(mode='w') as w:
            data[selected] = 0
            json.dump(data, w)
        return 0


def get_title(ep):
    #prioritize upper levels when finding
    mkvs = sorted(list(curr_dir.glob('**/*.mkv')))
    #opening next episode
    return mkvs[ep]

ep = get_ep(selected)
title = get_title(ep)
subprocess.run([f'mpv \"{title}\"'], cwd=f'/mnt/misc-ssd/Anime/{selected}/', shell=True)






