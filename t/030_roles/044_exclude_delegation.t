use strict;
use warnings;
use Test::More;

my $ok = eval {
  {
    package R;
    use Moose::Role;

    has foo => (is => 'ro', handles => [ 'bar' ]);
  }

  {
    package C;
    use Moose;
    with 'R' => { -excludes => 'bar' };
    sub bar { 1 }
  }
  1;
};

my $error = $@;
ok($ok, "we can compose");
unlike($error, qr{delegation}, "error is undef, right? so no delegate error");

done_testing;
