#!perl -w
use strict;
use Data::Dumper;
my $tests;

use Test::More;

use lib qw( ./lib ../lib );
use POSIX::Account::LDAP;

plan skip_all => "TEST_LDAP not defined" if not defined $ENV{TEST_LDAP};

plan tests => 5;

use lib qw( ./lib ../lib );

diag( "Testing POSIX::Account::LDAP $POSIX::Account::LDAP::VERSION, Perl $], $^X" );


my $pal = POSIX::Account::LDAP->new( {config => 't/test.cfg', init => 1 });
isa_ok($pal, 'POSIX::Account::LDAP', "is a POSIX::Account::LDAP object");

# FIXME put in eval to avoid issues. Test if already exists in directory
# before...
my $xid;
$xid = $pal->findnextxid( );

ok($xid > 1000, "xid:$xid found > 1000");

my $xid2 = $pal->findnextxid( { minid => 1 + $xid }  );
ok($xid2 > $xid, "xid:$xid2 found > $xid");

my $uid = $pal->findnextuid( { minid => $xid } );
is($xid, $uid, "xid:$xid equals uid:$uid");

my $gid = $pal->findnextgid( { minid => $xid } );
is($xid, $gid, "xid:$xid equals gid:$gid");


