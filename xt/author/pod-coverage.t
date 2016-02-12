
use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::Pod::Coverage' => '1.04',    # skip all if not installed
};

# This is a stripped down version of all_pod_coverage_ok which lets us
# vary the trustme parameter per module.
my @modules
    = grep { !/Accessor::Native.*$/ && !/::Conflicts$/ && !/^Moose::Exception::/ } all_modules();
plan tests => scalar @modules;

my %trustme = (
    'Class::MOP' => [
        'IS_RUNNING_ON_5_10',
        'check_package_cache_flag',
        'is_class_loaded',
        'load_class',
        'load_first_existing_class',
    ],
    'Class::MOP::Class'     => [
        # unfinished feature
        'add_dependent_meta_instance',
        'add_meta_instance_dependencies',
        'invalidate_meta_instance',
        'invalidate_meta_instances',
        'remove_dependent_meta_instance',
        'remove_meta_instance_dependencies',
        'update_meta_instance_dependencies',

        # effectively internal
        'reinitialize',

        # doc'd with rebless_instance
        'rebless_instance_away',
    ],
    'Class::MOP::Class::Immutable::Trait'             => ['.+'],
    'Class::MOP::Instance'                            => [
        qw( BUILDARGS
            is_dependent_on_superclasses ),
    ],
    'Class::MOP::Method::Generated'    => ['new'],
    'Class::MOP::MiniTrait'            => ['.+'],
    'Class::MOP::Mixin::AttributeCore' => ['.+'],
    'Class::MOP::Mixin::HasAttributes' => ['.+'],
    'Class::MOP::Mixin::HasMethods'    => ['.+'],
    'Class::MOP::Mixin::HasOverloads'  => ['.+'],
    'Class::MOP::Overload'             => [ 'attach_to_class' ],
    'Moose'                  => [ 'init_meta', 'throw_error' ],
    'Moose::Error::Confess'  => ['new'],
    'Moose::Exception'       => ['BUILD'],
    'Moose::Meta::Attribute' => ['interpolate_class'],
    'Moose::Meta::Class' => [ qw( reinitialize) ],
    'Moose::Meta::Class::Immutable::Trait' => ['.+'],
    'Moose::Meta::Method::Accessor'   => ['new'],
    'Moose::Meta::Method::Constructor' => ['new'],
    'Moose::Meta::Method::Destructor' => [ 'options' ],
    'Moose::Meta::Method::Meta'       => ['wrap'],
    'Moose::Meta::Role'               => [
        qw( get_method_modifier_list
            reinitialize
            )
    ],
    'Moose::Meta::Role::Composite'      => [
        qw( add_method
            add_overloaded_operator
            get_all_overloaded_operators
            get_method
            get_method_list
            get_overload_fallback_value
            has_method
            is_anon
            is_overloaded
            set_overload_fallback_value
            ),
    ],
    'Moose::Object' => [ 'BUILDALL', 'DEMOLISHALL' ],
    'Moose::Role'   => [
        qw( after
            around
            augment
            before
            extends
            has
            inner
            init_meta
            override
            super
            with )
    ],
    'Moose::Meta::TypeCoercion'        => ['compile_type_coercion'],
    'Moose::Meta::TypeCoercion::Union' => ['compile_type_coercion'],
    'Moose::Meta::TypeConstraint' => [qw( compile_type_constraint )],
    'Moose::Meta::TypeConstraint::Class' =>
        [qw( equals is_a_type_of )],
    'Moose::Meta::TypeConstraint::Enum' => [qw( constraint equals )],
    'Moose::Meta::TypeConstraint::DuckType' =>
        [qw( equals get_message )],
    'Moose::Meta::TypeConstraint::Parameterizable' => ['.+'],
    'Moose::Meta::TypeConstraint::Parameterized'   => ['.+'],
    'Moose::Meta::TypeConstraint::Role'  => [qw( equals is_a_type_of )],
    'Moose::Meta::TypeConstraint::Union' => [
        qw( coercion
            has_coercion
            can_be_inlined
            inline_environment )
    ],
    'Moose::Util'                  => ['add_method_modifier'],
    'Moose::Util::TypeConstraints' => ['find_or_create_type_constraint'],
    'Moose::Util::TypeConstraints::Builtins' => ['.+'],
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
