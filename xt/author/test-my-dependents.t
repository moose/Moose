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
delete @ENV{ qw( AUTHOR_TESTING RELEASE_TESTING SMOKE_TESTING ) };

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
MooseX::APIRole
MooseX::AbstractFactory
MooseX::Accessors::ReadWritePrivate
MooseX::Aliases
MooseX::AlwaysCoerce
MooseX::App::Cmd
MooseX::Async
MooseX::Attribute::ENV
MooseX::Atom
MooseX::Attribute::Deflator
MooseX::Attribute::Dependent
MooseX::AttributeCloner
MooseX::AttributeDefaults
MooseX::AttributeHelpers
MooseX::AttributeIndexes
MooseX::AttributeInflate
MooseX::AttributeTree
MooseX::Attributes::Curried
MooseX::AuthorizedMethods
MooseX::AutoDestruct
MooseX::AutoImmute
MooseX::BatmanBeforeRobin
MooseX::Blessed::Reconstruct
MooseX::CascadeClearing
MooseX::ChainedAccessors::Accessor
MooseX::ClassAttribute
MooseX::Clone
MooseX::CompileTime::Traits
MooseX::ComposedBehavior
MooseX::ConfigFromFile
MooseX::Configuration
MooseX::Constructor::AllErrors
MooseX::Contract
MooseX::Control
MooseX::CurriedHandles
MooseX::Daemonize
MooseX::Declare
MooseX::DeepAccessors
MooseX::Emulate::Class::Accessor::Fast
MooseX::Error::Trap
MooseX::FileAttribute
MooseX::File_or_DB::Storage
MooseX::FollowPBP
MooseX::Getopt
MooseX::Getopt::Defanged
MooseX::HasDefaults
MooseX::GlobRef
MooseX::Has::Sugar
MooseX::HasDefaults
MooseX::InsideOut
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
MooseX::Meta::Attribute::Index
MooseX::Meta::Attribute::Lvalue
MooseX::Meta::TypeConstraint::ForceCoercion
MooseX::Meta::TypeConstraint::Intersection
MooseX::MetaDescription
MooseX::Method
MooseX::MethodAttributes
MooseX::Method::Signatures
MooseX::MultiInitArg
MooseX::MultiMethods
MooseX::MultiObject
MooseX::MutatorAttributes
MooseX::Net::API
MooseX::NonMoose
MooseX::Object::Pluggable
MooseX::OneArgNew
MooseX::Param
MooseX::Params::Validate
MooseX::Plaggerize
MooseX::POE
MooseX::Privacy
MooseX::PrivateSetters
MooseX::RelatedClassRoles
MooseX::Role::BuildInstanceOf
MooseX::Role::Cmd
MooseX::Role::DBIx::Connector
MooseX::Role::Matcher
MooseX::Role::Parameterized
MooseX::Role::Pluggable
MooseX::Role::Restricted
MooseX::Role::Strict
MooseX::Role::Timer
MooseX::Role::TraitConstructor
MooseX::Role::WithOverloading
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
MooseX::SymmetricAttribute
MooseX::Templated
MooseX::Timestamp
MooseX::Traits
MooseX::Traits::Attribute::CascadeClear
MooseX::Traits::Attribute::MergeHashRef
MooseX::Traits::Pluggable
MooseX::TransactionalMethods
MooseX::TypeMap
MooseX::Types
MooseX::Types::Authen::Passphrase
MooseX::Types::Buf
MooseX::Types::Common
MooseX::Types::Data::GUID
MooseX::Types::DateTime
MooseX::Types::DateTime::ButMaintained
MooseX::Types::DateTime::W3C
MooseX::Types::Digest
MooseX::Types::Email
MooseX::Types::IO
MooseX::Types::ISO8601
MooseX::Types::Implements
MooseX::Types::JSON
MooseX::Types::LWP::UserAgent
MooseX::Types::LoadableClass
MooseX::Types::Locale::Country
MooseX::Types::Locale::Language
MooseX::Types::Log::Dispatch
MooseX::Types::Meta
MooseX::Types::Moose::MutualCoercion
MooseX::Types::NetAddr::IP
MooseX::Types::Parameterizable
MooseX::Types::Path::Class
MooseX::Types::Set::Object
MooseX::Types::Signal
MooseX::Types::Structured
MooseX::Types::URI
MooseX::Types::UUID
MooseX::Types::UniStr
MooseX::Types::Varchar
MooseX::UndefTolerant
MooseX::WithCache
MooseX::Workers
MooseX::YAML
App::Nopaste
App::Termcast
Bread::Board
Bread::Board::Declare
Cache::Ref
Cantella::Worker
Carp::REPL
Catalyst
Catalyst::Devel
CatalystX::Declare
Chart::Clicker
CHI
Config::MVP
Crypt::Util
Data::Stream::Bulk
Data::Visitor
DBIx::Class
Devel::REPL
Dist::Zilla
Email::MIME::Kit
Email::Sender
FCGI::Engine
Fey
Fey::ORM
File::ChangeNotify
Forest
Git::PurePerl
Gitalist
Hailo
HTML::FormHandler
IM::Engine
JSON::RPC::Common
JSORB
KiokuDB
KiokuDB::Backend::DBI
KiokuX::Model::Role::Annotations
KiokuX::User
Lighttpd::Control
Locale::POFileManager
Markdent
Metabase
MojoMojo
Mongoose
namespace::autoclean
Net::HTTP::API
Net::Twitter
Path::Class::Versioned
Path::Router
Perl::PrereqScanner
Pod::Elemental
Pod::Weaver
PRANG
Reaction
Reflex
Resource::Pack
Role::Subsystem
Search::GIN
Silki
Test::Able
Test::Routine
Test::Sweet
Throwable
Throwable::X
TryCatch
WWW::AdventCalendar
Web::Hippie
XML::Rabbit
XML::Schematron
XML::Toolkit
