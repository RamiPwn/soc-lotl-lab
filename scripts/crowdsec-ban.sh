#!/usr/bin/env bash

# Manual containment used in the lab.
# Replace the IP address if Kali uses another address.

sudo cscli decisions add \
  --ip 192.168.1.30 \
  --duration 1h \
  --reason "LOTL lab containment"
