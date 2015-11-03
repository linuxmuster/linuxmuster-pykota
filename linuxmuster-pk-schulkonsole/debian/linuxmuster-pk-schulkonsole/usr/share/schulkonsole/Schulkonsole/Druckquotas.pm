use strict;
use utf8;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Error;
use Schulkonsole::Config;

package Schulkonsole::Druckquotas;

=head1 NAME
Schulkonsole::Druckquotas - interface to Pykota Druckquotas
=head1 SYNOPSIS
 use Schulkonsole::Druckquotas;
 use Schulkonsole::Session;

=head1 DESCRIPTION

If a wrapper command fails, it usually dies with a Schulkonsole::Error.
The output of the failed command is stored in the Schulkonsole::Error.

25.6.2012

=cut

require Exporter;
use vars qw(%balance $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.2;


@ISA = qw(Exporter);
@EXPORT_OK = qw(
	read_pykota_conf_file
	read_linuxmuster_pykota_conf_file
	get_linuxmuster_pykota_conf
	get_balance
	gwt_balancelist
	set_balance
	reset_balance
	delete_balance
	get_printers
	add_printer
	delete_printer
	charge_printer
	passthrough_printer
	add_standard
	delete_standard
	modify_standard
	set_aktiv
);

#
# Konstanten nach Schulkonsole::Config verschieben
#
my $wrapper = "sudo /usr/lib/schulkonsole/bin/druckquotas.pl";
my $linuxmuster_pykota_conf_filename = "/etc/linuxmuster/pykota.conf";
my $pykota_conf_filename = "/etc/pykota/pykota.conf";


sub set_balance {
	my $id = shift;
	my $password = shift;
	my $balance = shift;
	my @benutzer_array = @_;
	qx($wrapper $id $password balance $balance @benutzer_array);
}

sub reset_balance {
	my $id = shift;
	my $password = shift;
	my $balance = shift;
	my @benutzer_array = @_;
	qx($wrapper $id $password reset $balance @benutzer_array);
}

sub delete_balance {
	my $id = shift;
	my $password = shift;
	my @benutzer_array = @_;
	qx($wrapper $id $password delete @benutzer_array);
}

sub get_balance {
	my $id = shift;
	my $password = shift;
	my $login = shift;
	(my $maxmb, my $mb) = split (/ /, qx($wrapper $id $password list $login));
	return ($maxmb, $mb);
}

sub get_balancelist {
	my $id = shift;
	my $password = shift;
	my @login_array = @_;
	my @userlist = split (/ /, qx($wrapper $id $password userlist @login_array));
	return (@userlist);
}

sub get_printers {
	my $id = shift;
	my $password = shift;
	my @printers = split (/ /, qx($wrapper $id $password printers));
	return (@printers);
}

sub add_printer {
	my $id = shift;
	my $password = shift;
	my $printer = shift;
	qx($wrapper $id $password printeradd $printer);
}

sub delete_printer {
	my $id = shift;
	my $password = shift;
	my $printer = shift;
	qx($wrapper $id $password printerdelete $printer);
}

sub charge_printer {
	my $id = shift;
	my $password = shift;
	my $value = shift;
	my $printer = shift;
	qx($wrapper $id $password charge $value $printer);
}

sub passthrough_printer {
	my $id = shift;
	my $password = shift;
	my $value = shift;
	my $printer = shift;
	qx($wrapper $id $password passthrough $value $printer);
}

sub get_linuxmuster_pykota_conf {
	my $id = shift;
	my $password = shift;
	do "$linuxmuster_pykota_conf_filename";
	return (%balance);
}

sub read_linuxmuster_pykota_conf_file {
	my $id = shift;
	my $password = shift;
	my @lines;
	if (open PYKOTACONF , $linuxmuster_pykota_conf_filename) {
		while (my $line = <PYKOTACONF> ){
			push (@lines, $line);
			}
		close PYKOTACONF;
	}
	return (@lines);
}

sub read_pykota_conf_file {
	my $id = shift;
	my $password = shift;
	my $output = qx($wrapper $id $password readpykotafile);
	my @lines = split (/\n/, $output);
	return (@lines);
}

sub add_standard {
	my $id = shift;
	my $password = shift;
	my $gruppe = shift;
	my $value = shift;
	qx ($wrapper $id $password addstandard $gruppe $value);
}

sub delete_standard {
	my $id = shift;
	my $password = shift;
	my $gruppe = shift;
	qx ($wrapper $id $password deletestandard $gruppe);
}

sub modify_standard {
	my $id = shift;
	my $password = shift;
	my $gruppe = shift;
	my $value = shift;
	qx ($wrapper $id $password modifystandard $gruppe $value);
}

sub set_aktiv {
	my $id = shift;
	my $password = shift;
	my $nummer = shift;
	qx ($wrapper $id $password setaktiv $nummer);
}


##################################################
#      ???????????????????????                   #
##################################################

my $input_buffer;
sub buffer_input {
	my $in = shift;

	while (<$in>) {
		$input_buffer .= $_;
	}
}

#sub start_wrapper {
#	my $app_id = shift;
#	my $id = shift;
#	my $password = shift;
#	my $out = shift;
#	my $in = shift;
#	my $err = shift;
#
#	my $pid = IPC::Open3::open3 $out, $in, $err,
#		$Schulkonsole::Config::_wrapper_files
#		or die new Schulkonsole::Error(
#			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
#			$Schulkonsole::Config::_wrapper_files, $!);
#
#	binmode $out, ':utf8';
#	binmode $in, ':utf8';
#	binmode $err, ':utf8';
#
#	my $re = waitpid $pid, POSIX::WNOHANG;
#	if (   $re == $pid
#	    or $re == -1) {
#		my $error = ($? >> 8) - 256;
#		if ($error < -127) {
#			die new Schulkonsole::Error(
#				Schulkonsole::Error::WRAPPER_EXEC_FAILED,
#				$Schulkonsole::Config::_wrapper_files, $!);
#		} else {
#			die new Schulkonsole::Error(
#				Schulkonsole::Error::WRAPPER_FILES_ERROR_BASE + $error,
#				$Schulkonsole::Config::_wrapper_files);
#		}
#	}
#
#	print $out "$id\n$password\n$app_id\n";
#
#	return $pid;
#}

#sub stop_wrapper {
#	my $pid = shift;
#	my $out = shift;
#	my $in = shift;
#	my $err = shift;
#
#	my $re = waitpid $pid, 0;
#	if (    ($re == $pid or $re == -1)
#	    and $?) {
#		my $error = ($? >> 8) - 256;
#		if ($error < -127) {
#			die new Schulkonsole::Error(
#				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
#				$Schulkonsole::Config::_wrapper_files, $!,
#				($input_buffer ? "Output: $input_buffer" : 'No Output'));
#		} else {
#			die new Schulkonsole::Error(
#				Schulkonsole::Error::WRAPPER_FILES_ERROR_BASE + $error,
#				$Schulkonsole::Config::_wrapper_files);
#		}
#	}
#
#	if ($out) {
#		close $out
#			or die new Schulkonsole::Error(
#				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
#				$Schulkonsole::Config::_wrapper_files, $!,
#				($input_buffer ? "Output: $input_buffer" : 'No Output'));
#	}
#
#	close $in
#		or die new Schulkonsole::Error(
#			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
#			$Schulkonsole::Config::_wrapper_files, $!,
#			($input_buffer ? "Output: $input_buffer" : 'No Output'));
#
#	undef $input_buffer;
#}


#
#sub read_file {
#	my $id = shift;
#	my $password = shift;
#	my $file_number = shift;
#
#	my $pid = start_wrapper(Schulkonsole::Config::READFILEAPP,
#		$id, $password,
#		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
#
#	print SCRIPTOUT "$file_number\n";
#
#	my @re;
#	while (<SCRIPTIN>) {
#		push @re, $_;
#	}
#
#
#	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
#
#
#	return \@re;
#}

sub write_file {
	my $id = shift;
	my $password = shift;
	my $lines = shift;
	my $file_number = shift;

	my $pid = start_wrapper(Schulkonsole::Config::WRITEFILEAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$file_number\n", join('', @$lines);
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
}

1;
