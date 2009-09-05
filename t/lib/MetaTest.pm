package MetaTest;

use Exporter 'import';
use Test::More;
our @EXPORT = qw{skip_meta meta_can_ok};

sub skip_meta (&$) {
   my $fn = shift;
   my $amount = shift;
   local $Test::Builder::Level = $Test::Builder::Level + 1;
   SKIP: {
      local $Test::Builder::Level = $Test::Builder::Level + 1;
      skip 'meta-tests disabled', $amount if $ENV{SKIP_META_TESTS};
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
