#!/bin/bash

cat uvsphere.obj | perl filter.pl | ./parser > uvsphere.json

