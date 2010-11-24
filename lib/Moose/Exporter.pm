package Moose::Exporter;

use strict;
use warnings;

our $VERSION = '1.21';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Class::MOP;
use List::MoreUtils qw( first_index uniq );
use Moose::Util::MetaRole;
use Scalar::Util qw(reftype);
use Sub::Exporter 0.980;
use Sub::Name qw(subname);

use XSLoader;

XSLoader::load( 'Moose', $XS_VERSION );

my %EXPORT_SPEC;

sub setup_import_methods {
    my ( $class, %args ) = @_;

    my $exporting_package = $args{exporting_package} ||= caller();

    $class->build_import_methods(
        %args,
        install => [qw(import unimport init_meta)]
    );
}

sub build_import_methods {
    my ( $class, %args ) = @_;

    my $exporting_package = $args{exporting_package} ||= caller();

    $EXPORT_SPEC{$exporting_package} = \%args;

    my @exports_from = $class->_follow_also($exporting_package);

    my $export_recorder = {};
    my $is_reexport     = {};

    my $exports = $class->_make_sub_exporter_params(
        [ @exports_from, $exporting_package ],
        $export_recorder,
        $is_reexport,
    );

    my $exporter = $class->_make_exporter($exports, $is_reexport);

    my %methods;
    $methods{import} = $class->_make_import_sub(
        $exporting_package,
        $exporter,
        \@exports_from,
        $is_reexport
    );

    $methods{unimport} = $class->_make_unimport_sub(
        $exporting_package,
        $exports,
        $export_recorder,
        $is_reexport
    );

    $methods{init_meta} = $class->_make_init_meta(
        $exporting_package,
        \%args
    );

    my $package = Class::MOP::Package->initialize($exporting_package);
    for my $to_install ( @{ $args{install} || [] } ) {
        my $symbol = '&' . $to_install;
        next
            unless $methods{$to_install}
                && !$package->has_package_symbol($symbol);
        $package->add_package_symbol( $symbol, $methods{$to_install} );
    }

    return ( $methods{import}, $methods{unimport}, $methods{init_meta} );
}

sub _make_exporter {
    my ($class, $exports, $is_reexport) = @_;

    return Sub::Exporter::build_exporter(
        {
            exports   => $exports,
            groups    => { default => [':all'] },
            installer => sub {
                my ($arg, $to_export) = @_;
                my $meta = Class::MOP::class_of($arg->{into});

                goto &Sub::Exporter::default_installer unless $meta;

                # don't overwrite existing symbols with our magically flagged
                # version of it if we would install the same sub that's already
                # in the importer

                my @filtered_to_export;
                my %installed;
                for (my $i = 0; $i < @{ $to_export }; $i += 2) {
                    my ($as, $cv) = @{ $to_export }[$i, $i + 1];

                    next if !ref($as)
                         && $meta->has_package_symbol('&' . $as)
                         && $meta->get_package_symbol('&' . $as) == $cv;

                    push @filtered_to_export, $as, $cv;
                    $installed{$as} = 1 unless ref $as;
                }

                Sub::Exporter::default_installer($arg, \@filtered_to_export);

                for my $name ( keys %{$is_reexport} ) {
                    no strict 'refs';
                    no warnings 'once';
                    next unless exists $installed{$name};
                    _flag_as_reexport( \*{ join q{::}, $arg->{into}, $name } );
                }
            },
        }
    );
}

{
    my $seen = {};

    sub _follow_also {
        my $class             = shift;
        my $exporting_package = shift;

        local %$seen = ( $exporting_package => 1 );

        return uniq( _follow_also_real($exporting_package) );
    }

    sub _follow_also_real {
        my $exporting_package = shift;

        if ( !exists $EXPORT_SPEC{$exporting_package} ) {
            my $loaded = Class::MOP::is_class_loaded($exporting_package);

            die "Package in also ($exporting_package) does not seem to "
                . "use Moose::Exporter"
                . ( $loaded ? "" : " (is it loaded?)" );
        }

        my $also = $EXPORT_SPEC{$exporting_package}{also};

        return unless defined $also;

        my @also = ref $also ? @{$also} : $also;

        for my $package (@also) {
            die
                "Circular reference in 'also' parameter to Moose::Exporter between $exporting_package and $package"
                if $seen->{$package};

            $seen->{$package} = 1;
        }

        return @also, map { _follow_also_real($_) } @also;
    }
}

