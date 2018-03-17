#!/usr/bin/env bash

# Terminate script on error
set -e

# Get the source directory
# (This may not be portable.)
source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Arguments
instance_dir=$1
if [[ -z $instance_dir ]]; then
    echo "No argument given."
    exit
elif [[ "$instance_dir" != /* ]]; then
    echo "Argument must be an absolute path."
    exit
elif [[ ! -d $instance_dir ]]; then
    echo "Directory '$instance_dir' does not exist. Please create it and run this script again."
    exit
fi

################
# System Setup #
################

useradd -rm www-data || true
useradd -rm rtorrent || true
useradd -rm rutorrent || true
groupadd rtorrent-socket || true

gpasswd -a www-data rtorrent-socket
gpasswd -a rtorrent rtorrent-socket
gpasswd -a rutorrent rtorrent-socket

#################################
# Other Misc Instance Variables #
#################################

instance_name='public0'
php_fpm_poold_loc='/etc/php/7.0/fpm/pool.d/'
nginx_html_loc='/usr/share/nginx/html/'

#rpc_mountpoint="/RPC2-$instance_name"
rpc_mountpoint="/RPC2"
rutorrent_url="/rutorrent-$instance_name"

###################
# Instance Layout #
###################

## General

config_dir="$instance_dir/instance-config/"
rtorrent_inst_file="$config_dir/rtorrent-instance.rc"
nginx_inst_file="$config_dir/nginx-instance-config"

sockets_dir="$instance_dir/instance-sockets/"
rtorrent_sock="$sockets_dir/rtorrent.sock"
rutorrent_sock="$sockets_dir/php-fpm-rutorrent.sock"

## rtorrent

session_dir="$instance_dir/rtorrent-session/"
download_dir="$instance_dir/rtorrent-data/"
watch_start_dir="$instance_dir/rtorrent-watch-start/"
watch_normal_dir="$instance_dir/rtorrent-watch-normal/"
rtorrent_log_dir="$instance_dir/rtorrent-logs/"

## rutorrent
## NOTE: I find it strange how rutorrent sometimes makes its own directories,
## and sometimes doesn't.

rutorrent_data_dir="$instance_dir/rutorrent-webappdata/"
rutorrent_settings_dir="$rutorrent_data_dir/settings/"
rutorrent_tmp_dir="$rutorrent_data_dir/tmp/"
rutorrent_torrents_dir="$rutorrent_data_dir/torrents/"
rutorrent_users_dir="$rutorrent_data_dir/users/"

rutorrent_log_dir="$instance_dir/rutorrent-logs/"
nginx_access_log="$rutorrent_log_dir/nginx.rutorrent.access.log"
nginx_error_log="$rutorrent_log_dir/nginx.rutorrent.error.log"
nginx_rpc2_access_log="$rutorrent_log_dir/nginx.rutorrent.rpc2.access.log"
nginx_rpc2_error_log="$rutorrent_log_dir/nginx.rutorrent.rpc2.error.log"

#############################
# Directory Structure Setup #
#############################

mkdir -p $instance_dir \
    $config_dir \
    $sockets_dir \
    $session_dir \
    $download_dir \
    $watch_start_dir \
    $watch_normal_dir \
    $rtorrent_log_dir \
    $rutorrent_data_dir \
    $rutorrent_settings_dir \
    $rutorrent_tmp_dir \
    $rutorrent_torrents_dir \
    $rutorrent_users_dir \
    $rutorrent_log_dir \

########################
# Other Instance Setup #
########################

function create_sock_file () {
    python -c "import socket as s; sock = s.socket(s.AF_UNIX); sock.bind('$1')" || true
}

create_sock_file $rtorrent_sock
chmod 0660 $rtorrent_sock
chown rtorrent $rtorrent_sock
chgrp rtorrent-socket $rtorrent_sock

create_sock_file $rutorrent_sock
chmod 0660 $rutorrent_sock
chown rutorrent $rutorrent_sock
chgrp www-data $rutorrent_sock

# This file specifies the instance base directory for rtorrent.
cat <<EOF > $rtorrent_inst_file
method.insert = cfg.basedir, private|const|string, (cat, "$instance_dir")
EOF

# This file specifies the instance base directory for rtorrent.
cat <<EOF > $nginx_inst_file
location $rutorrent_url {
    scgi_param CFG_INSTANCE_DIR $instance_dir;
    scgi_param CFG_XMLRPC_MOUNTPOINT $rpc_mountpoint;

    access_log $nginx_access_log;
    error_log $nginx_error_log debug;

    location ~ .php$ {
        fastcgi_split_path_info ^(.+\\.php)(.*)$;
        fastcgi_pass    unix:$rutorrent_sock;
        fastcgi_index   index.php;
        #fastcgi_param   SCRIPT_FILENAME \$document_root$rutorrent_url\$fastcgi_script_name;
        fastcgi_param   SCRIPT_FILENAME \$request_filename;

        include /etc/nginx/fastcgi_params;
        fastcgi_intercept_errors        on;
        fastcgi_ignore_client_abort     off;
        fastcgi_connect_timeout         60;
        fastcgi_send_timeout            180;
        fastcgi_read_timeout            180;
        fastcgi_buffer_size             128k;
        fastcgi_buffers                 4       256k;
        fastcgi_busy_buffers_size       256k;
        fastcgi_temp_file_write_size    256k;
    }
}

location $rpc_mountpoint {
    access_log $nginx_rpc2_access_log;
    error_log $nginx_rpc2_error_log debug;
    include /etc/nginx/scgi_params;
    scgi_pass unix:$rtorrent_sock;
}
EOF

cat <<EOF > $php_fpm_poold_loc/rutorrent-$instance_name.conf
[rutorrent-$instance_name]
user = rutorrent
group = rutorrent
listen = $rutorrent_sock
listen.owner = rutorrent
listen.group = www-data
listen.mode = 0660
pm = static
pm.max_children = 2
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
chdir = /
EOF

ln -s /mnt/drive0/rtorrent/rutorrent/ $nginx_html_loc/$rutorrent_url || true

##############
# Conclusion #
##############

cat <<EOF
DONE!

(If you saw a lot of errors, that's usually normal as long as you see this message.)

#############################
# WHAT YOU NEED TO DO NEXT: #
#############################

1) Add this line to the nginx config:
---
include $nginx_inst_file;
---

2) Add the following to 'open_basedir' in the file 'php.ini':
---
<<TODO: do this.>>
---

3) After doing the above steps (in any order), restart/enable nginx and php-fpm as needed:
---
systemctl enable nginx php-fpm
systemctl restart nginx php-fpm
---
(Service names may differ. Check 'systemctl list-unit-files' if necessary.)
EOF

