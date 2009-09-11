#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

# This is a stripped down version of all_pod_coverage_ok which lets us
# vary the trustme parameter per module.
my @modules = all_modules();
plan tests => scalar @modules;

my %trustme = (
    'Moose::Meta::Attribute' => [
        qw( interpolate_class
            throw_error
            attach_to_class
            )
    ],
    'Moose::Meta::Attribute::Native::MethodProvider::Array'   => ['.+'],
    'Moose::Meta::Attribute::Native::MethodProvider::Bool'    => ['.+'],
    'Moose::Meta::Attribute::Native::MethodProvider::Code'    => ['.+'],
    'Moose::Meta::Attribute::Native::MethodProvider::Counter' => ['.+'],
    'Moose::Meta::Attribute::Native::MethodProvider::Hash'    => ['.+'],
    'Moose::Meta::Attribute::Native::MethodProvider::String'  => ['.+'],
    'Moose::Meta::Class'                                      => [
        qw( check_metaclass_compatibility
            construct_instance
            create_error
            raise_error
            superclasses
            )
    ],
    'Moose::Meta::Class::Immutable::Trait' => ['.+'],
    'Moose::Meta::Method'                  => ['throw_error'],
    'Moose::Meta::Method::Accessor'        => [
        qw( generate_accessor_method
            generate_accessor_method_inline
            generate_clearer_method
            generate_predicate_method
            generate_reader_method
            generate_reader_method_inline
            generate_writer_method
            generate_writer_method_inline
            )
    ],
    'Moose::Meta::Method::Constructor' => [
        qw( attributes
            initialize_body
            meta_instance
            new
            options
            )
    ],
    'Moose::Meta::Method::Destructor' => [ 'initialize_body', 'options' ],
    'Moose::Meta::Role'               => [
        qw( alias_method
            get_method_modifier_list
            reset_package_cache_flag
            update_package_cache_flag
            wrap_method_body
            )
    ],
    'Moose::Meta::Role::Composite' =>
        [ 'get_method', 'get_method_list', 'has_method', 'add_method' ],
    'Moose::Role' => [
        qw( after
            around
            augment
            before
            extends
            has
            inner
            override
            super
            with )
    ],
    'Moose::Meta::TypeCoercion'        => ['compile_type_coercion'],
    'Moose::Meta::TypeCoercion::Union' => ['compile_type_coercion'],
    'Moose::Meta::TypeConstraint'      => ['compile_type_constraint'],
    'Moose::Meta::TypeConstraint::Class' =>
        [qw( equals is_a_type_of is_a_subtype_of )],
    'Moose::Meta::TypeConstraint::Enum' => [qw( constraint equals )],
    'Moose::Meta::TypeConstraint::DuckType' =>
        [qw( constraint equals get_message )],
    'Moose::Meta::TypeConstraint::Parameterizable' => ['.+'],
    'Moose::Meta::TypeConstraint::Parameterized'   => ['.+'],
    'Moose::Meta::TypeConstraint::Role'  => [qw( equals is_a_type_of )],
    'Moose::Meta::TypeConstraint::Union' => ['compile_type_constraint'],
    'Moose::Util'                        => ['add_method_modifier'],
    'Moose::Util::TypeConstraints' => ['find_or_create_type_constraint'],
);

for my $module ( sort @modules ) {
    my $trustme = [];
    if ( $trustme{$module} ) {
        my $methods = join '|', @{ $trustme{$module} };
        $trustme = [qr/^(?:$methods)$/];
    }

    pod_coverage_ok(
        $module, { trustme => $trustme },
        "Pod coverage for $module"
    );
}
