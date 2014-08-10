package Class::MOP::Method::Accessor;
our $VERSION = '2.2006';

use strict;
use warnings;

use Scalar::Util 'blessed', 'weaken';
use Try::Tiny;

use parent 'Class::MOP::Method::Generated';

sub new {
    my $class   = shift;
    my %options = @_;

    (exists $options{attribute})
        || $class->_throw_exception( MustSupplyAnAttributeToConstructWith => params => \%options,
                                                                    class  => $class,
                          );

    (exists $options{accessor_type})
        || $class->_throw_exception( MustSupplyAnAccessorTypeToConstructWith => params => \%options,
                                                                       class  => $class,
                          );

    (blessed($options{attribute}) && $options{attribute}->isa('Class::MOP::Attribute'))
        || $class->_throw_exception( MustSupplyAClassMOPAttributeInstance => params => \%options,
                                                                    class  => $class
                          );

    ($options{package_name} && $options{name})
        || $class->_throw_exception( MustSupplyPackageNameAndName => params => \%options,
                                                            class  => $class
                          );

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
        'method',
        ($self->is_inline ? 'inline' : ())
    );

    $self->{'body'} = $self->$method_name();
}

## generators

sub _generate_accessor_method {
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
        $self->_throw_exception( CouldNotGenerateInlineAttributeMethod => instance => $self,
                                                                  error    => $_,
                                                                  option   => "accessor"
                       );
    };
}

sub _generate_reader_method {
    my $self = shift;
    my $attr = $self->associated_attribute;
    my $class = $attr->associated_class;

    return sub {
        $self->_throw_exception( CannotAssignValueToReadOnlyAccessor => class_name => $class->name,
                                                                value      => $_[1],
                                                                attribute  => $attr
                       )
            if @_ > 1;
        $attr->get_value($_[0]);
    };
}

sub _generate_reader_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;
    my $attr_name = $attr->name;

    return try {
        $self->_compile_code([
            'sub {',
                'if (@_ > 1) {',
                    $self->_inline_throw_exception( CannotAssignValueToReadOnlyAccessor =>
                                                    'class_name                          => ref $_[0],'.
                                                    'value                               => $_[1],'.
                                                    "attribute_name                      => '".$attr_name."'",
                    ) . ';',
                '}',
                $attr->_inline_get_value('$_[0]'),
            '}',
        ]);
    }
    catch {
        $self->_throw_exception( CouldNotGenerateInlineAttributeMethod => instance => $self,
                                                                  error    => $_,
                                                                  option   => "reader"
                       );
    };
}

sub _generate_writer_method {
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
        $self->_throw_exception( CouldNotGenerateInlineAttributeMethod => instance => $self,
                                                                  error    => $_,
                                                                  option   => "writer"
                       );
    };
}

sub _generate_predicate_method {
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
        $self->_throw_exception( CouldNotGenerateInlineAttributeMethod => instance => $self,
                                                                  error    => $_,
                                                                  option   => "predicate"
                       );
    };
}

sub _generate_clearer_method {
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
        $self->_throw_exception( CouldNotGenerateInlineAttributeMethod => instance => $self,
                                                                  error    => $_,
                                                                  option   => "clearer"
                       );
    };
}

1;

# ABSTRACT: Method Meta Object for accessors

__END__

=pod

=head1 DESCRIPTION

See the L<Moose::Meta::Method::Accessor> documentation for API details.

=cut
