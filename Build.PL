use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POSIX::Account::LDAP',
    license             => 'perl',
    dist_author         => 'Jérôme Fenal <jerome@fenal.org>',
    dist_version_from   => 'lib/POSIX/Account/LDAP.pm',
    build_requires => {
        'Test::More' => 0,
        'Net::LDAP' => 0,
        'Config::Simple' => 0,
        'Log::Dispatch' => 0,
    },
    recommends => {
        'Test::Pod' => 0,
        'Test::Pod::Coverage' => 0,
    },
    add_to_cleanup      => [ 'POSIX-Account-LDAP-*' ],
);

$builder->create_build_script();
