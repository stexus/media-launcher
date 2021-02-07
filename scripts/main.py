#!/usr/bin/env python3

import sys
from pathlib import Path
import subprocess

#given a media name

#check if saved list exists, then read everything into a dictionary (i.e name to ep #)
#if not, create a new file and import everything from media_dir at 0
#media_list = Path.home() / '.medialist'
media_list = Path.home() / '.testmedialist'
selected = sys.argv[1]
media_dir=Path(sys.argv[2])
def get_ep_number(title):
    try:
        with media_list.open(mode='r') as reader:
            for line in reader.read().splitlines():
                title = line[:-2]
                if title == selected:
                    return line[-1]
    except:
        #create .medialist in Path.home()
        media_list.touch()
        with media_list.open(mode='w') as writer:
            for title in media_dir.iterdir():
                if title.is_dir():
                    writer.write(f'{title.name} 1\n')

def get_ep_title(ep, dir):
    #prioritize upper levels when finding
    curr_dir = media_dir / selected
    mkvs = list(curr_dir.glob('**/*.mkv'))
    return mkvs[int(ep) - 1]

ep = get_ep_number(selected)
title = get_ep_title(ep, '')
subprocess.run(['mpv', title])






