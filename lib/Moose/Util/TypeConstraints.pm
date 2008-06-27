
package Moose::Util::TypeConstraints;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';
use Sub::Exporter;

our $VERSION   = '0.52';
our $AUTHORITY = 'cpan:STEVAN';

## --------------------------------------------------------
# Prototyped subs must be predeclared because we have a
# circular dependency with Moose::Meta::Attribute et. al.
# so in case of us being use'd first the predeclaration
# ensures the prototypes are in scope when consumers are
# compiled.

# creation and location
sub find_type_constraint                 ($);
sub register_type_constraint             ($);
sub find_or_create_type_constraint       ($;$);
sub find_or_parse_type_constraint        ($);
sub find_or_create_isa_type_constraint   ($);
sub find_or_create_does_type_constraint  ($);
sub create_type_constraint_union         (@);
sub create_parameterized_type_constraint ($);
sub create_class_type_constraint         ($;$);
sub create_role_type_constraint          ($;$);
sub create_enum_type_constraint          ($$);

# dah sugah!
sub type        ($$;$$);
sub subtype     ($$;$$$);
sub class_type  ($;$);
sub coerce      ($@);
sub as          ($);
sub from        ($);
sub where       (&);
sub via         (&);
sub message     (&);
sub optimize_as (&);
sub enum        ($;@);

## private stuff ...
sub _create_type_constraint ($$$;$$);
sub _install_type_coercions ($$);

## --------------------------------------------------------

use Moose::Meta::TypeConstraint;
use Moose::Meta::TypeConstraint::Union;
use Moose::Meta::TypeConstraint::Parameterized;
use Moose::Meta::TypeConstraint::Parameterizable;
use Moose::Meta::TypeConstraint::Class;
use Moose::Meta::TypeConstraint::Role;
use Moose::Meta::TypeConstraint::Enum;
use Moose::Meta::TypeCoercion;
use Moose::Meta::TypeCoercion::Union;
use Moose::Meta::TypeConstraint::Registry;
use Moose::Util::TypeConstraints::OptimizedConstraints;

my @exports = qw/
    type subtype class_type role_type as where message optimize_as
    coerce from via
    enum
    find_type_constraint
    register_type_constraint
/;

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { default => [':all'] }
});

sub unimport {
    no strict 'refs';
    my $class = caller();
    # loop through the exports ...
    foreach my $name (@exports) {
        # if we find one ...
        if (defined &{$class . '::' . $name}) {
            my $keyword = \&{$class . '::' . $name};

            # make sure it is from Moose
            my ($pkg_name) = Class::MOP::get_code_info($keyword);
            next if $@;
            next if $pkg_name ne 'Moose::Util::TypeConstraints';

            # and if it is from Moose then undef the slot
            delete ${$class . '::'}{$name};
        }
    }
}

## --------------------------------------------------------
## type registry and some useful functions for it
## --------------------------------------------------------

my $REGISTRY = Moose::Meta::TypeConstraint::Registry->new;

sub get_type_constraint_registry         { $REGISTRY }
sub list_all_type_constraints            { keys %{$REGISTRY->type_constraints} }
sub export_type_constraints_as_functions {
    my $pkg = caller();
    no strict 'refs';
    foreach my $constraint (keys %{$REGISTRY->type_constraints}) {
        my $tc = $REGISTRY->get_type_constraint($constraint)->_compiled_type_constraint;
        *{"${pkg}::${constraint}"} = sub { $tc->($_[0]) ? 1 : undef }; # the undef is for compat
    }
}

sub create_type_constraint_union (@) {
    my @type_constraint_names;

    if (scalar @_ == 1 && _detect_type_constraint_union($_[0])) {
        @type_constraint_names = _parse_type_constraint_union($_[0]);
    }
    else {
        @type_constraint_names = @_;
    }

    (scalar @type_constraint_names >= 2)
        || confess "You must pass in at least 2 type names to make a union";

    ($REGISTRY->has_type_constraint($_))
        || confess "Could not locate type constraint ($_) for the union"
            foreach @type_constraint_names;

    return Moose::Meta::TypeConstraint::Union->new(
        type_constraints => [
            map {
                $REGISTRY->get_type_constraint($_)
            } @type_constraint_names
        ],
    );
}

