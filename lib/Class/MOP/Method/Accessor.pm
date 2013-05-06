
package Class::MOP::Method::Accessor;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed', 'weaken', 'refaddr';
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

sub _generate_deferred_inline_method {
    my ($self, $gen, $gen_type) = @_;

    my $RuNNeR;
    my $orig;
    return $orig = bless sub {
        # there are several situations to handle - mostly just think about
        # what happens on inheritance, composition, overriding, monkey-patching,
        # etc.  This should sync with the latest canonical database of record.
        if (!defined($RuNNeR)) {
            try {
                $RuNNeR = $gen->($self, $self->associated_attribute);
            }
            catch {
                confess "Could not generate inline $gen_type because : $_";
            };
            # update the body member unless something else has stomped on it
            my $body = $self->{'body'};
            if (refaddr($orig) != refaddr($body)) {
                # we seem to be outdated... paranoid future-proofing, I think..
                goto $RuNNeR = $body;
            }
            $self->{'body'} = $RuNNeR;
            # update the symbol in the stash if it's currently immutable
            # and it's still the original we set previously.
            my $assoc_class = $self->associated_attribute->associated_class;
            my $sigiled_name = '&'.$self->{'name'};
            if ($assoc_class->is_immutable) {
                my $stash = $assoc_class->_package_stash;
                my $symbol_ref = $stash->get_symbol($sigiled_name);
                if (!defined($symbol_ref)) {
                    confess "A metaobject is corrupted";
                }
                if (refaddr($orig) != refaddr($symbol_ref)) {
                    goto $RuNNeR = $symbol_ref;
                }
                $stash->add_symbol($sigiled_name, $RuNNeR);
            }
        };
        return unless defined($_[0]);
        goto $RuNNeR;
    },'RuNNeR';
}

sub _generate_accessor_method_inline {
    return _generate_deferred_inline_method(shift, sub {
        my ($self, $attr) = @_;
        return $self->_compile_code([
            'sub {',
                'if (@_ > 1) {',
                    $attr->_inline_set_value('$_[0]', '$_[1]'),
                '}',
                $attr->_inline_get_value('$_[0]'),
            '}',
        ]);
    }, "accessor");
}

sub _generate_reader_method {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return sub {
        confess "Cannot assign a value to a read-only accessor"
            if @_ > 1;
        $attr->get_value($_[0]);
    };
}

sub _generate_reader_method_inline {
    return _generate_deferred_inline_method(shift, sub {
        my ($self, $attr) = @_;
        return $self->_compile_code([
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
    }, "reader");
}

sub _inline_throw_error {
    my $self = shift;
    return 'Carp::confess ' . $_[0];
}

sub _generate_writer_method {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return sub {
        $attr->set_value($_[0], $_[1]);
    };
}

sub _generate_writer_method_inline {
    return _generate_deferred_inline_method(shift, sub {
        my ($self, $attr) = @_;
        return $self->_compile_code([
            'sub {',
                $attr->_inline_set_value('$_[0]', '$_[1]'),
            '}',
        ]);
    }, "writer");
}

sub _generate_predicate_method {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return sub {
        $attr->has_value($_[0])
    };
}

sub _generate_predicate_method_inline {
    return _generate_deferred_inline_method(shift, sub {
        my ($self, $attr) = @_;
        return $self->_compile_code([
            'sub {',
                $attr->_inline_has_value('$_[0]'),
            '}',
        ]);
    }, "predicate");
}

sub _generate_clearer_method {
    my $self = shift;
    my $attr = $self->associated_attribute;

    return sub {
        $attr->clear_value($_[0])
    };
}

sub _generate_clearer_method_inline {
    return _generate_deferred_inline_method(shift, sub {
        my ($self, $attr) = @_;
        return $self->_compile_code([
            'sub {',
                $attr->_inline_clear_value('$_[0]'),
            '}',
        ]);
    }, "clearer");
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

