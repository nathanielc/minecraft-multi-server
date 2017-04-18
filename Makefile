.DEFAULT = install

PREFIX ?= /

.PHONY: install
install:
	install -D -m0644 src/minecraftd@.service \
		$(PREFIX)/usr/lib/systemd/system/minecraftd@.service
	install -D -m0644 src/minecraftd-backup@.service \
		$(PREFIX)/usr/lib/systemd/system/minecraftd-backup@.service
	install -D -m0644 src/minecraftd-backup@.timer \
		$(PREFIX)/usr/lib/systemd/system/minecraftd-backup@.timer
	install -D -m0644 src/minecraftd-save@.service \
		$(PREFIX)/usr/lib/systemd/system/minecraftd-save@.service
	install -D -m0644 src/minecraftd-save@.timer \
		$(PREFIX)/usr/lib/systemd/system/minecraftd-save@.timer
	install -D -m0755 src/minecraftctl.sh  $(PREFIX)/usr/bin/minecraftctl

.PHONY: uninstall
uninstall:
	rm     $(PREFIX)/usr/lib/systemd/system/minecraftd@.service
	rm     $(PREFIX)/usr/lib/systemd/system/minecraftd-backup@.service
	rm     $(PREFIX)/usr/lib/systemd/system/minecraftd-backup@.timer
	rm     $(PREFIX)/usr/lib/systemd/system/minecraftd-save@.service
	rm     $(PREFIX)/usr/lib/systemd/system/minecraftd-save@.timer
	rm     $(PREFIX)/usr/bin/minecraftctl
