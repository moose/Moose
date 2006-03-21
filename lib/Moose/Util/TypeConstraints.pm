
package Moose::Util::TypeConstraints;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

our $VERSION = '0.02';

use Moose::Meta::TypeConstraint;
use Moose::Meta::TypeCoercion;

sub import {
	shift;
	my $pkg = shift || caller();
	return if $pkg eq '-no-export';
	no strict 'refs';
	foreach my $export (qw(type subtype as where coerce from via find_type_constraint)) {
		*{"${pkg}::${export}"} = \&{"${export}"};
	}	
}

{
    my %TYPES;
    sub find_type_constraint { $TYPES{$_[0]} }

    sub _create_type_constraint { 
        my ($name, $parent, $check) = @_;
        (!exists $TYPES{$name})
            || confess "The type constraint '$name' has already been created"
                if defined $name;
        $parent = $TYPES{$parent} if defined $parent;
        my $constraint = Moose::Meta::TypeConstraint->new(
            name       => $name || '__ANON__',
            parent     => $parent,            
            constraint => $check,           
        );
        $TYPES{$name} = $constraint if defined $name;
        return $constraint;
    }

    sub _install_type_coercions { 
        my ($type_name, $coercion_map) = @_;
        my $type = $TYPES{$type_name};
        (!$type->has_coercion)
            || confess "The type coercion for '$type_name' has already been registered";        
        my $type_coercion = Moose::Meta::TypeCoercion->new(
            type_coercion_map => $coercion_map,
            type_constraint   => $type
        );            
        $type->coercion($type_coercion);
    }
    
    sub export_type_contstraints_as_functions {
        my $pkg = caller();
	    no strict 'refs';
    	foreach my $constraint (keys %TYPES) {
    		*{"${pkg}::${constraint}"} = $TYPES{$constraint}->_compiled_type_constraint;
    	}        
    }    
}

# type constructors

sub type ($$) {
	my ($name, $check) = @_;
	_create_type_constraint($name, undef, $check);
}

sub subtype ($$;$) {
	unshift @_ => undef if scalar @_ == 2;
	_create_type_constraint(@_);
}

sub coerce ($@) {
    my ($type_name, @coercion_map) = @_;   
    _install_type_coercions($type_name, \@coercion_map);
}

sub as    ($) { $_[0] }
sub from  ($) { $_[0] }
sub where (&) { $_[0] }
sub via   (&) { $_[0] }

# define some basic types

type Any => where { 1 };

type Value => where { !ref($_) };
type Ref   => where {  ref($_) };

subtype Int => as Value => where {  Scalar::Util::looks_like_number($_) };
subtype Str => as Value => where { !Scalar::Util::looks_like_number($_) };

subtype ScalarRef => as Ref => where { ref($_) eq 'SCALAR' };	
subtype ArrayRef  => as Ref => where { ref($_) eq 'ARRAY'  };
subtype HashRef   => as Ref => where { ref($_) eq 'HASH'   };	
subtype CodeRef   => as Ref => where { ref($_) eq 'CODE'   };
subtype RegexpRef => as Ref => where { ref($_) eq 'Regexp' };	

# NOTE: 
# blessed(qr/.../) returns true,.. how odd
subtype Object => as Ref => where { blessed($_) && blessed($_) ne 'Regexp' };

1;

__END__

=pod

=head1 NAME

Moose::Util::TypeConstraints - Type constraint system for Moose

=head1 SYNOPSIS

  use Moose::Util::TypeConstraints;

  type Num => where { Scalar::Util::looks_like_number($_) };
  
  subtype Natural 
      => as Num 
      => where { $_ > 0 };
  
  subtype NaturalLessThanTen 
      => as Natural
      => where { $_ < 10 };
      
  coerce Num 
      => from Str
        => via { 0+$_ }; 

=head1 DESCRIPTION

This module provides Moose with the ability to create type contraints 
to be are used in both attribute definitions and for method argument 
validation. 

=head2 Important Caveat

This is B<NOT> a type system for Perl 5. These are type constraints, 
and they are not used by Moose unless you tell it to. No type 
inference is performed, expression are not typed, etc. etc. etc. 

This is simply a means of creating small constraint functions which 
can be used to simply your own type-checking code.

=head2 Default Type Constraints

This module also provides a simple hierarchy for Perl 5 types, this 
could probably use some work, but it works for me at the moment.

  Any
      Value
          Int
          Str
      Ref
          ScalarRef
          ArrayRef
          HashRef
          CodeRef
          RegexpRef
          Object	

Suggestions for improvement are welcome.
    
=head1 FUNCTIONS

=head2 Type Constraint Registry

=over 4

=item B<find_type_constraint ($type_name)>

This function can be used to locate a specific type constraint 
meta-object. What you do with it from there is up to you :)

=item B<export_type_contstraints_as_functions>

This will export all the current type constraints as functions 
into the caller's namespace. Right now, this is mostly used for 
testing, but it might prove useful to others.

=back

=head2 Type Constraint Constructors

The following functions are used to create type constraints. 
They will then register the type constraints in a global store 
where Moose can get to them if it needs to. 

See the L<SYNOPOSIS> for an example of how to use these.

=over 4

=item B<type ($name, $where_clause)>

This creates a base type, which has no parent. 

=item B<subtype ($name, $parent, $where_clause)>

This creates a named subtype. 

=item B<subtype ($parent, $where_clause)>

This creates an unnamed subtype and will return the type 
constraint meta-object, which will be an instance of 
L<Moose::Meta::TypeConstraint>. 

=item B<as>

This is just sugar for the type constraint construction syntax.

=item B<where>

This is just sugar for the type constraint construction syntax.

=back

=head2 Type Coercion Constructors

Type constraints can also contain type coercions as well. In most 
cases Moose will run the type-coercion code first, followed by the 
type constraint check. This feature should be used carefully as it 
is very powerful and could easily take off a limb if you are not 
careful.

See the L<SYNOPOSIS> for an example of how to use these.

=over 4

=item B<coerce>

=item B<from>

This is just sugar for the type coercion construction syntax.

=item B<via>

This is just sugar for the type coercion construction syntax.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut