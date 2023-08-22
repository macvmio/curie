#!/bin/sh -e

quick build
quick sign

.build/debug/curie "$@"