sub _parse_trait_aliases {
    my $class   = shift;
    my ($package, $aliases) = @_;

    my @ret;
    for my $alias (@$aliases) {
        my $name;
        if (ref($alias)) {
            reftype($alias) eq 'ARRAY'
                or Moose->throw_error(reftype($alias) . " references are not "
                                    . "valid arguments to the 'trait_aliases' "
                                    . "option");

            ($alias, $name) = @$alias;
        }
        else {
            ($name = $alias) =~ s/.*:://;
        }
        push @ret, subname "${package}::${name}" => sub () { $alias };
    }

    return @ret;
}

sub _make_sub_exporter_params {
    my $class           = shift;
    my $packages        = shift;
    my $export_recorder = shift;
    my $is_reexport  = shift;

    my %exports;

    for my $package ( @{$packages} ) {
        my $args = $EXPORT_SPEC{$package}
            or die "The $package package does not use Moose::Exporter\n";

        for my $name ( @{ $args->{with_meta} } ) {
            my $sub = $class->_sub_from_package( $package, $name )
                or next;

            my $fq_name = $package . '::' . $name;

            $exports{$name} = $class->_make_wrapped_sub_with_meta(
                $fq_name,
                $sub,
                $export_recorder,
            );
        }

        for my $name ( @{ $args->{with_caller} } ) {
            my $sub = $class->_sub_from_package( $package, $name )
                or next;

            my $fq_name = $package . '::' . $name;

            $exports{$name} = $class->_make_wrapped_sub(
                $fq_name,
                $sub,
                $export_recorder,
            );
        }

        my @extra_exports = $class->_parse_trait_aliases(
            $package, $args->{trait_aliases},
        );
        for my $name ( @{ $args->{as_is} }, @extra_exports ) {
            my ( $sub, $coderef_name );

            if ( ref $name ) {
                $sub = $name;

                my $coderef_pkg;
                ( $coderef_pkg, $coderef_name )
                    = Class::MOP::get_code_info($name);

                if ( $coderef_pkg ne $package ) {
                    $is_reexport->{$coderef_name} = 1;
                }
            }
            else {
                $sub = $class->_sub_from_package( $package, $name )
                    or next;

                $coderef_name = $name;
            }

            $export_recorder->{$sub} = 1;

            $exports{$coderef_name} = sub {$sub};
        }
    }

    return \%exports;
}

sub _sub_from_package {
    my $sclass  = shift;
    my $package = shift;
    my $name    = shift;

    my $sub = do {
        no strict 'refs';
        \&{ $package . '::' . $name };
    };

    return $sub if defined &$sub;

    Carp::cluck "Trying to export undefined sub ${package}::${name}";

    return;
}

our $CALLER;

sub _make_wrapped_sub {
    my $self            = shift;
    my $fq_name         = shift;
    my $sub             = shift;
    my $export_recorder = shift;

    # We need to set the package at import time, so that when
    # package Foo imports has(), we capture "Foo" as the
    # package. This lets other packages call Foo::has() and get
    # the right package. This is done for backwards compatibility
    # with existing production code, not because this is a good
    # idea ;)
    return sub {
        my $caller = $CALLER;

        my $wrapper = $self->_curry_wrapper( $sub, $fq_name, $caller );

        my $sub = subname( $fq_name => $wrapper );

        $export_recorder->{$sub} = 1;

        return $sub;
    };
}

sub _make_wrapped_sub_with_meta {
    my $self            = shift;
    my $fq_name         = shift;
    my $sub             = shift;
    my $export_recorder = shift;

    return sub {
        my $caller = $CALLER;

        my $wrapper = $self->_late_curry_wrapper(
            $sub, $fq_name,
            sub { Class::MOP::class_of(shift) } => $caller
        );

        my $sub = subname( $fq_name => $wrapper );

        $export_recorder->{$sub} = 1;

        return $sub;
    };
}

sub _curry_wrapper {
    my $class   = shift;
    my $sub     = shift;
    my $fq_name = shift;
    my @extra   = @_;

    my $wrapper = sub { $sub->( @extra, @_ ) };
    if ( my $proto = prototype $sub ) {

        # XXX - Perl's prototype sucks. Use & to make set_prototype
        # ignore the fact that we're passing "private variables"
        &Scalar::Util::set_prototype( $wrapper, $proto );
    }
    return $wrapper;
}

sub _late_curry_wrapper {
    my $class   = shift;
    my $sub     = shift;
    my $fq_name = shift;
    my $extra   = shift;
    my @ex_args = @_;

    my $wrapper = sub {

        # resolve curried arguments at runtime via this closure
        my @curry = ( $extra->(@ex_args) );
        return $sub->( @curry, @_ );
    };

    if ( my $proto = prototype $sub ) {

        # XXX - Perl's prototype sucks. Use & to make set_prototype
        # ignore the fact that we're passing "private variables"
        &Scalar::Util::set_prototype( $wrapper, $proto );
    }
    return $wrapper;
}

