#!/bin/sh
LC_ALL=C
dpkg-query -W -f '${package} ${version} ${architecture}\n' | sort
