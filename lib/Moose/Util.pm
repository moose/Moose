package Moose::Util;

use strict;
use warnings;

use Data::OptList;
use Sub::Exporter;
use Scalar::Util 'blessed';
use Class::MOP   0.60;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

my @exports = qw[
    find_meta
    does_role
    search_class_by_role
    ensure_all_roles
    apply_all_roles
    get_all_init_args
    get_all_attribute_values
    resolve_metatrait_alias
    resolve_metaclass_alias
    add_method_modifier
    english_list
    meta_attribute_alias
    meta_class_alias
];

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { all => \@exports }
});

## some utils for the utils ...

sub find_meta { Class::MOP::class_of(@_) }

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

# this can possibly behave in unexpected ways because the roles being composed
# before being applied could differ from call to call; I'm not sure if or how
# to document this possible quirk.
sub ensure_all_roles {
    my $applicant = shift;
    _apply_all_roles($applicant, sub { !does_role($applicant, $_) }, @_);
}

sub apply_all_roles {
    my $applicant = shift;
    _apply_all_roles($applicant, undef, @_);
}

sub _apply_all_roles {
    my $applicant = shift;
    my $role_filter = shift;

    unless (@_) {
        require Moose;
        Moose->throw_error("Must specify at least one role to apply to $applicant");
    }

    my $roles = Data::OptList::mkopt( [@_] );

    foreach my $role (@$roles) {
        Class::MOP::load_class( $role->[0] );
        my $meta = Class::MOP::class_of( $role->[0] );

        unless ($meta && $meta->isa('Moose::Meta::Role') ) {
            require Moose;
            Moose->throw_error( "You can only consume roles, "
                    . $role->[0]
                    . " is not a Moose role" );
        }
    }

    if ( defined $role_filter ) {
        @$roles = grep { local $_ = $_->[0]; $role_filter->() } @$roles;
    }

    return unless @$roles;

    my $meta = ( blessed $applicant ? $applicant : find_meta($applicant) );

    if ( scalar @$roles == 1 ) {
        my ( $role, $params ) = @{ $roles->[0] };
        my $role_meta = Class::MOP::class_of($role);
        $role_meta->apply( $meta, ( defined $params ? %$params : () ) );
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
                $class->get_all_attributes
    };
}

sub get_all_init_args {
    my ($class, $instance) = @_;
    return +{
        map { $_->init_arg => $_->get_value($instance) }
            grep { $_->has_value($instance) }
                grep { defined($_->init_arg) }
                    $class->get_all_attributes
    };
}

sub resolve_metatrait_alias {
    return resolve_metaclass_alias( @_, trait => 1 );
}

sub _build_alias_package_name {
    my ($type, $name, $trait) = @_;
    return 'Moose::Meta::'
         . $type
         . '::Custom::'
         . ( $trait ? 'Trait::' : '' )
         . $name;
}

{
    my %cache;

    sub resolve_metaclass_alias {
        my ( $type, $metaclass_name, %options ) = @_;

        my $cache_key = $type . q{ } . ( $options{trait} ? '-Trait' : '' );
        return $cache{$cache_key}{$metaclass_name}
            if $cache{$cache_key}{$metaclass_name};

        my $possible_full_name = _build_alias_package_name(
            $type, $metaclass_name, $options{trait}
        );

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
    my $meta
        = $class_or_obj->can('add_before_method_modifier')
        ? $class_or_obj
        : find_meta($class_or_obj);
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

sub _caller_info {
    my $level = @_ ? ($_[0] + 1) : 2;
    my %info;
    @info{qw(package file line)} = caller($level);
    return \%info;
}

sub _create_alias {
    my ($type, $name, $trait, $for) = @_;
    my $package = _build_alias_package_name($type, $name, $trait);
    Class::MOP::Class->initialize($package)->add_method(
        register_implementation => sub { $for }
    );
}

sub meta_attribute_alias {
    my ($to, $from) = @_;
    $from ||= caller;
    my $meta = Class::MOP::class_of($from);
    my $trait = $meta->isa('Moose::Meta::Role');
    _create_alias('Attribute', $to, $trait, $from);
}

sub meta_class_alias {
    my ($to, $from) = @_;
    $from ||= caller;
    my $meta = Class::MOP::class_of($from);
    my $trait = $meta->isa('Moose::Meta::Role');
    _create_alias('Class', $to, $trait, $from);
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

This module provides a set of utility functions. Many of these
functions are intended for use in Moose itself or MooseX modules, but
some of them may be useful for use in your own code.

=head1 EXPORTED FUNCTIONS

=over 4

=item B<find_meta($class_or_obj)>

This method takes a class name or object and attempts to find a
metaclass for the class, if one exists. It will B<not> create one if it
does not yet exist.

=item B<does_role($class_or_obj, $role_name)>

Returns true if C<$class_or_obj> does the given C<$role_name>.

The class must already have a metaclass for this to work.

=item B<search_class_by_role($class_or_obj, $role_name)>

Returns the first class in the class's precedence list that does
C<$role_name>, if any.

The class must already have a metaclass for this to work.

=item B<apply_all_roles($applicant, @roles)>

This function applies one or more roles to the given C<$applicant> The
applicant can be a role name, class name, or object.

The C<$applicant> must already have a metaclass object.

The list of C<@roles> should be a list of names, each of which can be
followed by an optional hash reference of options (C<-excludes> and
C<-alias>).

=item B<ensure_all_roles($applicant, @roles)>

This function is similar to L</apply_all_roles>, but only applies roles that
C<$applicant> does not already consume.

=item B<get_all_attribute_values($meta, $instance)>

Returns a hash reference containing all of the C<$instance>'s
attributes. The keys are attribute names.

=item B<get_all_init_args($meta, $instance)>

Returns a hash reference containing all of the C<init_arg> values for
the instance's attributes. The values are the associated attribute
values. If an attribute does not have a defined C<init_arg>, it is
skipped.

This could be useful in cloning an object.

=item B<resolve_metaclass_alias($category, $name, %options)>

=item B<resolve_metatrait_alias($category, $name, %options)>

Resolves a short name to a full class name. Short names are often used
when specifying the C<metaclass> or C<traits> option for an attribute:

    has foo => (
        metaclass => "Bar",
    );

The name resolution mechanism is covered in
L<Moose/Metaclass and Trait Name Resolution>.

=item B<english_list(@items)>

Given a list of scalars, turns them into a proper list in English
("one and two", "one, two, three, and four"). This is used to help us
make nicer error messages.

=item B<meta_class_alias($to[, $from])>

=item B<meta_attribute_alias($to[, $from])>

Create an alias from the class C<$from> (or the current package, if
C<$from> is unspecified), so that
L<Moose/Metaclass and Trait Name Resolution> works properly.

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

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