sub _make_import_sub {
    shift;
    my $exporting_package = shift;
    my $exporter          = shift;
    my $exports_from      = shift;
    my $is_reexport    = shift;

    return sub {

        # I think we could use Sub::Exporter's collector feature
        # to do this, but that would be rather gross, since that
        # feature isn't really designed to return a value to the
        # caller of the exporter sub.
        #
        # Also, this makes sure we preserve backwards compat for
        # _get_caller, so it always sees the arguments in the
        # expected order.
        my $traits;
        ( $traits, @_ ) = _strip_traits(@_);

        my $metaclass;
        ( $metaclass, @_ ) = _strip_metaclass(@_);
        $metaclass
            = Moose::Util::resolve_metaclass_alias( 'Class' => $metaclass )
            if defined $metaclass && length $metaclass;

        my $meta_name;
        ( $meta_name, @_ ) = _strip_meta_name(@_);

        # Normally we could look at $_[0], but in some weird cases
        # (involving goto &Moose::import), $_[0] ends as something
        # else (like Squirrel).
        my $class = $exporting_package;

        $CALLER = _get_caller(@_);

        # this works because both pragmas set $^H (see perldoc
        # perlvar) which affects the current compilation -
        # i.e. the file who use'd us - which is why we don't need
        # to do anything special to make it affect that file
        # rather than this one (which is already compiled)

        strict->import;
        warnings->import;

        my $did_init_meta;
        for my $c ( grep { $_->can('init_meta') } $class, @{$exports_from} ) {

            # init_meta can apply a role, which when loaded uses
            # Moose::Exporter, which in turn sets $CALLER, so we need
            # to protect against that.
            local $CALLER = $CALLER;
            $c->init_meta(
                for_class => $CALLER,
                metaclass => $metaclass,
                meta_name => $meta_name,
            );
            $did_init_meta = 1;
        }

        if ( $did_init_meta && @{$traits} ) {

            # The traits will use Moose::Role, which in turn uses
            # Moose::Exporter, which in turn sets $CALLER, so we need
            # to protect against that.
            local $CALLER = $CALLER;
            _apply_meta_traits( $CALLER, $traits );
        }
        elsif ( @{$traits} ) {
            require Moose;
            Moose->throw_error(
                "Cannot provide traits when $class does not have an init_meta() method"
            );
        }

        my ( undef, @args ) = @_;
        my $extra = shift @args if ref $args[0] eq 'HASH';

        $extra ||= {};
        if ( !$extra->{into} ) {
            $extra->{into_level} ||= 0;
            $extra->{into_level}++;
        }

        $class->$exporter( $extra, @args );
    };
}

sub _strip_traits {
    my $idx = first_index { ( $_ || '' ) eq '-traits' } @_;

    return ( [], @_ ) unless $idx >= 0 && $#_ >= $idx + 1;

    my $traits = $_[ $idx + 1 ];

    splice @_, $idx, 2;

    $traits = [$traits] unless ref $traits;

    return ( $traits, @_ );
}

sub _strip_metaclass {
    my $idx = first_index { ( $_ || '' ) eq '-metaclass' } @_;

    return ( undef, @_ ) unless $idx >= 0 && $#_ >= $idx + 1;

    my $metaclass = $_[ $idx + 1 ];

    splice @_, $idx, 2;

    return ( $metaclass, @_ );
}

sub _strip_meta_name {
    my $idx = first_index { ( $_ || '' ) eq '-meta_name' } @_;

    return ( 'meta', @_ ) unless $idx >= 0 && $#_ >= $idx + 1;

    my $meta_name = $_[ $idx + 1 ];

    splice @_, $idx, 2;

    return ( $meta_name, @_ );
}

sub _apply_meta_traits {
    my ( $class, $traits ) = @_;

    return unless @{$traits};

    my $meta = Class::MOP::class_of($class);

    my $type = ( split /::/, ref $meta )[-1]
        or Moose->throw_error(
        'Cannot determine metaclass type for trait application . Meta isa '
            . ref $meta );

    my @resolved_traits = map {
        ref $_
            ? $_
            : Moose::Util::resolve_metatrait_alias( $type => $_ )
    } @$traits;

    return unless @resolved_traits;

    my %args = ( for => $class );

    if ( $meta->isa('Moose::Meta::Role') ) {
        $args{role_metaroles} = { role => \@resolved_traits };
    }
    else {
        $args{class_metaroles} = { class => \@resolved_traits };
    }

    Moose::Util::MetaRole::apply_metaroles(%args);
}

