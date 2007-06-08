package POSIX::Account::LDAP;

use warnings;
use strict;
use Carp;
use Config::Simple;
use Data::Dumper;
use Net::LDAP;
use Log::Dispatch;
use Log::Dispatch::File;
use Log::Dispatch::Syslog;

our @ISA    = qw( Exporter );
our @EXPORT = qw( &ldapconnect &findnextuid &useradd &groupadd );

=head1 NAME

POSIX::Account::LDAP - LDAP posixAccount, posixGroup, netgroup, etc. management

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

POSIX::Account::LDAP gives you an extensive API to manage POSIX accounts
in a LDAP directory.

    use POSIX::Account::LDAP;

    my $foo = POSIX::Account::LDAP->new( { config => "mysite.cfg" } );
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 new

Create a new object 

Options:

  * config : configuration file name
  * init : load configuration if 


=cut

sub new
{
    my ( $class, $arg_ref ) = @_;
#    $class = ref($class) || $class;

    $arg_ref->{init}=1 if not defined $arg_ref->{init};

    my %valarg = ( config => 1, init => 1 );

    foreach my $v (keys %{$arg_ref} ) {
        croak "Unknown parameter $v" if not exists $valarg{$v};
    }
        
    my $self = {};
    bless $self, $class;

    foreach my $f ( "/etc/pal.conf", "$ENV{HOME}/.pal.conf" ) {
        if ( -r $f ) {
            $self->{configfile} = $f;
        }
    }
    if (defined( $arg_ref->{config} ) ) {
        $self->{configfile} = $arg_ref->{config};
        my %c;
        if (-f $self->{configfile}) {
            Config::Simple->import_from( $self->{configfile}, \%c);
            foreach my $i (keys %c) {
                    # Don't flatten ref to ARRAYS by untainting
                    if (ref($c{$i}) eq 'SCALAR' && $c{$i} =~ m/(.+)/) {
                        $c{$i} = $1;
                    }
            }
        }

        $self->{config} = \%c;
    }

    $self->{logger} = Log::Dispatch->new;
    if ( defined($self->{config}->{'logging.level'} )
      && defined($self->{config}->{'logging.file'}) ) {

        $self->{logger}->add(
            Log::Dispatch::File->new(
                name      => 'file1',
                min_level => $self->{config}->{'logging.level'},
                filename  => $self->{config}->{'logging.file'},
            )
        );
    }
    else {
        $self->{logger}->add(
            Log::Dispatch::Syslog->new(
                name      => 'syslog1',
                min_level => 'debug',
                ident     => 'POSIX::Account::LDAP',
            )
        );
    }
     
    if (defined( $arg_ref->{init} ) && $arg_ref->{init} ) {
        $self->init();
    }

    $self;
}

=head2 init

Initialise the object by:

* read configuration
* start LDAP connection

=cut

sub init
{
    my ( $self, @args ) = @_;

    $self->ldapconnect;

    1;
}

=head2 ldapconnect

Connect to the directory using the configuration.

=cut

sub ldapconnect {
    my ($self, @args) = @_;
    
    croak "LDAP parameters not defined"
      if ! defined($self->{config}->{'directory.host'} )
      || ! defined($self->{config}->{'directory.port'})
      || ! defined($self->{config}->{'directory.managerdn'})
      || ! defined($self->{config}->{'directory.managerpw'});

    # Connexion à l'annuaire
    $self->{ldap} = Net::LDAP->new( $self->{config}->{'directory.host'},
        defined( $self->{config}->{'directory.port'} )
        ? ( port => $self->{config}->{'directory.port'} )
        : () )
      or croak "$@";

    $self->{logger}->log(level=>'info', message=>"ldapconnect: connected to directory, $self->{config}->{'directory.host'}, $self->{config}->{'directory.port'}");

    # Authentification auprès de l'annuaire
    my $mesg = $self->{ldap}->bind( $self->{config}->{'directory.managerdn'},
        password => $self->{config}->{'directory.managerpw'} );
    $mesg->code && die $mesg->error;

    $self->{logger}->log(level=>'info', message=>"ldapconnect: authenticated to directory");

    return $self->{ldap};
}

=head2 findnextuid

Find next uid within Configured min & max uid numbers

