#!/bin/sh

# firewall.sh
# firewall script for DSE [subnet:150.1.93.0/16]
# Written by Ayub <mrayub@gmail.com>
# Generated automatically by buildrc.sh, do NOT edit!!!

# follow strict path
PATH="/bin:/sbin:/usr/bin:/usr/sbin"

ADDR="150.1.93.0/16"
LOADDR="127.0.0.0/8"

# remove all existing rules belonging to this filter (flush)
iptables -F
iptables -F -t nat

# remove any existing user-defined chains
iptables -X

# set the default policy of the filter to deny
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# 255.255.255.224 is used as subnet mask for MEM093 network [/27]
# unlimited traffic on the loopback interface
iptables -A INPUT -s $LOADDR -d $LOADDR -j ACCEPT
iptables -A OUTPUT -s $LOADDR -d $LOADDR -j ACCEPT

# we consider only our network. No packets will go outside the sub-network
iptables -A INPUT -s $ADDR -d $ADDR -j ACCEPT
iptables -A OUTPUT -s $ADDR -d $ADDR -j ACCEPT
iptables -A FORWARD -s $ADDR -d $ADDR -j ACCEPT
