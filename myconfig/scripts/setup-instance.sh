#!/usr/bin/env bash

# Terminate script on error
set -e

# Get the source directory
# (This may not be portable.)
source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

print_usage() {
    echo ""
    echo "Usage:"
    echo "./setup-instance.sh <instance_directory> <instance_name> <bittorrent_port>"
    echo ""
    echo "Example:"
    echo "./setup-instance.sh /mnt/drive11/rtorrent/instance-public0 public0 50000"
    echo ""
}

# Arguments with some basic checks.
instance_dir=$1
if [[ -z $instance_dir ]]; then
    echo ""
    echo "No instance directory argument given."
    print_usage
    exit
elif [[ "$instance_dir" != /* ]]; then
    echo ""
    echo "Argument must be an absolute path."
    print_usage
    exit
elif [[ ! -d $instance_dir ]]; then
    echo ""
    echo "Directory '$instance_dir' does not exist. Please create it and run this script again."
    print_usage
    exit
fi
echo "instance_dir <-- '$instance_dir'"
instance_name=$2
if [[ -z $instance_name ]]; then
    echo ""
    echo "No instance name argument given."
    print_usage
    exit
fi
echo "instance_name <-- '$instance_name'"
torrent_listening_port=$3
if [[ -z $torrent_listening_port ]]; then
    echo ""
    echo "No torrent listening port argument given."
    print_usage
    exit
fi
echo "torrent_listening_port <-- '$torrent_listening_port'"

################
# System Setup #
################

useradd -r www-data || true
useradd -r rtorrent || true
useradd -r rutorrent || true
groupadd rtorrent-socket || true

gpasswd -a www-data rtorrent-socket
gpasswd -a rtorrent rtorrent-socket
gpasswd -a rutorrent rtorrent-socket

#################################
# Other Misc Manifest Variables #
#################################

# THESE CAN BE EDITED AS NECESSARY.

php_fpm_poold_loc='/etc/php/7.3/fpm/pool.d/'
nginx_html_loc='/usr/share/nginx/html/'

rpc_mountpoint="/RPC2-$instance_name"
rutorrent_url="/rutorrent-$instance_name"

###################
# Instance Layout #
###################

## General

scripts_dir="$instance_dir/instance-scripts/"
run_sh="$scripts_dir/run.sh"

config_dir="$instance_dir/instance-config/"
rtorrent_inst_file="$config_dir/rtorrent-instance.rc"
nginx_inst_file="$config_dir/nginx-instance-config"

sockets_dir="$instance_dir/instance-sockets/"
rtorrent_sock="$sockets_dir/rtorrent.sock"
rutorrent_sock="$sockets_dir/php-fpm-rutorrent.sock"

## rtorrent

session_dir="$instance_dir/rtorrent-session/"
pid_file="$session_dir/rtorrent.pid"

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

nginx_log_dir="$instance_dir/nginx-logs/"
nginx_access_log="$nginx_log_dir/nginx.rutorrent.access.log"
nginx_error_log="$nginx_log_dir/nginx.rutorrent.error.log"
nginx_rpc2_access_log="$nginx_log_dir/nginx.rutorrent.rpc2.access.log"
nginx_rpc2_error_log="$nginx_log_dir/nginx.rutorrent.rpc2.error.log"

#############################
# Directory Structure Setup #
#############################

# We assume the instance directory has already been set up.
chmod 755 $instance_dir

mkdir -p $scripts_dir

mkdir -p $config_dir

mkdir -p $sockets_dir
chmod 770 $sockets_dir
chgrp rtorrent-socket $sockets_dir
# clear out sockets directory
rm $sockets_dir/* || true

mkdir -p $session_dir
chmod 700 $session_dir
chmod -R 744 $session_dir/* || true
chown -R rtorrent $session_dir
chgrp -R rtorrent $session_dir

mkdir -p $download_dir
chmod 6775 $download_dir
chown -R rtorrent $download_dir
chgrp -R www-data $download_dir
chmod 775 $download_dir
#chmod -R 644 $download_dir/* || true
chmod -R 775 $download_dir/* || true

mkdir -p $watch_start_dir
chmod 6700 $watch_start_dir
chown rtorrent $watch_start_dir
chgrp www-data $watch_start_dir
# TODO: Any ID/permission changes?

mkdir -p $watch_normal_dir
chmod 6700 $watch_normal_dir
chown rtorrent $watch_normal_dir
chgrp www-data $watch_normal_dir
# TODO: Any ID/permission changes?

mkdir -p $rtorrent_log_dir
chmod 755 $rtorrent_log_dir
chown rtorrent $rtorrent_log_dir
# Fix further permissions
chown -R rtorrent $rtorrent_log_dir # (yes, this is redundant, I know.)
chgrp rtorrent $rtorrent_log_dir/* || true

mkdir -p $rutorrent_data_dir \
    $rutorrent_settings_dir \
    $rutorrent_tmp_dir \
    $rutorrent_torrents_dir \
    $rutorrent_users_dir
chmod -R 6770 $rutorrent_data_dir
chown -R rutorrent $rutorrent_data_dir
chgrp -R rtorrent $rutorrent_data_dir
# Permissions are already fixed with -R.

mkdir -p $rutorrent_log_dir
chmod 755 $rutorrent_log_dir
chown rutorrent $rutorrent_log_dir
# TODO: Any ID/permission changes?

mkdir -p $nginx_log_dir
chmod 755 $nginx_log_dir

# TODO: Consider tightening access to the sockets. These might be useful.

#function create_sock_file () {
#    python -c "import socket as s; sock = s.socket(s.AF_UNIX); sock.bind('$1')" || true
#}
#
#rm $rtorrent_sock $rutorrent_sock || true
#
#create_sock_file $rtorrent_sock
#chmod 0660 $rtorrent_sock
#chown rtorrent $rtorrent_sock
#chgrp rtorrent-socket $rtorrent_sock
#
#create_sock_file $rutorrent_sock
#chmod 0660 $rutorrent_sock
#chown rutorrent $rutorrent_sock
#chgrp www-data $rutorrent_sock

###############################################################################
#
#  RTORRENT CONFIGURATION FILE
# 
#  Watch https://github.com/rakshasa/rtorrent/wiki/CONFIG-Template for possible
#  configuration options.
#
###############################################################################
cat <<EOF > $rtorrent_inst_file

# Log file manifest variables
method.insert = cfg.logfile, private|const|string, (cat, "$rtorrent_log_dir", "rtorrent-", (system.time), ".log")
method.insert = cfg.execlogfile, private|const|string, (cat, "$rtorrent_log_dir", "execute.log")
method.insert = cfg.xmlrpclogfile, private|const|string, (cat, "$rtorrent_log_dir", "xmlrpc.log")

system.cwd.set = "$instance_dir"
system.umask.set = 0033

###########
# Logging #
###########

print         = (cat, "Logging to ", (cfg.logfile))
log.open_file = "log", (cfg.logfile)

# Each 'log.add_output' adds to the scope of a named log file.
# The scope is specified in the format <group>_<level>.
#    Levels = critical error warn notice info debug
#    Groups = connection_* dht_* peer_* rpc_* storage_* thread_* tracker_* torrent_*
# Example:
#    log.add_output = "tracker_debug", "log"

log.add_output   = "info", "log"

log.execute      = (cfg.execlogfile)
log.xmlrpc       = (cfg.xmlrpclogfile)

#########################
# Other Config Commands #
#########################

session.path.set      = "$session_dir"
directory.default.set = "$download_dir"

# Write PID file
execute.nothrow       = bash, -c, (cat, "echo >", $pid_file, " ", (system.pid))

# Watch directory load scheduling ('.torrent' files are loaded in every 10 seconds.)
schedule2 = watch_start,  10, 10, ((load.start,  (cat, "$watch_start_dir",  "*.torrent")))
schedule2 = watch_normal, 11, 10, ((load.normal, (cat, "$watch_normal_dir", "*.torrent")))

# Listening port for incoming peer traffic
network.port_range.set = $torrent_listening_port-$torrent_listening_port
network.port_random.set = no

# Tracker-less torrent and UDP tracker support
# (Conservative settings suitable for private trackers.)
dht.mode.set = disable
protocol.pex.set = no
trackers.use_udp.set = no

# Peer settings
# TODO: These settings are small, which is more suitable for testing my raspberry pi.
#       Make them bigger when I get better hardware!
throttle.max_uploads.global.set   = 40
throttle.max_downloads.global.set = 40

throttle.max_uploads.set   = 20
throttle.max_downloads.set = 20

throttle.min_peers.normal.set = 19
throttle.max_peers.normal.set = 20
throttle.min_peers.seed.set   = 19
throttle.max_peers.seed.set   = 20

trackers.numwant.set = 20

protocol.encryption.set = allow_incoming,try_outgoing,enable_retry

# Limits for file handle resources, this is optimized for
# an 'ulimit' of 1024 (a common default). You MUST leave
# a ceiling of handles reserved for rTorrent's internal needs!
# TODO: Further optimize later.
network.http.max_open.set = 50
network.max_open_files.set = 600
network.max_open_sockets.set = 300

# Memory resource usage (increase if you have a large number of items loaded,
# and/or the available resources to spend)
# TODO: Further optimize later.
pieces.memory.max.set = 1024M
network.xmlrpc.size_limit.set = 4M

# Other operational settings
encoding.add = utf8
network.http.dns_cache_timeout.set = 25
##network.http.capath.set = "/etc/ssl/certs"
##network.http.ssl_verify_peer.set = 0
##network.http.ssl_verify_host.set = 0
##pieces.hash.on_completion.set = no
##keys.layout.set = qwerty

##view.sort_current = seeding, greater=d.ratio=

# TODO: What does this do?
schedule2 = monitor_diskspace, 15, 60, ((close_low_diskspace, 1000M))

# Some additional values and commands
method.insert = system.startup_time, value|const, (system.time)
method.insert = d.data_path, simple,\
    "if=(d.is_multi_file),\
        (cat, (d.directory), /),\
        (cat, (d.directory), /, (d.name))"
method.insert = d.session_file, simple, "cat=(session.path), (d.hash), .torrent"

# SCGI
execute.nothrow = rm,$rtorrent_sock
network.scgi.open_local = $rtorrent_sock
schedule = socket_chmod,0,0,"execute=chmod,0660,$rtorrent_sock"
schedule = socket_chgrp,0,0,"execute=chgrp,rtorrent-socket,$rtorrent_sock"
EOF

###############################################################################
#
#  NGINX INCLUDE FILE
#
###############################################################################
cat <<EOF > $nginx_inst_file
location $rutorrent_url {
    access_log $nginx_access_log;
    error_log $nginx_error_log info;

    location ~ .php$ {
		fastcgi_param CFG_INSTANCE_DIR "$instance_dir";
		fastcgi_param CFG_XMLRPC_MOUNTPOINT "$rpc_mountpoint";

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
    error_log $nginx_rpc2_error_log info;
    include /etc/nginx/scgi_params;
    scgi_pass unix:$rtorrent_sock;
}
EOF

###############################################################################
#
#  PHP POOL.D FILE
#
###############################################################################
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

cat <<EOF > $run_sh
#!/usr/bin/env bash

#if [[ "$EUID" == 0 ]]; then
#    echo "User ID detected as 0 (i.e. 'root')."
#    echo "Please don't run as root."
#    echo "Exiting."
#    exit 1
#fi
if [[ \`whoami\` == 'root' ]]; then
    echo "Username detected as 'root'."
    echo "Please don't run as root."
    echo "Exiting."
    exit 1
fi

rtorrent -n -o import=$rtorrent_inst_file
EOF
chgrp rtorrent $run_sh
chmod g+x $run_sh

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
systemctl enable nginx php7.3-fpm
systemctl restart nginx php7.3-fpm
---
(Service names may differ. Check 'systemctl list-unit-files' if necessary.)
EOF

