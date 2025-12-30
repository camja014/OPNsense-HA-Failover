# OPNsense HA Failover Makefile

PREFIX = /usr/local
ETCDIR = $(PREFIX)/etc
CARPDIR = $(ETCDIR)/rc.syshook.d/carp
SYSHOOKDIR = $(ETCDIR)/rc.syshook.d
RCDIR = $(ETCDIR)/rc.d
RC_CONF = /etc/rc.conf.local

.PHONY: install uninstall check

install:
	@mkdir -p $(CARPDIR) $(SYSHOOKDIR) $(RCDIR)
	@[ -f $(ETCDIR)/ha_failover.conf ] && cp -p $(ETCDIR)/ha_failover.conf $(ETCDIR)/ha_failover.conf.bak || true
	install -m 600 config/ha_failover.conf $(ETCDIR)/
	install -m 755 scripts/validate_ha_config.php $(ETCDIR)/
	install -m 755 scripts/10-failover.php $(CARPDIR)/
	install -m 755 scripts/98-ha_set_routes.php $(SYSHOOKDIR)/
	install -m 755 scripts/99-ha_passive_enforcer.sh $(RCDIR)/
	@grep -qF 'ha_passive_enforcer_enable="YES"' $(RC_CONF) 2>/dev/null || \
		echo 'ha_passive_enforcer_enable="YES"' >> $(RC_CONF)
	@echo "Installed. Edit $(ETCDIR)/ha_failover.conf and run 'make check'"

uninstall:
	@[ -f $(ETCDIR)/ha_failover.conf ] && cp -p $(ETCDIR)/ha_failover.conf $(ETCDIR)/ha_failover.conf.uninstall || true
	rm -f $(ETCDIR)/ha_failover.conf
	rm -f $(ETCDIR)/validate_ha_config.php
	rm -f $(CARPDIR)/10-failover.php
	rm -f $(SYSHOOKDIR)/98-ha_set_routes.php
	rm -f $(RCDIR)/99-ha_passive_enforcer.sh
	@[ -f $(RC_CONF) ] && grep -vF 'ha_passive_enforcer_enable="YES"' $(RC_CONF) > $(RC_CONF).tmp && \
		mv $(RC_CONF).tmp $(RC_CONF) || true
	@echo "Uninstalled. Config backup: $(ETCDIR)/ha_failover.conf.uninstall"

check:
	@php $(ETCDIR)/validate_ha_config.php
