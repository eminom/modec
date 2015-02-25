#!/bin/bash

cat input/uvsphere.obj | perl filter.pl | ./parser > uvsphere.json
cat input/uvsphere8.obj | perl filter.pl | ./parser > uvsphere8.json

