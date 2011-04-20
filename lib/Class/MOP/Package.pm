
package Class::MOP::Package;

use strict;
use warnings;

use Scalar::Util 'blessed', 'reftype', 'weaken';
use Carp         'confess';
use Devel::GlobalDestruction 'in_global_destruction';
use Package::Stash;

use base 'Class::MOP::Object';

# creation ...

sub initialize {
    my ( $class, @args ) = @_;

    unshift @args, "package" if @args % 2;

    my %options = @args;
    my $package_name = delete $options{package};


    # we hand-construct the class 
    # until we can bootstrap it
    if ( my $meta = Class::MOP::get_metaclass_by_name($package_name) ) {
        return $meta;
    } else {
        my $meta = ( ref $class || $class )->_new({
            'package'   => $package_name,
            %options,
        });
        Class::MOP::store_metaclass_by_name($package_name, $meta);

        Class::MOP::weaken_metaclass($package_name) if $options{weaken};


        return $meta;
    }
}

sub reinitialize {
    my ( $class, @args ) = @_;

    unshift @args, "package" if @args % 2;

    my %options = @args;
    my $package_name = delete $options{package};

    (defined $package_name && $package_name
      && (!blessed $package_name || $package_name->isa('Class::MOP::Package')))
        || confess "You must pass a package name or an existing Class::MOP::Package instance";

    $package_name = $package_name->name
        if blessed $package_name;

    Class::MOP::remove_metaclass_by_name($package_name);

    $class->initialize($package_name, %options); # call with first arg form for compat
}

sub create {
    my $class = shift;
    my @args = @_;

    return $class->initialize(@args);
}

## ANON packages

{
    # NOTE:
    # this should be sufficient, if you have a
    # use case where it is not, write a test and
    # I will change it.
    my $ANON_SERIAL = 0;

    my %ANON_PACKAGE_CACHE;

    # NOTE:
    # we need a sufficiently annoying prefix
    # this should suffice for now, this is
    # used in a couple of places below, so
    # need to put it up here for now.
    sub _anon_package_prefix { 'Class::MOP::Package::__ANON__::SERIAL::' }

    sub is_anon {
        my $self = shift;
        no warnings 'uninitialized';
        my $prefix = $self->_anon_package_prefix;
        $self->name =~ /^$prefix/;
    }

    sub create_anon {
        my ($class, %options) = @_;

        my $cache_ok = delete $options{cache};

        my $cache_key;
        if ($cache_ok) {
            $cache_key = $class->_anon_cache_key(%options);

            if (defined $ANON_PACKAGE_CACHE{$cache_key}) {
                return $ANON_PACKAGE_CACHE{$cache_key};
            }
        }

        $options{weaken} = !$cache_ok unless exists $options{weaken};

        my $package_name = $class->_anon_package_prefix . ++$ANON_SERIAL;

        my $meta = $class->create($package_name, %options);

        if ($cache_ok) {
            $ANON_PACKAGE_CACHE{$cache_key} = $meta;
            weaken($ANON_PACKAGE_CACHE{$cache_key});
        }

        return $meta;
    }

    sub _anon_cache_key { confess "Packages are not cacheable" }

    sub DESTROY {
        my $self = shift;

        return if in_global_destruction(); # it'll happen soon anyway and this just makes things more complicated

        $self->_free_anon
            if $self->is_anon;
    }

    sub _free_anon {
        my $self = shift;
        my $name = $self->name;

        # Moose does a weird thing where it replaces the metaclass for
        # class when fixing metaclass incompatibility. In that case,
        # we don't want to clean out the namespace now. We can detect
        # that because Moose will explicitly update the singleton
        # cache in Class::MOP.
        no warnings 'uninitialized';
        my $current_meta = Class::MOP::get_metaclass_by_name($name);
        return if $current_meta ne $self;

        my ($first_fragments, $last_fragment) = ($name =~ /^(.*)::(.*)$/);

        no strict 'refs';
        @{$name . '::ISA'} = ();
        %{$name . '::'}    = ();
        delete ${$first_fragments . '::'}{$last_fragment . '::'};

        Class::MOP::remove_metaclass_by_name($name);
    }

}

sub _new {
    my $class = shift;

    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $params = @_ == 1 ? $_[0] : {@_};

    return bless {
        # Need to quote package to avoid a problem with PPI mis-parsing this
        # as a package statement.
        'package' => $params->{package},

        # NOTE:
        # because of issues with the Perl API
        # to the typeglob in some versions, we
        # need to just always grab a new
        # reference to the hash in the accessor.
        # Ideally we could just store a ref and
        # it would Just Work, but oh well :\

        namespace => \undef,

    } => $class;
}

