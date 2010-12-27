
package Class::MOP::Method::Generated;

use strict;
use warnings;

use Carp 'confess';
use Eval::Closure;

our $AUTHORITY = 'cpan:STEVAN';

use base 'Class::MOP::Method';

## accessors

sub new {
    confess __PACKAGE__ . " is an abstract base class, you must provide a constructor.";
}

sub _initialize_body {
    confess "No body to initialize, " . __PACKAGE__ . " is an abstract base class";
}

sub _generate_description {
    my ( $self, $context ) = @_;
    $context ||= $self->definition_context;

    return "generated method (unknown origin)"
        unless defined $context;

    if (defined $context->{description}) {
        return "$context->{description} "
             . "(defined at $context->{file} line $context->{line})";
    } else {
        return "$context->{file} (line $context->{line})";
    }
}

sub _compile_code {
    my ( $self, @args ) = @_;
    unshift @args, 'source' if @args % 2;
    my %args = @args;

    my $context = delete $args{context};
    my $environment = $self->can('_eval_environment')
        ? $self->_eval_environment
        : {};

    return eval_closure(
        environment => $environment,
        description => $self->_generate_description($context),
        %args,
    );
}

1;

__END__

=pod

=head1 NAME 

Class::MOP::Method::Generated - Abstract base class for generated methods

=head1 DESCRIPTION

This is a C<Class::MOP::Method> subclass which is subclassed by
C<Class::MOP::Method::Accessor> and
C<Class::MOP::Method::Constructor>.

It is not intended to be used directly.

=cut

