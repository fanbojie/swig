#!/usr/bin/env sh

rm -rf *.java gcc_wrap.*
swig -c++ -java -package com.webex.eureka.arm.wrapper -outdir ./ -I./ gcc.i

