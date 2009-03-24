package Moose::Meta::Role::Application;

use strict;
use warnings;
use metaclass;

our $VERSION   = '0.72';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

__PACKAGE__->meta->add_attribute('method_exclusions' => (
    init_arg => 'excludes',
    reader   => 'get_method_exclusions',
    default  => sub { [] }
));

__PACKAGE__->meta->add_attribute('method_aliases' => (
    init_arg => 'alias',
    reader   => 'get_method_aliases',
    default  => sub { {} }
));

sub new { 
    my ($class, %params) = @_;
    
    if (exists $params{excludes}) {
        # I wish we had coercion here :)
        $params{excludes} = (ref $params{excludes} eq 'ARRAY' 
                                ? $params{excludes} 
                                : [ $params{excludes} ]);
    }
    
    $class->_new(\%params);
}

sub is_method_excluded {
    my ($self, $method_name) = @_;
    foreach (@{$self->get_method_exclusions}) {
        return 1 if $_ eq $method_name;
    }
    return 0;
}

sub is_method_aliased {
    my ($self, $method_name) = @_;
    exists $self->get_method_aliases->{$method_name} ? 1 : 0
}

sub is_aliased_method {
    my ($self, $method_name) = @_;
    my %aliased_names = reverse %{$self->get_method_aliases};
    exists $aliased_names{$method_name} ? 1 : 0;
}

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

sub check_role_exclusions           { Carp::croak "Abstract Method" }
sub check_required_methods          { Carp::croak "Abstract Method" }
sub check_required_attributes       { Carp::croak "Abstract Method" }

sub apply_attributes                { Carp::croak "Abstract Method" }
sub apply_methods                   { Carp::croak "Abstract Method" }
sub apply_override_method_modifiers { Carp::croak "Abstract Method" }
sub apply_method_modifiers          { Carp::croak "Abstract Method" }

sub apply_before_method_modifiers   { (shift)->apply_method_modifiers('before' => @_) }
sub apply_around_method_modifiers   { (shift)->apply_method_modifiers('around' => @_) }
sub apply_after_method_modifiers    { (shift)->apply_method_modifiers('after'  => @_) }

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role::Application - A base class for role application

=head1 DESCRIPTION

This is the abstract base class for role applications. Role
application is the logic of composing a role into something. That
something could be a class, another role, or an object instance.

=head2 METHODS

=over 4

=item B<< Moose::Meta::Role::Application->new(%options) >>

This method returns a new role application. It accepts several
options:

=over 8

=item * excludes

This is an optional array reference of methods to be excluded when
applying the role.

=item * alias

This is an optional hash reference of methods to be renamed when
applying the role. The keys are the original method names, and the
values are the new method names.

=back

Note that the constructor does not actually take any roles as
arguments.

=item B<< $application->get_method_exclusions >>

Returns an array reference containing the names of the excluded
methods.

=item B<< $application->is_method_excluded($method_name) >>

Given a method name, returns true if the method is excluded.

=item B<< $application->get_method_aliases >>

Returns the hash reference of method aliases passed to the
constructor.

=item B<< $application->is_aliased_method($method_name) >>

This takes the name of the original method, and returns true if it is
aliased.

=item B<< $application->is_method_aliased($method_name) >>

Returns true if the method name given is being used as the I<new> name
for any method.

=item B<< $application->apply($role, $thing) >>

This method implements the logic of role application by calling the
various check and apply methods below. Any arguments passed to this
method are simply passed on to the other methods, without any
processing.

The first argument is always a L<Moose::Meta::Role> object, and the
second is the thing to which the role is being applied.

In some cases, the second

=item B<< $application->check_role_exclusions(...) >>

A virtual method. Subclasses are expected to throw an error if 

=item B<check_required_methods>

=item B<check_required_attributes>

=item B<apply_attributes>

=item B<apply_methods>

=item B<apply_method_modifiers>

=item B<apply_before_method_modifiers>

=item B<apply_after_method_modifiers>

=item B<apply_around_method_modifiers>

=item B<apply_override_method_modifiers>

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

