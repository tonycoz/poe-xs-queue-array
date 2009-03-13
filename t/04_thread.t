#!perl -w
use strict;
use threads;
use Test::More;
use Config;
use POE::XS::Queue::Array;

$| =1;

$Config{useithreads} && $Config{useithreads} eq 'define'
  or plan skip_all => "No threads to test against";

plan tests => 28;

# check the weak ref logic
{
  is(POE::XS::Queue::Array::_active_refs(), 0, "start with none active");
  my $q1 = POE::XS::Queue::Array->new;
  is(POE::XS::Queue::Array::_active_refs(), 1, "one active");
  my $q2 = POE::XS::Queue::Array->new;
  is(POE::XS::Queue::Array::_active_refs(), 2, "two active");
  undef $q1;
  is(POE::XS::Queue::Array::_active_refs(), 1, "destroy one - one active");
  undef $q2;
  is(POE::XS::Queue::Array::_active_refs(), 0, "destroyed both - none active");
}

{
  # simple clone check
  my $q1 = POE::XS::Queue::Array->new;
  my $first_id = $q1->enqueue(100, 101);
  #print STDERR $q1;
  #$q1->dump;
  my $thread = threads->create
    (
     sub {
       #print STDERR $q1;
       #$q1->dump;
       my $second_id =$q1->enqueue(200, 201);
       is($second_id, 2, "check id of new item");
       my ($pri, $id, $pay) = $q1->dequeue_next;
       is($pri, 100, "check item queued first");
       is($id, $first_id, "check id");
       is($pay, 101, "check payload");

       ($pri, $id, $pay) = $q1->dequeue_next;
       is($pri, 200, "check item queued second");
       is($id, $second_id, "check id");
       is($pay, 201, "check payload");
       is($q1->get_item_count, 0, "should be empty");
     }
    );
  $thread->join;
  is($q1->get_item_count, 1, "only one item");
}

{
  # more complex clone check
  package Obj;
  our $created = 0;
  our $destroyed = 0;
  sub new {
    ++$created;
    my ($class, $id) = @_;
    print "# create $id in thread ", threads->tid, "\n";
    return bless \$id, $class;
  }
  sub id {
    ${$_[0]};
  }
  sub DESTROY { 
    my $self = shift;
    print "# destroy $$self in thread ", threads->tid, "\n";
    ++$destroyed;
  }

  package main;

  my $q1 = POE::XS::Queue::Array->new;
  my $first_id = $q1->enqueue(100, Obj->new(101));
  my $thread = threads->create
    (
     sub {
       my $second_id = $q1->enqueue(200, Obj->new(201));
       is($second_id, 2, "check id of new item");
       my ($pri, $id, $pay) = $q1->dequeue_next;
       is($pri, 100, "check item queued first");
       is($id, $first_id, "check id");
       is($pay->id, 101, "check payload");
       
       ($pri, $id, $pay) = $q1->dequeue_next;
       is($pri, 200, "check item queued second");
       is($id, $second_id, "check id");
       is($pay->id, 201, "check payload");
       is($q1->get_item_count, 0, "should be empty");
       undef $pay;
       is($Obj::created, 2, "2 objects created in thread");
       is($Obj::destroyed, 2, "2 objects destroyed in thread");
     }
    );
  $thread->join;
  is($q1->get_item_count, 1, "only 1 item left");
  is($Obj::created, 1, "1 objects created in main");
  is($Obj::destroyed, 0, "no objects destroyed in main");
  undef $q1;
  is($Obj::destroyed, 1, "1 objects destroyed in main after destroying queue");
}
