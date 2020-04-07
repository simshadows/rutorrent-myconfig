#!/usr/bin/env bash

# TODO: Make this more robust

# Get the source directory
# (This may not be portable.)
source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo systemctl restart nginx php7.3-fpm

# Set up tmux
tmux new -ds 'rtorrent'
tmux neww -t 'rtorrent' sudo -u rtorrent bash /mnt/drive11/rtorrent/instance-public0/instance-scripts/run.sh
#tmux neww -t 'rtorrent' sudo -u rtorrent bash /mnt/drive0/rtorrent/instance-red0/instance-scripts/run.sh
#tmux neww -t 'rtorrent' sudo -u rtorrent bash /mnt/drive0/rtorrent/instance-red0b/instance-scripts/run.sh
#tmux neww -t 'rtorrent' sudo -u rtorrent bash /mnt/drive0/rtorrent/instance-red1/instance-scripts/run.sh
#tmux neww -t 'rtorrent' sudo -u rtorrent bash /mnt/drive3/rtorrent/instance-red2/instance-scripts/run.sh
#tmux neww -t 'rtorrent' sudo -u rtorrent bash /mnt/drive0/rtorrent/instance-nw0/instance-scripts/run.sh
#tmux neww -t 'rtorrent' sudo -u rtorrent bash /mnt/drive0/rtorrent/instance-nw1/instance-scripts/run.sh
#tmux neww -t 'rtorrent' sudo -u rtorrent bash /mnt/drive3/rtorrent/instance-jpopsuki0/instance-scripts/run.sh
