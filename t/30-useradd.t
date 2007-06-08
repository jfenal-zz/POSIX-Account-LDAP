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

my $uid = "testgroup";


my $pal = POSIX::Account::LDAP->new( {config => 't/test.cfg', init => 1 });
isa_ok($pal, 'POSIX::Account::LDAP', "is a POSIX::Account::LDAP object");

# cleanup eventual already existing account
eval { $pal->userdel( { uid => $uid } ); };

# FIXME put in eval to avoid issues. Test if already exists in directory
# before...
my $rc;
$rc = $pal->useradd( { uid => $uid , (%opts) } );
is($rc, 1, "User created");

$rc=undef;
eval {
    $rc=$pal->userdel( { uid => $uid, uidNumber => 23456 } );
};

ok($@, "Echec sur parametre gidNumber non conforme");
is($rc, undef, "Echec sur parametre gidNumber non conforme");

$rc = $pal->userdel( { uid => $uid } );
is($rc, 1, "User deleted");

$rc = $pal->useradd( { uid => $uid } );
is($rc, 1, "User created");
$rc = $pal->userdel( { uid => $uid } );
is($rc, 1, "User deleted");



# FIXME : implement $ENV{TEST_NSS} 
#my @ent = getpwnam('jerome');
#ok($ent[0] eq 'jerome');
#ok($ent[2] eq 32767);
#ok($ent[7] eq '/home/jerome');
#ok($ent[8] eq '/bin/sh');
