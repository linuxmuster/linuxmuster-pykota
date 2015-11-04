#! /usr/bin/perl -U
#  Wrapper fuer Zugriff auf die pykota-Datenbank und die pykota-Dateien
#
#  04.11.2015
#
=head1 NAME

wrapper-druckquotas.pl - wrapper for configuration of druckquotas

=head1 SYNOPSIS

 my $id = $userdata{id};
 my $password = 'secret';
 my $app_id = Schulkonsole::Config::PRINTERQUOTASHOWAPP;

 open SCRIPT, "| $Schulkonsole::Config::_wrapper_druckquotas";
 print SCRIPT <<INPUT;
 $id
 $password
 $app_id

 INPUT

=head1 DESCRIPTION

=cut

use strict;
use CGI::Inspect;
use DBI;
use lib '/usr/share/schulkonsole';
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::DruckquotasConfig;
use Schulkonsole::Druckquotas;
use Schulkonsole::Error;
use Schulkonsole::Error::Druckquotas;
use POSIX;


my $id = <>;
$id = int($id);
my $password = <>;
chomp $password;

my $userdata = Schulkonsole::DB::verify_password_by_id($id, $password);
exit (  Schulkonsole::Error::Druckquotas::WRAPPER_UNAUTHENTICATED_ID
      - Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
	unless $userdata;


my $app_id = <>;
($app_id) = $app_id =~ /^(\d+)$/;
exit (  Schulkonsole::Error::Druckquotas::WRAPPER_APP_ID_DOES_NOT_EXIST
      - Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
	unless defined $app_id;

my $app_name = $Schulkonsole::DruckquotasConfig::_id_root_app_names{$app_id};
exit (  Schulkonsole::Error::Druckquotas::WRAPPER_APP_ID_DOES_NOT_EXIST
      - Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
	unless defined $app_name;



my $permissions = Schulkonsole::Config::permissions_apps();
my $groups = Schulkonsole::DB::user_groups(
	$$userdata{uidnumber}, $$userdata{gidnumber}, $$userdata{gid});
# FIXME: workaround for non existing students group!
if(! (defined $$groups{teachers} or defined $$groups{domadmins})) {
	$$groups{'students'} = 1;
}

my $is_permission_found = 0;
foreach my $group (('ALL', keys %$groups)) {
	if ($$permissions{$group}{$app_name}) {
		$is_permission_found = 1;
		last;
	}
}
exit (  Schulkonsole::Error::Druckquotas::WRAPPER_UNAUTHORIZED_ID
      - Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
	unless $is_permission_found;

SWITCH: {
	$app_id == Schulkonsole::DruckquotasConfig::PRINTQUOTASHOWAPP and do {
		printquota_show();
		last SWITCH;
	};
	$app_id == Schulkonsole::DruckquotasConfig::PRINTQUOTAAPP and do {
		printquota();
		last SWITCH;
	};
	$app_id == Schulkonsole::DruckquotasConfig::PRINTQUOTAPRINTERAPP and do {
		printquota_printer();
		last SWITCH;
	};
	$app_id == Schulkonsole::DruckquotasConfig::PRINTQUOTADEFAULTSAPP and do {
		printquota_defaults();
		last SWITCH;
	};
	$app_id == Schulkonsole::DruckquotasConfig::PRINTQUOTAACTIVATEAPP and do {
		printquota_activate();
		last SWITCH;
	};
};

exit -2;	# program error

=head3 printquota_show

numeric constant: C<Schulkonsole::DruckquotasConfig::PRINTQUOTASHOWAPP>

=head4 Description

Shows the print quota information for a user

=head4 Parameters from standard input

=over

=item C<user>

User name to show print quota

=back

=cut

sub printquota_show {
	my $user = <>;
	($user) = $user =~ m/^\s*(\w+?)\s*$/;
	exit  (   Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_USER
		- Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
		unless $user;

	my $dbh = dbconnect(); 
	my $dblist = $dbh->prepare("SELECT * FROM users WHERE username = '$user'");
	$dblist->execute();
	while(my $row=$dblist->fetchrow_hashref()) {
		my $maxmb = sprintf ('%.2f', $row->{'lifetimepaid'});
		my $mb    = sprintf ('%.2f', $row->{'balance'});
		print "$maxmb $mb";
	}
	$dbh->disconnect();
	
	exit 0;
}

=head3 printquota

numeric constant: C<Schulkonsole::Config::PRINTQUOTAAPP>

=head4 Description

Manage printquotas for users.

=head4 Parameters from standard input

=over

=item C<action>

1 userlist
2 delete
3 balance
4 reset

=item C<value> if action=3 or action=4

Numeric value to set the printquota to

=item C<userlist>

Read user names from standard input and do action for read user names.

=back

=cut

sub printquota {
	my $action = <>;
	($action) = $action =~ /^(\d+)$/;
	exit (   Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_ACTION
	      -  Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
	      unless $action;
	exit (   Schulkonsole::Error::Druckquotas::WRAPPER_WRONG_ACTION
	      -  Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
	      if 1 > $action or $action > 4;
	
	my $value = 0;
	if($action == 3 or $action == 4) {
		$value = <>;
		($value) = $value =~ /^([+-]?\d+)$/;
		exit (  Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_VALUE
		      - Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
		      unless $value;
	}
	
	my @userlist;
	while (my $user = <>) {
		last if $user =~ /^$/;
		($user) = $user =~ /^\s*(\w+)\s*$/;
		exit (  Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_USERLIST
		      - Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
			unless $user;

		push @userlist, $user;
	}
	exit (  Schulkonsole::Error::Druckquotas::WRAPPER_NO_USERS
	      - Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
		unless @userlist;

	my $dbh = dbconnect();
	 
	ACTION: {
		$action == 1 and do { #userlist
			foreach my $user (@userlist) {
				my $dblist = $dbh->prepare("SELECT * FROM users WHERE username = '$user'");
				$dblist->execute();
				while(my $row=$dblist->fetchrow_hashref()) {
					my $maxmb = sprintf ('%.2f', $row->{'lifetimepaid'});
					my $mb    = sprintf ('%.2f', $row->{'balance'});
					print "$user:$maxmb:$mb\n";
				}
			}
			last ACTION;
		};
		$action == 2 and do { #delete
			foreach my $user (@userlist) {
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
			last ACTION;
		};
		$action == 3 and do { #set
			foreach my $user (@userlist) {
				my $dbuser = $dbh->selectrow_hashref("SELECT * FROM users WHERE username ='$user'");
				my $id = $dbuser->{'id'};
				if ($id) {
					my $paid = $dbuser->{'lifetimepaid'};
					my $balance = $dbuser->{'balance'};
					if ( $value =~ /^\d+$/) {
						$balance = $balance + ($value - $paid);
						$paid = $value;
					} elsif ( $value =~ /^\+(\d+)$/ ) {
						$balance = $balance + $1;
						$paid = $paid + $1; 
					} elsif ( $value =~ /^\-(\d+)$/ ) {
						$balance = $balance - $1;
						$paid = $paid - $1;
					}
					$dbh->do("UPDATE users SET lifetimepaid = '$paid', balance = '$balance' WHERE id = '$id'");
				} else {
					$dbh->do("INSERT INTO users (username, lifetimepaid, balance, limitby) VALUES ('$user','$value','$value','balance')");
				}
			}
			last ACTION;
		};
		$action == 4 and do { #reset
			foreach my $user (@userlist) {
				my $dbuser = $dbh->selectrow_hashref("SELECT * FROM users WHERE username ='$user'");
				my $id = $dbuser->{'id'};
				if ($id) {
					$dbh->do("UPDATE users SET lifetimepaid = '$value', balance = '$value' WHERE id = '$id'");
				} else {
					$dbh->do("INSERT INTO users (username, lifetimepaid, balance, limitby) VALUES ('$user','$value','$value','balance')");
				}
			}
			last ACTION;
		};
	};
	$dbh->disconnect();
	
	exit 0;
}

=head3 printquota_printer

numeric constant: C<Schulkonsole::DruckquotasConfig::PRINTQUOTAPRINTERAPP>

=head4 Description

Manage printquota settings of printers

=head4 Parameters from standard input

=over

=item C<action>

0 - list printers
1 - add printer
2 - delete printer
3 - charge printer
4 - passthrough

= item C<value>

Value to use for action = 3,4

=item C<printer>

Name of printer for action = 1,2,3,4

=back

=cut

sub printquota_printer {
	my $action = <>;
	($action) = $action =~ /^(\d+)$/;
	exit (   Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_ACTION
	      -  Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
	      unless defined $action;
	exit (   Schulkonsole::Error::Druckquotas::WRAPPER_WRONG_ACTION
	      -  Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
	      if 0 > $action or $action > 4;
	
	my $value = 0;
	if($action == 3 or $action == 4) {
		$value = <>;
		($value) = $value =~ /^([+-]?\d+)$/;
		exit (  Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_VALUE
		      - Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
		      unless $value;
	}
	
	my $printer;
	if($action != 0) {
		$printer = <>;
		($printer) = $printer =~ /^\s*(\w+)\s*$/;
		exit (  Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_PRINTER
			- Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
			unless $printer;
	}
		
	my $dbh = dbconnect(); 

	ACTION: {
		$action == 0 and do { #list printers
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
				print "$name:$page:$job:$passthrough\n";
			}
			last ACTION;
		};
		
		$action == 1 and do { #add
			my $dbprinter = $dbh->selectrow_hashref("SELECT id FROM printers WHERE printername ='$printer'");
			my $id = $dbprinter->{'id'};
			if (not $id) {
				$dbh->do("INSERT INTO printers (printername) VALUES ('$printer')");
			}
			last ACTION;
		};

		$action == 2 and do { #delete
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
			last ACTION;
		};
		
		$action == 3 and do {
			if ($value =~ m/^\s*([\d\.]+)\,?([\d\.]+)?\s*$/) {
				my $page = $1;
				my $job  = $2;
				my $dbprinter = $dbh->selectrow_hashref("SELECT id FROM printers WHERE printername ='$printer'");
				my $id = $dbprinter->{'id'};
				if ($id) {
					if ($job) {
						$dbh->do("UPDATE printers SET priceperpage = '$page', priceperjob = '$job' WHERE id = '$id'");
					} else {
						$dbh->do("UPDATE printers SET priceperpage = '$page' WHERE id = '$id'");
					}
				}
			}
			last ACTION;
		};
		
		$action == 4 and do {
			if ($value =~ m/^\s*((?:ON|OFF))\s*$/i) {
				my $wert = $1;
				my $dbprinter = $dbh->selectrow_hashref("SELECT id FROM printers WHERE printername ='$printer'");
				my $id = $dbprinter->{'id'};
				if ($id) {
					if ($wert =~ m/ON/i) {
						$dbh->do("UPDATE printers SET passthrough = '1' WHERE id = '$id'");
					} else {
						$dbh->do("UPDATE printers SET passthrough = '0' WHERE id = '$id'");
					}
				}
			}
			last ACTION;
		};
		
	};
	$dbh->disconnect();
	
	exit 0;
}


=head3 printquota_defaults

numeric constant: C<Schulkonsole::DruckquotasConfig::PRINTQUOTADEFAULTSAPP>

=head4 Description

Modifies pykota settings for linuxmuster groups

=head4 Parameters from standard input

=over

=item C<action>

1 - add standard
2 - delete standard
3 - modify standard

=item C<group>

group name to act upon

=item C<value>

Wert für action = 1,3

=back

=cut

sub printquota_defaults {
	my $action = <>;
	($action) = $action =~ /^(\d+)$/;
	exit (   Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_ACTION
	      -  Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
	      unless $action;
	exit (   Schulkonsole::Error::Druckquotas::WRAPPER_WRONG_ACTION
	      -  Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
	      if 1 > $action or $action > 4;
	
	my $group = <>;
	($group) = $group =~ /^\s*([\-\w]+)\s*$/;
	exit (  Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_GROUP
		- Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
		unless $group;
	
	my $value = 0;
	if($action == 1 or $action == 3) {
		$value = <>;
		($value) = $value =~ /^\s*([\.\,\d]+)\s*$/;
		exit (  Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_VALUE
		      - Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
		      unless $value;
	}
	
	my $dbh = dbconnect(); 

	ACTION: {
		$action == 1 and do { #add
			$value =~ tr/\,/\./;
			if (open PYKOTACONF , ">>$Schulkonsole::DruckquotasConfig::_linuxmuster_pykota_conf_file") {
				my $wert = sprintf('%.2f',$value);
				print PYKOTACONF "\n".'$balance{"'."$group".'"}  =  '.$wert.';';
				close PYKOTACONF;
			}
			last ACTION;
		};

		
		$action == 2 and do { #delete
			my $is_changed;
			my @lines;
			if (open PYKOTACONF , $Schulkonsole::DruckquotasConfig::_linuxmuster_pykota_conf_file) {
					while (my $line = <PYKOTACONF> ){
						if ($line !~ m/\s*\$balance\{[\"\']?($group)[\"\']?\}/i ) {
							push @lines, $line;
						} else {
							$is_changed++;
						}
					}
					close PYKOTACONF;
			}
			if ($is_changed) {
				if (open PYKOTACONF , ">$Schulkonsole::DruckquotasConfig::_linuxmuster_pykota_conf_file") {
					foreach my $line (@lines) {
						print PYKOTACONF "$line"; 
					}
					close PYKOTACONF;
				}
			}
			last ACTION;
		};
		
		$action == 3 and do {
			my $wert = sprintf('%.2f',$value);
			$value =~ tr/\,/\./;
			my @lines;
			my $is_changed;
			if (open PYKOTACONF , $Schulkonsole::DruckquotasConfig::_linuxmuster_pykota_conf_file) {
				while (my $line = <PYKOTACONF> ){
					if ($line !~ m/\s*\$balance\{[\"\']?($group)[\"\']?\}/i ) {
						push @lines, $line;
					} else {
						push @lines, '$balance{"'."$group".'"}  =  '.$wert.";\n";
						$is_changed++;
					}
				}
				close PYKOTACONF;
			}
			if ($is_changed) {
				if (open PYKOTACONF , ">$Schulkonsole::DruckquotasConfig::_linuxmuster_pykota_conf_file") {
					foreach my $line (@lines) {
						print PYKOTACONF "$line"; 
					}
					close PYKOTACONF;
				}
			}
			last ACTION;
		};
	};

	$dbh->disconnect();
	
	exit 0;
}

=head3 printquota_activate

numeric constant: C<Schulkonsole::DruckquotasConfig::PRINTQUOTAACTIVATEAPP>

=head4 Description

Activates / deactivates quota messages

=head4 Parameters from standard input

=over

=item C<number>

messages number to act upon

=back

=cut

sub printquota_activate {
	my $number = <>;
	($number) = $number =~ /^(\d+)$/;
	exit (   Schulkonsole::Error::Druckquotas::WRAPPER_INVALID_NUMBER
	      -  Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
	      unless $number;
	
	my @lines;
	my $count = 0 ;
	my @typ;
	my @position;
	my @text;
	my $linecount = 0;
	my $is_changed;
	if (open PYKOTACONF , $Schulkonsole::DruckquotasConfig::_pykota_conf_file) {
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
	if (($number <= $count) and ( $count >0 )){
		for (my $i=1; $i<$count+1; $i++) {
			if ($number == $i) {
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
			if (open PYKOTACONF , ">$Schulkonsole::DruckquotasConfig::_pykota_conf_file") {
				foreach my $line (@lines) {
					print PYKOTACONF "$line"; 
				}
				close PYKOTACONF;
			}
		}
	}
	
	exit 0;
}

sub dbconnect {
	my $dbpassword;
	if (open PYKOTACONF , $Schulkonsole::DruckquotasConfig::_pykota_admin_conf_file) {
		while (my $line = <PYKOTACONF> ){
				if ( $line =~ /^\s*storageadminpw\s*\:\s*(\w+)\s*$/) {
					$dbpassword = $1;
					last;
				}
			}
		close PYKOTACONF;
	}
	exit (  Schulkonsole::Error::Druckquotas::WRAPPER_NO_DBPASSWORD
	      - Schulkonsole::Error::Druckquotas::WRAPPER_ERROR_BASE)
	      unless $dbpassword;
	
	my $dbh = DBI->connect("DBI:Pg:dbname=$Schulkonsole::DruckquotasConfig::_pykota_dbname;host=$Schulkonsole::DruckquotasConfig::_pykota_dbhost",
				$Schulkonsole::DruckquotasConfig::_pykota_dbuser,$dbpassword,{'RaiseError' => 1});
	return $dbh;
}