=cut
sub findnextuid {
    my ($self, $arg_ref) = @_;
    my $minuid = $self->{config}->{'posixaccount.minuid'};
    my $maxuid = $self->{config}->{'posixaccount.maxuid'};
    
    $minuid = $minuid > $arg_ref->{minid} ? $minuid : $arg_ref->{minid}
      if defined $arg_ref->{minid};
    
    my $min = $minuid;

    # find lowest uid via name service switch
#    foreach my $i ($minuid .. $maxuid) {
#        if ( !getpwuid($i) ) {
#            $min = $i;
#            last;
#        }
#    }

    # find lowest uid (greater than lowest system uid) in LDAP
    while (
        $self->{ldap}->search(
            base   => $self->{config}->{'directory.base'},
            filter => "(&(objectclass=posixaccount)(uidnumber=$min))",
        )->count != 0
      )
    {
        $min++;
    }

    croak "No more free gid within range" if $min > $maxuid;
#print STDERR "Lowest free uid: $min\n";

    # we now have the lowest free uid...
    return $min;
}

=head2 findnextgid

Find next gid within Configured min & max gid numbers

=cut
sub findnextgid {
    my ($self, $arg_ref) = @_;
    my $mingid = $self->{config}->{'posixaccount.minuid'};
    my $maxgid = $self->{config}->{'posixaccount.maxuid'};

    $mingid = $mingid > $arg_ref->{minid} ? $mingid : $arg_ref->{minid}
      if defined $arg_ref->{minid};
    
    my $min = $mingid;

    # find lowest uid via name service switch
#    foreach my $i ($minuid .. $maxuid) {
#        if ( !getpwuid($i) ) {
#            $min = $i;
#            last;
#        }
#    }

    # find lowest gid (greater than lowest system gid) in LDAP
    while (
        $self->{ldap}->search(
            base   => $self->{config}->{'directory.base'},
            filter => "(&(objectclass=posixaccount)(gidnumber=$min))",
        )->count != 0
      )
    {
        $min++;
    }

    croak "No more free gid within range" if $min > $maxgid;
#print STDERR "Lowest free uid: $min\n";

    # we now have the lowest free uid...
    return $min;
}

=head2 findnextxid

Find next id in uid and gid number spaces.

=cut
sub findnextxid {
    my ($self, $arg_ref) = @_;

    my $minuid = $self->{config}->{'posixaccount.minuid'};
    my $mingid = $self->{config}->{'posixaccount.mingid'};
    my $maxuid = $self->{config}->{'posixaccount.maxuid'};
    my $maxgid = $self->{config}->{'posixaccount.maxgid'};
    
    # min
    my $maxxid = $maxuid < $maxgid ? $maxuid : $maxgid;
    # max
    my $minxid = $minuid > $mingid ? $minuid : $mingid;
    $minxid = $minxid > $arg_ref->{minid} ? $minxid : $arg_ref->{minid}
      if defined $arg_ref->{minid};
    
    my $uid=0;
    my $gid=1;  # must be different!!
    while ($gid != $uid) {
        $uid = $self->findnextuid( { minid => $minxid } );
        $gid = $self->findnextgid( { minid => $minxid } );

    #    last NEXTXID if $gid == $uid;

        $minxid = $uid > $gid ? $uid : $gid ;
        $minxid++;
    }

    $minxid = $uid; # or $gid :)

    croak "No more free gid within range" if $minxid > $maxxid;

#print STDERR "Lowest free gid: $min\n";
    # we now have the lowest free gid...
    return $minxid;
}

=head2 useradd( { name => $name , %opts } )

Add a user.

Acceptable named options:

=over

=item * create_group => 1

If present, this option will call groupadd() to create a new group
having a gidNumber equal to the user account uidNumber.

=item * uid => "name"

Name of the user (usually less than 8 characters), ASCII only.

=item * gecos 

GECOS field (ASCII only).

Defaults to "Charlie uid".

=item * loginShell

Shell to give to the user. Defaults to C</bin/sh>.

=item * userPassword  

Self descriptive.

=item * uidNumber 

uid of the user account (numeric).

=item * gidNumber

gid of the user account (numeric).

The group having this gid must exist prior to creation.

=item * cn

More descriptive name. Will default to uid.

=item * sn     

More descriptive name. Will default to uid.

=item * description

