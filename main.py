#!/usr/bin/env python3


import sys
from pathlib import Path
import subprocess
import json

# ensure sorting is the same between python and helper script
from natsort import os_sorted

#given a media name

#check if saved list exists, then read everything into a dictionary (i.e name to ep #)
medialist = Path.home() / '.medialist.json'
selected = sys.argv[1]

if not selected: sys.exit(0)

curr_dir = Path(sys.argv[2]) / selected

def update_recent(rc_list):
    #manually going through to prevent two linear searches. not necessary but eh
    for i, val in enumerate(rc_list):
        if val == selected:
            rc_list.pop(i)
    rc_list.insert(0, selected)
    return rc_list

def get_ep():
    data = {}
    mkvs = os_sorted(list(curr_dir.glob('**/*.mkv')))
    try: 
        with medialist.open(mode='r+') as r:
            data = json.load(r)
            data['recency'] = update_recent(data['recency']) if 'recency' in data else [selected]
            r.seek(0)
            json.dump(data, r)
            r.truncate()
        return mkvs[data[selected]]
    except Exception as e:
        print(e)
        with medialist.open(mode='w') as w:
            data[selected] = 0
            json.dump(data, w)
        return mkvs[0]

ep = get_ep()
title = ep.name.replace("'", "\\'")

subprocess.run([f'mpv \'{title}\''], cwd=ep.parent, shell=True)






