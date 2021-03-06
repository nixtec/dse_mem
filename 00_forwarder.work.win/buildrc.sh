#!/bin/sh

# buildrc.sh

ENVNAME=${ENVFILE:-env.source}
#echo "Using environment from $ENVNAME"
source $ENVNAME

function forwarder() {
local FILENAME="$FORWARDER_RC"
cat << EOF > $FILENAME
#!/bin/sh
#
# $FILENAME
# automatically generated by 'make rcscripts'. DO NOT edit
#
# environment variables starts here
`cat $ENVNAME`
# environment variables ends here

# function definition starts here
function start() {
  PID=\`/sbin/pidof \$EXEPATH\`
  if [ "\$PID" != "" ] ; then
    echo "\$EXENAME already running. Try stopping first"
    return 1
  fi
  echo "Starting \$EXENAME ..."
  for port in \`cat \$PORTSCFG\` ; do
    echo "+++Listening on \$BINDADDR:\$port"
    \$EXEPATH \$BINDADDR \$port &> "\${LOGDIR}/log.\${EXENAME}.\${port}"&
  done
  RETVAL=\$?
  touch \$LOCKFILE &> /dev/null
  return \$RETVAL
}

function update() {
  echo -n "Updating interface list [sending HUP to \$EXENAME] ..."
  PID=\`/sbin/pidof \$EXEPATH\`
  if [ "\$PID" = "" ] ; then
    echo "\$EXENAME is not running"
    return 1
  fi
  kill -HUP \$PID
  return \$?
}

function stop() {
  echo -n "Stopping \$EXENAME ..."
  PID=\`/sbin/pidof \$EXEPATH\`
  if [ "\$PID" = "" ] ; then
    echo "\$EXENAME not running..."
    return 0
  fi
#  echo "Killing [\$PID] ..."
  kill -INT \$PID
  RETVAL=\$?
  if [ -f \$LOCKFILE ] ; then
    rm -f \$LOCKFILE &> /dev/null
  fi
  return \$RETVAL
}

function restart() {
  eval stop
  eval start
  return \$?
}

function status() {
  echo "Status ..."
  PID=\`/sbin/pidof \$EXEPATH\`
  if [ "\$PID" = "" ] ; then
    echo "\$EXENAME is not running"
  else
    echo "\$EXENAME is running... pid=[\$PID]"
    ps up \$PID
  fi
  return \$?
}

function iflist() {
  echo "List of interfaces to forward packets to"
  if [ -f \$IFINFOFILE ] ; then
    cat \$IFINFOFILE
  fi
  return \$?
}

if [ \$# -lt 1 ] ; then
  echo "Usage: \$0 {start|stop|update|restart|status|iflist}"
  exit 1
fi

eval \$1

if [ \$? -eq 0 ] ; then
  echo "[  OK  ]"
else
  echo "[FAILED]"
fi
EOF
return $?
}

function update_iflist() {
local FILENAME="$UPDIFLIST_RC"
cat << EOF > $FILENAME
#!/bin/sh
#
# $FILENAME
# automatically generated by 'make rcscripts'. DO NOT edit
#
# environment variables starts here
`cat $ENVNAME`
# environment variables ends here


ptrn="\`cat \$IFCFG\`"
NLINES=\`ip address show | grep "scope global \$ptrn" | wc -l\`
echo \$NLINES > \$IFINFOFILE
if [ \$NLINES -lt 1 ] ; then
  exit 0
fi

if [ "\$ptrn" = "ppp" ] ; then
  ip address show | grep "scope global \$ptrn" | awk '{ \\
    gsub(/\\/.*/, "", \$4);
    print \$7, \$4; }' >> \$IFINFOFILE
elif [ "\$ptrn" = "eth" ] ; then
  ip address show | grep "scope global \$ptrn" | awk '{ \\
    gsub(/\\/.*/, "", \$2);
    print \$7, \$2; }' >> \$IFINFOFILE
fi
EOF
return $?
}

function ip_up() {
local FILENAME="$IPUP_RC"
cat << EOF > $FILENAME
#!/bin/sh
#
# $FILENAME
# automatically generated by 'make rcscripts'. DO NOT edit
#
# environment variables starts here
`cat $ENVNAME`
# environment variables ends here


\$RCDIR/\$UPDIFLIST_RC
chmod 644 \$IFINFOFILE
\$RCDIR/\$FORWARDER_RC update
echo "Logged in at  \`date\`" >> \$LOGDIR/login.log
EOF
return $?
}

function ip_down() {
local FILENAME="$IPDOWN_RC"
cat << EOF > $FILENAME
#!/bin/sh
#
# $FILENAME
# automatically generated by 'make rcscripts'. DO NOT edit
#
# environment variables starts here
`cat $ENVNAME`
# environment variables ends here


\$RCDIR/\$UPDIFLIST_RC
chmod 644 \$IFINFOFILE
\$RCDIR/\$FORWARDER_RC update
echo "Logged out at  \`date\`" >> \$LOGDIR/login.log
EOF
return $?
}

function localrc() {
local FILENAME="$LOCAL_RC"
cat << EOF > $FILENAME
#!/bin/sh
#
# $FILENAME
# automatically generated by 'make rcscripts'. DO NOT edit
#
# environment variables starts here
`cat $ENVNAME`
# environment variables ends here

# set up a strict firewall
$RCDIR/$FIREWALL_RC

# there must be a user named \$USR [able to login to system]
USR=\`cat \$USRCFG\`

#chown \$USR \$BASEDIR
chown \$USR \$LOGDIR
#chmod 644 \$LOGDIR/log.*
# remove old log files
rm -f \$LOGDIR/log.*
su \$USR -c '$RCDIR/$FORWARDER_RC start'
touch \$LOCKFILE
# clear previous log information
[ -f \$LOGDIR/login.log ] && echo "" >> \$LOGDIR/login.log
EOF
return $?
}

function firewall() {
local FILENAME="$FIREWALL_RC"
cat << EOF > $FILENAME
#!/bin/sh

# $FILENAME
# firewall script for DSE [subnet:$SUBNET]
# Written by Ayub <mrayub@gmail.com>
# Generated automatically by buildrc.sh, do NOT edit!!!

# follow strict path
PATH="/bin:/sbin:/usr/bin:/usr/sbin"

ADDR="$SUBNET"
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
iptables -A INPUT -s \$LOADDR -d \$LOADDR -j ACCEPT
iptables -A OUTPUT -s \$LOADDR -d \$LOADDR -j ACCEPT

# we consider only our network. No packets will go outside the sub-network
iptables -A INPUT -s \$ADDR -d \$ADDR -j ACCEPT
iptables -A OUTPUT -s \$ADDR -d \$ADDR -j ACCEPT
iptables -A FORWARD -s \$ADDR -d \$ADDR -j ACCEPT
EOF
}

if [ $# -lt 1 ] ; then
  exit 1
fi

eval $1
