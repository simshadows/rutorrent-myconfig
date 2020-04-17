#!/usr/bin/env bash

instance_dir=$1
if [[ -z $instance_dir ]]; then
    echo "No instance directory argument given."
    exit
fi

download_dir="$instance_dir/rtorrent-data/"
chmod 6775 $download_dir
chown -R rtorrent $download_dir
chgrp -R www-data $download_dir
chmod -R 775 $download_dir/* || true

