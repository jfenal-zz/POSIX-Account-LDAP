#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan skip_all => "Do no test Test::Pod::Coverage if not defined TEST_KWALITEE"
  if not defined $ENV{TEST_KWALITEE};
all_pod_coverage_ok();

