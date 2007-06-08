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
my $gid;
$gid = $pal->findnextgid( );

ok($gid > 1000, "gid:$gid found > 1000");

my $gid2 = $pal->findnextgid( { minid => 1 + $gid }  );
ok($gid2 > $gid, "gid:$gid2 found > $gid");
