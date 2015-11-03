#! /usr/bin/perl -U
#  Wrapper fuer Zugriff auf die pykota-Datenbank und die pykota-Dateien
#
#  25.6.2012
#
#  Wrapper liest mit suid zunächst das Passwort des pykotadmins für die pykota-Datenbank ein
#
#  Usage:
#
# Datenbankoperationen:
#   druckquotas.pl list <user>
#   druckquotas.pl userlist <userlist>
#   druckquotas.pl balance <wert> <userlist>
#   druckquotas.pl delete <userlist>
#   druckquotas.pl reset <wert> <userlist>
#   druckquotas.pl printers
#   druckquotas.pl charge <wert> <printer>
#   druckquotas.pl printerdelete <printer>
#   druckquotas.pl printeradd <printer>
#   druckquotas.pl passthrough <wert> <printer>
#
#
# Dateioperationen:
#   druckquotas.pl readpykotafile
#   druckquotas.pl addstandard <gruppe> <wert>
#   druckquotas.pl deletestandard <gruppe>
#   druckquotas.pl modifystandard <gruppe> <wert>
#   druckquotas.pl setaktiv <nummer>
#
#

$ENV{'PATH'}='/bin:/usr/bin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

use strict;
use DBI;
use lib '/usr/share/schulkonsole';
use Schulkonsole::Config;
use Schulkonsole::DB;

#  root - Rechte - setzen ??? ##################
#$< = $> = 0;
#$( = $);
##############################################


my $id = shift;
$id = int($id);
my $password = shift;
chomp $password;


my $userdata = Schulkonsole::DB::verify_password_by_id($id, $password);
exit -32 unless $userdata;


#my $app_id = shift;
#($app_id) = $app_id =~ /^(\d+)$/;
#exit -33
#	unless defined $app_id && $Schulkonsole::Config::_root_apps[$app_id];
#
#my $permissions = Schulkonsole::Config::permissions_apps();
#my $groups = Schulkonsole::DB::user_groups(
#	$$userdata{uidnumber}, $$userdata{gidnumber}, $$userdata{gid});
#
#my $app;
#foreach my $group (('ALL', keys %$groups)) {
#	foreach my $name (keys %{ $$permissions{$group} }) {
#		if ($Schulkonsole::Config::_root_app_name_ids{$name} == $app_id) {
#			$app = $Schulkonsole::Config::_root_apps[$app_id];
#			last;
#		}
#	}
#}
#exit -34 unless $app;


#administrator darf alles, Benutzer nur sein eigenes Konto abfragen
if ($$userdata{uid} ne 'administrator') {
	exit -34 unless ( ($ARGV[0]='list') and ($ARGV[1] = $$userdata{uid}) );
}


my $befehl;
if ($ARGV[0] =~ m/^\s*(\w+?)\s*$/) {
	$befehl = $1;
	shift (@ARGV);
}

my $dbname     = "pykota";
my $dbhost     = "localhost";
my $dbuser     = "pykotaadmin";
my $dbpassword;

# nachfolgende Dateinamen nach Schulkonsole::Config verschieben
my $pykota_conf_filename = '/etc/pykota/pykota.conf';
my $pykota_admin_filename = '/etc/pykota/pykotadmin.conf';
my $pykota_linuxmuster_filename = '/etc/linuxmuster/pykota.conf';


# Passwort und Name des pykota-Datenbank-Admin einlesen:

if (open PYKOTACONF , $pykota_admin_filename) {
	while (my $line = <PYKOTACONF> ){
			if ( $line =~ /^\s*storageadmin\s*\:\s*(\w+)\s*$/) {
				$dbuser = $1;
			}
			if ( $line =~ /^\s*storageadminpw\s*\:\s*(\w+)\s*$/) {
				$dbpassword = $1;
			}
		}
	close PYKOTACONF;
}


