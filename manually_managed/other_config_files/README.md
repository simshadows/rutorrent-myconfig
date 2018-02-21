# Other Config Files

These files are to be symlinked from their original locations.

## Security

These must be only writable by root.

Additionally, care must also be taken when dealing with remotes, in case the remote repository is ever hijacked.

## How to link

Create the soft links below. Link targets are the corresponding files/directories in `manually_managed/other_config_files/`.

```
/etc/nginx/nginx.conf
/etc/nginx/scgi_params
/etc/php/
/home/sys-rtorrent/.rtorrent.rc
```
