package Moose::Meta::Role::Application::ToRole;

use strict;
use warnings;
use metaclass;

use Carp            'confess';
use Scalar::Util    'blessed';

use Data::Dumper;

our $VERSION   = '0.55_01';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Role::Application';

sub apply {
    my ($self, $role1, $role2) = @_;    
    $self->SUPER::apply($role1, $role2);   
    $role2->add_role($role1);     
}

sub check_role_exclusions {
    my ($self, $role1, $role2) = @_;
    confess "Conflict detected: " . $role2->name . " excludes role '" . $role1->name . "'"
        if $role2->excludes_role($role1->name);
    foreach my $excluded_role_name ($role1->get_excluded_roles_list) {
        confess "The class " . $role2->name . " does the excluded role '$excluded_role_name'"
            if $role2->does_role($excluded_role_name);
        $role2->add_excluded_roles($excluded_role_name);
    }
}

sub check_required_methods {
    my ($self, $role1, $role2) = @_;
    foreach my $required_method_name ($role1->get_required_method_list) {
            
        next if $self->is_aliased_method($required_method_name);
                    
        $role2->add_required_methods($required_method_name)
            unless $role2->find_method_by_name($required_method_name);
    }
}

sub check_required_attributes {
    
}

sub apply_attributes {
    my ($self, $role1, $role2) = @_;
    foreach my $attribute_name ($role1->get_attribute_list) {
        # it if it has one already
        if ($role2->has_attribute($attribute_name) &&
            # make sure we haven't seen this one already too
            $role2->get_attribute($attribute_name) != $role1->get_attribute($attribute_name)) {
            confess "Role '" . $role1->name . "' has encountered an attribute conflict " .
                    "during composition. This is fatal error and cannot be disambiguated.";
        }
        else {
            $role2->add_attribute(
                $attribute_name,
                $role1->get_attribute($attribute_name)
            );
        }
    }
}

sub apply_methods {
    my ($self, $role1, $role2) = @_;
    foreach my $method_name ($role1->get_method_list) {
        
        next if $self->is_method_excluded($method_name);        

        if ($self->is_method_aliased($method_name)) {
            my $aliased_method_name = $self->get_method_aliases->{$method_name};
            # it if it has one already
            if ($role2->has_method($aliased_method_name) &&
                # and if they are not the same thing ...
                $role2->get_method($aliased_method_name)->body != $role1->get_method($method_name)->body) {
                confess "Cannot create a method alias if a local method of the same name exists";
            }

            $role2->alias_method(
                $aliased_method_name,
                $role1->get_method($method_name)
            );

            if (!$role2->has_method($method_name)) {
                $role2->add_required_methods($method_name);
            }

            next;
        }        
        
        # it if it has one already
        if ($role2->has_method($method_name) &&
            # and if they are not the same thing ...
            $role2->get_method($method_name)->body != $role1->get_method($method_name)->body) {
            # method conflicts between roles result
            # in the method becoming a requirement
            $role2->add_required_methods($method_name);
        }
        else {
            # add it, although it could be overriden
            $role2->alias_method(
                $method_name,
                $role1->get_method($method_name)
            );
                        
        }
        
    }
}

sub apply_override_method_modifiers {
    my ($self, $role1, $role2) = @_;
    foreach my $method_name ($role1->get_method_modifier_list('override')) {
        # it if it has one already then ...
        if ($role2->has_method($method_name)) {
            # if it is being composed into another role
            # we have a conflict here, because you cannot
            # combine an overriden method with a locally
            # defined one
            confess "Role '" . $role1->name . "' has encountered an 'override' method conflict " .
                    "during composition (A local method of the same name as been found). This " .
                    "is fatal error.";
        }
        else {
            # if we are a role, we need to make sure
            # we dont have a conflict with the role
            # we are composing into
            if ($role2->has_override_method_modifier($method_name) &&
                $role2->get_override_method_modifier($method_name) != $role2->get_override_method_modifier($method_name)) {
                confess "Role '" . $role1->name . "' has encountered an 'override' method conflict " .
                        "during composition (Two 'override' methods of the same name encountered). " .
                        "This is fatal error.";
            }
            else {
                # if there is no conflict,
                # just add it to the role
                $role2->add_override_method_modifier(
                    $method_name,
                    $role1->get_override_method_modifier($method_name)
                );
            }
        }
    }
}

sub apply_method_modifiers {
    my ($self, $modifier_type, $role1, $role2) = @_;
    my $add = "add_${modifier_type}_method_modifier";
    my $get = "get_${modifier_type}_method_modifiers";
    foreach my $method_name ($role1->get_method_modifier_list($modifier_type)) {
        $role2->$add(
            $method_name,
            $_
        ) foreach $role1->$get($method_name);
    }
}


1;

__END__

=pod

=head1 NAME

Moose::Meta::Role::Application::ToRole - Compose a role into another role

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<new>

=item B<meta>

=item B<apply>

=item B<check_role_exclusions>

=item B<check_required_methods>

=item B<check_required_attributes>

=item B<apply_attributes>

=item B<apply_methods>

=item B<apply_method_modifiers>

=item B<apply_override_method_modifiers>

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

