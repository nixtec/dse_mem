#!/bin/sh

# postconf.sh
# post-[un]install configuration script
# following works will be done

ENVNAME=${ENVFILE:-env.source}
source $ENVNAME

# note that this function doesn't check previous entry
# so you must call 'remove_ip_up_local' first
function add_ip_up_local() {
local FILENAME="/etc/ppp/ip-up.local"

if [ ! -f $FILENAME ] ; then
cat << EOCAT > $FILENAME
#!/bin/sh

EOCAT
fi

# name=XXX entry is for easy recognizing my entry for 'ed' editor
cat << EOCAT >> $FILENAME
name=$EXENAME ${RCDIR}/${IPUP_RC}
EOCAT
chmod +x $FILENAME
return $?
}

function remove_ip_up_local() {
local FILENAME="/etc/ppp/ip-up.local"

if [ ! -f $FILENAME ] ; then
  return 0
fi
ed << EOD $FILENAME
%g/${IPUP_RC}/d
w
q
EOD
return $?
}

function add_ip_down_local() {
local FILENAME="/etc/ppp/ip-down.local"

if [ ! -f $FILENAME ] ; then
cat << EOCAT > $FILENAME
#!/bin/sh

EOCAT
fi

# name=XXX entry is for easy recognizing my entry for 'ed' editor
cat << EOCAT >> $FILENAME
name=$EXENAME ${RCDIR}/${IPDOWN_RC}
EOCAT
chmod +x $FILENAME
return $?
}

function remove_ip_down_local() {
local FILENAME="/etc/ppp/ip-down.local"

if [ ! -f $FILENAME ] ; then
  return 0
fi
ed -s << EOD $FILENAME
%g/${IPDOWN_RC}/d
w
q
EOD
return $?
}

function add_rc_local() {
FILENAME="/etc/rc.local"

if [ ! -f $FILENAME ] ; then
cat << EOCAT > $FILENAME
#!/bin/sh

EOCAT
fi

# name=XXX entry is for easy recognizing my entry for 'ed' editor
cat << EOCAT >> $FILENAME
name=$EXENAME ${RCDIR}/${LOCAL_RC}
EOCAT
chmod +x $FILENAME
return $?
}

function remove_rc_local() {
local FILENAME="/etc/rc.local"

if [ ! -f $FILENAME ] ; then
  return 0
fi
ed -s << EOD $FILENAME
%g/${LOCAL_RC}/d
w
q
EOD
return $?
}

function remove_all_entry() {
local FILES="/etc/ppp/ip-up.local /etc/ppp/ip-down.local /etc/rc.local"
for file in $FILES ; do
  if [ ! -f $file ] ; then
    continue
  fi
  ed -s << EOD $file
  %g/^name=${EXENAME}/d
  w
  q
EOD
done
return $?
}

if [ $# -lt 1 ] ; then
  echo "Usage: $0 {install|uninstall}"
  exit 1
fi

if [ "$1" = "install" ] ; then
  eval remove_all_entry
  eval add_ip_up_local
  eval add_ip_down_local
  eval add_rc_local
elif [ "$1" = "uninstall" ] ; then
  remove_all_entry
else
  echo "Usage: $0 {install|uninstall}"
  exit 1
fi
