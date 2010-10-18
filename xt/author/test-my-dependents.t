use strict;
use warnings;

use Cwd qw( abs_path );
use Test::More;

BEGIN {
    plan skip_all => 'This test will not run unless you set MOOSE_TEST_MD to a true value'
        unless $ENV{MOOSE_TEST_MD};
}

use Test::Requires {
    'Test::DependentModules' => '0.01', # skip all if not installed
};
use Test::DependentModules qw( test_all_dependents test_module );

use DateTime;
use Class::MOP ();
use Moose ();

diag(     'Test run performed at: '
        . DateTime->now
        . ' with Class::MOP '
        . Class::MOP->VERSION
        . ' and Moose '
        . Moose->VERSION );

$ENV{PERL_TEST_DM_LOG_DIR} = abs_path('.');

my $exclude = qr/^Acme-/x;

if ( $ENV{MOOSE_TEST_MD_ALL} ) {
    test_all_dependents( 'Moose', { exclude => $exclude } );
    done_testing;
}
else {
    my @modules = map { chomp; $_ } <DATA>;
    plan tests => scalar @modules;
    test_module($_) for @modules;
}

__DATA__
Moose::Autobox
MooseX::ABC
MooseX::AbstractFactory
MooseX::Accessors::ReadWritePrivate
MooseX::Aliases
MooseX::AlwaysCoerce
MooseX::App::Cmd
MooseX::Async
MooseX::Attribute::ENV
MooseX::AttributeCloner
MooseX::AttributeDefaults
MooseX::AttributeHelpers
MooseX::AttributeInflate
MooseX::Attributes::Curried
MooseX::AutoDestruct
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
MooseX::Dumper
MooseX::Emulate::Class::Accessor::Fast
MooseX::Error::Trap
MooseX::FileAttribute
MooseX::File_or_DB::Storage
MooseX::FollowPBP
MooseX::Getopt
MooseX::Getopt::Defanged
MooseX::HasDefaults
MooseX::Has::Sugar
MooseX::InsideOut
MooseX::InstanceTracking
MooseX::Iterator
MooseX::KeyedMutex
MooseX::LazyLogDispatch
MooseX::LazyRequire
MooseX::Lexical::Types
MooseX::LexicalRoleApplication
MooseX::Lists
MooseX::LogDispatch
MooseX::Log::Log4perl
MooseX::MakeImmutable
MooseX::Mangle
MooseX::MarkAsMethods
MooseX::Meta::TypeConstraint::ForceCoercion
MooseX::Meta::TypeConstraint::Intersection
MooseX::MetaDescription
MooseX::Method
MooseX::MethodAttributes
MooseX::Method::Signatures
MooseX::MultiInitArg
MooseX::MultiMethods
MooseX::MutatorAttributes
MooseX::NaturalKey
MooseX::NonMoose
MooseX::Object::Pluggable
MooseX::Param
MooseX::Params::Validate
MooseX::Plaggerize
MooseX::POE
MooseX::RelatedClassRoles
MooseX::Role::BuildInstanceOf
MooseX::Role::Cmd
MooseX::Role::DBIx::Connector
MooseX::Role::Matcher
MooseX::Role::Parameterized
MooseX::Role::Restricted
MooseX::Role::Strict
MooseX::Role::WithOverloading
MooseX::Role::XMLRPC::Client
MooseX::Runnable
MooseX::Scaffold
MooseX::SemiAffordanceAccessor
MooseX::SetOnce
MooseX::SimpleConfig
MooseX::Singleton
MooseX::SingletonMethod
MooseX::SlurpyConstructor
MooseX::Storage
MooseX::Storage::Format::XML::Simple
MooseX::StrictConstructor
MooseX::Struct
MooseX::Templated
MooseX::Timestamp
MooseX::TrackDirty::Attributes
MooseX::Traits
MooseX::Traits::Attribute::CascadeClear
MooseX::Traits::Attribute::MergeHashRef
MooseX::Traits::Pluggable
MooseX::TypeMap
MooseX::Types
MooseX::Types::Authen::Passphrase
MooseX::Types::Buf
MooseX::Types::Common
MooseX::Types::Data::GUID
MooseX::Types::DateTime
MooseX::Types::DateTime::ButMaintained
MooseX::Types::Digest
MooseX::Types::Email
MooseX::Types::IO
MooseX::Types::ISO8601
MooseX::Types::JSON
MooseX::Types::LoadableClass
MooseX::Types::Locale::Country
MooseX::Types::Locale::Language
MooseX::Types::Log::Dispatch
MooseX::Types::Path::Class
MooseX::Types::Set::Object
MooseX::Types::Structured
MooseX::Types::URI
MooseX::Types::UUID
MooseX::Types::UniStr
MooseX::Types::Varchar
MooseX::Types::VariantTable
MooseX::UndefTolerant
MooseX::WithCache
MooseX::Workers
MooseX::YAML
App::Nopaste
App::Termcast
Bread::Board
Cantella::Worker
Carp::REPL
Catalyst
Catalyst::Devel
Chart::Clicker
CHI
Config::MVP
Data::Stream::Bulk
Data::Visitor
DBIx::Class
Devel::REPL
Dist::Zilla
Email::Sender
FCGI::Engine
Fey
Fey::ORM
File::ChangeNotify
Forest
Git::PurePerl
Hailo
IM::Engine
JSORB
KiokuDB
KiokuDB::Backend::DBI
KiokuX::User
Lighttpd::Control
Locale::POFileManager
Markdent
namespace::autoclean
Net::HTTP::API
Net::Twitter
Path::Router
Pod::Elemental
Pod::Weaver
Reflex
Throwable
TryCatch
XML::Toolkit
