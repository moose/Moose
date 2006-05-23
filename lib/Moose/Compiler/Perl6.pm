
package Moose::Compiler::Perl6;
use Moose;

our $VERSION = '0.01';

with 'Moose::Compiler::Engine';

sub compile_class {
    my ($self, $meta) = @_;
    my $o = '';
    $o .= ('class ' . $meta->name . "-" . $meta->version . " {\n");
    $o .= ("\n");                      
    foreach my $attr_name ($meta->get_attribute_list) {
        my $attr = $meta->get_attribute($attr_name);
        my @options;
        push @options => ("is " . $attr->_is_metadata . "") 
            if $attr->_is_metadata;
        push @options => ("does " . $attr->_does_metadata . "") 
            if $attr->_does_metadata;            
        $o .= ("    has " . ($attr->_isa_metadata ? ($attr->_isa_metadata . " ") : '')
           .   "\$" . $attr->name . " " . (join " " => @options) . ";\n");                  
    }    
    $o .= ("\n"); 
    $o .= ("}\n");            
    return $o;      
}

1;

__END__

=pod

=head1 NAME

Moose::Compiler::Perl6 - A Moose compiler engine for compiling to Perl 6

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<meta>

This will return the metaclass associated with the given role.

=item B<compile_class>

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
