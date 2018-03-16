# simshadows/custom\_rutorrent

This repository is a copy of the original [rutorrent repository](https://github.com/Novik/ruTorrent), with my custom configuration changes.

## Notes-to-self on repo maintenance

It is recommended to have a remote to upstream in order to update rutorrent:

```
git remote add upstream https://github.com/Novik/ruTorrent
```

I only merge to official releases.

## Special files/directories in `mycustom_repo` not present in `master`

`manually_managed/` contains manually managed files that are not part of the rutorrent web application.

`app_data/` contains the web application-specific data (separate from rtorrent). I want to use this and not the existing `share/` directory to make it easier to merge cleanly.

## System Assumptions

* This repository's root directory is: `/usr/share/webapps/rutorrent/`
* **TODO: Other assumptions such as users and rtorrent data locations**

## Initial Setup

Config files are available in `manually_managed/other_config_files/`. It is intended that these files are (correspondingly) linked from the following files/directories:

```
/etc/nginx/nginx.conf
/etc/nginx/scgi_params
/etc/php/
/home/sys-rtorrent/.rtorrent.rc
```

**SECURITY: Make sure these are only writable by root.**

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
 * [Stable version](https://bintray.com/novik65/generic/ruTorrent)

## Getting started

  * There's no installation routine or compilation necessary. The sources are cloned/unpacked into a directory which is setup as document root of a web server of your choice (for detailed instructions see the [webserver wiki article](https://github.com/Novik/ruTorrent/wiki/WebSERVER).
  * After setting up the webserver `ruTorrent` itself needs to be configured. Instructions can be found in various articles in the [wiki](https://github.com/Novik/ruTorrent/wiki).
<br/>

<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6GTTAQWCGBMVA">![Donate!](https://www.paypal.com/en_US/i/btn/btn_donateCC_LG.gif)</a>
