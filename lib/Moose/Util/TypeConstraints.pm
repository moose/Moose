
package Moose::Util::TypeConstraints;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

our $VERSION = '0.08';

use Moose::Meta::TypeConstraint;
use Moose::Meta::TypeCoercion;

use Sub::Exporter -setup => { 
    exports => [qw/
        type subtype as where message 
        coerce from via 
        enum
        find_type_constraint
    /],
    groups  => {
        default => [':all']
    }
};

{
    my %TYPES;
    sub find_type_constraint ($) { 
        return $TYPES{$_[0]}->[1] 
            if exists $TYPES{$_[0]};
        return;
    }
    
    sub _dump_type_constraints {
        require Data::Dumper;        
        Data::Dumper::Dumper(\%TYPES);
    }
    
    sub _create_type_constraint ($$$;$) { 
        my ($name, $parent, $check, $message) = @_;
        my $pkg_defined_in = scalar(caller(1));
        ($TYPES{$name}->[0] eq $pkg_defined_in)
            || confess "The type constraint '$name' has already been created "
                 if defined $name && exists $TYPES{$name};                
        $parent = find_type_constraint($parent) if defined $parent;
        my $constraint = Moose::Meta::TypeConstraint->new(
            name       => $name || '__ANON__',
            parent     => $parent,            
            constraint => $check,       
            message    => $message,    
        );
        $TYPES{$name} = [ $pkg_defined_in, $constraint ] if defined $name;
        return $constraint;
    }

    sub _install_type_coercions ($$) { 
        my ($type_name, $coercion_map) = @_;
        my $type = find_type_constraint($type_name);
        (!$type->has_coercion)
            || confess "The type coercion for '$type_name' has already been registered";        
        my $type_coercion = Moose::Meta::TypeCoercion->new(
            type_coercion_map => $coercion_map,
            type_constraint   => $type
        );            
        $type->coercion($type_coercion);
    }
    
    sub create_type_constraint_union (@) {
        my (@type_constraint_names) = @_;
        return Moose::Meta::TypeConstraint->union(
            map { 
                find_type_constraint($_) 
            } @type_constraint_names
        );
    }
    
    sub export_type_contstraints_as_functions {
        my $pkg = caller();
	    no strict 'refs';
    	foreach my $constraint (keys %TYPES) {
    		*{"${pkg}::${constraint}"} = find_type_constraint($constraint)->_compiled_type_constraint;
    	}        
    }    
}

# type constructors

sub type ($$) {
	my ($name, $check) = @_;
	_create_type_constraint($name, undef, $check);
}

sub subtype ($$;$$) {
	unshift @_ => undef if scalar @_ <= 2;
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
sub message (&) { $_[0] }

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

# define some basic types

type 'Any'  => where { 1 }; # meta-type including all
type 'Item' => where { 1 }; # base-type 

subtype 'Undef'   => as 'Item' => where { !defined($_) };
subtype 'Defined' => as 'Item' => where {  defined($_) };

subtype 'Bool'  => as 'Item' => where { !defined($_) || $_ eq "" || "$_" eq '1' || "$_" eq '0' };

subtype 'Value' => as 'Defined' => where { !ref($_) };
subtype 'Ref'   => as 'Defined' => where {  ref($_) };

subtype 'Str' => as 'Value' => where { 1 };

subtype 'Num' => as 'Value' => where { Scalar::Util::looks_like_number($_) };
subtype 'Int' => as 'Num'   => where { "$_" =~ /^-?[0-9]+$/ };

subtype 'ScalarRef' => as 'Ref' => where { ref($_) eq 'SCALAR' };
subtype 'ArrayRef'  => as 'Ref' => where { ref($_) eq 'ARRAY'  };
subtype 'HashRef'   => as 'Ref' => where { ref($_) eq 'HASH'   };	
subtype 'CodeRef'   => as 'Ref' => where { ref($_) eq 'CODE'   };
subtype 'RegexpRef' => as 'Ref' => where { ref($_) eq 'Regexp' };	
subtype 'GlobRef'   => as 'Ref' => where { ref($_) eq 'GLOB'   };

# NOTE:
# scalar filehandles are GLOB refs, 
# but a GLOB ref is not always a filehandle
subtype 'FileHandle' => as 'GlobRef' => where { Scalar::Util::openhandle($_) };

# NOTE: 
# blessed(qr/.../) returns true,.. how odd
subtype 'Object' => as 'Ref' => where { blessed($_) && blessed($_) ne 'Regexp' };

subtype 'Role' => as 'Object' => where { $_->can('does') };

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

This module provides Moose with the ability to create type contraints 
to be are used in both attribute definitions and for method argument 
validation. 

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
  subtype 'DateTime' => as Object => where { $_->isa('DateTime') };

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
    
=head1 FUNCTIONS

=head2 Type Constraint Registry

=over 4

=item B<find_type_constraint ($type_name)>

This function can be used to locate a specific type constraint 
meta-object. What you do with it from there is up to you :)

=item B<create_type_constraint_union (@type_constraint_names)>

Given a list of C<@type_constraint_names>, this will return a 
B<Moose::Meta::TypeConstraint::Union> instance.

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