sub create_parameterized_type_constraint ($) {
    my $type_constraint_name = shift;

    my ($base_type, $type_parameter) = _parse_parameterized_type_constraint($type_constraint_name);

    (defined $base_type && defined $type_parameter)
        || confess "Could not parse type name ($type_constraint_name) correctly";

    ($REGISTRY->has_type_constraint($base_type))
        || confess "Could not locate the base type ($base_type)";

    return Moose::Meta::TypeConstraint::Parameterized->new(
        name           => $type_constraint_name,
        parent         => $REGISTRY->get_type_constraint($base_type),
        type_parameter => find_or_create_isa_type_constraint($type_parameter),
    );
}

#should we also support optimized checks?
sub create_class_type_constraint ($;$) {
    my ( $class, $options ) = @_;

    # too early for this check
    #find_type_constraint("ClassName")->check($class)
    #    || confess "Can't create a class type constraint because '$class' is not a class name";

    my %options = (
        class => $class,
        name  => $class,
        %{ $options || {} },
    );

    $options{name} ||= "__ANON__";

    Moose::Meta::TypeConstraint::Class->new( %options );
}

sub create_role_type_constraint ($;$) {
    my ( $role, $options ) = @_;

    # too early for this check
    #find_type_constraint("ClassName")->check($class)
    #    || confess "Can't create a class type constraint because '$class' is not a class name";

    my %options = (
        role => $role,
        name => $role,
        %{ $options || {} },
    );

    $options{name} ||= "__ANON__";

    Moose::Meta::TypeConstraint::Role->new( %options );
}


sub find_or_create_type_constraint ($;$) {
    my ( $type_constraint_name, $options_for_anon_type ) = @_;

    if ( my $constraint = find_or_parse_type_constraint($type_constraint_name) ) {
        return $constraint;
    }
    elsif ( defined $options_for_anon_type ) {
        # NOTE:
        # if there is no $options_for_anon_type
        # specified, then we assume they don't
        # want to create one, and return nothing.

        # otherwise assume that we should create
        # an ANON type with the $options_for_anon_type
        # options which can be passed in. It should
        # be noted that these don't get registered
        # so we need to return it.
        # - SL
        return Moose::Meta::TypeConstraint->new(
            name => '__ANON__',
            %{$options_for_anon_type}
        );
    }

    return;
}

sub find_or_create_isa_type_constraint ($) {
    my $type_constraint_name = shift;
    find_or_parse_type_constraint($type_constraint_name) || create_class_type_constraint($type_constraint_name)
}

sub find_or_create_does_type_constraint ($) {
    my $type_constraint_name = shift;
    find_or_parse_type_constraint($type_constraint_name) || create_role_type_constraint($type_constraint_name)
}

sub find_or_parse_type_constraint ($) {
    my $type_constraint_name = shift;

    return $REGISTRY->get_type_constraint($type_constraint_name)
        if $REGISTRY->has_type_constraint($type_constraint_name);

    my $constraint;

    if (_detect_type_constraint_union($type_constraint_name)) {
        $constraint = create_type_constraint_union($type_constraint_name);
    }
    elsif (_detect_parameterized_type_constraint($type_constraint_name)) {
        $constraint = create_parameterized_type_constraint($type_constraint_name);
    } else {
        return;
    }

    $REGISTRY->add_type_constraint($constraint);
    return $constraint;
}

## --------------------------------------------------------
## exported functions ...
## --------------------------------------------------------

sub find_type_constraint ($) {
    my $type = shift;

    if ( blessed $type and $type->isa("Moose::Meta::TypeConstraint") ) {
        return $type;
    } else {
        return $REGISTRY->get_type_constraint($type);
    }
}

sub register_type_constraint ($) {
    my $constraint = shift;
    confess "can't register an unnamed type constraint" unless defined $constraint->name;
    $REGISTRY->add_type_constraint($constraint);
    return $constraint;
}

# type constructors

sub type ($$;$$) {
    splice(@_, 1, 0, undef);
    goto &_create_type_constraint;
}

sub subtype ($$;$$$) {
    # NOTE:
    # this adds an undef for the name
    # if this is an anon-subtype:
    #   subtype(Num => where { $_ % 2 == 0 }) # anon 'even' subtype
    # but if the last arg is not a code
    # ref then it is a subtype alias:
    #   subtype(MyNumbers => as Num); # now MyNumbers is the same as Num
    # ... yeah I know it's ugly code
    # - SL
    unshift @_ => undef if scalar @_ <= 2 && ('CODE' eq ref($_[1]));
    goto &_create_type_constraint;
}

