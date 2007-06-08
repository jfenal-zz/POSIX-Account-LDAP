#!perl -T
use Test::More tests => 1;

BEGIN {
	use_ok( 'POSIX::Account::LDAP' );
}

diag( "Testing POSIX::Account::LDAP $POSIX::Account::LDAP::VERSION, Perl $], $^X" );