Description of the user account (not used by POSIX, but by LDAP).

Defaults to "System User uid".

=item * homeDirectory

Home directory of the user account.

Defaults to "/home/uid".

=back

=cut
my %uattrdefaults = (
    gecos         => "Charlie %u",
    loginShell    => "/bin/sh",
#    userPassword  => "",
    uid           => "%u",
    uidNumber     => "1000",
    gidNumber     => "1000",
    cn            => "%u",
    sn            => "%u",
    description   => "System User %u",
    homeDirectory => "/home/%u",
);


sub useradd
{
    my ($self, $arg_ref) = @_; # paramètres de la sub

#    print STDERR "name : $name\n";
    my $filt = $self->{config}->{'posixaccount.filter'};

    croak "No uid given" if not defined($arg_ref->{uid});

    # LDAP search filter
    $filt =~ s/%u/$arg_ref->{uid}/g;

    my $org = $self->{config}->{'posixaccount.defaultorg'};
    $org = $arg_ref->{org} if defined $arg_ref->{org};

    my $mesg = $self->{ldap}->search(    # perform a search
        base   => $self->{config}->{'directory.base'},
        filter => $filt,
    );

    $mesg->code && die $mesg->error;

    croak "Entry $filt already exists" if scalar $mesg->all_entries;

    my %attrs = (%uattrdefaults);

    # expansion de la macro %u en le nom de l'utilisateur
    foreach my $attr ( keys %uattrdefaults ) {
        $attrs{$attr} =~ s/%u/$arg_ref->{uid}/g;
    }
    # recuperer
    foreach my $attr ( keys %uattrdefaults ) {
        $attrs{$attr} = $arg_ref->{$attr}
            if defined( $arg_ref->{$attr} );
        $attrs{$attr} =~ s/%u/$arg_ref->{uid}/g;
    }

    # recherche de l'uid mini
    my $uidnum = $self->findnextuid();

    $attrs{uidNumber}  = $attrs{gidNumber} = $uidnum;

#    delete  $attrs{userPassword};
#print "password $attrs{userPassword}\n";

#print STDERR Dumper(\%attrs);
#print STDERR Dumper($self->{config}{'posixaccount.objectclass'});
#print STDERR "uid=$name, $self->{config}{'posixaccount.peopleou'}, o=$org, $self->{config}{'directory.base'}\n";

#print Dumper \%attrs;
#print Dumper $self->{config};

    $mesg = $self->{ldap}->add(
        "uid=$arg_ref->{uid}, $self->{config}->{'posixaccount.peopleou'}, o=$org, $self->{config}->{'directory.base'}",
        attr => [
            'objectClass' => $self->{config}->{'posixaccount.objectclass'} ,
            (%attrs),
        ]
    );

    $mesg->code && die $mesg->error;

    1;
}

=head2 userdel( { uid => $name } )

Delete a user by name.

=cut 

sub userdel
{
    my ($self, $arg_ref) = @_;

    my %valarg = ( uid => 1 );

    foreach my $v (keys %{$arg_ref} ) {
        croak "Unknown parameter $v" if not exists $valarg{$v};
    }
    croak "Must pass a uid (username) to userdel" if not defined $arg_ref->{uid};
        
    my $filt = $self->{config}->{'posixaccount.filter'};
    $filt =~ s/%u/$arg_ref->{uid}/g;

    # perform a search
    my $mesg = $self->{ldap}->search(
        base   => $self->{config}->{'directory.base'},
        filter => $filt,
    );

    $mesg->code && die $mesg->error;

#    print Dumper \$mesg;
    my $entry= $mesg->entry(0);

    if (defined($entry)) {
        my $dn = $entry->dn();

#    print STDERR "Entry to delete $dn \n";

        $mesg = $self->{ldap}->delete( $dn );
        $mesg->code && die $mesg->error;
    }

    return 1;
}

=head2 groupadd( { name => $name, %opts } )

Add a group.

Acceptable named options:

=over

=item * name

=item * gidNumber

gid number of the POSIX group (numeric).
Fail if that gid is not available.

Defaults at next available gid starting from 1000.

=item * description

LDAP relevant information, not used directly by POSIX.

=back

=cut 

my %gattrdefaults = (
    gidNumber     => "1000",
    description   => "System group %g",
);