sub class_type ($;$) {
    register_type_constraint(
        create_class_type_constraint(
            $_[0],
            ( defined($_[1]) ? $_[1] : () ),
        )
    );
}

sub role_type ($;$) {
    register_type_constraint(
        create_role_type_constraint(
            $_[0],
            ( defined($_[1]) ? $_[1] : () ),
        )
    );
}

sub coerce ($@) {
    my ($type_name, @coercion_map) = @_;
    _install_type_coercions($type_name, \@coercion_map);
}

sub as      ($) { $_[0] }
sub from    ($) { $_[0] }
sub where   (&) { $_[0] }
sub via     (&) { $_[0] }

sub message     (&) { +{ message   => $_[0] } }
sub optimize_as (&) { +{ optimized => $_[0] } }

sub enum ($;@) {
    my ($type_name, @values) = @_;
    # NOTE:
    # if only an array-ref is passed then
    # you get an anon-enum
    # - SL
    if (ref $type_name eq 'ARRAY' && !@values) {
        @values    = @$type_name;
        $type_name = undef;
    }
    (scalar @values >= 2)
        || confess "You must have at least two values to enumerate through";
    my %valid = map { $_ => 1 } @values;

    register_type_constraint(
        create_enum_type_constraint(
            $type_name,
            \@values,
        )
    );
}

sub create_enum_type_constraint ($$) {
    my ( $type_name, $values ) = @_;
    
    Moose::Meta::TypeConstraint::Enum->new(
        name   => $type_name || '__ANON__',
        values => $values,
    );
}

## --------------------------------------------------------
## desugaring functions ...
## --------------------------------------------------------

sub _create_type_constraint ($$$;$$) {
    my $name   = shift;
    my $parent = shift;
    my $check  = shift;

    my ($message, $optimized);
    for (@_) {
        $message   = $_->{message}   if exists $_->{message};
        $optimized = $_->{optimized} if exists $_->{optimized};
    }

    my $pkg_defined_in = scalar(caller(0));

    if (defined $name) {
        my $type = $REGISTRY->get_type_constraint($name);

        ($type->_package_defined_in eq $pkg_defined_in)
            || confess ("The type constraint '$name' has already been created in "
                       . $type->_package_defined_in . " and cannot be created again in "
                       . $pkg_defined_in)
                 if defined $type;
    }

    my $class = "Moose::Meta::TypeConstraint";

    # FIXME should probably not be a special case
    if ( defined $parent and $parent = find_or_parse_type_constraint($parent) ) {
        $class = "Moose::Meta::TypeConstraint::Parameterizable" 
            if $parent->isa("Moose::Meta::TypeConstraint::Parameterizable");
    }

    my $constraint = $class->new(
        name               => $name || '__ANON__',
        package_defined_in => $pkg_defined_in,

        ($parent    ? (parent     => $parent )   : ()),
        ($check     ? (constraint => $check)     : ()),
        ($message   ? (message    => $message)   : ()),
        ($optimized ? (optimized  => $optimized) : ()),
    );

    # NOTE:
    # if we have a type constraint union, and no
    # type check, this means we are just aliasing
    # the union constraint, which means we need to
    # handle this differently.
    # - SL
    if (not(defined $check)
        && $parent->isa('Moose::Meta::TypeConstraint::Union')
        && $parent->has_coercion
        ){
        $constraint->coercion(Moose::Meta::TypeCoercion::Union->new(
            type_constraint => $parent
        ));
    }

    $REGISTRY->add_type_constraint($constraint)
        if defined $name;

    return $constraint;
}

sub _install_type_coercions ($$) {
    my ($type_name, $coercion_map) = @_;
    my $type = $REGISTRY->get_type_constraint($type_name);
    (defined $type)
        || confess "Cannot find type '$type_name', perhaps you forgot to load it.";
    if ($type->has_coercion) {
        $type->coercion->add_type_coercions(@$coercion_map);
    }
    else {
        my $type_coercion = Moose::Meta::TypeCoercion->new(
            type_coercion_map => $coercion_map,
            type_constraint   => $type
        );
        $type->coercion($type_coercion);
    }
}

