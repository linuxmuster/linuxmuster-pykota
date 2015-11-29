use strict;
use utf8;

package Schulkonsole::Error::Druckquotas;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	OK
	WRAPPER_ERROR_BASE
	WRAPPER_GENERAL_ERROR
	WRAPPER_UNAUTHORIZED_UID
	WRAPPER_SCRIPT_EXEC_FAILED
	WRAPPER_UNAUTHENTICATED_ID
	WRAPPER_APP_ID_DOES_NOT_EXIST
	WRAPPER_UNAUTHORIZED_ID
	WRAPPER_INVALID_USER
	WRAPPER_INVALID_ACTION
	WRAPPER_WRONG_ACTION
	WRAPPER_INVALID_VALUE
	WRAPPER_INVALID_USERLIST
	WRAPPER_NO_USERS
	WRAPPER_INVALID_PRINTER
	WRAPPER_INVALID_GROUP
	WRAPPER_INVALID_NUMBER
	WRAPPER_NO_DBPASSWORD
);

# package constants
use constant {
	OK => 0,

	WRAPPER_ERROR_BASE => 100000,
	WRAPPER_GENERAL_ERROR => 100000 -1,
	WRAPPER_PROGRAM_ERROR => 100000 -2,
	WRAPPER_UNAUTHORIZED_UID => 100000 -3,
	WRAPPER_SCRIPT_EXEC_FAILED => 100000 -6,
	WRAPPER_UNAUTHENTICATED_ID => 100000 -32,
	WRAPPER_APP_ID_DOES_NOT_EXIST => 100000 -33,
	WRAPPER_UNAUTHORIZED_ID => 100000 -34,
	WRAPPER_INVALID_USER => 100000 -35,
	WRAPPER_INVALID_ACTION => 100000 -36,
	WRAPPER_WRONG_ACTION => 100000 -37,
	WRAPPER_INVALID_VALUE => 100000 -38,
	WRAPPER_INVALID_USERLIST => 100000 -39,
	WRAPPER_NO_USERS => 100000 -40,
	WRAPPER_INVALID_PRINTER => 100000 -41,
	WRAPPER_INVALID_GROUP => 100000 -42,
	WRAPPER_INVALID_NUMBER => 100000 -43,
	WRAPPER_NO_DBPASSWORD => 100000 -44,
};



1;
