#!/usr/bin/env bash

instance_dir=$1
if [[ -z $instance_dir ]]; then
    echo "No instance directory argument given."
    exit
fi

download_dir="$instance_dir/rtorrent-data/"
chmod -R 775 $download_dir