## --------------------------------------------------------
## type notation parsing ...
## --------------------------------------------------------

{
    # All I have to say is mugwump++ cause I know
    # do not even have enough regexp-fu to be able
    # to have written this (I can only barely
    # understand it as it is)
    # - SL

    use re "eval";

    my $valid_chars = qr{[\w:]};
    my $type_atom   = qr{ $valid_chars+ };

    my $any;

    my $type                = qr{  $valid_chars+  (?: \[  (??{$any})  \] )? }x;
    my $type_capture_parts  = qr{ ($valid_chars+) (?: \[ ((??{$any})) \] )? }x;
    my $type_with_parameter = qr{  $valid_chars+      \[  (??{$any})  \]    }x;

    my $op_union = qr{ \s* \| \s* }x;
    my $union    = qr{ $type (?: $op_union $type )+ }x;

    $any = qr{ $type | $union }x;

    sub _parse_parameterized_type_constraint {
        { no warnings 'void'; $any; } # force capture of interpolated lexical
        $_[0] =~ m{ $type_capture_parts }x;
        return ($1, $2);
    }

    sub _detect_parameterized_type_constraint {
        { no warnings 'void'; $any; } # force capture of interpolated lexical
        $_[0] =~ m{ ^ $type_with_parameter $ }x;
    }

    sub _parse_type_constraint_union {
        { no warnings 'void'; $any; } # force capture of interpolated lexical
        my $given = shift;
        my @rv;
        while ( $given =~ m{ \G (?: $op_union )? ($type) }gcx ) {
            push @rv => $1;
        }
        (pos($given) eq length($given))
            || confess "'$given' didn't parse (parse-pos="
                     . pos($given)
                     . " and str-length="
                     . length($given)
                     . ")";
        @rv;
    }

    sub _detect_type_constraint_union {
        { no warnings 'void'; $any; } # force capture of interpolated lexical
        $_[0] =~ m{^ $type $op_union $type ( $op_union .* )? $}x;
    }
}

## --------------------------------------------------------
# define some basic built-in types
## --------------------------------------------------------

type 'Any'  => where { 1 }; # meta-type including all
type 'Item' => where { 1 }; # base-type

subtype 'Undef'   => as 'Item' => where { !defined($_) };
subtype 'Defined' => as 'Item' => where {  defined($_) };

subtype 'Bool'
    => as 'Item'
    => where { !defined($_) || $_ eq "" || "$_" eq '1' || "$_" eq '0' };

subtype 'Value'
    => as 'Defined'
    => where { !ref($_) }
    => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::Value;

subtype 'Ref'
    => as 'Defined'
    => where {  ref($_) }
    => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::Ref;

subtype 'Str'
    => as 'Value'
    => where { 1 }
    => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::Str;

subtype 'Num'
    => as 'Value'
    => where { Scalar::Util::looks_like_number($_) }
    => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::Num;

subtype 'Int'
    => as 'Num'
    => where { "$_" =~ /^-?[0-9]+$/ }
    => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::Int;

subtype 'ScalarRef' => as 'Ref' => where { ref($_) eq 'SCALAR' } => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::ScalarRef;
subtype 'CodeRef'   => as 'Ref' => where { ref($_) eq 'CODE'   } => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::CodeRef;
subtype 'RegexpRef' => as 'Ref' => where { ref($_) eq 'Regexp' } => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::RegexpRef;
subtype 'GlobRef'   => as 'Ref' => where { ref($_) eq 'GLOB'   } => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::GlobRef;

# NOTE:
# scalar filehandles are GLOB refs,
# but a GLOB ref is not always a filehandle
subtype 'FileHandle'
    => as 'GlobRef'
    => where { Scalar::Util::openhandle($_) || ( blessed($_) && $_->isa("IO::Handle") ) }
    => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::FileHandle;

# NOTE:
# blessed(qr/.../) returns true,.. how odd
subtype 'Object'
    => as 'Ref'
    => where { blessed($_) && blessed($_) ne 'Regexp' }
    => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::Object;

subtype 'Role'
    => as 'Object'
    => where { $_->can('does') }
    => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::Role;

my $_class_name_checker = sub {
};

