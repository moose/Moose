use strict;
use warnings;

use Cwd qw( abs_path );
use Test::More;

plan skip_all => 'This test will not run unless you set MOOSE_TEST_MD to a true value'
    unless $ENV{MOOSE_TEST_MD};

eval 'use Test::DependentModules qw( test_all_dependents test_module );';
plan skip_all => 'This test requires Test::DependentModules'
    if $@;

$ENV{PERL_TEST_DM_LOG_DIR} = abs_path('.');

my $exclude = qr/^Acme-/x;

if ( $ENV{MOOSE_TEST_MD_ALL} ) {
    test_all_dependents( 'Moose', { exclude => $exclude } );
}
else {
    my @modules = map { chomp; $_ } <DATA>;
    test_module($_) for @modules;
    done_testing;
}

__DATA__
Moose::Autobox
MooseX::ABC
MooseX::Accessors::ReadWritePrivate
MooseX::Aliases
MooseX::App::Cmd
MooseX::Async
MooseX::Attribute::ENV
MooseX::AttributeHelpers
MooseX::AttributeInflate
MooseX::Attribute::Prototype
MooseX::Attributes::Curried
MooseX::Blessed::Reconstruct
MooseX::ClassAttribute
MooseX::Clone
MooseX::ConfigFromFile
MooseX::Constructor::AllErrors
MooseX::Contract
MooseX::Control
MooseX::CurriedHandles
MooseX::Daemonize
MooseX::Declare
MooseX::DeepAccessors
MooseX::Emulate::Class::Accessor::Fast
MooseX::FollowPBP
MooseX::Getopt
MooseX::GlobRef
MooseX::GlobRef::Object
MooseX::HasDefaults
MooseX::Has::Sugar
MooseX::InsideOut
MooseX::InstanceTracking
MooseX::Iterator
MooseX::KeyedMutex
MooseX::LazyLogDispatch
MooseX::LogDispatch
MooseX::Log::Log4perl
MooseX::MakeImmutable
MooseX::Mangle
MooseX::Meta::TypeConstraint::ForceCoercion
MooseX::MethodAttributes
MooseX::Method::Signatures
MooseX::MultiInitArg
MooseX::MultiMethods
MooseX::MutatorAttributes
MooseX::NonMoose
MooseX::Object::Pluggable
MooseX::Param
MooseX::Params::Validate
MooseX::Plaggerize
MooseX::POE
MooseX::Policy::SemiAffordanceAccessor
MooseX::Q4MLog
MooseX::Role::Cmd
MooseX::Role::Matcher
MooseX::Role::Parameterized
MooseX::Role::XMLRPC::Client
MooseX::SemiAffordanceAccessor
MooseX::SimpleConfig
MooseX::Singleton
MooseX::SingletonMethod
MooseX::Storage
MooseX::Storage::Format::XML::Simple
MooseX::StrictConstructor
MooseX::Struct
MooseX::Templated
MooseX::Timestamp
MooseX::Traits
MooseX::Types
MooseX::Types::Authen::Passphrase
MooseX::Types::Common
MooseX::Types::Data::GUID
MooseX::Types::DateTime
MooseX::Types::IO
MooseX::Types::Path::Class
MooseX::Types::Set::Object
MooseX::Types::Structured
MooseX::Types::URI
MooseX::Types::UUID
MooseX::Types::VariantTable
MooseX::WithCache
MooseX::Workers
MooseX::YAML
Fey::ORM
KiokuDB
Catalyst
Chart::Clicker
TryCatch
Bread::Board
Devel::REPL
Carp::REPL
IM::Engine
NetHack::Item
Forest
App::Nopaste
CHI
Data::Visitor
namespace::autoclean
DBIx::Class
Hailo
