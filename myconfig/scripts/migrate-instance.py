#!/usr/bin/env python3
# -*- coding: ascii -*-

"""
Filename: migrate-instance.py
Author:   contact@simshadows.com

Migrates an instance to a new directory.

Dependency:
    pip install bencode.py
If you're paranoid about the dependency, don't run this as root.
Resursively chown the instance to a safe user first, then run it.
"""

from sys import argv
from os import listdir
from shutil import copytree
import bencode

instance_dir = argv[1]
old_dir = argv[2]

session_dir = instance_dir + "/rtorrent-session"

# Quick backup!
copytree(session_dir, session_dir + "_BACKUP")

# Now, we do the migration!
for filename in listdir(session_dir):
    if filename.endswith(".rtorrent"):
        path = session_dir + "/" + filename
        data = bencode.bread(path)
        data["directory"] = data["directory"].replace(old_dir, instance_dir)
        bencode.bwrite(data, path)

print("done!")