sub _get_caller {

    # 1 extra level because it's called by import so there's a layer
    # of indirection
    my $offset = 1;

    return
          ( ref $_[1] && defined $_[1]->{into} ) ? $_[1]->{into}
        : ( ref $_[1] && defined $_[1]->{into_level} )
        ? caller( $offset + $_[1]->{into_level} )
        : caller($offset);
}

sub _make_unimport_sub {
    shift;
    my $exporting_package = shift;
    my $exports           = shift;
    my $export_recorder   = shift;
    my $is_reexport    = shift;

    return sub {
        my $caller = scalar caller();
        Moose::Exporter->_remove_keywords(
            $caller,
            [ keys %{$exports} ],
            $export_recorder,
            $is_reexport,
        );
    };
}

sub _remove_keywords {
    shift;
    my $package          = shift;
    my $keywords         = shift;
    my $recorded_exports = shift;
    my $is_reexport   = shift;

    no strict 'refs';

    foreach my $name ( @{$keywords} ) {
        if ( defined &{ $package . '::' . $name } ) {
            my $sub = \&{ $package . '::' . $name };

            # make sure it is from us
            next unless $recorded_exports->{$sub};

            if ( $is_reexport->{$name} ) {
                no strict 'refs';
                next
                    unless _export_is_flagged(
                            \*{ join q{::} => $package, $name } );
            }

            # and if it is from us, then undef the slot
            delete ${ $package . '::' }{$name};
        }
    }
}

sub _make_init_meta {
    shift;
    my $class = shift;
    my $args  = shift;

    my %old_style_roles;
    for my $role (
        map {"${_}_roles"}
        qw(
        metaclass
        attribute_metaclass
        method_metaclass
        wrapped_method_metaclass
        instance_metaclass
        constructor_class
        destructor_class
        error_class
        )
        ) {
        $old_style_roles{$role} = $args->{$role}
            if exists $args->{$role};
    }

    my %base_class_roles;
    %base_class_roles = ( roles => $args->{base_class_roles} )
        if exists $args->{base_class_roles};

    my %new_style_roles = map { $_ => $args->{$_} }
        grep { exists $args->{$_} } qw( class_metaroles role_metaroles );

    return unless %new_style_roles || %old_style_roles || %base_class_roles;

    return sub {
        shift;
        my %options = @_;

        return unless Class::MOP::class_of( $options{for_class} );

        if ( %new_style_roles || %old_style_roles ) {
            Moose::Util::MetaRole::apply_metaroles(
                for => $options{for_class},
                %new_style_roles,
                %old_style_roles,
            );
        }

        Moose::Util::MetaRole::apply_base_class_roles(
            for_class => $options{for_class},
            %base_class_roles,
            )
            if Class::MOP::class_of( $options{for_class} )
                ->isa('Moose::Meta::Class');

        return Class::MOP::class_of( $options{for_class} );
    };
}

sub import {
    strict->import;
    warnings->import;
}

1;

__END__

=head1 NAME

Moose::Exporter - make an import() and unimport() just like Moose.pm

=head1 SYNOPSIS

  package MyApp::Moose;

  use Moose ();
  use Moose::Exporter;

  Moose::Exporter->setup_import_methods(
      with_meta => [ 'has_rw', 'sugar2' ],
      as_is     => [ 'sugar3', \&Some::Random::thing ],
      also      => 'Moose',
  );

  sub has_rw {
      my ( $meta, $name, %options ) = @_;
      $meta->add_attribute(
          $name,
          is => 'rw',
          %options,
      );
  }

  # then later ...
  package MyApp::User;

  use MyApp::Moose;

  has 'name';
  has_rw 'size';
  thing;

  no MyApp::Moose;

=head1 DESCRIPTION

This module encapsulates the exporting of sugar functions in a
C<Moose.pm>-like manner. It does this by building custom C<import>,
C<unimport>, and C<init_meta> methods for your module, based on a spec you
provide.

It also lets you "stack" Moose-alike modules so you can export Moose's sugar
as well as your own, along with sugar from any random C<MooseX> module, as
long as they all use C<Moose::Exporter>. This feature exists to let you bundle
a set of MooseX modules into a policy module that developers can use directly
instead of using Moose itself.

To simplify writing exporter modules, C<Moose::Exporter> also imports
C<strict> and C<warnings> into your exporter module, as well as into
modules that use it.

=head1 METHODS

This module provides two public methods:

=over 4

=item  B<< Moose::Exporter->setup_import_methods(...) >>

When you call this method, C<Moose::Exporter> builds custom C<import>,
C<unimport>, and C<init_meta> methods for your module. The C<import> method
will export the functions you specify, and can also re-export functions
exported by some other module (like C<Moose.pm>).