# Attributes

# NOTE:
# all these attribute readers will be bootstrapped 
# away in the Class::MOP bootstrap section

sub _package_stash {
    $_[0]->{_package_stash} ||= Package::Stash->new($_[0]->name)
}
sub namespace {
    $_[0]->_package_stash->namespace
}

# Class attributes

# ... these functions have to touch the symbol table itself,.. yuk

sub add_package_symbol {
    my $self = shift;
    $self->_package_stash->add_symbol(@_);
}

sub remove_package_glob {
    my $self = shift;
    $self->_package_stash->remove_glob(@_);
}

# ... these functions deal with stuff on the namespace level

sub has_package_symbol {
    my $self = shift;
    $self->_package_stash->has_symbol(@_);
}

sub get_package_symbol {
    my $self = shift;
    $self->_package_stash->get_symbol(@_);
}

sub get_or_add_package_symbol {
    my $self = shift;
    $self->_package_stash->get_or_add_symbol(@_);
}

sub remove_package_symbol {
    my $self = shift;
    $self->_package_stash->remove_symbol(@_);
}

sub list_all_package_symbols {
    my $self = shift;
    $self->_package_stash->list_all_symbols(@_);
}

sub get_all_package_symbols {
    my $self = shift;
    $self->_package_stash->get_all_symbols(@_);
}

1;

# ABSTRACT: Package Meta Object

__END__

=pod

=head1 DESCRIPTION

The Package Protocol provides an abstraction of a Perl 5 package. A
package is basically namespace, and this module provides methods for
looking at and changing that namespace's symbol table.

=head1 METHODS

=over 4

=item B<< Class::MOP::Package->initialize($package_name) >>

This method creates a new C<Class::MOP::Package> instance which
represents specified package. If an existing metaclass object exists
for the package, that will be returned instead.

=item B<< Class::MOP::Package->reinitialize($package) >>

This method forcibly removes any existing metaclass for the package
before calling C<initialize>. In contrast to C<initialize>, you may
also pass an existing C<Class::MOP::Package> instance instead of just
a package name as C<$package>.

Do not call this unless you know what you are doing.

=item B<< $metapackage->name >>

This is returns the package's name, as passed to the constructor.

=item B<< $metapackage->namespace >>

This returns a hash reference to the package's symbol table. The keys
are symbol names and the values are typeglob references.

=item B<< $metapackage->add_package_symbol($variable_name, $initial_value) >>

This method accepts a variable name and an optional initial value. The
C<$variable_name> must contain a leading sigil.

This method creates the variable in the package's symbol table, and
sets it to the initial value if one was provided.

=item B<< $metapackage->get_package_symbol($variable_name) >>

Given a variable name, this method returns the variable as a reference
or undef if it does not exist. The C<$variable_name> must contain a
leading sigil.

=item B<< $metapackage->get_or_add_package_symbol($variable_name) >>

Given a variable name, this method returns the variable as a reference.
If it does not exist, a default value will be generated if possible. The
C<$variable_name> must contain a leading sigil.

=item B<< $metapackage->has_package_symbol($variable_name) >>

Returns true if there is a package variable defined for
C<$variable_name>. The C<$variable_name> must contain a leading sigil.

=item B<< $metapackage->remove_package_symbol($variable_name) >>

This will remove the package variable specified C<$variable_name>. The
C<$variable_name> must contain a leading sigil.

=item B<< $metapackage->remove_package_glob($glob_name) >>

Given the name of a glob, this will remove that glob from the
package's symbol table. Glob names do not include a sigil. Removing
the glob removes all variables and subroutines with the specified
name.

=item B<< $metapackage->list_all_package_symbols($type_filter) >>

This will list all the glob names associated with the current
package. These names do not have leading sigils.

You can provide an optional type filter, which should be one of
'SCALAR', 'ARRAY', 'HASH', or 'CODE'.

=item B<< $metapackage->get_all_package_symbols($type_filter) >>

This works much like C<list_all_package_symbols>, but it returns a
hash reference. The keys are glob names and the values are references
to the value for that name.

=item B<< Class::MOP::Package->meta >>

This will return a L<Class::MOP::Class> instance for this class.

=back

=cut
