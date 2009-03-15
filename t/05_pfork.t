#!perl -w
use strict;
use Test::More;
use POE::XS::Queue::Array;
use Config;

$^O eq 'MSWin32'
  or plan skip_all => "You probably have a sane fork(), not testing";

$Config{useithreads} && $Config{useithreads} eq 'define'
  or plan skip_all => "No ithreads to support pseudo-fork";

plan tests => 2;

{
  my $q1 = POE::XS::Queue::Array->new;
  $q1->enqueue(100, 101);
  if (!fork) {
    # child
    is($q1, undef, "queue object should be magically undef");
    exit;
  }
  isa_ok($q1, "POE::XS::Queue::Array", "parent should still have an object");
}
