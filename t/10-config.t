#!perl -w
use strict;
use Test::More;
plan tests => 5;

use lib qw( ./lib ../lib );

use_ok( 'POSIX::Account::LDAP' );
diag( "Testing POSIX::Account::LDAP $POSIX::Account::LDAP::VERSION, Perl $], $^X" );
can_ok('POSIX::Account::LDAP', qw(new init ldapconnect findnextuid findnextgid useradd groupadd findnextxid userdel groupdel));

#
# New 
#
my $pal;
eval {
    $pal = new POSIX::Account::LDAP;
};
if (! $@) {
    # can fail if no default config file
    isa_ok($pal, 'POSIX::Account::LDAP', "is a POSIX::Account::LDAP object")
}
else {
    ok(!defined $pal, "undef returned when called as new POSIX::Account::LDAP");
}

eval {
    $pal = POSIX::Account::LDAP->new( );
};
if (! $@) {
    # can fail if no default config file
    isa_ok($pal, 'POSIX::Account::LDAP', "is a POSIX::Account::LDAP object")
}

$pal = POSIX::Account::LDAP->new( { config => 't/test.cfg', init => 0 } );
isa_ok($pal, 'POSIX::Account::LDAP', "is a POSIX::Account::LDAP object");
ok( !defined( $pal->{ldap}) , "\$self->{ldap} not defined when init=0" );

