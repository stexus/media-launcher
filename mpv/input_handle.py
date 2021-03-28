#!/usr/bin/env python3
import sys
from pathlib import Path
import json
import subprocess
from threading import Timer
#hacky way to import stuff
parent_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(parent_dir))
from helpers.anilist import Anilist
class TimerWrapper():
    def __init__(self):
        self.timer = None

    #if timer hasn't called cb yet, filter current results instead of doing nothing
    def start_timer(self, cb):
        if self.timer:
            self.timer.cancel()
        self.timer = Timer(0.5, cb)
        self.timer.start()



#rofi blocks doesn't read python's stdout; need to use bash
def print_bash(msg):
    subprocess.run([f'echo \'{msg}\''], shell=True)

def escape(text):
    return text.replace("'", '\"')

def format_lines(input):
    message = {}
    #blocks doesn't support single quotes
    message['lines'] = [{'text': escape(entry)} for entry in input]
    return json.dumps(message)

def send_lines(lines):
    msg = format_lines(lines)
    print(msg, file=sys.stderr)
    print_bash(msg)

api = Anilist()
timer = TimerWrapper()

#temp file name passed in from mpv
tmp = Path(sys.argv[1]) if len(sys.argv) > 1 else None

print_bash('{"input action":"send", "prompt":""}')
def on_line_change(line):
    line_json = json.loads(line)
    name = line_json['name']
    value = line_json['value']
    if name == 'input change': 
        query = json.loads(line)['value']
        cb = lambda: send_lines(api.search(query))
        timer.start_timer(cb)
    elif name == 'select entry':
        #somehow communicate between lua script
        #webbrowser.open(f'https://anilist.co/anime/{api.curr_search[value]}')
        id = api.curr_search[value]
        if tmp:
            tmp.write_text(str(id))
        return True
    return False

for line in sys.stdin:
    id = on_line_change(line)
    if id: 
        break; 
