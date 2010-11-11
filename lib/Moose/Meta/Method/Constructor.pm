
package Moose::Meta::Method::Constructor;

use strict;
use warnings;

use Carp ();
use Scalar::Util 'blessed', 'weaken', 'looks_like_number', 'refaddr';
use Try::Tiny;

our $VERSION   = '1.19';
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Constructor';

sub new {
    my $class   = shift;
    my %options = @_;

    my $meta = $options{metaclass};

    (ref $options{options} eq 'HASH')
        || $class->throw_error("You must pass a hash of options", data => $options{options});

    ($options{package_name} && $options{name})
        || $class->throw_error("You must supply the package_name and name parameters $Class::MOP::Method::UPGRADE_ERROR_TEXT");

    my $self = bless {
        'body'          => undef,
        'package_name'  => $options{package_name},
        'name'          => $options{name},
        'options'       => $options{options},
        'associated_metaclass' => $meta,
        '_expected_method_class' => $options{_expected_method_class} || 'Moose::Object',
    } => $class;

    # we don't want this creating
    # a cycle in the code, if not
    # needed
    weaken($self->{'associated_metaclass'});

    $self->_initialize_body;

    return $self;
}

## method

sub _initialize_body {
    my $self = shift;
    $self->{'body'} = $self->_generate_constructor_method_inline;
}

sub _eval_environment {
    my $self = shift;

    my $attrs = $self->_attributes;

    my $defaults = [map { $_->default } @$attrs];

    # We need to check if the attribute ->can('type_constraint')
    # since we may be trying to immutabilize a Moose meta class,
    # which in turn has attributes which are Class::MOP::Attribute
    # objects, rather than Moose::Meta::Attribute. And
    # Class::MOP::Attribute attributes have no type constraints.
    # However we need to make sure we leave an undef value there
    # because the inlined code is using the index of the attributes
    # to determine where to find the type constraint

    my @type_constraints = map {
        $_->can('type_constraint') ? $_->type_constraint : undef
    } @$attrs;

    my @type_constraint_bodies = map {
        defined $_ ? $_->_compiled_type_constraint : undef;
    } @type_constraints;

    return {
        '$meta'  => \$self,
        '$attrs' => \$attrs,
        '$defaults' => \$defaults,
        '@type_constraints' => \@type_constraints,
        '@type_constraint_bodies' => \@type_constraint_bodies,
    };
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Method::Constructor - Method Meta Object for constructors

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Method::Constructor> that
provides additional Moose-specific functionality

To understand this class, you should read the the
L<Class::MOP::Method::Constructor> documentation as well.

=head1 INHERITANCE

C<Moose::Meta::Method::Constructor> is a subclass of
L<Moose::Meta::Method> I<and> L<Class::MOP::Method::Constructor>.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHORS

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

