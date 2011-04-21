package Moose::Util::TypeConstraints::Builtins;

use strict;
use warnings;

use List::MoreUtils ();
use Scalar::Util qw( blessed looks_like_number reftype );

sub type { goto &Moose::Util::TypeConstraints::type }
sub subtype { goto &Moose::Util::TypeConstraints::subtype }
sub as { goto &Moose::Util::TypeConstraints::as }
sub where (&) { goto &Moose::Util::TypeConstraints::where }
sub optimize_as (&) { goto &Moose::Util::TypeConstraints::optimize_as }
sub inline_as (&) { goto &Moose::Util::TypeConstraints::inline_as }

sub define_builtins {
    my $registry = shift;

    type 'Any'    # meta-type including all
        => where {1}
        => inline_as { '1' };

    subtype 'Item'  # base-type
        => as 'Any'
        => inline_as { '1' };

    subtype 'Undef'
        => as 'Item'
        => where { !defined($_) }
        => inline_as { '!defined(' . $_[1] . ')' };

    subtype 'Defined'
        => as 'Item'
        => where { defined($_) }
        => inline_as { 'defined(' . $_[1] . ')' };

    subtype 'Bool'
        => as 'Item'
        => where { !defined($_) || $_ eq "" || "$_" eq '1' || "$_" eq '0' }
        => inline_as {
            '!defined(' . $_[1] . ') '
              . '|| ' . $_[1] . ' eq "" '
              . '|| "' . $_[1] . '" eq "1" '
              . '|| "' . $_[1] . '" eq "0"'
        };

    subtype 'Value'
        => as 'Defined'
        => where { !ref($_) }
        => inline_as { 'defined(' . $_[1] . ') && !ref(' . $_[1] . ')' };

    subtype 'Ref'
        => as 'Defined'
        => where { ref($_) }
        => inline_as { 'ref(' . $_[1] . ')' };

    subtype 'Str'
        => as 'Value'
        => where { ref(\$_) eq 'SCALAR' }
        => inline_as {
            'defined(' . $_[1] . ') '
              . '&& (ref(\\' . $_[1] . ') eq "SCALAR"'
               . '|| ref(\\(my $val = ' . $_[1] . ')) eq "SCALAR")'
        };

    subtype 'Num'
        => as 'Str'
        => where { Scalar::Util::looks_like_number($_) }
        => inline_as {
            '!ref(' . $_[1] . ') '
              . '&& Scalar::Util::looks_like_number(' . $_[1] . ')'
        };

    subtype 'Int'
        => as 'Num'
        => where { "$_" =~ /\A-?[0-9]+\z/ }
        => inline_as {
            'defined(' . $_[1] . ') '
              . '&& !ref(' . $_[1] . ') '
              . '&& (my $val = ' . $_[1] . ') =~ /\A-?[0-9]+\z/'
        };

    subtype 'CodeRef'
        => as 'Ref'
        => where { ref($_) eq 'CODE' }
        => inline_as { 'ref(' . $_[1] . ') eq "CODE"' };

    subtype 'RegexpRef'
        => as 'Ref'
        => where( \&_RegexpRef )
        => inline_as {
            'Moose::Util::TypeConstraints::Builtins::_RegexpRef(' . $_[1] . ')'
        };

    subtype 'GlobRef'
        => as 'Ref'
        => where { ref($_) eq 'GLOB' }
        => inline_as { 'ref(' . $_[1] . ') eq "GLOB"' };

    # NOTE: scalar filehandles are GLOB refs, but a GLOB ref is not always a
    # filehandle
    subtype 'FileHandle'
        => as 'Ref'
        => where {
            Scalar::Util::openhandle($_) || ( blessed($_) && $_->isa("IO::Handle") );
        }
        => inline_as {
            '(ref(' . $_[1] . ') eq "GLOB" '
              . '&& Scalar::Util::openhandle(' . $_[1] . ')) '
       . '|| (Scalar::Util::blessed(' . $_[1] . ') '
              . '&& ' . $_[1] . '->isa("IO::Handle"))'
        };

    subtype 'Object'
        => as 'Ref'
        => where { blessed($_) }
        => inline_as { 'Scalar::Util::blessed(' . $_[1] . ')' };

    # This type is deprecated.
    subtype 'Role'
        => as 'Object'
        => where { $_->can('does') };

    subtype 'ClassName'
        => as 'Str'
        => where { Class::MOP::is_class_loaded($_) }
        => inline_as { 'Class::MOP::is_class_loaded(' . $_[1] . ')' };

    subtype 'RoleName'
        => as 'ClassName'
        => where {
            (Class::MOP::class_of($_) || return)->isa('Moose::Meta::Role');
        }
        => inline_as {
            'Class::MOP::is_class_loaded(' . $_[1] . ') '
              . '&& (Class::MOP::class_of(' . $_[1] . ') || return)->isa('
                  . '"Moose::Meta::Role"'
              . ')'
        };

    $registry->add_type_constraint(
        Moose::Meta::TypeConstraint::Parameterizable->new(
            name               => 'ScalarRef',
            package_defined_in => __PACKAGE__,
            parent =>
                Moose::Util::TypeConstraints::find_type_constraint('Ref'),
            constraint => sub { ref($_) eq 'SCALAR' || ref($_) eq 'REF' },
            constraint_generator => sub {
                my $type_parameter = shift;
                my $check = $type_parameter->_compiled_type_constraint;
                return sub {
                    return $check->( ${$_} );
                };
            },
            inlined => sub {
                'ref(' . $_[1] . ') eq "SCALAR" '
                  . '|| ref(' . $_[1] . ') eq "REF"'
            },
            inline_generator => sub {
                my $self           = shift;
                my $type_parameter = shift;
                my $val            = shift;
                '(ref(' . $val . ') eq "SCALAR" || ref(' . $val . ') eq "REF") '
                  . '&& ' . $type_parameter->_inline_check('${(' . $val . ')}')
            },
        )
    );

    $registry->add_type_constraint(
        Moose::Meta::TypeConstraint::Parameterizable->new(
            name               => 'ArrayRef',
            package_defined_in => __PACKAGE__,
            parent =>
                Moose::Util::TypeConstraints::find_type_constraint('Ref'),
            constraint => sub { ref($_) eq 'ARRAY' },
            constraint_generator => sub {
                my $type_parameter = shift;
                my $check = $type_parameter->_compiled_type_constraint;
                return sub {
                    foreach my $x (@$_) {
                        ( $check->($x) ) || return;
                    }
                    1;
                    }
            },
            inlined          => sub { 'ref(' . $_[1] . ') eq "ARRAY"' },
            inline_generator => sub {
                my $self           = shift;
                my $type_parameter = shift;
                my $val            = shift;
                'ref(' . $val . ') eq "ARRAY" '
                  . '&& &List::MoreUtils::all('
                      . 'sub { ' . $type_parameter->_inline_check('$_') . ' }, '
                      . '@{' . $val . '}'
                  . ')'
            },
        )
    );

    $registry->add_type_constraint(
        Moose::Meta::TypeConstraint::Parameterizable->new(
            name               => 'HashRef',
            package_defined_in => __PACKAGE__,
            parent =>
                Moose::Util::TypeConstraints::find_type_constraint('Ref'),
            constraint => sub { ref($_) eq 'HASH' },
            constraint_generator => sub {
                my $type_parameter = shift;
                my $check = $type_parameter->_compiled_type_constraint;
                return sub {
                    foreach my $x ( values %$_ ) {
                        ( $check->($x) ) || return;
                    }
                    1;
                    }
            },
            inlined          => sub { 'ref(' . $_[1] . ') eq "HASH"' },
            inline_generator => sub {
                my $self           = shift;
                my $type_parameter = shift;
                my $val            = shift;
                'ref(' . $val . ') eq "HASH" '
                  . '&& &List::MoreUtils::all('
                      . 'sub { ' . $type_parameter->_inline_check('$_') . ' }, '
                      . 'values %{' . $val . '}'
                  . ')'
            },
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
            },
            inlined          => sub {'1'},
            inline_generator => sub {
                my $self           = shift;
                my $type_parameter = shift;
                my $val            = shift;
                '!defined(' . $val . ') '
                  . '|| (' . $type_parameter->_inline_check($val) . ')'
            },
        )
    );
}

1;
