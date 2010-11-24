package Test::Moose;

use strict;
use warnings;

use Sub::Exporter;
use Test::Builder;

use List::MoreUtils 'all';
use Moose::Util 'does_role', 'find_meta';

our $VERSION   = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

my @exports = qw[
    meta_ok
    does_ok
    has_attribute_ok
    with_immutable
];

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { default => \@exports }
});

## the test builder instance ...

my $Test = Test::Builder->new;

## exported functions

sub meta_ok ($;$) {
    my ($class_or_obj, $message) = @_;

    $message ||= "The object has a meta";

    if (find_meta($class_or_obj)) {
        return $Test->ok(1, $message)
    }
    else {
        return $Test->ok(0, $message);
    }
}

sub does_ok ($$;$) {
    my ($class_or_obj, $does, $message) = @_;

    $message ||= "The object does $does";

    if (does_role($class_or_obj, $does)) {
        return $Test->ok(1, $message)
    }
    else {
        return $Test->ok(0, $message);
    }
}

sub has_attribute_ok ($$;$) {
    my ($class_or_obj, $attr_name, $message) = @_;

    $message ||= "The object does has an attribute named $attr_name";

    my $meta = find_meta($class_or_obj);

    if ($meta->find_attribute_by_name($attr_name)) {
        return $Test->ok(1, $message)
    }
    else {
        return $Test->ok(0, $message);
    }
}

sub with_immutable (&@) {
    my $block = shift;
    my $before = $Test->current_test;
    $block->();
    Class::MOP::class_of($_)->make_immutable for @_;
    $block->();
    my $num_tests = $Test->current_test - $before;
    return all { $_ } ($Test->summary)[-$num_tests..-1];
}

1;

__END__

=pod

=head1 NAME

Test::Moose - Test functions for Moose specific features

=head1 SYNOPSIS

  use Test::More plan => 1;
  use Test::Moose;

  meta_ok($class_or_obj, "... Foo has a ->meta");
  does_ok($class_or_obj, $role, "... Foo does the Baz role");
  has_attribute_ok($class_or_obj, $attr_name, "... Foo has the 'bar' attribute");

=head1 DESCRIPTION

This module provides some useful test functions for Moose based classes. It
is an experimental first release, so comments and suggestions are very welcome.

=head1 EXPORTED FUNCTIONS

=over 4

=item B<meta_ok ($class_or_object)>

Tests if a class or object has a metaclass.

=item B<does_ok ($class_or_object, $role, ?$message)>

Tests if a class or object does a certain role, similar to what C<isa_ok>
does for the C<isa> method.

=item B<has_attribute_ok($class_or_object, $attr_name, ?$message)>

Tests if a class or object has a certain attribute, similar to what C<can_ok>
does for the methods.

=item B<with_immutable { CODE } @class_names>

Runs B<CODE> (which should contain normal tests) twice, and make each
class in C<@class_names> immutable in between the two runs.

=back

=head1 TODO

=over 4

=item Convert the Moose test suite to use this module.

=item Here is a list of possible functions to write

=over 4

=item immutability predicates

=item anon-class predicates

=item discovering original method from modified method

=item attribute metaclass predicates (attribute_isa?)

=back

=back

=head1 SEE ALSO

=over 4

=item L<Test::More>

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