sub groupadd
{
    my ($self, $arg_ref) = @_;

    my %valarg = ( name => 1, gidNumber => 1 );

    foreach my $v (keys %{$arg_ref} ) {
        croak "Unknown parameter $v" if not exists $valarg{$v};
    }
    croak "Must pass a name to groupadd" if not defined $arg_ref->{name};

    my $filt = $self->{config}->{'posixgroup.filter'};
    $filt =~ s/%g/$arg_ref->{name}/g;

    my $org = $self->{config}->{'posixgroup.defaultorg'};
    $org = $arg_ref->{org} if defined $arg_ref->{org};

    my $mesg = $self->{ldap}->search(    # perform a search
        base   => $self->{config}->{'directory.base'},
        filter => $filt,
    );

    $mesg->code && die $mesg->error;

    croak "Entry $filt already exists" if scalar $mesg->all_entries;

    my %attrs = (%gattrdefaults);

    # expansion de la macro %g en le nom de groupe
    foreach my $attr ( keys %gattrdefaults ) {
        $attrs{$attr} =~ s/%g/$arg_ref->{name}/g;
    }
    # recuperer
    foreach my $attr ( keys %gattrdefaults ) {
        $attrs{$attr} = $arg_ref->{$attr}
            if defined( $arg_ref->{$attr} );
    }

    # recherche de l'uid mini
    if (defined( $arg_ref->{gidNumber} ) ) {
        $attrs{gidNumber} = $arg_ref->{gidNumber};
    } else {
        $attrs{gidNumber} = $self->findnextgid();
    }

#print STDERR Dumper(\%attrs);
#print STDERR Dumper($self->{config}{'posixaccount.objectclass'});
#print STDERR "uid=$name, $self->{config}{'posixaccount.peopleou'}, o=$org, $self->{config}{'directory.base'}\n";

#print STDERR  "cn=$arg_ref->{name}, $self->{config}->{'posixgroup.groupou'}, o=$org, $self->{config}->{'directory.base'}", "\n";
    $mesg = $self->{ldap}->add(
        "cn=$arg_ref->{name}, $self->{config}->{'posixgroup.groupou'}, o=$org, $self->{config}->{'directory.base'}",
        attr => [
            'cn' => $arg_ref->{name},
            'objectClass' => $self->{config}->{'posixgroup.objectclass'} ,
            (%attrs),
        ]
    );

    $mesg->code && die $mesg->error;

    1;
}

=head2 groupdel( { name => $name } )

Delete a group

=cut 

sub groupdel
{
    my ($self, $arg_ref) = @_;

    my %valarg = ( name => 1 );

    foreach my $v (keys %{$arg_ref} ) {
        croak "Unknown parameter $v" if not exists $valarg{$v};
    }
    croak "Must pass a name to groupdel" if not defined $arg_ref->{name};
        
    my $filt = $self->{config}->{'posixgroup.filter'};
    $filt =~ s/%g/$arg_ref->{name}/g;

    # perform a search
    my $mesg = $self->{ldap}->search(
        base   => $self->{config}->{'directory.base'},
        filter => $filt,
    );

    $mesg->code && die $mesg->error;

    my $dn = $mesg->entry(0)->dn();

#    print STDERR "Entry to delete $dn \n";

    $mesg = $self->{ldap}->delete( $dn );
    $mesg->code && die $mesg->error;

    return 1;
}


=head2 DESTROY

Not to be used directly, will be called when uninstantiating a
POSIX::Account::LDAP object, mainly to disconnect from the LDAP
directory.

=cut

sub DESTROY
{
    my ($self) = @_;

    if ( defined($self->{ldap} ) ) {
        $self->{ldap}->unbind();
        delete $self->{ldap};
    }
}



=head1 AUTHOR

Jérôme Fenal, C<< <jerome at fenal.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-posix-account-ldap at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POSIX-Account-LDAP>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POSIX::Account::LDAP

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POSIX-Account-LDAP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POSIX-Account-LDAP>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POSIX-Account-LDAP>

=item * Search CPAN

L<http://search.cpan.org/dist/POSIX-Account-LDAP>

=back

=head1 ACKNOWLEDGEMENTS

The Perl community for all those valuable tools that helped creating
these module and scripts.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jérôme Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of POSIX::Account::LDAP
