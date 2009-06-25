
package Moose::AttributeHelpers::Trait::Base;
use Moose::Role;
use Moose::Util::TypeConstraints;

our $VERSION   = '0.19';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

requires 'helper_type';

# these next two are the possible methods
# you can use in the 'handles' map.

# provide a Class or Role which we can
# collect the method providers from

# requires_attr 'method_provider'

# or you can provide a HASH ref of anon subs
# yourself. This will also collect and store
# the methods from a method_provider as well
has 'method_constructors' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return +{} unless $self->has_method_provider;
        # or grab them from the role/class
        my $method_provider = $self->method_provider->meta;
        return +{
            map {
                $_ => $method_provider->get_method($_)
            } $method_provider->get_method_list
        };
    },
);

# extend the parents stuff to make sure
# certain bits are now required ...
has '+default'         => (required => 1);
has '+type_constraint' => (required => 1);

## Methods called prior to instantiation

sub process_options_for_handles {
    my ($self, $options) = @_;

    if (my $type = $self->helper_type) {
        (exists $options->{isa})
            || confess "You must define a type with the $type metaclass";

        my $isa = $options->{isa};

        unless (blessed($isa) && $isa->isa('Moose::Meta::TypeConstraint')) {
            $isa = Moose::Util::TypeConstraints::find_or_create_type_constraint($isa);
        }

        ($isa->is_a_type_of($type))
            || confess "The type constraint for a $type ($options->{isa}) must be a subtype of $type";
    }
}

before '_process_options' => sub {
    my ($self, $name, $options) = @_;
    $self->process_options_for_handles($options, $name);
};

## methods called after instantiation

sub check_handles_values {
    my $self = shift;

    my $method_constructors = $self->method_constructors;

    foreach my $key (keys %{$self->handles}) {
        (exists $method_constructors->{$key})
            || confess "$key is an unsupported method type";
    }

}

after 'install_accessors' => sub {
    my $attr  = shift;
    my $class = $attr->associated_class;

    # grab the reader and writer methods
    # as well, this will be useful for
    # our method provider constructors
    my $attr_reader = $attr->get_read_method_ref;
    my $attr_writer = $attr->get_write_method_ref;

    # before we install them, lets
    # make sure they are valid
    $attr->check_handles_values;

    my $method_constructors = $attr->method_constructors;

    my $class_name = $class->name;

    foreach my $key (keys %{$attr->handles}) {

        my $method_name = $attr->handles->{$key};

        if ($class->has_method($method_name)) {
            confess "The method ($method_name) already exists in class (" . $class->name . ")";
        }

        my $method = Moose::AttributeHelpers::Meta::Method::Provided->wrap(
            $method_constructors->{$key}->(
                $attr,
                $attr_reader,
                $attr_writer,
            ),
            package_name => $class_name,
            name => $method_name,
        );

        $attr->associate_method($method);
        $class->add_method($method_name => $method);
    }
};

after 'remove_accessors' => sub {
    my $attr  = shift;
    my $class = $attr->associated_class;

    # provides accessors
    foreach my $key (keys %{$attr->handles}) {
        my $method_name = $attr->handles->{$key};
        my $method = $class->get_method($method_name);
        $class->remove_method($method_name)
            if blessed($method) &&
               $method->isa('Moose::AttributeHelpers::Meta::Method::Provided');
    }
};

no Moose::Role;
no Moose::Util::TypeConstraints;

1;

__END__

=head1 NAME

Moose::AttributeHelpers::Trait::Base - base role for helpers

=head1 METHODS

=head2 check_handles_values

Confirms that handles has all valid possibilities in it.

=head2 process_options_for_handles

Ensures that the type constraint (C<isa>) matches the helper type.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHORS

Yuval Kogman

Shawn M Moore

Jesse Luehrs

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