if ($befehl eq 'list') {
	if ($ARGV[0] =~ m/^\s*(\w+?)\s*$/) {
		my $user = $1;
		my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost",$dbuser,$dbpassword,{'RaiseError' => 1}); 
		my $dblist = $dbh->prepare("SELECT * FROM users WHERE username = '$user'");
		$dblist->execute();
		while(my $row=$dblist->fetchrow_hashref()) {
			my $maxmb = sprintf ('%.2f', $row->{'lifetimepaid'});
			my $mb    = sprintf ('%.2f', $row->{'balance'});
			print "$maxmb $mb";
		}
		$dbh->disconnect();
	}
} elsif ($befehl eq 'userlist') {
	my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost",$dbuser,$dbpassword,{'RaiseError' => 1}); 
	foreach my $user (@ARGV) {
		if ($user =~ m/^\s*(\w+?)\s*$/) {
			my $dblist = $dbh->prepare("SELECT * FROM users WHERE username = '$user'");
			$dblist->execute();
			while(my $row=$dblist->fetchrow_hashref()) {
				my $maxmb = sprintf ('%.2f', $row->{'lifetimepaid'});
				my $mb    = sprintf ('%.2f', $row->{'balance'});
				print "$user:$maxmb:$mb ";
			}
		}
	}
	$dbh->disconnect();
} elsif ($befehl eq 'delete') {
	my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost",$dbuser,$dbpassword,{'RaiseError' => 1}); 
	foreach my $user (@ARGV) {
		if ($user =~ m/^\s*(\w+?)\s*$/) {
			my $dbid = $dbh->selectrow_hashref("SELECT * FROM users WHERE username ='$user'");
			my $id = $dbid->{'id'};
			if ($id) {
				$dbh->do("DELETE FROM payments WHERE userid = '$id'");
				$dbh->do("DELETE FROM jobhistory WHERE userid = '$id'");
				$dbh->do("DELETE FROM userpquota WHERE userid = '$id'");
				$dbh->do("DELETE FROM groupsmembers WHERE userid = '$id'");
				$dbh->do("DELETE FROM users WHERE id = '$id'");
			}
		}
	}
	$dbh->disconnect();
} elsif ($befehl eq 'balance') {
	my $wert;
	my @userliste;
	if ($ARGV[0] =~ m/^\s*([\+\-]?\d+)\s*$/) {
		$wert = $1;
		shift (@ARGV);
		my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost",$dbuser,$dbpassword,{'RaiseError' => 1}); 
		foreach my $user (@ARGV) {
			if ($user =~ m/^\s*(\w+?)\s*$/) {
				my $dbuser = $dbh->selectrow_hashref("SELECT * FROM users WHERE username ='$user'");
				my $id = $dbuser->{'id'};
				if ($id) {
					my $paid = $dbuser->{'lifetimepaid'};
					my $balance = $dbuser->{'balance'};
					if ( $wert =~ /^\d+$/) {
						$balance = $balance + ($wert - $paid);
						$paid = $wert;
					} elsif ( $wert =~ /^\+(\d+)$/ ) {
						$balance = $balance + $1;
						$paid = $paid + $1; 
					} elsif ( $wert =~ /^\-(\d+)$/ ) {
						$balance = $balance - $1;
						$paid = $paid - $1;
					}
					$dbh->do("UPDATE users SET lifetimepaid = '$paid', balance = '$balance' WHERE id = '$id'");
				}
			}
		}
		$dbh->disconnect();
	}
} elsif ($befehl eq 'reset') {
	my $wert;
	my @userliste;
	if ($ARGV[0] =~ m/^\s*(\d+)\s*$/) {
		$wert = $1;
		shift(@ARGV);
		my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost",$dbuser,$dbpassword,{'RaiseError' => 1}); 
		foreach my $user (@ARGV) {
			if ($user =~ m/^\s*(\w+?)\s*$/) {
				my $dbuser = $dbh->selectrow_hashref("SELECT * FROM users WHERE username ='$user'");
				my $id = $dbuser->{'id'};
				if ($id) {
					$dbh->do("UPDATE users SET lifetimepaid = '$wert', balance = '$wert' WHERE id = '$id'");
				} else {
					$dbh->do("INSERT INTO users (username, lifetimepaid, balance, limitby) VALUES ('$user','$wert','$wert','balance')");
				}
			}
		}
		$dbh->disconnect();
	}
} elsif ($befehl eq 'printers') {
	my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost",$dbuser,$dbpassword,{'RaiseError' => 1}); 
	my $dblist = $dbh->prepare("SELECT * FROM printers");
	$dblist->execute();
	while(my $row=$dblist->fetchrow_hashref()) {
		my $name = $row->{'printername'};
		my $page = sprintf ('%.2f', $row->{'priceperpage'});
		my $job  = sprintf ('%.2f', $row->{'priceperjob'});
		my $passthrough;
		if ( $row->{'passthrough'} == 1 ) {
			$passthrough='ON';
		} else {
			$passthrough='OFF';
		};
		print "$name:$page:$job:$passthrough ";
	}
	$dbh->disconnect();
} elsif ($befehl eq 'charge') {
	my $printer;
	if ($ARGV[0] =~ m/^\s*([\d\.]+)\,?([\d\.]+)?\s*$/) {
		my $page = $1;
		my $job  = $2;
		if ($ARGV[1] =~ m/^\s*([\-\w]+)\s*$/) {
			$printer = $1;
			my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost",$dbuser,$dbpassword,{'RaiseError' => 1}); 
			my $dbprinter = $dbh->selectrow_hashref("SELECT id FROM printers WHERE printername ='$printer'");
			my $id = $dbprinter->{'id'};
			if ($id) {
				if ($job) {
					$dbh->do("UPDATE printers SET priceperpage = '$page', priceperjob = '$job' WHERE id = '$id'");
				} else {
					$dbh->do("UPDATE printers SET priceperpage = '$page' WHERE id = '$id'");
				}
			}
			$dbh->disconnect();
		}
	}
} elsif ($befehl eq 'passthrough') {
	my $wert;
	my $printer;
	if ($ARGV[0] =~ m/^\s*((?:ON|OFF))\s*$/i) {
		$wert = $1;
		if ($ARGV[1] =~ m/^\s*([\-\w]+)\s*$/) {
			$printer = $1;
			my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost",$dbuser,$dbpassword,{'RaiseError' => 1}); 
			my $dbprinter = $dbh->selectrow_hashref("SELECT id FROM printers WHERE printername ='$printer'");
			my $id = $dbprinter->{'id'};
			if ($id) {
				if ($wert =~ m/ON/i) {
					$dbh->do("UPDATE printers SET passthrough = '1' WHERE id = '$id'");
				} else {
					$dbh->do("UPDATE printers SET passthrough = '0' WHERE id = '$id'");
				}
			}
			$dbh->disconnect();
		}
	}
} elsif ($befehl eq 'printerdelete') {
	my $printer;
	if ($ARGV[0] =~ m/^\s*([\-\w]+)\s*$/) {
		$printer = $1;
		my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost",$dbuser,$dbpassword,{'RaiseError' => 1}); 
		my $dbprinter = $dbh->selectrow_hashref("SELECT id FROM printers WHERE printername ='$printer'");
		my $id = $dbprinter->{'id'};
		if ($id) {
			$dbh->do("DELETE FROM jobhistory WHERE printerid = '$id'");
			$dbh->do("DELETE FROM coefficients WHERE printerid = '$id'");
			$dbh->do("DELETE FROM printergroupsmembers WHERE printerid = '$id'");
			$dbh->do("DELETE FROM userpquota WHERE printerid = '$id'");
			$dbh->do("DELETE FROM grouppquota WHERE printerid = '$id'");
			$dbh->do("DELETE FROM printers WHERE id = '$id'");
		}
		$dbh->disconnect();
	}
} elsif ($befehl eq 'printeradd') {
	my $printer;
	if ($ARGV[0] =~ m/^\s*([\-\w]+)\s*$/) {
		$printer = $1;
		my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost",$dbuser,$dbpassword,{'RaiseError' => 1}); 
		my $dbprinter = $dbh->selectrow_hashref("SELECT id FROM printers WHERE printername ='$printer'");
		my $id = $dbprinter->{'id'};
		if (not $id) {
			$dbh->do("INSERT INTO printers (printername) VALUES ('$printer')");
		}
		$dbh->disconnect();
	}
} elsif ($befehl eq 'readpykotafile') {
	if (open PYKOTACONF , $pykota_conf_filename) {
		while (my $line = <PYKOTACONF> ){
			print "$line\n";
			}
		close PYKOTACONF;
	}
} elsif ($befehl eq 'addstandard') {
	my $gruppe;
	my $value;
	if ($ARGV[0] =~ m/^\s*([\-\w]+)\s*$/) {
		$gruppe = $1;
		if ( $ARGV[1] =~ /^\s*([\.\,\d]+)\s*$/) {
			$value = $1;
			$value =~ tr/\,/\./;
			if (open PYKOTACONF , ">>$pykota_linuxmuster_filename") {
				my $wert = sprintf('%.2f',$value);
				print PYKOTACONF "\n".'$balance{"'."$gruppe".'"}  =  '.$wert.';';
				close PYKOTACONF;
			}
		}
	}
} elsif ($befehl eq 'deletestandard') {
	my $gruppe;
	if ($ARGV[0] =~ m/^\s*([\-\w]+)\s*$/) {
		$gruppe = $1;
		my $is_changed;
		my @lines;
		if (open PYKOTACONF , $pykota_linuxmuster_filename) {
				while (my $line = <PYKOTACONF> ){
					if ($line !~ m/\s*\$balance\{[\"\']?($gruppe)[\"\']?\}/i ) {
						push @lines, $line;
					} else {
						$is_changed++;
					}
				}
				close PYKOTACONF;
		}
		if ($is_changed) {
			if (open PYKOTACONF , ">$pykota_linuxmuster_filename") {
				foreach my $line (@lines) {
					print PYKOTACONF "$line"; 
				}
				close PYKOTACONF;
			}
		}
		
	}
} elsif ($befehl eq 'modifystandard') {
	my $gruppe;
	if ($ARGV[0] =~ m/^\s*([\-\w]+)\s*$/) {
		$gruppe = $1;
		if ( $ARGV[1] =~ /^\s*([\.\d]+)\s*$/) {
			my $value = $1;
			my $wert = sprintf('%.2f',$value);
			$value =~ tr/\,/\./;
			my @lines;
			my $is_changed;
			if (open PYKOTACONF , $pykota_linuxmuster_filename) {
				while (my $line = <PYKOTACONF> ){
					if ($line !~ m/\s*\$balance\{[\"\']?($gruppe)[\"\']?\}/i ) {
						push @lines, $line;
					} else {
						push @lines, '$balance{"'."$gruppe".'"}  =  '.$wert.";\n";
						$is_changed++;
					}
				}
				close PYKOTACONF;
			}
			if ($is_changed) {
				if (open PYKOTACONF , ">$pykota_linuxmuster_filename") {
					foreach my $line (@lines) {
						print PYKOTACONF "$line"; 
					}
					close PYKOTACONF;
				}
			}
		}
	}
} elsif ($befehl eq 'setaktiv') {
	my $nummer;
	if ( $ARGV[0] =~ m/^\s*(\d+)\s*$/ ) {
		$nummer = $1;
		my @lines;
		my $count = 0 ;
		my @typ;
		my @position;
		my @text;
		my $linecount = 0;
		my $is_changed;
		if (open PYKOTACONF , $pykota_conf_filename) {
			while (my $line = <PYKOTACONF> ){
				if ( $line =~ m/\s*(#*)\s*(askconfirmation\s*\:\s*\/usr\/bin\/pknotify.*)/ ) {
					$count++;
					$typ[$count] = $1;
					$text[$count] = $2;
					$position[$count] = $linecount;
				}
				push @lines, $line;
				$linecount++;
			}
			close PYKOTACONF;
		}
		if (($nummer <= $count) and ( $count >0 )){
			for (my $i=1; $i<$count+1; $i++) {
				if ($nummer == $i) {
					if ($typ [$i] =~ m/#+/ ) {
						$lines[$position[$i]] = $text[$i]."\n";
						$is_changed++;
					}
				} else {
					if ($typ [$i] !~ m/#+/ ) {
						$lines[$position[$i]] = '#'.$text[$i]."\n";
						$is_changed++;
					}
				}
			}
			if ($is_changed) {
				if (open PYKOTACONF , ">$pykota_conf_filename") {
					foreach my $line (@lines) {
						print PYKOTACONF "$line"; 
					}
					close PYKOTACONF;
				}
			}
		}
	}
} else {
	exit -1;
}
