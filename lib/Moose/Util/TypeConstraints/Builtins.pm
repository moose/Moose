package Moose::Util::TypeConstraints::Builtins;

use strict;
use warnings;

use Scalar::Util qw( blessed reftype );

sub type { goto &Moose::Util::TypeConstraints::type }
sub subtype { goto &Moose::Util::TypeConstraints::subtype }
sub as { goto &Moose::Util::TypeConstraints::as }
sub where (&) { goto &Moose::Util::TypeConstraints::where }
sub optimize_as (&) { goto &Moose::Util::TypeConstraints::optimize_as }

sub define_builtins {
    my $registry = shift;

    type 'Any'  => where {1};    # meta-type including all
    subtype 'Item' => as 'Any';  # base-type

    subtype 'Undef'   => as 'Item' => where { !defined($_) };
    subtype 'Defined' => as 'Item' => where { defined($_) };

    subtype 'Bool'
        => as 'Item'
        => where { !defined($_) || $_ eq "" || "$_" eq '1' || "$_" eq '0' };

    subtype 'Value'
        => as 'Defined'
        => where { !ref($_) }
        => optimize_as
            \&Moose::Util::TypeConstraints::OptimizedConstraints::Value;

    subtype 'Ref'
        => as 'Defined'
        => where { ref($_) }
        => optimize_as
            \&Moose::Util::TypeConstraints::OptimizedConstraints::Ref;

    subtype 'Str'
        => as 'Value'
        => where { ref(\$_) eq 'SCALAR' }
        => optimize_as
            \&Moose::Util::TypeConstraints::OptimizedConstraints::Str;

    subtype 'Num'
        => as 'Str'
        => where { Scalar::Util::looks_like_number($_) }
        => optimize_as
            \&Moose::Util::TypeConstraints::OptimizedConstraints::Num;

    subtype 'Int'
        => as 'Num'
        => where { "$_" =~ /^-?[0-9]+$/ }
        => optimize_as
            \&Moose::Util::TypeConstraints::OptimizedConstraints::Int;

    subtype 'CodeRef'
        => as 'Ref'
        => where { ref($_) eq 'CODE' }
        => optimize_as
            \&Moose::Util::TypeConstraints::OptimizedConstraints::CodeRef;

    subtype 'RegexpRef'
        => as 'Ref'
        => where( \&Moose::Util::TypeConstraints::OptimizedConstraints::RegexpRef )
        => optimize_as
            \&Moose::Util::TypeConstraints::OptimizedConstraints::RegexpRef;

    subtype 'GlobRef'
        => as 'Ref'
        => where { ref($_) eq 'GLOB' }
        => optimize_as
            \&Moose::Util::TypeConstraints::OptimizedConstraints::GlobRef;

    # NOTE: scalar filehandles are GLOB refs, but a GLOB ref is not always a
    # filehandle
    subtype 'FileHandle'
        => as 'GlobRef'
        => where {
            Scalar::Util::openhandle($_) || ( blessed($_) && $_->isa("IO::Handle") );
        }
        => optimize_as
            \&Moose::Util::TypeConstraints::OptimizedConstraints::FileHandle;

    subtype 'Object'
        => as 'Ref'
        => where { blessed($_) }
        => optimize_as
            \&Moose::Util::TypeConstraints::OptimizedConstraints::Object;

    # This type is deprecated.
    subtype 'Role'
        => as 'Object'
        => where { $_->can('does') }
        => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::Role;

    subtype 'ClassName'
        => as 'Str'
        => where { Class::MOP::is_class_loaded($_) }
        => optimize_as
            \&Moose::Util::TypeConstraints::OptimizedConstraints::ClassName;

    subtype 'RoleName'
        => as 'ClassName'
        => where {
            (Class::MOP::class_of($_) || return)->isa('Moose::Meta::Role');
        }
        => optimize_as
            \&Moose::Util::TypeConstraints::OptimizedConstraints::RoleName;

    $registry->add_type_constraint(
        Moose::Meta::TypeConstraint::Parameterizable->new(
            name               => 'ScalarRef',
            package_defined_in => __PACKAGE__,
            parent =>
                Moose::Util::TypeConstraints::find_type_constraint('Ref'),
            constraint => sub { ref($_) eq 'SCALAR' || ref($_) eq 'REF' },
            optimized =>
                \&Moose::Util::TypeConstraints::OptimizedConstraints::ScalarRef,
            constraint_generator => sub {
                my $type_parameter = shift;
                my $check = $type_parameter->_compiled_type_constraint;
                return sub {
                    return $check->( ${$_} );
                };
            }
        )
    );

    $registry->add_type_constraint(
        Moose::Meta::TypeConstraint::Parameterizable->new(
            name               => 'ArrayRef',
            package_defined_in => __PACKAGE__,
            parent =>
                Moose::Util::TypeConstraints::find_type_constraint('Ref'),
            constraint => sub { ref($_) eq 'ARRAY' },
            optimized =>
                \&Moose::Util::TypeConstraints::OptimizedConstraints::ArrayRef,
            constraint_generator => sub {
                my $type_parameter = shift;
                my $check = $type_parameter->_compiled_type_constraint;
                return sub {
                    foreach my $x (@$_) {
                        ( $check->($x) ) || return;
                    }
                    1;
                    }
            }
        )
    );

    $registry->add_type_constraint(
        Moose::Meta::TypeConstraint::Parameterizable->new(
            name               => 'HashRef',
            package_defined_in => __PACKAGE__,
            parent =>
                Moose::Util::TypeConstraints::find_type_constraint('Ref'),
            constraint => sub { ref($_) eq 'HASH' },
            optimized =>
                \&Moose::Util::TypeConstraints::OptimizedConstraints::HashRef,
            constraint_generator => sub {
                my $type_parameter = shift;
                my $check = $type_parameter->_compiled_type_constraint;
                return sub {
                    foreach my $x ( values %$_ ) {
                        ( $check->($x) ) || return;
                    }
                    1;
                    }
            }
        )
    );

    $registry->add_type_constraint(
        Moose::Meta::TypeConstraint::Parameterizable->new(
            name               => 'Maybe',
            package_defined_in => __PACKAGE__,
            parent =>
                Moose::Util::TypeConstraints::find_type_constraint('Item'),
            constraint           => sub {1},
            constraint_generator => sub {
                my $type_parameter = shift;
                my $check = $type_parameter->_compiled_type_constraint;
                return sub {
                    return 1 if not( defined($_) ) || $check->($_);
                    return;
                    }
            }
        )
    );
}

1;
