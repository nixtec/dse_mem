# Makefile for forwarder [ip-helper simulation of cisco]
# You need to change only inside 'CUSTOMIZATION {START|END}' sections
CC		:= gcc
EXTRAFLAGS	:=
CFLAGS		:= -Wall -O3 $(EXTRAFLAGS)
DCFLAGS		:= -g -Wall -D__DEBUG__ $(EXTRAFLAGS)
DISTFILES	:= dsecommon.h forwarder.c receiver.c sender.c
DISTFILES	+= Makefile scripts.make buildrc.sh postconf.sh README
PROJECT_NAME	:= forwarder
PROJECT_VERSION	:= 1.0
DISTDIR		:= $(PROJECT_NAME)-$(PROJECT_VERSION)
ARCHIVE		:= $(DISTDIR).tar.gz

#
# CUSTOMIZATION START
#
# for release
#
# pattern to be matched for updating list
IFACE		:= ppp
# the program will be run as the following user for safety
RUNUSR		:= forward
# network information
# Just set the MEM variable
DSE_MEM		:= 0
NETWORK		:= 150.1.$(DSE_MEM).0
MASK		:= 16

#
# for testing
#
#IFACE		:= eth
#RUNUSR		:= ayub
#MEM		:= 0
#NETWORK		:= 10.1.$(MEM).0
#MASK		:= 16
#
# CUSTOMIZATION END
#

# base directory for forwarder
BASEDIR		:= /var/dse
VARDIR		:= $(BASEDIR)
BINDIR		:= $(VARDIR)/bin
RCDIR		:= $(VARDIR)/rc
CFGDIR		:= $(VARDIR)/cfg
LOGDIR		:= $(VARDIR)/log
IFCFG		:= $(CFGDIR)/iface.cfg

# runtime interface information
IFINFOFILE	:= $(CFGDIR)/ifinfo.cfg
# which user the program should run as '/etc/rc.local' will use it
USRCFG		:= $(CFGDIR)/user.cfg


SUBNET		:= $(NETWORK)/$(MASK)
# which address should the program bind to [broadcast address of the subnet]
BINDADDR	:= $(shell ipcalc -b $(SUBNET) | cut -d '=' -f 2)
ADDRCFG		:= $(CFGDIR)/bindaddr.cfg

BINDPORT	:= 6000
PEERPORT	:= 7860
CONFIG_H	:= config.h

# following ports will be forwarded
# multiple ports not usable in 'forwarder.work.win' directory
# 6000 => tesa client
# 445  => microsoft-ds
# 137  => netbios-ns
# 138  => netbios-dgm
PORTS		:= 6000
PORTSCFG	:= $(CFGDIR)/ports.cfg

# information about executable file
EXENAME		:= forwarder
EXEPATH		:= $(BINDIR)/$(EXENAME)
EXECFG		:= $(CFGDIR)/exe.cfg

# /etc/init.d/ entry
INITSCRIPT	:= /etc/init.d/$(EXENAME)

EXT		:= .sh
FORWARDER_RC	:= forwarder$(EXT)
UPDIFLIST_RC	:= update-iflist$(EXT)
IPUP_RC		:= ip-up$(EXT)
IPDOWN_RC	:= ip-down$(EXT)
LOCAL_RC	:= local$(EXT)
FIREWALL_RC	:= firewall$(EXT)

# files to be installed in $(BINDIR)
BINFILES	:= $(EXENAME)
# files to be installed in $(VARDIR)
RCFILES		:= $(strip $(FORWARDER_RC) $(UPDIFLIST_RC) \
			$(IPUP_RC) $(IPDOWN_RC) \
			$(LOCAL_RC) $(FIREWALL_RC))


# build targets
TARGETS		:= forwarder sender receiver forwarder.debug
OTHERS		:= config.h

ENVFILE		:= env.source
LOCKFILE	:= /var/lock/subsys/forwarder

# NOTE: if you introduce/modify new variables, update the 'writenv' target
# in scripts.make


all: $(TARGETS) $(OTHERS) $(RCFILES)

.PHONY: clean install uninstall config dist

# all global environment variables should be defined above this line
include scripts.make

config.h: Makefile
	make config

