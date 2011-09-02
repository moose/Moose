
package Class::MOP::Method::Accessor;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed', 'weaken';
use Try::Tiny;

use base 'Class::MOP::Method::Generated';

sub new {
    my $class   = shift;
    my %options = @_;

    (exists $options{attribute})
        || confess "You must supply an attribute to construct with";

    (exists $options{accessor_type})
        || confess "You must supply an accessor_type to construct with";

    (blessed($options{attribute}) && $options{attribute}->isa('Class::MOP::Attribute'))
        || confess "You must supply an attribute which is a 'Class::MOP::Attribute' instance";

    ($options{package_name} && $options{name})
        || confess "You must supply the package_name and name parameters $Class::MOP::Method::UPGRADE_ERROR_TEXT";

    my $self = $class->_new(\%options);

    # we don't want this creating
    # a cycle in the code, if not
    # needed
    weaken($self->{'attribute'});

    $self->_initialize_body;

    return $self;
}

sub _new {
    my $class = shift;

    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $params = @_ == 1 ? $_[0] : {@_};

    return bless {
        # inherited from Class::MOP::Method
        body                 => $params->{body},
        associated_metaclass => $params->{associated_metaclass},
        package_name         => $params->{package_name},
        name                 => $params->{name},
        original_method      => $params->{original_method},

        # inherit from Class::MOP::Generated
        is_inline            => $params->{is_inline} || 0,
        definition_context   => $params->{definition_context},

        # defined in this class
        attribute            => $params->{attribute},
        accessor_type        => $params->{accessor_type},
    } => $class;
}

## accessors

sub associated_attribute { (shift)->{'attribute'}     }
sub accessor_type        { (shift)->{'accessor_type'} }

## factory

sub _initialize_body {
    my $self = shift;

    my $method_name = join "_" => (
        '_generate',
        $self->accessor_type,
        'method'
    );

    $self->{'body'} = $self->$method_name();
}

sub _error_thrower {
    my $self = shift;

    return $self->associated_attribute
        if ref $self
            && $self->associated_attribute
            && $self->associated_attribute->can('throw_error');

    return $self->SUPER::_error_thrower;
}

sub _compile_code {
    my $self = shift;
    my @args = @_;
    try {
        $self->SUPER::_compile_code(@args);
    }
    catch {
        $self->throw_error(
            'Could not create writer for '
          . "'" . $self->associated_attribute->name . "' "
          . 'because ' . $_,
            error => $_,
        );
    };
}

sub _eval_environment {
    my $self = shift;
    return $self->associated_attribute->_eval_environment
        if $self->associated_attribute->can('_eval_environment');
}

sub _instance_is_inlinable {
    my $self = shift;
    return $self->associated_attribute->associated_class->instance_metaclass->is_inlinable;
}

sub _generate_reader_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_reader_method_inline(@_)
                                  : $self->_generate_reader_method_non_inline(@_);
}

sub _generate_writer_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_writer_method_inline(@_)
                                  : $self->_generate_writer_method_non_inline(@_);
}

sub _generate_accessor_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_accessor_method_inline(@_)
                                  : $self->_generate_accessor_method_non_inline(@_);
}

sub _generate_predicate_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_predicate_method_inline(@_)
                                  : $self->_generate_predicate_method_non_inline(@_);
}

sub _generate_clearer_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_clearer_method_inline(@_)
                                  : $self->_generate_clearer_method_non_inline(@_);
}

sub _generate_accessor_method_non_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return sub {
        if (@_ >= 2) {
            $attr->set_value($_[0], $_[1]);
        }
        $attr->get_value($_[0]);
    };
}

sub _generate_accessor_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return try {
        $self->_compile_code([
            'sub {',
                'if (@_ > 1) {',
                    $attr->_inline_set_value('$_[0]', '$_[1]'),
                '}',
                $attr->_inline_get_value('$_[0]'),
            '}',
        ]);
    }
    catch {
        confess "Could not generate inline accessor because : $_";
    };
}

sub _generate_reader_method_non_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return sub {
        confess "Cannot assign a value to a read-only accessor"
            if @_ > 1;
        $attr->get_value($_[0]);
    };
}

sub _generate_reader_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return try {
        $self->_compile_code([
            'sub {',
                'if (@_ > 1) {',
                    # XXX: this is a hack, but our error stuff is terrible
                    $self->_inline_throw_error(
                        '"Cannot assign a value to a read-only accessor"',
                        'data => \@_'
                    ) . ';',
                '}',
                $attr->_inline_get_value('$_[0]'),
            '}',
        ]);
    }
    catch {
        confess "Could not generate inline reader because : $_";
    };
}

sub _inline_throw_error {
    my $self = shift;
    return 'Carp::confess ' . $_[0];
}

sub _generate_writer_method_non_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return sub {
        $attr->set_value($_[0], $_[1]);
    };
}

sub _generate_writer_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return try {
        $self->_compile_code([
            'sub {',
                $attr->_inline_set_value('$_[0]', '$_[1]'),
            '}',
        ]);
    }
    catch {
        confess "Could not generate inline writer because : $_";
    };
}

sub _generate_predicate_method_non_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return sub {
        $attr->has_value($_[0])
    };
}

sub _generate_predicate_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return try {
        $self->_compile_code([
            'sub {',
                $attr->_inline_has_value('$_[0]'),
            '}',
        ]);
    }
    catch {
        confess "Could not generate inline predicate because : $_";
    };
}

sub _generate_clearer_method_non_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return sub {
        $attr->clear_value($_[0])
    };
}

sub _generate_clearer_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return try {
        $self->_compile_code([
            'sub {',
                $attr->_inline_clear_value('$_[0]'),
            '}',
        ]);
    }
    catch {
        confess "Could not generate inline clearer because : $_";
    };
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

# ABSTRACT: Method Meta Object for accessors

__END__

=pod

=head1 SYNOPSIS

    use Class::MOP::Method::Accessor;

    my $reader = Class::MOP::Method::Accessor->new(
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

=head1 METHODS

=over 4

=item B<< Class::MOP::Method::Accessor->new(%options) >>

This returns a new C<Class::MOP::Method::Accessor> based on the
C<%options> provided.

=over 4

=item * attribute

This is the C<Class::MOP::Attribute> for which accessors are being
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

=item B<< $metamethod->accessor_type >>

Returns the accessor type which was passed to C<new>.

=item B<< $metamethod->is_inline >>

Returns a boolean indicating whether or not the accessor is inlined.

=item B<< $metamethod->associated_attribute >>

This returns the L<Class::MOP::Attribute> object which was passed to
C<new>.

=item B<< $metamethod->body >>

The method itself is I<generated> when the accessor object is
constructed.

=back

=cut

