#!/bin/bash

dir=$(pwd)
path="$HOME/.local/bin/"
mpv_dir="$HOME/.config/mpv/scripts"

ln_path() {
  for f in "$@"; do
    ln -s "${dir}/${f}" $path
  done
}

ln_path "media_launcher" "main.py" "helpers/recency_ls.py" 
ln -s "${dir}/helpers/update_ep.lua" $mpv_dir


