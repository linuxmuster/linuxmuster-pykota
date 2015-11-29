use strict;
use utf8;
use POSIX;
eval {
	require Locale::gettext;
	Locale::gettext->require_version(1.04);
};
if ($@) {
	require Schulkonsole::Gettext;
}
use Schulkonsole::Error::Druckquotas;

package Schulkonsole::DruckquotasError;
require Exporter;
require Schulkonsole::Error;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Schulkonsole::Error Exporter);
@EXPORT_OK = qw(
	new
	what
	errstr
);


use overload
	'""' => \&errstr;


sub _init {
	my $this = shift;
	$this->SUPER::_init(@_);
	$$this{dplugin} = Locale::gettext->domain('linuxmuster-pk-schulkonsole');
	$$this{dplugin}->dir('/usr/share/locale');
}



sub what {
	my $this = shift;
	return $this->{errstr} if $this->{errstr};
	
	SWITCH: {
		$this->{code} == Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_USER and do {
			return $this->{dplugin}->get('Ungültiger Benutzer');
		};
		$this->{code} == Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_ACTION and do {
			return $this->{dplugin}->get('Ungültige Aktion');
		};
		$this->{code} == Schulkonsole::Error::Druckquotas::WRAPPER_WRONG_ACTION and do {
			return $this->{dplugin}->get('Unpassende Aktion');
		};
		$this->{code} == Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_VALUE and do {
			return $this->{dplugin}->get('Ungültiger Wert');
		};
		$this->{code} == Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_USERLIST and do {
			return $this->{dplugin}->get('Ungültige Benutzerliste');
		};
		$this->{code} == Schulkonsole::Error::Druckquotas::WRAPPER_NO_USERS and do {
			return $this->{dplugin}->get('Keine Benutzer vorhanden');
		};
		$this->{code} == Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_PRINTER and do {
			return $this->{dplugin}->get('Ungültiger Drucker');
		};
		$this->{code} == Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_GROUP and do {
			return $this->{dplugin}->get('Ungültige Gruppe');
		};
		$this->{code} == Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_NUMBER and do {
			return $this->{dplugin}->get('Ungültige Zahl');
		};
		$this->{code} == Schulkonsole::Error::Druckquotas::WRAPPER_NO_DBPASSWORD and do {
			return $this->{dplugin}->get('Das Datenbankpassword konnte nicht ermittelt werden');
		};
	};

	return $this->SUPER::what();
}



sub errstr {
	my $this = shift;
	
	return $0
		. ': '
		. $this->what()
		. "\n"
		. ($this->{info} ? ' (' . join(', ', @{ $this->{info} }) . ')' : '')
		. "\n";
}





1;
