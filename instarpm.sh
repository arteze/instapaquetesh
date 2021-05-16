#!/bin/sh

rm -r ./tmp
file-roller -e tmp $1 --force
cp -vfr ./tmp/* /
