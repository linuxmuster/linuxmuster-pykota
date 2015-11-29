use strict;
use utf8;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::DruckquotasError;
use Schulkonsole::Error::Druckquotas;
use Schulkonsole::Config;
use Schulkonsole::DruckquotasConfig;

package Schulkonsole::Druckquotas;

=head1 NAME
Schulkonsole::Druckquotas - interface to Pykota Druckquotas
=head1 SYNOPSIS
 use Schulkonsole::Druckquotas;
 use Schulkonsole::Session;

=head1 DESCRIPTION

If a wrapper command fails, it usually dies with a Schulkonsole::DruckquotasError.
The output of the failed command is stored in the Schulkonsole::DruckquotasError.

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
	get_balancelist
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

sub set_balance {
	my $id = shift;
	my $password = shift;
	my $balance = shift;
	my @benutzer_array = @_;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTAAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "3\n$balance\n", join("\n", @benutzer_array), "\n\n";
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
	
}

sub reset_balance {
	my $id = shift;
	my $password = shift;
	my $balance = shift;
	my @benutzer_array = @_;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTAAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "4\n$balance\n", join("\n", @benutzer_array), "\n\n";
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
	
}

sub delete_balance {
	my $id = shift;
	my $password = shift;
	my @benutzer_array = @_;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTAAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "2\n", join("\n", @benutzer_array), "\n\n";
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
	
}

sub get_balance {
	my $id = shift;
	my $password = shift;
	my $login = shift;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTASHOWAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$login\n", "\n\n";
	close SCRIPTOUT;

	my $maxmb,
	my $mb;
	while (<SCRIPTIN>) {
		($maxmb,$mb) = split(/ /, $_);
	}

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
	
	return ($maxmb, $mb);
}

sub get_balancelist {
	my $id = shift;
	my $password = shift;
	my @login_array = @_;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTAAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "1\n", join("\n", @login_array), "\n\n";
	close SCRIPTOUT;

	my @re;
	while (<SCRIPTIN>) {
		s/\R//g;
		last if /^$/;
		push @re, $_;
	}
			
	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
	
	return @re;
}

sub get_printers {
	my $id = shift;
	my $password = shift;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTAPRINTERAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "0\n", "\n\n";
	close SCRIPTOUT;

	my @re;
	while (<SCRIPTIN>) {
		s/\R//g;
		last if /^$/;
		push @re, $_;
	}

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
	
	return @re;
}

sub add_printer {
	my $id = shift;
	my $password = shift;
	my $printer = shift;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTAPRINTERAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "1\n$printer\n", "\n\n";
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
}

sub delete_printer {
	my $id = shift;
	my $password = shift;
	my $printer = shift;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTAPRINTERAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "2\n$printer\n", "\n\n";
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
}

sub charge_printer {
	my $id = shift;
	my $password = shift;
	my $value = shift;
	my $printer = shift;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTAPRINTERAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "3\n$value\n$printer\n", "\n\n";
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
}

sub passthrough_printer {
	my $id = shift;
	my $password = shift;
	my $value = shift;
	my $printer = shift;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTAPRINTERAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "4\n$value\n$printer\n", "\n\n";
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
}

sub get_linuxmuster_pykota_conf {
	my $id = shift;
	my $password = shift;
	do "$Schulkonsole::DruckquotasConfig::_linuxmuster_pykota_conf_file";
	return (%balance);
}

sub read_linuxmuster_pykota_conf_file {
	my $id = shift;
	my $password = shift;
	my @lines;
	if (open PYKOTACONF , $Schulkonsole::DruckquotasConfig::_linuxmuster_pykota_conf_file) {
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
	my @lines;
	if (open PYKOTACONF , $Schulkonsole::DruckquotasConfig::_pykota_conf_file) {
		while (my $line = <PYKOTACONF> ){
			push @lines, $line;
		}
		close PYKOTACONF;
	}
	return (@lines);
}

sub add_standard {
	my $id = shift;
	my $password = shift;
	my $group = shift;
	my $value = shift;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTADEFAULTSAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "1\n$group\n$value\n", "\n\n";
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
}

sub delete_standard {
	my $id = shift;
	my $password = shift;
	my $group = shift;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTADEFAULTSAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "2\n$group\n", "\n\n";
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
}

sub modify_standard {
	my $id = shift;
	my $password = shift;
	my $group = shift;
	my $value = shift;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTADEFAULTSAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "3\n$group\n$value\n", "\n\n";
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
}

sub set_aktiv {
	my $id = shift;
	my $password = shift;
	my $nummer = shift;

	my $pid = start_wrapper(Schulkonsole::DruckquotasConfig::PRINTQUOTADEFAULTSAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$nummer\n", "\n\n";
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
}


my $input_buffer;
sub buffer_input {
	my $in = shift;

	while (<$in>) {
		$input_buffer .= $_;
	}
}

sub start_wrapper {
	my $app_id = shift;
	my $id = shift;
	my $password = shift;
	my $out = shift;
	my $in = shift;
	my $err = shift;

	my $pid = IPC::Open3::open3 $out, $in, $err,
		$Schulkonsole::DruckquotasConfig::_wrapper_druckquotas
		or die new Schulkonsole::DruckquotasError(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::DruckquotasConfig::_wrapper_druckquotas, $!);

	binmode $out, ':utf8';
	binmode $in, ':utf8';
	binmode $err, ':utf8';

	my $re = waitpid $pid, POSIX::WNOHANG;
	if (   $re == $pid
	    or $re == -1) {
		my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::DruckquotasError(
				Schulkonsole::Error::WRAPPER_EXEC_FAILED,
				$Schulkonsole::DruckquotasConfig::_wrapper_druckquotas, $!);
		} else {
			die new Schulkonsole::DruckquotasError(
				Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::DruckquotasConfig::_wrapper_druckquotas);
		}
	}

	print $out "$id\n$password\n$app_id\n";

	return $pid;
}

sub stop_wrapper {
	my $pid = shift;
	my $out = shift;
	my $in = shift;
	my $err = shift;

	my $re = waitpid $pid, 0;
	if (    ($re == $pid or $re == -1)
	    and $?) {
		my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::DruckquotasError(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
				$Schulkonsole::DruckquotasConfig::_wrapper_druckquotas, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
		} else {
			die new Schulkonsole::DruckquotasError(
				Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::DruckquotasConfig::_wrapper_druckquotas);
		}
	}

	if ($out) {
		close $out
			or die new Schulkonsole::DruckquotasError(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
				$Schulkonsole::DruckquotasConfig::_wrapper_druckquotas, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
	}

	close $in
		or die new Schulkonsole::DruckquotasError(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::DruckquotasConfig::_wrapper_druckquotas, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));

	undef $input_buffer;
}


1;
