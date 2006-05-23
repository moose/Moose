
package Moose::Compiler::Perl5;
use Moose;

our $VERSION = '0.01';

with 'Moose::Compiler::Engine';

sub compile_class {
    my ($self, $meta) = @_;
    my $o = '';
    $o .= ('package ' . $meta->name . ";\n");
    $o .= ("\n");  
    $o .= ("use strict;\n");    
    $o .= ("use warnings;\n");         
    $o .= ("\n");  
    $o .= ("our \$VERSION = '" . $meta->version . "';\n");      
    $o .= ("\n");  
    $o .= ("sub new {\n");      
    $o .= ("    my (\$class, \%params) = \@_;\n");          
    $o .= ("    my \%proto = (\n");                  
    foreach my $attr_name ($meta->get_attribute_list) {
        $o .= ("        '" . $attr_name . "' => undef,\n");                          
    }
    $o .= ("    );\n");                      
    $o .= ("    return bless { \%proto, \%params } => \$class;\n");              
    $o .= ("}\n");  
    $o .= ("\n");  
    
    foreach my $attr_name ($meta->get_attribute_list) {
        my $attr = $meta->get_attribute($attr_name);        
        $o .= ("sub " . $attr->reader    . " {" . ('') . "}\n\n")    if $attr->has_reader;                          
        $o .= ("sub " . $attr->writer    . " {" . ('') . "}\n\n")    if $attr->has_writer;                          
        $o .= ("sub " . $attr->accessor  . " {" . ('') . "}\n\n")  if $attr->has_accessor;                                  
        $o .= ("sub " . $attr->predicate . " {" . ('') . "}\n\n") if $attr->has_predicate;                                          
    }
    
    $o .= ("1;\n");          
    $o .= ("\n");  
    $o .= ("__END__\n");          
    return $o;      
}

1;

__END__

=pod

=head1 NAME

Moose::Compiler::Perl5 - A Moose compiler engine for compiling to Perl 5

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
