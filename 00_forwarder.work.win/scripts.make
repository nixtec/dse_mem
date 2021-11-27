# scripts.make [Makefile]
# builds following scripts
# vim command: :set filetype=make
# forwarder.sh		[/var/dse/rc/]
# ip-up.sh		[/var/dse/rc/]
# ip-down.sh		[/var/dse/rc/]
# local.sh		[/var/dse/rc/]
# update-iflist.sh	[/var/dse/rc/]
#
# this script MUST have to be called by the Makefile in this directory
# otherwise variables will not be available

.PHONY: writenv bulidrc-forwarder buildrc-update-iflist buildrc-localrc \
	buildrc-ip-up buildrc-ip-down buildrc-firewall rcscripts

rcscripts: buildrc-forwarder buildrc-update-iflist buildrc-localrc \
		buildrc-ip-up buildrc-ip-down

writenv:
	@echo -n "Writing variables to $(ENVFILE) ..."
	@echo "BASEDIR=\"$(BASEDIR)\"" > $(ENVFILE)
	@echo "VARDIR=\"$(VARDIR)\"" >> $(ENVFILE)
	@echo "BINDIR=\"$(BINDIR)\"" >> $(ENVFILE)
	@echo "RCDIR=\"$(RCDIR)\"" >> $(ENVFILE)
	@echo "CFGDIR=\"$(CFGDIR)\"" >> $(ENVFILE)
	@echo "LOGDIR=\"$(LOGDIR)\"" >> $(ENVFILE)
	@echo "IFACE=\"$(IFACE)\"" >> $(ENVFILE)
	@echo "IFCFG=\"$(IFCFG)\"" >> $(ENVFILE)
	@echo "IFINFOFILE=\"$(IFINFOFILE)\"" >> $(ENVFILE)
	@echo "RUNUSR=\"$(RUNUSR)\"" >> $(ENVFILE)
	@echo "USRCFG=\"$(USRCFG)\"" >> $(ENVFILE)
	@echo "NETWORK=\"$(NETWORK)\"" >> $(ENVFILE)
	@echo "MASK=\"$(MASK)\"" >> $(ENVFILE)
	@echo "SUBNET=\"$(SUBNET)\"" >> $(ENVFILE)
	@echo "BINDADDR=\"$(BINDADDR)\"" >> $(ENVFILE)
	@echo "BINDPORT=\"$(BINDPORT)\"" >> $(ENVFILE)
	@echo "PEERPORT=\"$(PEERPORT)\"" >> $(ENVFILE)
	@echo "CONFIG_H=\"$(CONFIG_H)\"" >> $(ENVFILE)
	@echo "PORTS=\"$(PORTS)\"" >> $(ENVFILE)
	@echo "PORTSCFG=\"$(PORTSCFG)\"" >> $(ENVFILE)
	@echo "EXENAME=\"$(EXENAME)\"" >> $(ENVFILE)
	@echo "EXEPATH=\"$(EXEPATH)\"" >> $(ENVFILE)
	@echo "EXECFG=\"$(EXECFG)\"" >> $(ENVFILE)
	@echo "INITSCRIPT=\"$(INITSCRIPT)\"" >> $(ENVFILE)
	@echo "EXT=\"$(EXT)\"" >> $(ENVFILE)
	@echo "FORWARDER_RC=\"$(FORWARDER_RC)\"" >> $(ENVFILE)
	@echo "UPDIFLIST_RC=\"$(UPDIFLIST_RC)\"" >> $(ENVFILE)
	@echo "IPUP_RC=\"$(IPUP_RC)\"" >> $(ENVFILE)
	@echo "IPDOWN_RC=\"$(IPDOWN_RC)\"" >> $(ENVFILE)
	@echo "LOCAL_RC=\"$(LOCAL_RC)\"" >> $(ENVFILE)
	@echo "FIREWALL_RC=\"$(FIREWALL_RC)\"" >> $(ENVFILE)
	@echo "BINFILES=\"$(BINFILES)\"" >> $(ENVFILE)
	@echo "RCFILES=\"$(RCFILES)\"" >> $(ENVFILE)
	@echo "TARGETS=\"$(TARGETS)\"" >> $(ENVFILE)
	@echo "OTHERS=\"$(OTHERS)\"" >> $(ENVFILE)
	@echo "ENVFILE=\"$(ENVFILE)\"" >> $(ENVFILE)
	@echo "LOCKFILE=\"$(LOCKFILE)\"" >> $(ENVFILE)
	@echo "DONE"

$(FORWARDER_RC): buildrc-forwarder
$(UPDIFLIST_RC): buildrc-update-iflist
$(IPUP_RC): buildrc-ip-up
$(IPDOWN_RC): buildrc-ip-down
$(LOCAL_RC): buildrc-localrc
$(FIREWALL_RC): buildrc-firewall

buildrc-forwarder: writenv
	@echo -n "Creating $(FORWARDER_RC) ..."
	@ENVFILE=$(ENVFILE) ./buildrc.sh forwarder
	@echo "DONE"

buildrc-update-iflist: writenv
	@echo -n "Creating $(UPDIFLIST_RC) ..."
	@ENVFILE=$(ENVFILE) ./buildrc.sh update_iflist
	@echo "DONE"

buildrc-ip-up: writenv
	@echo -n "Creating $(IPUP_RC) ..."
	@ENVFILE=$(ENVFILE) ./buildrc.sh ip_up
	@echo "DONE"

buildrc-ip-down: writenv
	@echo -n "Creating $(IPDOWN_RC) ..."
	@ENVFILE=$(ENVFILE) ./buildrc.sh ip_down
	@echo "DONE"

buildrc-localrc: writenv
	@echo -n "Creating $(LOCAL_RC) ..."
	@ENVFILE=$(ENVFILE) ./buildrc.sh localrc
	@echo "DONE"

buildrc-firewall:
	@echo -n "Creating $(FIREWALL_RC) ..."
	@ENVFILE=$(ENVFILE) ./buildrc.sh firewall
	@echo "DONE"
