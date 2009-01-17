package Moose::Util;

use strict;
use warnings;

use Sub::Exporter;
use Scalar::Util 'blessed';
use Class::MOP   0.60;

our $VERSION   = '0.64';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

my @exports = qw[
    find_meta 
    does_role
    search_class_by_role   
    apply_all_roles
    get_all_init_args
    get_all_attribute_values
    resolve_metatrait_alias
    resolve_metaclass_alias
    add_method_modifier
    english_list
];

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { all => \@exports }
});

## some utils for the utils ...

sub find_meta { 
    return unless $_[0];
    return Class::MOP::get_metaclass_by_name(blessed($_[0]) || $_[0]);
}

## the functions ...

sub does_role {
    my ($class_or_obj, $role) = @_;

    my $meta = find_meta($class_or_obj);
    
    return unless defined $meta;
    return unless $meta->can('does_role');
    return 1 if $meta->does_role($role);
    return;
}

sub search_class_by_role {
    my ($class_or_obj, $role_name) = @_;
    
    my $meta = find_meta($class_or_obj);

    return unless defined $meta;

    foreach my $class ($meta->class_precedence_list) {
        
        my $_meta = find_meta($class);        

        next unless defined $_meta;

        foreach my $role (@{ $_meta->roles || [] }) {
            return $class if $role->name eq $role_name;
        }
    }

    return;
}

sub apply_all_roles {
    my $applicant = shift;

    Moose->throw_error("Must specify at least one role to apply to $applicant") unless @_;

    my $roles = Data::OptList::mkopt( [@_] );

    my $meta = ( blessed $applicant ? $applicant : find_meta($applicant) );

    foreach my $role_spec (@$roles) {
        Class::MOP::load_class( $role_spec->[0] );
    }

    ( $_->[0]->can('meta') && $_->[0]->meta->isa('Moose::Meta::Role') )
        || Moose->throw_error("You can only consume roles, "
        . $_->[0]
        . " is not a Moose role")
        foreach @$roles;

    if ( scalar @$roles == 1 ) {
        my ( $role, $params ) = @{ $roles->[0] };
        $role->meta->apply( $meta, ( defined $params ? %$params : () ) );
    }
    else {
        Moose::Meta::Role->combine( @$roles )->apply($meta);
    }
}

# instance deconstruction ...

sub get_all_attribute_values {
    my ($class, $instance) = @_;
    return +{
        map { $_->name => $_->get_value($instance) }
            grep { $_->has_value($instance) }
                $class->compute_all_applicable_attributes
    };
}

sub get_all_init_args {
    my ($class, $instance) = @_;
    return +{
        map { $_->init_arg => $_->get_value($instance) }
            grep { $_->has_value($instance) }
                grep { defined($_->init_arg) } 
                    $class->compute_all_applicable_attributes
    };
}

sub resolve_metatrait_alias {
    return resolve_metaclass_alias( @_, trait => 1 );
}

{
    my %cache;

    sub resolve_metaclass_alias {
        my ( $type, $metaclass_name, %options ) = @_;

        my $cache_key = $type . q{ } . ( $options{trait} ? '-Trait' : '' );
        return $cache{$cache_key}{$metaclass_name}
            if $cache{$cache_key}{$metaclass_name};

        my $possible_full_name
            = 'Moose::Meta::' 
            . $type
            . '::Custom::'
            . ( $options{trait} ? "Trait::" : "" )
            . $metaclass_name;

        my $loaded_class = Class::MOP::load_first_existing_class(
            $possible_full_name,
            $metaclass_name
        );

        return $cache{$cache_key}{$metaclass_name}
            = $loaded_class->can('register_implementation')
            ? $loaded_class->register_implementation
            : $loaded_class;
    }
}

sub add_method_modifier {
    my ( $class_or_obj, $modifier_name, $args ) = @_;
    my $meta                = find_meta($class_or_obj);
    my $code                = pop @{$args};
    my $add_modifier_method = 'add_' . $modifier_name . '_method_modifier';
    if ( my $method_modifier_type = ref( @{$args}[0] ) ) {
        if ( $method_modifier_type eq 'Regexp' ) {
            my @all_methods = $meta->get_all_methods;
            my @matched_methods
                = grep { $_->name =~ @{$args}[0] } @all_methods;
            $meta->$add_modifier_method( $_->name, $code )
                for @matched_methods;
        }
    }
    else {
        $meta->$add_modifier_method( $_, $code ) for @{$args};
    }
}

sub english_list {
    my @items = sort @_;

    return $items[0] if @items == 1;
    return "$items[0] and $items[1]" if @items == 2;

    my $tail = pop @items;
    my $list = join ', ', @items;
    $list .= ', and ' . $tail;

    return $list;
}

1;

__END__

=pod

=head1 NAME

Moose::Util - Utilities for working with Moose classes

=head1 SYNOPSIS

  use Moose::Util qw/find_meta does_role search_class_by_role/;

  my $meta = find_meta($object) || die "No metaclass found";

  if (does_role($object, $role)) {
    print "The object can do $role!\n";
  }

  my $class = search_class_by_role($object, 'FooRole');
  print "Nearest class with 'FooRole' is $class\n";

=head1 DESCRIPTION

This is a set of utility functions to help working with Moose classes, and 
is used internally by Moose itself. The goal is to provide useful functions
that for both Moose users and Moose extenders (MooseX:: authors).

This is a relatively new addition to the Moose toolchest, so ideas, 
suggestions and contributions to this collection are most welcome. 
See the L<TODO> section below for a list of ideas for possible functions 
to write.

=head1 EXPORTED FUNCTIONS

=over 4

=item B<find_meta ($class_or_obj)>

This will attempt to locate a metaclass for the given C<$class_or_obj>
and return it.

=item B<does_role ($class_or_obj, $role_name)>

Returns true if C<$class_or_obj> can do the role C<$role_name>.

=item B<search_class_by_role ($class_or_obj, $role_name)>

Returns first class in precedence list that consumed C<$role_name>.

=item B<apply_all_roles ($applicant, @roles)>

Given an C<$applicant> (which can somehow be turned into either a 
metaclass or a metarole) and a list of C<@roles> this will do the 
right thing to apply the C<@roles> to the C<$applicant>. This is 
actually used internally by both L<Moose> and L<Moose::Role>, and the
C<@roles> will be pre-processed through L<Data::OptList::mkopt>
to allow for the additional arguments to be passed. 

=item B<get_all_attribute_values($meta, $instance)>

Returns the values of the C<$instance>'s fields keyed by the attribute names.

=item B<get_all_init_args($meta, $instance)>

Returns a hash reference where the keys are all the attributes' C<init_arg>s
and the values are the instance's fields. Attributes without an C<init_arg>
will be skipped.

=item B<resolve_metaclass_alias($category, $name, %options)>

=item B<resolve_metatrait_alias($category, $name, %options)>

Resolve a short name like in e.g.

    has foo => (
        metaclass => "Bar",
    );

to a full class name.

=item B<add_method_modifier ($class_or_obj, $modifier_name, $args)>

=item B<english_list(@items)>

Given a list of scalars, turns them into a proper list in English
("one and two", "one, two, three, and four"). This is used to help us
make nicer error messages.

=back

=head1 TODO

Here is a list of possible functions to write

=over 4

=item discovering original method from modified method

=item search for origin class of a method or attribute

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

B<with contributions from:>

Robert (phaylon) Sedlacek

Stevan Little

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