config:
	@echo -n "Creating $(CONFIG_H) ..."
	@echo "/* generated automatically by 'make config', DONT edit */" > \
	$(CONFIG_H)
	@echo "#ifndef _CONFIG_H" >> $(CONFIG_H)
	@echo "#define _CONFIG_H" >> $(CONFIG_H)
	@echo "" >> $(CONFIG_H)
	@echo "#define BINDADDR \"$(BINDADDR)\"" >> $(CONFIG_H)
	@echo "#define BINDPORT $(BINDPORT)" >> $(CONFIG_H)
	@echo "#define PEERPORT $(PEERPORT)" >> $(CONFIG_H)
	@echo "#define IFINFOFILE \"$(IFINFOFILE)\"" >> $(CONFIG_H)
	@echo "" >> $(CONFIG_H)
	@echo "#endif" >> $(CONFIG_H)
	@echo "DONE"


forwarder: forwarder.c dsecommon.h config.h
	$(CC) $(CFLAGS) -o forwarder forwarder.c
	strip forwarder

forwarder.debug: forwarder.c dsecommon.h config.h
	$(CC) $(DCFLAGS) -o forwarder.debug forwarder.c

sender: sender.c dsecommon.h config.h
	$(CC) $(CFLAGS) -o sender sender.c

receiver: receiver.c dsecommon.h config.h
	$(CC) $(CFLAGS) -o receiver receiver.c

# NOTE: $(RUNUSER) user must exist
# you must be 'root' to run the following target
# if $(RUNUSR) does not exist, install will fail. creat user manually first
# also 'forwarder' is being 'setuid' root [however it will call setuid()] later
install: forwarder
	@echo "Checking if $(RUNUSR) exists..."
	id -un $(RUNUSR)
	mkdir -p $(BASEDIR)
	mkdir -p $(VARDIR)
	mkdir -p $(BINDIR)
	mkdir -p $(CFGDIR)
	mkdir -p $(RCDIR)
	mkdir -p $(LOGDIR)
	install -m 755 $(BINFILES) $(BINDIR)
	chmod u+s $(EXEPATH)
	install -m 755 $(RCFILES) $(RCDIR)
	-ln -s $(RCDIR)/$(FORWARDER_RC) $(INITSCRIPT)
	echo $(RUNUSR) > $(USRCFG)
	chmod 644 $(USRCFG)
	echo $(PORTS) > $(PORTSCFG)
	chmod 644 $(PORTSCFG)
	echo $(EXEPATH) > $(EXECFG)
	chmod 644 $(EXECFG)
	echo $(IFACE) > $(IFCFG)
	echo $(BINDADDR) > $(ADDRCFG)
	install -m 644 $(ENVFILE) $(CFGDIR)
	chown -R $(RUNUSR) $(CFGDIR) $(LOGDIR)
	rm -f $(VARDIR)/uninstall.log
	echo "INSTALLED at `date`" > $(VARDIR)/install.log
	@echo -n "Performing post-install configuration ..."
	@ENVFILE=$(ENVFILE) ./postconf.sh install
	@echo "DONE"
	@echo ""
	@echo "^^^^^ INSTALL COMPLETE ^^^^^"
	@echo ""

# i am not removing the '/var/dse' directory because it may contain other
# necessary files
# you must be 'root' to run the following target
uninstall:
	$(RCDIR)/$(FORWARDER_RC) stop
	rm -f $(addprefix $(BINDIR)/,$(BINFILES))
	rm -f $(INITSCRIPT)
	rm -f $(addprefix $(RCDIR)/,$(RCFILES))
	rm -f $(VARDIR)/install.log
	echo "UNINSTALLED at `date`" > $(VARDIR)/uninstall.log
	@echo -n "Performing post-uninstall tasks ..."
	@ENVFILE=$(ENVFILE) ./postconf.sh uninstall
	@echo "DONE"
	@echo ""
	@echo "^^^^^ UNINSTALL COMPLETE ^^^^^"
	@echo ""

dist: $(DISTFILES)
	mkdir -p $(DISTDIR)
	cp $(DISTFILES) $(DISTDIR)
	tar -czf $(ARCHIVE) $(DISTDIR)
	rm -rf $(DISTDIR)


clean:
	rm -f *.o $(TARGETS) $(OTHERS) $(RCFILES)
