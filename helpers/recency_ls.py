#!/usr/bin/env python3

from pathlib import Path
import json
import sys
from natsort import os_sorted

medialist = Path.home() / '.medialist.json'
media_dir = Path(sys.argv[1])

def get_recency():
    data = []
    try: 
        with medialist.open(mode='r') as r:
            data = json.load(r)
        return data['recency']
    except Exception:
        return []

def recency_ls(rc_list):
    bash_ls = os_sorted([dir.name for dir in media_dir.iterdir() if dir.is_dir()])
    rc_ls = {r:None for r in rc_list}
    for title in bash_ls:
        if title not in rc_ls:
            rc_ls[title] = None
    return list(rc_ls)


rc_list = get_recency()

sys.stdout.write('\n'.join(recency_ls(rc_list)))








