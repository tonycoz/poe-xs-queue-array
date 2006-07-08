#!/usr/bin/perl -w
use POE::XS::Queue::Array;
my $q = POE::XS::Queue::Array->new;
# or
#use POE::Queue::Array;
#my $q = POE::Queue::Array->new;

print "inital: \n";
system "ps -o rss -p $$";
for (1..2000){
my $id = $q->enqueue($_ % 4, "payload $_");
$q->dequeue_next;
}
system "ps -o rss -p $$";
for (1..2000){
my $id = $q->enqueue($_ % 4, "payload $_");
$q->dequeue_next;
}
system "ps -o rss -p $$";

