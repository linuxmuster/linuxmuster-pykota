PACKAGE = linuxmuster-pk-schulkonsole
VERSION = 0.1.0
SUFFIXES = .po .pot .mo
XGETTEXT = xgettext
MSGMERGE = msgmerge
MSGFMT = msgfmt
INSTALL = install
DESTDIR = ../debian/$(PACKAGE)

# use xgettext.pl for tt files
XGETTEXTTT = xgettext.pl

# these are the supported languages, 
ALL_LINGUAS = de en
POFILES = $(ALL_LINGUAS:=.po)
MSGFILES = $(ALL_LINGUAS:=.mo)

TEMPLATE = $(PACKAGE).pot

libpdpodir = /usr/share/locale

EXTRA_DIST = $(POFILES)

# install
install-locale:
	for l in $(ALL_LINGUAS); do \
	    $(INSTALL) -m 644 -D $(addsuffix .mo,$$l) $(DESTDIR)$(libpdpodir)/$$l/LC_MESSAGES/$(PACKAGE).mo; \
	done

# generate .mo files from the .po files
all-local: clean $(MSGFILES)



# refresh .po files from the template
clean:
	-rm -f -- $(MSGFILES)
	-rm -f -- $(POFILES:=~)
	-rm -f -- $(TEMPLATE)

messages: clean $(POFILES)

# refresh the template from the source code
template: $(TEMPLATE)

$(TEMPLATE): POTFILES.tt.in POTFILES.perl.in
	$(XGETTEXTTT) --plugin tt2 --gnu-gettext --use-gettext-style \
	--output=$(TEMPLATE) --files-from=POTFILES.tt.in
	sed 's/CHARSET/UTF-8/' -i $(TEMPLATE)
	$(XGETTEXT) --join-existing \
	--from-code=UTF-8 --language=Perl --output=$(TEMPLATE) \
	--package-name="linuxmuster-pk-schulkonsole" --package-version=$(VERSION) \
	--copyright-holder='This file is put in the public domain' \
	--msgid-bugs-address=fschuett@gymhim.de \
	--keyword=get --files-from=POTFILES.perl.in

$(POFILES): $(TEMPLATE)
	$(MSGMERGE) -s $@ $< -o $@


%.mo: %.po
	$(MSGFMT) -f -o $@  $<
