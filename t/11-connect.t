#!perl -w
use strict;
use Data::Dumper;
my $tests;

use Test::More;

use lib qw( ./lib ../lib );
use POSIX::Account::LDAP;

plan skip_all => "TEST_LDAP not defined" if not defined $ENV{TEST_LDAP};

plan tests => $tests;

use lib qw( ./lib ../lib );

my $pal;

diag( "Testing POSIX::Account::LDAP $POSIX::Account::LDAP::VERSION, Perl $], $^X" );
BEGIN { $tests += 4; }

$pal = POSIX::Account::LDAP->new( { config => 't/test.cfg', init => 1 } );
isa_ok($pal, 'POSIX::Account::LDAP', "is a POSIX::Account::LDAP object");
ok( defined( $pal->{ldap}) , "\$self->{ldap} defined when init=0" );


$pal = POSIX::Account::LDAP->new( { config => 't/test.cfg' } );
isa_ok($pal, 'POSIX::Account::LDAP', "is a POSIX::Account::LDAP object");
ok( defined( $pal->{ldap}) , "\$self->{ldap} defined when init parm omitted" );

