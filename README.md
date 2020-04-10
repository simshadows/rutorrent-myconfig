# simshadows/rutorrent-myconfig

This repository is a copy of the [original rutorrent repository](https://github.com/Novik/ruTorrent), with my custom configuration changes.

I only merge in official releases, or fixes.

## Changes compared to upstream

Most of my files are contained in `/myconfig/`.

Some other important changes are:

- `/conf/config.php`
- Plugins are removed/added as needed from `/plugins/`.
	- Removed plugins are kept in `/myconfig/removed-plugins/`.

## Absolute Filepaths

I'm currently using absolute filepaths, but I'll be looking into using relative filepaths instead.

If an instance folder must be moved to a different location, you'll need to run my instance migration script `migrate-instance.py`, and run `setup-instance.sh` again:

```
# chown -R simshadows INSTANCEDIR
# sudo -u simshadows bash
$ ./migrate-instance.py INSTANCEDIR OLDINSTANCEDIR
$ exit
# ./setup-instance.sh INSTANCEDIR INSTANCENAME PORT
```

Do note that I ran `migrate-instance.py` in a safer non-root user. I just prefer to do it this way if I'm using dependencies that I don't necessarily trust. In this case, I'm using a bencode library.

Once you're done running `migrate-instance.py`, the `setup-instance.sh` will redo all file permissions.

## TODO

Things I want done:

- Isolate all my custom files to `/myconfig/` somehow.
	- This reduces the pain of reconciling merge conflicts.
- Improve the usability of the basic scripts
	- Particularly solve the challenges of user checking and privilege escalation.

# ruTorrent

ruTorrent is a front-end for the popular Bittorrent client [rtorrent](http://rakshasa.github.io/rtorrent).

This project is released under the GPLv3 license, for more details, take a look at the LICENSE.md file in the source.

## Main features

* Lightweight server side, so it can be installed on old and low-end servers and even on some SOHO routers
* Extensible - there are several plugins and everybody can create their own one
* Nice look ;) 

## Screenshots

[![](https://github.com/Novik/ruTorrent/wiki/images/scr1_small.jpg)](https://github.com/Novik/ruTorrent/wiki/images/scr1_big.jpg)
[![](https://github.com/Novik/ruTorrent/wiki/images/scr2_small.jpg)](https://github.com/Novik/ruTorrent/wiki/images/scr2_big.jpg)
[![](https://github.com/Novik/ruTorrent/wiki/images/scr3_small.jpg)](https://github.com/Novik/ruTorrent/wiki/images/scr3_big.jpg)

## Download

 * [Development version](https://github.com/Novik/ruTorrent/tarball/master)
 * [Stable version](https://github.com/Novik/ruTorrent/releases)

## Getting started

  * There's no installation routine or compilation necessary. The sources are cloned/unpacked into a directory which is setup as document root of a web server of your choice (for detailed instructions see the [webserver wiki article](https://github.com/Novik/ruTorrent/wiki/WebSERVER)).
  * After setting up the webserver `ruTorrent` itself needs to be configured. Instructions can be found in various articles in the [wiki](https://github.com/Novik/ruTorrent/wiki).
<br/>

<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6GTTAQWCGBMVA">![Donate!](https://www.paypal.com/en_US/i/btn/btn_donateCC_LG.gif)</a>
