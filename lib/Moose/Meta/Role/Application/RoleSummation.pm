package Moose::Meta::Role::Application::RoleSummation;

use strict;
use warnings;
use metaclass;

use Carp            'confess';
use Scalar::Util    'blessed';
use Data::Dumper;

use Moose::Meta::Role::Composite;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Role::Application';

# stolen from List::MoreUtils ...
my $uniq = sub { my %h; map { $h{$_}++ == 0 ? $_ : () } @_ };

sub check_role_exclusions {
    my ($self, $c) = @_;

    my @all_excluded_roles = $uniq->(map {
        $_->get_excluded_roles_list
    } @{$c->get_roles});

    foreach my $role (@{$c->get_roles}) {
        foreach my $excluded (@all_excluded_roles) {
            confess "Conflict detected: " . $role->name . " excludes role '" . $excluded . "'"
                if $role->does_role($excluded);
        }
    }

    $c->add_excluded_roles(@all_excluded_roles);
}

sub check_required_methods {
    my ($self, $c) = @_;

    my %all_required_methods = map { $_ => undef } $uniq->(map {
        $_->get_required_method_list
    } @{$c->get_roles});

    foreach my $role (@{$c->get_roles}) {
        foreach my $required (keys %all_required_methods) {
            delete $all_required_methods{$required}
                if $role->has_method($required);
        }
    }

    $c->add_required_methods(keys %all_required_methods);
}

sub apply_attributes {
    my ($self, $c) = @_;
    
    my @all_attributes = map {
        my $role = $_;
        map { 
            +{ 
                name => $_,
                attr => $role->get_attribute($_),
            }
        } $role->get_attribute_list
    } @{$c->get_roles};
    
    my %seen;
    foreach my $attr (@all_attributes) {
        if (exists $seen{$attr->{name}}) {
            confess "We have encountered an attribute conflict with '" . $attr->{name} . "'" 
                  . "during composition. This is fatal error and cannot be disambiguated."
                if $seen{$attr->{name}} != $attr->{attr};           
        }
        $seen{$attr->{name}} = $attr->{attr};
    }

    foreach my $attr (@all_attributes) {    
        $c->add_attribute($attr->{name}, $attr->{attr});
    }
}

sub apply_methods {
    my ($self, $c) = @_;
    
    my @all_methods = map {
        my $role = $_;
        map { 
            +{ 
                name   => $_,
                method => $role->get_method($_),
            }
        } $role->get_method_list;
    } @{$c->get_roles};
    
    my (%seen, %method_map);
    foreach my $method (@all_methods) {
        if (exists $seen{$method->{name}}) {
            if ($seen{$method->{name}}->body != $method->{method}->body) {
                $c->add_required_methods($method->{name});
                delete $method_map{$method->{name}};
                next;
            }           
        }
        $seen{$method->{name}}       = $method->{method};
        $method_map{$method->{name}} = $method->{method};
    }

    $c->alias_method($_ => $method_map{$_}) for keys %method_map;
}

sub apply_override_method_modifiers {
    my ($self, $c) = @_;
    
    my @all_overrides = map {
        my $role = $_;
        map { 
            +{ 
                name   => $_,
                method => $role->get_override_method_modifier($_),
            }
        } $role->get_method_modifier_list('override');
    } @{$c->get_roles};
    
    my %seen;
    foreach my $override (@all_overrides) {
        confess "Role '" . $c->name . "' has encountered an 'override' method conflict " .
                "during composition (A local method of the same name as been found). This " .
                "is fatal error."
            if $c->has_method($override->{name});        
        if (exists $seen{$override->{name}}) {
            confess "We have encountered an 'override' method conflict during " .
                    "composition (Two 'override' methods of the same name encountered). " .
                    "This is fatal error."
                if $seen{$override->{name}} != $override->{method};                
        }
        $seen{$override->{name}} = $override->{method};
    }
        
    $c->add_override_method_modifier(
        $_->{name}, $_->{method}
    ) for @all_overrides;
            
}

sub apply_method_modifiers {
    my ($self, $modifier_type, $c) = @_;
    my $add = "add_${modifier_type}_method_modifier";
    my $get = "get_${modifier_type}_method_modifiers";
    foreach my $role (@{$c->get_roles}) {
        foreach my $method_name ($role->get_method_modifier_list($modifier_type)) {
            $c->$add(
                $method_name,
                $_
            ) foreach $role->$get($method_name);
        }
    }
}

sub apply_before_method_modifiers { (shift)->apply_method_modifiers('before' => @_) }
sub apply_around_method_modifiers { (shift)->apply_method_modifiers('around' => @_) }
sub apply_after_method_modifiers  { (shift)->apply_method_modifiers('after'  => @_) }

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role::Application::RoleSummation

=head1 DESCRIPTION

Summation composes two traits, forming the union of non-conflicting 
bindings and 'disabling' the conflicting bindings

=head2 METHODS

=over 4

=item B<new>

=item B<meta>

=item B<apply>

=item B<check_required_methods>

=item B<check_role_exclusions>

=item B<apply_attributes>

=item B<apply_methods>

=item B<apply_method_modifiers>

=item B<apply_before_method_modifiers>

=item B<apply_after_method_modifiers>

=item B<apply_around_method_modifiers>

=item B<apply_override_method_modifiers>

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

