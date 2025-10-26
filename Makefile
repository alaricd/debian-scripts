SHELL := /bin/bash
PREFIX ?= /usr/local
SBINDIR ?= $(PREFIX)/sbin
SYSTEMD_UNIT_DIR ?= /etc/systemd/system
SYSTEMCTL ?= systemctl
SHELLCHECK ?= shellcheck
SHFMT ?= shfmt
BATS ?= bats

SCRIPT := autoupdate-and-reboot.sh
SERVICE := systemd/autoupdate.service
TIMER := systemd/autoupdate.timer

.PHONY: install uninstall lint test

install: $(SCRIPT) $(SERVICE) $(TIMER)
	install -Dm755 $(SCRIPT) $(DESTDIR)$(SBINDIR)/autoupdate-and-reboot.sh
	install -Dm644 $(SERVICE) $(DESTDIR)$(SYSTEMD_UNIT_DIR)/autoupdate.service
	install -Dm644 $(TIMER) $(DESTDIR)$(SYSTEMD_UNIT_DIR)/autoupdate.timer
	$(SYSTEMCTL) daemon-reload
	$(SYSTEMCTL) enable --now autoupdate.timer
	-$(SYSTEMCTL) disable --now apt-daily-upgrade.timer

uninstall:
	-$(SYSTEMCTL) disable --now autoupdate.timer
	rm -f $(DESTDIR)$(SBINDIR)/autoupdate-and-reboot.sh
	rm -f $(DESTDIR)$(SYSTEMD_UNIT_DIR)/autoupdate.service
	rm -f $(DESTDIR)$(SYSTEMD_UNIT_DIR)/autoupdate.timer
	$(SYSTEMCTL) daemon-reload

lint:
	$(SHELLCHECK) $(SCRIPT)
	$(SHFMT) -d .

test:
	$(BATS) test
