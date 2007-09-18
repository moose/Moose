
package Moose::Util::TypeConstraints;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed', 'reftype';
use B            'svref_2object';
use Sub::Exporter;

our $VERSION   = '0.14';
our $AUTHORITY = 'cpan:STEVAN';

## --------------------------------------------------------
# Prototyped subs must be predeclared because we have a 
# circular dependency with Moose::Meta::Attribute et. al. 
# so in case of us being use'd first the predeclaration 
# ensures the prototypes are in scope when consumers are
# compiled.

# creation and location
sub find_type_constraint                 ($);
sub find_or_create_type_constraint       ($;$);
sub create_type_constraint_union         (@);
sub create_parameterized_type_constraint ($);

# dah sugah!
sub type        ($$;$$);
sub subtype     ($$;$$$);
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
use Moose::Meta::TypeCoercion;
use Moose::Meta::TypeCoercion::Union;
use Moose::Meta::TypeConstraint::Registry;

my @exports = qw/
    type subtype as where message optimize_as
    coerce from via 
    enum
    find_type_constraint
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
            my $pkg_name = eval { svref_2object($keyword)->GV->STASH->NAME };
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
		*{"${pkg}::${constraint}"} = $REGISTRY->get_type_constraint($constraint)
		                                      ->_compiled_type_constraint;
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
        type_parameter => find_or_create_type_constraint(
            $type_parameter => {
                parent     => $REGISTRY->get_type_constraint('Object'),
                constraint => sub { $_[0]->isa($type_parameter) }
            }
        ),
    );    
}

sub find_or_create_type_constraint ($;$) {
    my ($type_constraint_name, $options_for_anon_type) = @_;
    
    return $REGISTRY->get_type_constraint($type_constraint_name)
        if $REGISTRY->has_type_constraint($type_constraint_name);
    
    my $constraint;
    
    if (_detect_type_constraint_union($type_constraint_name)) {
        $constraint = create_type_constraint_union($type_constraint_name);
    }
    elsif (_detect_parameterized_type_constraint($type_constraint_name)) {
        $constraint = create_parameterized_type_constraint($type_constraint_name);       
    }
    else {
        # NOTE:
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
    
    $REGISTRY->add_type_constraint($constraint);
    return $constraint;    
}

## --------------------------------------------------------
## exported functions ...
## --------------------------------------------------------

sub find_type_constraint ($) { $REGISTRY->get_type_constraint(@_) }

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
	unshift @_ => undef if scalar @_ <= 2 && (reftype($_[1]) || '') eq 'CODE';	
	goto &_create_type_constraint;
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
    (scalar @values >= 2)
        || confess "You must have at least two values to enumerate through";
    my $regexp = join '|' => @values;
	_create_type_constraint(
	    $type_name,
	    'Str',
	    sub { qr/^$regexp$/i }
	);    
}

## --------------------------------------------------------
## desugaring functions ...
## --------------------------------------------------------

sub _create_type_constraint ($$$;$$) { 
    my $name   = shift;
    my $parent = shift;
    my $check  = shift || sub { 1 };
    
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
                          
    $parent = $REGISTRY->get_type_constraint($parent) if defined $parent;
    
    my $constraint = Moose::Meta::TypeConstraint->new(
        name               => $name || '__ANON__',
        parent             => $parent,            
        constraint         => $check,       
        message            => $message,    
        optimized          => $optimized,
        package_defined_in => $pkg_defined_in,
    );

    $REGISTRY->add_type_constraint($constraint)
        if defined $name;

    return $constraint;
}

