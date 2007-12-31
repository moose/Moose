package Moose::Meta::Role::Application;

use strict;
use warnings;
use metaclass;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub new { (shift)->meta->new_object(@_) }

sub apply {
    my $self = shift;

    $self->check_role_exclusions(@_);
    $self->check_required_methods(@_);
    $self->check_required_attributes(@_);
    
    $self->apply_attributes(@_);
    $self->apply_methods(@_);    
    
    $self->apply_override_method_modifiers(@_);
    
    $self->apply_before_method_modifiers(@_);
    $self->apply_around_method_modifiers(@_);
    $self->apply_after_method_modifiers(@_);
}

sub check_role_exclusions           { die "Abstract Method" }
sub check_required_methods          { die "Abstract Method" }
sub check_required_attributes       { die "Abstract Method" }

sub apply_attributes                { die "Abstract Method" }
sub apply_methods                   { die "Abstract Method" }
sub apply_override_method_modifiers { die "Abstract Method" }
sub apply_method_modifiers          { die "Abstract Method" }

sub apply_before_method_modifiers   { (shift)->apply_method_modifiers('before' => @_) }
sub apply_around_method_modifiers   { (shift)->apply_method_modifiers('around' => @_) }
sub apply_after_method_modifiers    { (shift)->apply_method_modifiers('after'  => @_) }

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role::Application

=head1 DESCRIPTION

This is the abstract base class for role applications.

=head2 METHODS

=over 4

=item B<new>

=item B<meta>

=item B<apply>

=item B<check_role_exclusions>

=item B<check_required_methods>

=item B<check_required_attributes>

=item B<apply_attributes>

=item B<apply_methods>

=item B<apply_method_modifiers>

=item B<apply_before_method_modifiers>

=item B<apply_after_method_modifiers>

=item B<apply_around_method_modifiers>

=item B<apply_override_method_modifiers>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

