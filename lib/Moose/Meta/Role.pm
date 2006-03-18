
package Moose::Meta::Role;

use strict;
use warnings;
use metaclass;

use Carp         'confess';
use Scalar::Util 'blessed', 'reftype';
use Sub::Name    'subname';
use B            'svref_2object';

our $VERSION = '0.01';

Moose::Meta::Role->meta->add_attribute('$:package' => (
    reader   => 'name',
    init_arg => ':package',
));

Moose::Meta::Role->meta->add_attribute('@:requires' => (
    reader    => 'requires',
    predicate => 'has_requires',    
    init_arg  => ':requires',
    default   => sub { [] }
));

{
    my %ROLES;
    sub initialize {
        my ($class, %options) = @_;
        my $pkg = $options{':package'};
        $ROLES{$pkg} ||= $class->meta->new_object(%options);
    }
}

sub add_method {
    my ($self, $method_name, $method) = @_;
    (defined $method_name && $method_name)
        || confess "You must define a method name";
    # use reftype here to allow for blessed subs ...
    ('CODE' eq (reftype($method) || ''))
        || confess "Your code block must be a CODE reference";
    my $full_method_name = ($self->name . '::' . $method_name);    
	
    no strict 'refs';
    no warnings 'redefine';
    *{$full_method_name} = subname $full_method_name => $method;
}

sub alias_method {
    my ($self, $method_name, $method) = @_;
    (defined $method_name && $method_name)
        || confess "You must define a method name";
    # use reftype here to allow for blessed subs ...
    ('CODE' eq (reftype($method) || ''))
        || confess "Your code block must be a CODE reference";
    my $full_method_name = ($self->name . '::' . $method_name);  
        
    no strict 'refs';
    no warnings 'redefine';
    *{$full_method_name} = $method;
}

sub has_method {
    my ($self, $method_name) = @_;
    (defined $method_name && $method_name)
        || confess "You must define a method name";    

    my $sub_name = ($self->name . '::' . $method_name);   
    
    no strict 'refs';
    return 0 if !defined(&{$sub_name});        
	my $method = \&{$sub_name};
    return 0 if (svref_2object($method)->GV->STASH->NAME || '') ne $self->name &&
                (svref_2object($method)->GV->NAME || '')        ne '__ANON__';		
    return 1;
}

sub get_method {
    my ($self, $method_name) = @_;
    (defined $method_name && $method_name)
        || confess "You must define a method name";

	return unless $self->has_method($method_name);

    no strict 'refs';    
    return \&{$self->name . '::' . $method_name};
}

sub remove_method {
    my ($self, $method_name) = @_;
    (defined $method_name && $method_name)
        || confess "You must define a method name";
    
    my $removed_method = $self->get_method($method_name);    
    
    no strict 'refs';
    delete ${$self->name . '::'}{$method_name}
        if defined $removed_method;
        
    return $removed_method;
}

sub get_method_list {
    my $self = shift;
    no strict 'refs';
    grep { !/meta/ && $self->has_method($_) } %{$self->name . '::'};
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role - The Moose role metaobject

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

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