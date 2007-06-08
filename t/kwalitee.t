#!perl -T

use Test::More;

plan( skip_all => "Do no test Kwalitee if not defined TEST_KWALITEE")
  if not defined $ENV{TEST_KWALITEE};
eval {
    require Test::Kwalitee;
    Test::Kwalitee->import( tests =>
        [ qw( -has_test_pod -has_test_pod_coverage ) ]
        );
};

plan( skip_all => 'Test::Kwalitee not installed; skipping') if $@;
