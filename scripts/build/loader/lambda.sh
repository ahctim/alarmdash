#!/usr/bin/env bash

cd cmd/loader

GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o ../../bin/loader ./

cd ../../

zip -j loader.zip bin/loader