The C<unimport> method cleans the caller's namespace of all the exported
functions. This includes any functions you re-export from other
packages. However, if the consumer of your package also imports those
functions from the original package, they will I<not> be cleaned.

If you pass any parameters for L<Moose::Util::MetaRole>, this method will
generate an C<init_meta> for you as well (see below for details). This
C<init_meta> will call C<Moose::Util::MetaRole::apply_metaroles> and
C<Moose::Util::MetaRole::apply_base_class_roles> as needed.

Note that if any of these methods already exist, they will not be
overridden, you will have to use C<build_import_methods> to get the
coderef that would be installed.

This method accepts the following parameters:

=over 8

=item * with_meta => [ ... ]

This list of function I<names only> will be wrapped and then exported. The
wrapper will pass the metaclass object for the caller as its first argument.

Many sugar functions will need to use this metaclass object to do something to
the calling package.

=item * as_is => [ ... ]

This list of function names or sub references will be exported as-is. You can
identify a subroutine by reference, which is handy to re-export some other
module's functions directly by reference (C<\&Some::Package::function>).

If you do export some other package's function, this function will never be
removed by the C<unimport> method. The reason for this is we cannot know if
the caller I<also> explicitly imported the sub themselves, and therefore wants
to keep it.

=item * trait_aliases => [ ... ]

This is a list of package names which should have shortened aliases exported,
similar to the functionality of L<aliased>. Each element in the list can be
either a package name, in which case the export will be named as the last
namespace component of the package, or an arrayref, whose first element is the
package to alias to, and second element is the alias to export.

=item * also => $name or \@names

This is a list of modules which contain functions that the caller
wants to export. These modules must also use C<Moose::Exporter>. The
most common use case will be to export the functions from C<Moose.pm>.
Functions specified by C<with_meta> or C<as_is> take precedence over
functions exported by modules specified by C<also>, so that a module
can selectively override functions exported by another module.

C<Moose::Exporter> also makes sure all these functions get removed
when C<unimport> is called.

=back

You can also provide parameters for C<Moose::Util::MetaRole::apply_metaroles>
and C<Moose::Util::MetaRole::base_class_roles>. Specifically, valid parameters
are "class_metaroles", "role_metaroles", and "base_class_roles".

=item B<< Moose::Exporter->build_import_methods(...) >>

Returns two or three code refs, one for C<import>, one for
C<unimport>, and optionally one for C<init_meta>, if the appropriate
options are passed in.

Accepts the additional C<install> option, which accepts an arrayref of method
names to install into your exporting package. The valid options are C<import>,
C<unimport>, and C<init_meta>. Calling C<setup_import_methods> is equivalent
to calling C<build_import_methods> with C<< install => [qw(import unimport
init_meta)] >> except that it doesn't also return the methods.

Used by C<setup_import_methods>.

=back

=head1 IMPORTING AND init_meta

If you want to set an alternative base object class or metaclass class, see
above for details on how this module can call L<Moose::Util::MetaRole> for
you.

If you want to do something that is not supported by this module, simply
define an C<init_meta> method in your class. The C<import> method that
C<Moose::Exporter> generates for you will call this method (if it exists). It
will always pass the caller to this method via the C<for_class> parameter.

Most of the time, your C<init_meta> method will probably just call C<<
Moose->init_meta >> to do the real work:

  sub init_meta {
      shift; # our class name
      return Moose->init_meta( @_, metaclass => 'My::Metaclass' );
  }

Keep in mind that C<build_import_methods> will return an C<init_meta>
method for you, which you can also call from within your custom
C<init_meta>:

  my ( $import, $unimport, $init_meta ) =
      Moose::Exporter->build_import_methods( ... );

  sub import {
     my $class = shift;

     ...

     $class->$import(...);

     ...
  }

  sub unimport { goto &$unimport }

  sub init_meta {
     my $class = shift;

     ...

     $class->$init_meta(...);

     ...
  }

=head1 METACLASS TRAITS

The C<import> method generated by C<Moose::Exporter> will allow the
user of your module to specify metaclass traits in a C<-traits>
parameter passed as part of the import:

  use Moose -traits => 'My::Meta::Trait';

  use Moose -traits => [ 'My::Meta::Trait', 'My::Other::Trait' ];

These traits will be applied to the caller's metaclass
instance. Providing traits for an exporting class that does not create
a metaclass for the caller is an error.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Dave Rolsky E<lt>autarch@urth.orgE<gt>

This is largely a reworking of code in Moose.pm originally written by
Stevan Little and others.

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
