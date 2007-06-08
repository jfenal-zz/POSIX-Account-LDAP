use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POSIX::Account::LDAP',
    AUTHOR              => 'Jérôme Fenal <jerome@fenal.org>',
    VERSION_FROM        => 'lib/POSIX/Account/LDAP.pm',
    ABSTRACT_FROM       => 'lib/POSIX/Account/LDAP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::LDAP' => 0,
        'Config::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POSIX-Account-LDAP-*' },
);
