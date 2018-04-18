#!/bin/sh

addr=`grep kPitchDarkBinaryAddress src/constants.a | cut -d"$" -f2`
sed -i -e "s/kPitchDarkBinaryAddress/$addr/g" "$1"