subtype 'ClassName'
    => as 'Str'
    => where { Class::MOP::is_class_loaded($_) }
    => optimize_as \&Moose::Util::TypeConstraints::OptimizedConstraints::ClassName;

## --------------------------------------------------------
# parameterizable types ...

$REGISTRY->add_type_constraint(
    Moose::Meta::TypeConstraint::Parameterizable->new(
        name                 => 'ArrayRef',
        package_defined_in   => __PACKAGE__,
        parent               => find_type_constraint('Ref'),
        constraint           => sub { ref($_) eq 'ARRAY'  },
        optimized            => \&Moose::Util::TypeConstraints::OptimizedConstraints::ArrayRef,
        constraint_generator => sub {
            my $type_parameter = shift;
            my $check = $type_parameter->_compiled_type_constraint;
            return sub {
                foreach my $x (@$_) {
                    ($check->($x)) || return
                } 1;
            }
        }
    )
);

$REGISTRY->add_type_constraint(
    Moose::Meta::TypeConstraint::Parameterizable->new(
        name                 => 'HashRef',
        package_defined_in   => __PACKAGE__,
        parent               => find_type_constraint('Ref'),
        constraint           => sub { ref($_) eq 'HASH'  },
        optimized            => \&Moose::Util::TypeConstraints::OptimizedConstraints::HashRef,
        constraint_generator => sub {
            my $type_parameter = shift;
            my $check = $type_parameter->_compiled_type_constraint;
            return sub {
                foreach my $x (values %$_) {
                    ($check->($x)) || return
                } 1;
            }
        }
    )
);

$REGISTRY->add_type_constraint(
    Moose::Meta::TypeConstraint::Parameterizable->new(
        name                 => 'Maybe',
        package_defined_in   => __PACKAGE__,
        parent               => find_type_constraint('Item'),
        constraint           => sub { 1 },
        constraint_generator => sub {
            my $type_parameter = shift;
            my $check = $type_parameter->_compiled_type_constraint;
            return sub {
                return 1 if not(defined($_)) || $check->($_);
                return;
            }
        }
    )
);

my @PARAMETERIZABLE_TYPES = map {
    $REGISTRY->get_type_constraint($_)
} qw[ArrayRef HashRef Maybe];

sub get_all_parameterizable_types { @PARAMETERIZABLE_TYPES }
sub add_parameterizable_type {
    my $type = shift;
    (blessed $type && $type->isa('Moose::Meta::TypeConstraint::Parameterizable'))
        || confess "Type must be a Moose::Meta::TypeConstraint::Parameterizable not $type";
    push @PARAMETERIZABLE_TYPES => $type;
}

## --------------------------------------------------------
# end of built-in types ...
## --------------------------------------------------------

{
    my @BUILTINS = list_all_type_constraints();
    sub list_all_builtin_type_constraints { @BUILTINS }
}

1;

__END__

=pod

=head1 NAME

Moose::Util::TypeConstraints - Type constraint system for Moose

=head1 SYNOPSIS

  use Moose::Util::TypeConstraints;

  type 'Num' => where { Scalar::Util::looks_like_number($_) };

  subtype 'Natural'
      => as 'Num'
      => where { $_ > 0 };

  subtype 'NaturalLessThanTen'
      => as 'Natural'
      => where { $_ < 10 }
      => message { "This number ($_) is not less than ten!" };

  coerce 'Num'
      => from 'Str'
        => via { 0+$_ };

  enum 'RGBColors' => qw(red green blue);

=head1 DESCRIPTION

This module provides Moose with the ability to create custom type
contraints to be used in attribute definition.

=head2 Important Caveat

This is B<NOT> a type system for Perl 5. These are type constraints,
and they are not used by Moose unless you tell it to. No type
inference is performed, expression are not typed, etc. etc. etc.

This is simply a means of creating small constraint functions which
can be used to simplify your own type-checking code, with the added 
side benefit of making your intentions clearer through self-documentation.

=head2 Slightly Less Important Caveat

It is B<always> a good idea to quote your type and subtype names.

This is to prevent perl from trying to execute the call as an indirect
object call. This issue only seems to come up when you have a subtype
the same name as a valid class, but when the issue does arise it tends
to be quite annoying to debug.

