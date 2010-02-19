package MetaTest;

use strict;
use warnings;

use Exporter 'import';
use Class::MOP;
use Test::More;
use Carp 'confess';
our @EXPORT = qw{skip_meta meta_can_ok skip_all_meta};

if (skip_meta_condition()) {
   my $die_method = sub { confess 'meta should never be called!' };
   for (Class::MOP::get_all_metaclass_instances) {
      if ($_->is_immutable) {
         my %o = $_->immutable_options;
         # the following break since they apparently use ->meta
         # How does that even make sense?

         #$_->make_mutable;
         #$_->add_method(meta => $die_method);
         #$_->make_immutable(%o);
      } else {
         $_->add_method(meta => $die_method);
      }
   }
}

sub SKIP_META_MESSAGE() {
   'meta-tests disabled';
}

sub skip_meta_condition {
   $ENV{SKIP_META_TESTS};
}

sub skip_all_meta {
   my $plan = shift;
    plan skip_all => SKIP_META_MESSAGE if skip_meta_condition;
    plan tests => $plan;
}

sub skip_meta (&$) {
   my $fn = shift;
   my $amount = shift;
   local $Test::Builder::Level = $Test::Builder::Level + 1;
   SKIP: {
      local $Test::Builder::Level = $Test::Builder::Level + 1;
      skip SKIP_META_MESSAGE, $amount if skip_meta_condition;
      $fn->();
   };
}

sub meta_can_ok {
   my $class = shift;
   my $method = shift;
   my $message = shift;
   local $Test::Builder::Level = $Test::Builder::Level + 1;
   skip_meta {
      local $Test::Builder::Level = $Test::Builder::Level + 1;
      ok($class->meta->has_method($method), $message);
   } 1;
   ok($class->can($method), $message);
}

1;
