#!/bin/bash

cat input/uvsphere.obj | perl filter.pl | ./parser > uvsphere.json