So for instance, this:

  subtype DateTime => as Object => where { $_->isa('DateTime') };

will I<Just Work>, while this:

  use DateTime;
  subtype DateTime => as Object => where { $_->isa('DateTime') };

will fail silently and cause many headaches. The simple way to solve
this, as well as future proof your subtypes from classes which have
yet to have been created yet, is to simply do this:

  use DateTime;
  subtype 'DateTime' => as 'Object' => where { $_->isa('DateTime') };

=head2 Default Type Constraints

This module also provides a simple hierarchy for Perl 5 types, here is 
that hierarchy represented visually.

  Any
  Item
      Bool
      Maybe[`a]
      Undef
      Defined
          Value
              Num
                Int
              Str
                ClassName
          Ref
              ScalarRef
              ArrayRef[`a]
              HashRef[`a]
              CodeRef
              RegexpRef
              GlobRef
                FileHandle
              Object
                  Role

B<NOTE:> Any type followed by a type parameter C<[`a]> can be
parameterized, this means you can say:

  ArrayRef[Int]    # an array of intergers
  HashRef[CodeRef] # a hash of str to CODE ref mappings
  Maybe[Str]       # value may be a string, may be undefined

B<NOTE:> The C<Undef> type constraint for the most part works
correctly now, but edge cases may still exist, please use it
sparringly.

B<NOTE:> The C<ClassName> type constraint does a complex package
existence check. This means that your class B<must> be loaded for
this type constraint to pass. I know this is not ideal for all,
but it is a saner restriction than most others.

=head2 Type Constraint Naming 

Since the types created by this module are global, it is suggested 
that you namespace your types just as you would namespace your 
modules. So instead of creating a I<Color> type for your B<My::Graphics>
module, you would call the type I<My::Graphics::Color> instead.

=head2 Use with Other Constraint Modules

This module should play fairly nicely with other constraint
modules with only some slight tweaking. The C<where> clause
in types is expected to be a C<CODE> reference which checks
it's first argument and returns a boolean. Since most constraint
modules work in a similar way, it should be simple to adapt
them to work with Moose.

For instance, this is how you could use it with
L<Declare::Constraints::Simple> to declare a completely new type.

  type 'HashOfArrayOfObjects'
      => IsHashRef(
          -keys   => HasLength,
          -values => IsArrayRef( IsObject ));

For more examples see the F<t/200_examples/204_example_w_DCS.t> 
test file.

Here is an example of using L<Test::Deep> and it's non-test
related C<eq_deeply> function.

  type 'ArrayOfHashOfBarsAndRandomNumbers'
      => where {
          eq_deeply($_,
              array_each(subhashof({
                  bar           => isa('Bar'),
                  random_number => ignore()
              })))
        };

For a complete example see the 
F<t/200_examples/205_example_w_TestDeep.t> test file.

=head1 FUNCTIONS

=head2 Type Constraint Constructors

The following functions are used to create type constraints.
They will then register the type constraints in a global store
where Moose can get to them if it needs to.

See the L<SYNOPSIS> for an example of how to use these.

=over 4

=item B<type ($name, $where_clause)>

This creates a base type, which has no parent.

=item B<subtype ($name, $parent, $where_clause, ?$message)>

This creates a named subtype.

=item B<subtype ($parent, $where_clause, ?$message)>

This creates an unnamed subtype and will return the type
constraint meta-object, which will be an instance of
L<Moose::Meta::TypeConstraint>.

=item B<class_type ($class, ?$options)>

Creates a type constraint with the name C<$class> and the metaclass
L<Moose::Meta::TypeConstraint::Class>.

=item B<role_type ($role, ?$options)>

Creates a type constraint with the name C<$role> and the metaclass
L<Moose::Meta::TypeConstraint::Role>.

=item B<enum ($name, @values)>

This will create a basic subtype for a given set of strings.
The resulting constraint will be a subtype of C<Str> and
will match any of the items in C<@values>. It is case sensitive.
See the L<SYNOPSIS> for a simple example.

B<NOTE:> This is not a true proper enum type, it is simple
a convient constraint builder.

=item B<enum (\@values)>

If passed an ARRAY reference instead of the C<$name>, C<@values> pair,
this will create an unnamed enum. This can then be used in an attribute
definition like so:

  has 'sort_order' => (
      is  => 'ro',
      isa => enum([qw[ ascending descending ]]),
  );

