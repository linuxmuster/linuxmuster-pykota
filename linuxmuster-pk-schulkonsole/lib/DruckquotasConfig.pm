#
# $Id$
#
=head1 NAME

Schulkonsole::DruckquotasConfig - access to schulkonsole druckquotas configuration

=head1 SYNOPSIS

 use Schulkonsole::DruckquotasConfig;

=cut

use strict;
use utf8;
use open ':utf8';

package Schulkonsole::DruckquotasConfig;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	$_pykota_conf_file 
	$_pykota_admin_conf_file 
	$_linuxmuster_pykota_conf_file
	
	$_wrapper_druckquotas
	
	$_cmd_linuxmuster_pk
	
	%_id_root_app_names
	
	PRINTQUOTASHOWAPP
	PRINTQUOTAAPP
	PRINTQUOTAPRINTERAPP
	PRINTQUOTADEFAULTSAPP
	PRINTQUOTAACTIVATEAPP
);

use Env::Bash;
use Schulkonsole::Encode;
use Schulkonsole::Error;

=head1 DESCRIPTION

=head2 Constants

The following constants are used by the wrapper druckquotas to identify which
application to invoke. A user can only use these applications if the
corresponding string is listed for his group in the section
C<[External Programs]> in C<$_permissions_conf_file>.

=head3 Constants for wrapper-druckquotas

=over

=item C<PRINTQUOTASHOWAPP>

C<printquota_show>

=item C<PRINTQUOTAAPP>

C<printquota>

=item C<PRINTQUOTAPRINTERAPP>

C<printquota_printer>

=item C<PRINTQUOTAACTIVATEAPP>

C<printquota_activate>

=item C<PRINTQUOTADEFAULTSAPP>

C<printquota_defaults>

=back

=cut

use constant {
	PRINTQUOTASHOWAPP => 100001,
	PRINTQUOTAAPP => 100002,
	PRINTQUOTAPRINTERAPP => 100003,
	PRINTQUOTAACTIVATEAPP => 100004,
	PRINTQUOTADEFAULTSAPP => 100005,
};


=head3 printquota configuration files

=over

=item C<$_pykota_conf_file>

This file contains pykota configuration values

=item C<$_pykota_admin_conf_file>

This file contains pykota configuration restricted values

=item C<$_linuxmuster_pykota_conf_file>

This file contains the linuxmuster configuration default values

=back

=cut

use vars qw($_pykota_conf_file $_pykota_admin_conf_file $_linuxmuster_pykota_conf_file);


=head3 SUID-Wrapper

=over

=item C<$_wrapper_druckquotas>

Path to wrapper to execute commands for printquota

=back

=cut

use vars qw($_wrapper_druckquotas);


=head3 Variables used by wrapper

=over

=item C<%_id_root_app_names>

Hash that maps the numerical ID of an application in the permissions 
configuration file to its name

=item C<$_cmd_linuxmuster_pk>

Path to command to query printer quotas C<linuxmuster-pk>

=item C<$_pykota_dbname>

Pykota database name

=item C<$_pykota_dbhost>

Host with pykota database

=item C<$_pykota_dbuser>

Username to access the pykota db

=back

=cut

use vars qw(%_id_root_app_names $_cmd_linuxmuster_pk $_pykota_dbname $_pykota_dbhost $_pykota_dbuser);

$_pykota_conf_file = '/etc/pykota/pykota.conf';
$_pykota_admin_conf_file = '/etc/pykota/pykotadmin.conf';
$_linuxmuster_pykota_conf_file = '/etc/linuxmuster/pykota.conf';
$_pykota_dbname = 'pykota';
$_pykota_dbhost = 'localhost';
$_pykota_dbuser = 'pykotaadmin';

$_wrapper_druckquotas = '/usr/lib/schulkonsole/bin/wrapper-druckquotas';

%_id_root_app_names = (
	PRINTQUOTASHOWAPP() => 'printquota_show',
	PRINTQUOTAAPP() => 'printquota',
	PRINTQUOTAPRINTERAPP() => 'printquota_printer',
	PRINTQUOTAACTIVATEAPP() => 'printquota_activate',
	PRINTQUOTADEFAULTSAPP() => 'printquota_defaults',
);



$_cmd_linuxmuster_pk = '/usr/bin/linuxmuster-pk';

1;
