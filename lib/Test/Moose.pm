package Test::Moose;

use Exporter;
use Moose::Util qw/can_role/;
use Test::Builder;

use strict;
use warnings;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

our @EXPORT = qw/can_role/;

my $tester = Test::Builder->new;

sub import {
  my $class = shift;

  if (@_) {
    my $package = caller;
    
    $tester->exported_to ($package);

    $tester->plan (@_);
  }

  @_ = ($class);

  goto &Exporter::import;
}

sub does_ok ($$;$) {
  my ($class,$does,$name) = @_;

  return $tester->ok (can_role ($class,$does),$name)
}

1;

__END__

=pod

=head1 NAME

Test::Moose - Test functions for Moose specific features

=head1 SYNOPSIS

  use Test::Moose plan => 1;

  does_ok ($class,$role,"Does $class do $role");

=head1 TESTS

=over 4

=item does_ok

  does_ok ($class,$role,$name);

Tests if a class does a certain role, similar to what isa_ok does for
isa.

=back

=head1 SEE ALSO

=over 4

=item L<Test::More>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