=item B<as>

This is just sugar for the type constraint construction syntax.

=item B<where>

This is just sugar for the type constraint construction syntax.

=item B<message>

This is just sugar for the type constraint construction syntax.

=item B<optimize_as>

This can be used to define a "hand optimized" version of your
type constraint which can be used to avoid traversing a subtype
constraint heirarchy.

B<NOTE:> You should only use this if you know what you are doing,
all the built in types use this, so your subtypes (assuming they
are shallow) will not likely need to use this.

=back

=head2 Type Coercion Constructors

Type constraints can also contain type coercions as well. If you
ask your accessor to coerce, then Moose will run the type-coercion
code first, followed by the type constraint check. This feature
should be used carefully as it is very powerful and could easily
take off a limb if you are not careful.

See the L<SYNOPSIS> for an example of how to use these.

=over 4

=item B<coerce>

=item B<from>

This is just sugar for the type coercion construction syntax.

=item B<via>

This is just sugar for the type coercion construction syntax.

=back

=head2 Type Constraint Construction & Locating

=over 4

=item B<create_type_constraint_union ($pipe_seperated_types | @type_constraint_names)>

Given string with C<$pipe_seperated_types> or a list of C<@type_constraint_names>,
this will return a L<Moose::Meta::TypeConstraint::Union> instance.

=item B<create_parameterized_type_constraint ($type_name)>

Given a C<$type_name> in the form of:

  BaseType[ContainerType]

this will extract the base type and container type and build an instance of
L<Moose::Meta::TypeConstraint::Parameterized> for it.

=item B<create_class_type_constraint ($class, ?$options)>

Given a class name it will create a new L<Moose::Meta::TypeConstraint::Class>
object for that class name.

=item B<create_role_type_constraint ($role, ?$options)>

Given a role name it will create a new L<Moose::Meta::TypeConstraint::Role>
object for that role name.

=item B<create_enum_type_constraint ($name, $values)>

=item B<find_or_parse_type_constraint ($type_name)>

This will attempt to find or create a type constraint given the a C<$type_name>.
If it cannot find it in the registry, it will see if it should be a union or
container type an create one if appropriate

=item B<find_or_create_type_constraint ($type_name, ?$options_for_anon_type)>

This function will first call C<find_or_parse_type_constraint> with the type name.

If no type is found or created, but C<$options_for_anon_type> are provided, it
will create the corresponding type.

This was used by the C<does> and C<isa> parameters to L<Moose::Meta::Attribute>
and are now superseded by C<find_or_create_isa_type_constraint> and
C<find_or_create_does_type_constraint>.

=item B<find_or_create_isa_type_constraint ($type_name)>

=item B<find_or_create_does_type_constraint ($type_name)>

Attempts to parse the type name using L<find_or_parse_type_constraint> and if
no appropriate constraint is found will create a new anonymous one.

The C<isa> variant will use C<create_class_type_constraint> and the C<does>
variant will use C<create_role_type_constraint>.

=item B<find_type_constraint ($type_name)>

This function can be used to locate a specific type constraint
meta-object, of the class L<Moose::Meta::TypeConstraint> or a
derivative. What you do with it from there is up to you :)

=item B<register_type_constraint ($type_object)>

This function will register a named type constraint with the type registry.

=item B<get_type_constraint_registry>

Fetch the L<Moose::Meta::TypeConstraint::Registry> object which
keeps track of all type constraints.

=item B<list_all_type_constraints>

This will return a list of type constraint names, you can then
fetch them using C<find_type_constraint ($type_name)> if you
want to.

=item B<list_all_builtin_type_constraints>

This will return a list of builtin type constraints, meaning,
those which are defined in this module. See the section
labeled L<Default Type Constraints> for a complete list.

=item B<export_type_constraints_as_functions>

This will export all the current type constraints as functions
into the caller's namespace. Right now, this is mostly used for
testing, but it might prove useful to others.

=item B<get_all_parameterizable_types>

This returns all the parameterizable types that have been registered.

=item B<add_parameterizable_type ($type)>

Adds C<$type> to the list of parameterizable types

=back

=head2 Namespace Management

=over 4

=item B<unimport>

This will remove all the type constraint keywords from the
calling class namespace.

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
