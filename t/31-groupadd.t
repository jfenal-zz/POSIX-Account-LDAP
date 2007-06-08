#!perl -w
use strict;
use Data::Dumper;
my $tests;

use Test::More;

use lib qw( ./lib ../lib );
use POSIX::Account::LDAP;

plan skip_all => "TEST_LDAP not defined" if not defined $ENV{TEST_LDAP};

plan tests => 7;

use lib qw( ./lib ../lib );

diag( "Testing POSIX::Account::LDAP $POSIX::Account::LDAP::VERSION, Perl $], $^X" );

BEGIN { $tests += 4; }

my %opts = (
    expire => 0,
    inactive => 0,
    group => "jerome",
    groups=> "",
    userPassword => "secret",
    loginShell => "/bin/sh",
    org => "Altair",
    uidNumber => 32767,
    homeDirectory => '/home/%u',
);

my $name = "jerome";

my $pal = POSIX::Account::LDAP->new( {config => 't/test.cfg', init => 1 });
isa_ok($pal, 'POSIX::Account::LDAP', "is a POSIX::Account::LDAP object");

# FIXME put in eval to avoid issues. Test if already exists in directory
# before...
my $rc;
eval {
    $rc = $pal->groupadd( { name => "testgroup", gidNumber => 23456 } );
    };
is($rc, 1, "Group created");
$rc=undef;
eval {
    $rc=$pal->groupdel( { name => "testgroup", gidNumber => 23456 } );
    };
ok($@, "Echec sur parametre gidNumber non conforme");    
is($rc, undef, "Echec sur parametre gidNumber non conforme");    

$rc = $pal->groupdel( { name => "testgroup" } );
is($rc, 1, "Group deleted");


$rc = $pal->groupadd( { name => "testgroup" } );
is($rc, 1, "Group created");
$rc = $pal->groupdel( { name => "testgroup" } );
is($rc, 1, "Group deleted");


# FIXME : implement $ENV{TEST_NSS} 
#my @ent = getpwnam('jerome');
#ok($ent[0] eq 'jerome');
#ok($ent[2] eq 32767);
#ok($ent[7] eq '/home/jerome');
#ok($ent[8] eq '/bin/sh');
