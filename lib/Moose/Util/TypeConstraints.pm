
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

This is B<NOT> a type system for Perl 5.

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

=item B<_create_type_constraint ($type_name, $type_constraint)>

=item B<_install_type_coercions>

=item B<export_type_contstraints_as_functions>

=back

=head2 Type Constraint Constructors

=over 4

=item B<type>

=item B<subtype>

=item B<as>

=item B<where>

=item B<coerce>

=item B<from>

=item B<via>

=back

=head2 Built-in Type Constraints

=over 4

=item B<Any>

=item B<Value>

=item B<Int>

=item B<Str>

=item B<Ref>

=item B<ArrayRef>

=item B<CodeRef>

=item B<HashRef>

=item B<RegexpRef>

=item B<ScalarRef>

=item B<Object>

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