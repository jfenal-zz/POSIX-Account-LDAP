#!perl -w
use strict;
use Data::Dumper;
my $tests;

use Test::More;

use lib qw( ./lib ../lib );
use POSIX::Account::LDAP;

plan skip_all => "TEST_LDAP not defined" if not defined $ENV{TEST_LDAP};

plan tests => 3;

use lib qw( ./lib ../lib );

diag( "Testing POSIX::Account::LDAP $POSIX::Account::LDAP::VERSION, Perl $], $^X" );


my $pal = POSIX::Account::LDAP->new( {config => 't/test.cfg', init => 1 });
isa_ok($pal, 'POSIX::Account::LDAP', "is a POSIX::Account::LDAP object");

# FIXME put in eval to avoid issues. Test if already exists in directory
# before...
my $uid;
$uid = $pal->findnextuid( );

ok($uid > 1000, "uid:$uid found > 1000");

my $uid2 = $pal->findnextuid( { minid => 1 + $uid }  );
ok($uid2 > $uid, "uid:$uid2 found > $uid");
