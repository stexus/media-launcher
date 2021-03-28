#!/usr/bin/env python3
import sys
from pathlib import Path

absolute_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(absolute_dir))
from helpers.anilist import Anilist

id = sys.argv[1]
episode = sys.argv[2]
api = Anilist()
api.update_entry(id, episode)
