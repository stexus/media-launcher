#!/bin/bash

dir=$(pwd)
path="$HOME/.local/bin/"
mpv_dir="$HOME/.config/mpv/scripts"

ln_path() {
  for f in "$@"; do
    stripped=${f##*/}
    ln -s "${dir}/${f}" ${path}${stripped%.*}
  done
}


ln_path "media_launcher" "helpers/launch_selected.py" "mpv/selector"\
  "mpv/input_handle.py" "mpv/update_anilist_entry.py"
ln -s "${dir}/mpv/update_ep.lua" $mpv_dir