sub _install_type_coercions ($$) { 
    my ($type_name, $coercion_map) = @_;
    my $type = $REGISTRY->get_type_constraint($type_name);
    (!$type->has_coercion)
        || confess "The type coercion for '$type_name' has already been registered";        
    my $type_coercion = Moose::Meta::TypeCoercion->new(
        type_coercion_map => $coercion_map,
        type_constraint   => $type
    );            
    $type->coercion($type_coercion);
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

    my $valid_chars = qr{[\w:|]};
    my $type_atom   = qr{ $valid_chars+ };

    my $type                = qr{  $valid_chars+  (?: \[  (??{$any})  \] )? }x;
    my $type_capture_parts  = qr{ ($valid_chars+) (?: \[ ((??{$any})) \] )? }x;
    my $type_with_parameter = qr{  $valid_chars+      \[  (??{$any})  \]    }x;

    my $op_union = qr{ \s+ \| \s+ }x;
    my $union    = qr{ $type (?: $op_union $type )+ }x;

    our $any = qr{ $type | $union }x;

    sub _parse_parameterized_type_constraint {
    	$_[0] =~ m{ $type_capture_parts }x;
    	return ($1, $2);
    }

    sub _detect_parameterized_type_constraint {
    	$_[0] =~ m{ ^ $type_with_parameter $ }x;
    }

    sub _parse_type_constraint_union {
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
    => optimize_as { defined($_[0]) && !ref($_[0]) };
    
subtype 'Ref'
    => as 'Defined' 
    => where {  ref($_) } 
    => optimize_as { ref($_[0]) };

subtype 'Str' 
    => as 'Value' 
    => where { 1 } 
    => optimize_as { defined($_[0]) && !ref($_[0]) };

subtype 'Num' 
    => as 'Value' 
    => where { Scalar::Util::looks_like_number($_) } 
    => optimize_as { !ref($_[0]) && Scalar::Util::looks_like_number($_[0]) };
    
subtype 'Int' 
    => as 'Num'   
    => where { "$_" =~ /^-?[0-9]+$/ }
    => optimize_as { defined($_[0]) && !ref($_[0]) && $_[0] =~ /^-?[0-9]+$/ };

subtype 'ScalarRef' => as 'Ref' => where { ref($_) eq 'SCALAR' } => optimize_as { ref($_[0]) eq 'SCALAR' };
subtype 'ArrayRef'  => as 'Ref' => where { ref($_) eq 'ARRAY'  } => optimize_as { ref($_[0]) eq 'ARRAY'  };
subtype 'HashRef'   => as 'Ref' => where { ref($_) eq 'HASH'   } => optimize_as { ref($_[0]) eq 'HASH'   };	
subtype 'CodeRef'   => as 'Ref' => where { ref($_) eq 'CODE'   } => optimize_as { ref($_[0]) eq 'CODE'   };
subtype 'RegexpRef' => as 'Ref' => where { ref($_) eq 'Regexp' } => optimize_as { ref($_[0]) eq 'Regexp' };	
subtype 'GlobRef'   => as 'Ref' => where { ref($_) eq 'GLOB'   } => optimize_as { ref($_[0]) eq 'GLOB'   };

# NOTE:
# scalar filehandles are GLOB refs, 
# but a GLOB ref is not always a filehandle
subtype 'FileHandle' 
    => as 'GlobRef' 
    => where { Scalar::Util::openhandle($_) }
    => optimize_as { ref($_[0]) eq 'GLOB' && Scalar::Util::openhandle($_[0]) };

# NOTE: 
# blessed(qr/.../) returns true,.. how odd
subtype 'Object' 
    => as 'Ref' 
    => where { blessed($_) && blessed($_) ne 'Regexp' }
    => optimize_as { blessed($_[0]) && blessed($_[0]) ne 'Regexp' };

subtype 'Role' 
    => as 'Object' 
    => where { $_->can('does') }
    => optimize_as { blessed($_[0]) && $_[0]->can('does') };
    
subtype 'ClassName' 
    => as 'Str' 
    => where { eval { $_->isa('UNIVERSAL') } }
    => optimize_as { !ref($_[0]) && eval { $_[0]->isa('UNIVERSAL') } };    

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
can be used to simplify your own type-checking code.

=head2 Slightly Less Important Caveat

It is almost always a good idea to quote your type and subtype names. 
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

This module also provides a simple hierarchy for Perl 5 types, this 
could probably use some work, but it works for me at the moment.

  Any
  Item 
      Bool
      Undef
      Defined
          Value
              Num
                Int
              Str
                ClassName
          Ref
              ScalarRef
              ArrayRef
              HashRef
              CodeRef
              RegexpRef
              GlobRef
                FileHandle
              Object	
                  Role

Suggestions for improvement are welcome.

B<NOTE:> The C<Undef> type constraint does not work correctly 
in every occasion, please use it sparringly.

B<NOTE:> The C<ClassName> type constraint is simply a subtype 
of string which responds true to C<isa('UNIVERSAL')>. This means
that your class B<must> be loaded for this type constraint to 
pass. I know this is not ideal for all, but it is a saner 
restriction than most others. 

=head2 Use with Other Constraint Modules

This module should play fairly nicely with other constraint 
modules with only some slight tweaking. The C<where> clause 
in types is expected to be a C<CODE> reference which checks
it's first argument and returns a bool. Since most constraint
modules work in a similar way, it should be simple to adapt 
them to work with Moose.

For instance, this is how you could use it with 
L<Declare::Constraints::Simple> to declare a completely new type. 

  type 'HashOfArrayOfObjects' 
      => IsHashRef(
          -keys   => HasLength,
          -values => IsArrayRef( IsObject ));

For more examples see the F<t/204_example_w_DCS.t> test file.

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

For a complete example see the F<t/205_example_w_TestDeep.t> 
test file.    
    
=head1 FUNCTIONS

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

=item B<find_or_create_type_constraint ($type_name, ?$options_for_anon_type)>

This will attempt to find or create a type constraint given the a C<$type_name>. 
If it cannot find it in the registry, it will see if it should be a union or 
container type an create one if appropriate, and lastly if nothing can be 
found or created that way, it will create an anon-type using the 
C<$options_for_anon_type> HASH ref to populate it.

=item B<find_type_constraint ($type_name)>

This function can be used to locate a specific type constraint
meta-object, of the class L<Moose::Meta::TypeConstraint> or a
derivative. What you do with it from there is up to you :)

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

=back

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

=item B<enum ($name, @values)>

This will create a basic subtype for a given set of strings. 
The resulting constraint will be a subtype of C<Str> and 
will match any of the items in C<@values>. See the L<SYNOPSIS> 
for a simple example.

B<NOTE:> This is not a true proper enum type, it is simple 
a convient constraint builder.

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

Copyright 2006, 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
