all: install clean

compile:
	x86_64-linux-gnu-gcc -DENABLE_NLS=1 -DHAVE_GETTEXT=1 -DHAVE_DCGETTEXT=1 -DHAVE_CATGETS=1 -DENABLE_NLS=1 \
	-DHAVE_LC_MESSAGES=1 -DHAVE_STPCPY=1 -I.   -D_FORTIFY_SOURCE=2 \
	-DPWRAPPERDRUCKQUOTASPERLAPP=\"/usr/lib/schulkonsole/bin/wrapper-druckquotas.pl\" \
	-Wall -g -O2 -DWWWUID=33  -DMINUID=500 -MT wrapper-druckquotas.o -MD -MP \
	-c -o wrapper-druckquotas.o wrapper-druckquotas.c

link: compile
	x86_64-linux-gnu-gcc -DWRAPPERDRUCKQUOTASPERLAPP=\"/usr/lib/schulkonsole/bin/wrapper-druckquotas.pl\" \
	 -Wall -g -O2 -DWWWUID=33     -DMINUID=500     -Wl,-Bsymbolic-functions -Wl,-z,relro \
	-o wrapper-druckquotas wrapper-druckquotas.o

install: link
	chmod -f 4755 wrapper-druckquotas
	mkdir -p ../bin
	mv wrapper-druckquotas ../bin
	cp wrapper-druckquotas.pl ../bin

clean:
	rm -f wrapper-druckquotas.o wrapper-druckquotas.d

dist-clean: clean
	rm -f wrapper-druckquotas
	rm -rf ../bin
