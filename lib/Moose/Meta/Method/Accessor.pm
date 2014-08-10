package Moose::Meta::Method::Accessor;
our $VERSION = '2.2006';

use strict;
use warnings;

use Try::Tiny;

use parent 'Moose::Meta::Method',
         'Class::MOP::Method::Accessor';

use Moose::Util 'throw_exception';

# multiple inheritance is terrible
sub new {
    goto &Class::MOP::Method::Accessor::new;
}

sub _new {
    goto &Class::MOP::Method::Accessor::_new;
}

sub _error_thrower {
    my $self = shift;
    return $self->associated_attribute
        if ref($self) && defined($self->associated_attribute);
    return $self->SUPER::_error_thrower;
}

sub _compile_code {
    my $self = shift;
    my @args = @_;
    try {
        $self->SUPER::_compile_code(@args);
    }
    catch {
        throw_exception( CouldNotCreateWriter => attribute      => $self->associated_attribute,
                                                 error          => $_,
                                                 instance       => $self
                       );
    };
}

sub _eval_environment {
    my $self = shift;
    return $self->associated_attribute->_eval_environment;
}

sub _instance_is_inlinable {
    my $self = shift;
    return $self->associated_attribute->associated_class->instance_metaclass->is_inlinable;
}

sub _generate_reader_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_reader_method_inline(@_)
                                  : $self->SUPER::_generate_reader_method(@_);
}

sub _generate_writer_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_writer_method_inline(@_)
                                  : $self->SUPER::_generate_writer_method(@_);
}

sub _generate_accessor_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_accessor_method_inline(@_)
                                  : $self->SUPER::_generate_accessor_method(@_);
}

sub _generate_predicate_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_predicate_method_inline(@_)
                                  : $self->SUPER::_generate_predicate_method(@_);
}

sub _generate_clearer_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_clearer_method_inline(@_)
                                  : $self->SUPER::_generate_clearer_method(@_);
}

sub _writer_value_needs_copy {
    shift->associated_attribute->_writer_value_needs_copy(@_);
}

sub _inline_tc_code {
    shift->associated_attribute->_inline_tc_code(@_);
}

sub _inline_check_coercion {
    shift->associated_attribute->_inline_check_coercion(@_);
}

sub _inline_check_constraint {
    shift->associated_attribute->_inline_check_constraint(@_);
}

sub _inline_check_lazy {
    shift->associated_attribute->_inline_check_lazy(@_);
}

sub _inline_store_value {
    shift->associated_attribute->_inline_instance_set(@_) . ';';
}

sub _inline_get_old_value_for_trigger {
    shift->associated_attribute->_inline_get_old_value_for_trigger(@_);
}

sub _inline_trigger {
    shift->associated_attribute->_inline_trigger(@_);
}

sub _get_value {
    shift->associated_attribute->_inline_instance_get(@_);
}

sub _has_value {
    shift->associated_attribute->_inline_instance_has(@_);
}

1;

# ABSTRACT: A Moose Method metaclass for accessors

__END__

=pod

=head1 SYNOPSIS

    use Moose::Meta::Method::Accessor;

    my $reader = Moose::Meta::Method::Accessor->new(
        attribute     => $attribute,
        is_inline     => 1,
        accessor_type => 'reader',
    );

    $reader->body->execute($instance); # call the reader method

=head1 DESCRIPTION

This is a subclass of C<Class::MOP::Method> which is used by
C<Class::MOP::Attribute> to generate accessor code. It handles
generation of readers, writers, predicates and clearers. For each type
of method, it can either create a subroutine reference, or actually
inline code by generating a string and C<eval>'ing it.

=head1 INHERITANCE

C<Moose::Meta::Method::Accessor> is a subclass of L<Moose::Meta::Method>
I<and> C<Class::MOP::Method::Accessor>. All of the methods for
C<Moose::Meta::Method::Accessor> and C<Class::MOP::Method::Accessor> are
documented here.

=head1 METHODS

This class provides the following methods.

=head2 Moose::Meta::Method::Accessor->new(%options)

This returns a new C<Moose::Meta::Method::Accessor> based on the
C<%options> provided.

=over 4

=item * attribute

This is the C<Moose::Meta::Attribute> for which accessors are being
generated. This option is required.

=item * accessor_type

This is a string which should be one of "reader", "writer",
"accessor", "predicate", or "clearer". This is the type of method
being generated. This option is required.

=item * is_inline

This indicates whether or not the accessor should be inlined. This
defaults to false.

=item * name

The method name (without a package name). This is required.

=item * package_name

The package name for the method. This is required.

=back

=head2 $metamethod->accessor_type

Returns the accessor type which was passed to C<new>.

=head2 $metamethod->is_inline

Returns a boolean indicating whether or not the accessor is inlined.

=head2 $metamethod->associated_attribute

This returns the L<Moose::Meta::Attribute> object which was passed to C<new>.

=head2 $metamethod->body

The method itself is I<generated> when the accessor object is
constructed.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
