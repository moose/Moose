use strict;
use warnings;

use Cwd qw( abs_path );
use Test::More;

BEGIN {
    plan skip_all => 'This test will not run unless you set MOOSE_TEST_MD to a true value'
        unless $ENV{MOOSE_TEST_MD};
}

use Test::Requires {
    'Archive::Zip' => 0, # or else .zip dists won't be able to be installed
    'Test::DependentModules' => '0.09', # skip all if not installed
    'MetaCPAN::API' => '0.33',
};
use Test::DependentModules qw( test_all_dependents test_modules );

use DateTime;
use List::MoreUtils qw(any);
use Moose ();

diag(     'Test run performed at: '
        . DateTime->now
        . ' with Moose '
        . Moose->VERSION );

$ENV{PERL_TEST_DM_LOG_DIR} = abs_path('.');
delete @ENV{ qw( AUTHOR_TESTING RELEASE_TESTING SMOKE_TESTING ) };

$ENV{ANY_MOOSE} = 'Moose';

my $mcpan = MetaCPAN::API->new;
my $res = $mcpan->post(
    '/release/_search' => {
        query  => { match_all => {} },
        size   => 5000,
        filter => { and => [
            { or => [
                { term => { 'release.dependency.module' => 'Moose' } },
                { term => { 'release.dependency.module' => 'Moose::Role' } },
                { term => { 'release.dependency.module' => 'Moose::Exporter' } },
                { term => { 'release.dependency.module' => 'Class::MOP' } },
                { term => { 'release.dependency.module' => 'MooseX::Role::Parameterized' } },
                { term => { 'release.dependency.module' => 'Any::Moose' } },
            ] },
            { term => { 'release.status'   => 'latest' } },
            { term => { 'release.maturity' => 'released' } },
        ] },
        fields => 'distribution'
    }
);

my %skip = map { $_ => 1 } grep { /\w/ } map { chomp; s/\s*#.*$//; $_ } <DATA>;
my @skip_prefix = qw(Acme Task Bundle);
my %name_fix = (
    'App-PipeFilter'                 => 'App::PipeFilter::Generic',
    'Constructible'                  => 'Constructible::Maxima',
    'DCOLLINS-ANN-Locals'            => 'DCOLLINS::ANN::Robot',
    'Dist-Zilla-Deb'                 => 'Dist::Zilla::Plugin::Deb::VersionFromChangelog',
    'Dist-Zilla-Plugin-TemplateFile' => 'Dist::Zilla::Plugin::TemplateFiles',
    'Dist-Zilla-Plugins-CJM'         => 'Dist::Zilla::Plugin::TemplateCJM',
    'OWL-Simple'                     => 'OWL::Simple::Class',
    'Patterns-ChainOfResponsibility' => 'Patterns::ChainOfResponsibility::Application',
    'Role-Identifiable'              => 'Role::Identifiable::HasIdent',
    'X11-XCB'                        => 'X11::XCB::Connection',
    'XML-Ant-BuildFile'              => 'XML::Ant::BuildFile::Project',
    'helm'                           => 'Helm',
    'marc-moose'                     => 'MARC::Moose',
    'mobirc'                         => 'App::Mobirc',
    'smokebrew'                      => 'App::SmokeBrew',
    'v6-alpha'                       => 'v6',
);
my @modules = map  { exists $name_fix{$_} ? $name_fix{$_} : $_ }
              sort
              grep { !$skip{$_} }
              grep { my $dist = $_; !any { $dist =~ /^$_-/ } @skip_prefix }
              map  { $_->{fields}{distribution} }
              @{ $res->{hits}{hits} };

plan tests => scalar @modules;
test_modules(@modules);

# Modules that are known to fail
# PRANG - failing for quite some time (since before 2.0400)

__DATA__
# won't build, for actual reasons:
App-CPAN2Pkg                           # Tk doesn't compile
App-Fotagger                           # Imager doesn't compile
Black-Board                            # not found on cpan because of mxd
CM-Permutation                         # OpenGL uses graphics in Makefile.PL
Dackup                                 # depends on running ssh
Date-Biorhythm                         # Date::Business prompts in Makefile.PL
Data-Collector                         # depends on running ssh
POE-Component-OpenSSH                  # depends on running ssh
Perl-Dist-Strawberry-BuildPerl-5123    # windows only
Perl-Dist-WiX                          # windows only
Perl-Dist-WiX-BuildPerl-5123           # windows only
Test-SFTP                              # Term::ReadPassword prompts in tests
VirtualBox-Manage                      # not found on cpan because of mxd
helm                                   # depends on running ssh

# won't build, for unknown reasons
App-HistHub                            # ???
App-Twitch                             # ???
CPAN-Patches                           # ???
CPAN-Patches-Plugin-Debian             # ???
Debian-Apt-PM                          # ???
Dist-Zilla-Plugin-BuildSelf            # ???
Dist-Zilla-Plugin-ModuleBuildTiny      # ???
Dist-Zilla-Plugin-Test-DistManifest    # ???
Dist-Zilla-Plugin-Test-Portability     # ???
Dist-Zilla-Plugin-Test-Synopsis        # ???
Dist-Zilla-Plugin-Test-UnusedVars      # ???
Lingua-TreeTagger                      # ???
POE-Component-CPAN-Mirror-Multiplexer  # ???
POE-Component-Client-CouchDB           # ???
POE-Component-Github                   # ???
POE-Component-Metabase-Relay-Server    # ???
POE-Component-Server-SimpleHTTP-PreFork  # ???
Tapper-Testplan                        # ??? (hangs)
Test-Daily                             # ???
WWW-Alltop                             # ???
WWW-Hashdb                             # ??? (hangs, pegging cpu)
WebService-Async                       # ??? (hangs, pegging cpu)
WebService-LOC-CongRec                 # ???
Zucchini                               # ??? (hangs)

# not in cpan index for some reason
Hopkins                                # not found on cpan (?)
PostScript-Barcode                     # not found on cpan (?)

# failing for a reason
AI-ExpertSystem-Advanced               # no tests
API-Assembla                           # no tests
Algorithm-KernelKMeans                 # mx-types-common changes broke it
Alien-ActiveMQ                         # can't install activemq
AnyEvent-Inotify-Simple                # ??? (maybe issue with test::sweet)
AnyEvent-JSONRPC                       # tests require recommended deps
AnyEvent-Retry                         # mx-types-common changes broke it
AnyEvent-ZeroMQ                        # requires zeromq installation
App-Dataninja                          # bad M::I install in inc/
App-ForExample                         # getopt::chain is broken
App-Magpie                             # deps on URPM which doesn't exist
App-PgCryobit                          # requires postgres installation
App-TemplateServer                     # broken use of types
App-TemplateServer-Provider-HTML-Template  # dep on app-templateserver
App-TemplateServer-Provider-Mason      # dep on app-templateserver
App-TemplateServer-Provider-TD         # dep on app-templateserver
App-TimeTracker                        # git::repository is broken
App-USBKeyCopyCon                      # gtk tests are graphical
App-mkfeyorm                           # no tests
Archive-RPM                            # requires cpio
Bio-MAGETAB                            # datetime-format-datemanip is broken
Bot-Applebot                           # no tests
Bot-Backbone                           # broken deps
Business-UPS-Tracking                  # broken
CHI-Driver-Redis                       # requires redis server
CPAN-Mini-Webserver                    # undeclared dep on lingua-stopwords
Cache-Profile                          # broken
Catalyst-Authentication-Credential-Facebook-OAuth2  # no tests
Catalyst-Authentication-Store-Fey-ORM  # no tests
Catalyst-Authentication-Store-LDAP-AD-Class  # pod coverage fail
Catalyst-Controller-MovableType        # no tests
Catalyst-Controller-Resources          # broken
Catalyst-Engine-Stomp                  # requires alien::activemq
Catalyst-Model-MenuGrinder             # no tests
Catalyst-Model-Search-ElasticSearch    # requires elasticsearch
Catalyst-Model-Sedna                   # deps on Alien-Sedna which doesn't exist
Catalyst-Plugin-Continuation           # undeclared dep
Catalyst-Plugin-ErrorCatcher-ActiveMQ-Stomp  # pod coverage fail
Catalyst-Plugin-SwiffUploaderCookieHack  # undeclared dep
Catalyst-TraitFor-Component-ConfigPerSite  # undeclared dep
Catalyst-TraitFor-Controller-jQuery-jqGrid  # bad test (missing files)
CatalystX-MooseComponent               # broken
CatalystX-Restarter-GTK                # gtk tests are graphical
CatalystX-RoleApplicator               # broken
CatalystX-SimpleAPI                    # depends on ::RoleApplicator
CatalystX-SimpleLogin                  # broken
CatalystX-Usul                         # proc::processtable doesn't load
Cave-Wrapper                           # requires cave to be installed
Cheater                                # parse::randgen is broken
Class-OWL                              # uses CMOP::Class without loading cmop
Cogwheel                               # uses ancient moose apis
Constructible                          # GD::SVG is a broken dist
Coro-Amazon-SimpleDB                   # amazon::simpledb::client doesn't exist

# dep resolution failures or something (these pass when run manually)
AXL-Client-Simple
Alien-Ditaa
App-Benchmark-Accessors
Bot-BasicBot-Pluggable
Bot-BasicBot-Pluggable-Module-JIRA
CPAN-Digger
Cantella-Worker
Cantella-Worker-Role-Beanstalk
Catalyst-Plugin-Session
Catalyst-View-ByCode
Catalyst-View-RDF
CatalystX-Declare
CatalystX-Syntax-Action
Chart-Clicker
Chart-Weather-Forecast
Chef
Code-Statistics
Crypt-PBKDF2
Curses-Toolkit

# failing for some reason or another (need to look into this)
DBICx-Modeler-Generator
DBIx-Class-DeploymentHandler
DBIx-PgLink
DBIx-SchemaChecksum
Data-Apache-mod_status
Data-PackageName
Data-Pipeline
Data-SearchEngine-ElasticSearch
DayDayUp
Devel-Events
Devel-IntelliPerl
Dist-Zilla-Plugin-DualLife
Dist-Zilla-Plugin-GitFlow
Dist-Zilla-Plugin-MetaResourcesFromGit
Dist-Zilla-Plugin-ProgCriticTests
Dist-Zilla-Plugin-Rsync
Dist-Zilla-Plugin-SVK
Dist-Zilla-Plugin-Test-CPAN-Changes
Dist-Zilla-Plugin-Test-Kwalitee
Dist-Zilla-PluginBundle-ARODLAND
Dist-Zilla-PluginBundle-Author-OLIVER
Dist-Zilla-PluginBundle-FLORA
Dist-Zilla-PluginBundle-NIGELM
Dist-Zilla-PluginBundle-NUFFIN
Dist-Zilla-PluginBundle-RBUELS
DustyDB
ELF-Extract-Sections
ETLp
FCGI-Engine
FFmpeg-Thumbnail
Fedora-App-MaintainerTools
Fedora-App-ReviewTool
Fey-SQL-Pg
File-DataClass
Finance-Bank-SentinelBenefits-Csv401kConverter
Finance-Bank-SuomenVerkkomaksut
Forest-Tree-Viewer-Gtk2
Form-Factory
Frost
GOBO
Games-AssaultCube
Games-HotPotato
Games-Pandemic
Games-RailRoad
Games-Risk
Games-Tetris-Complete
Gearman-Driver
Geo-Calc
Getopt-Chain
Gitalist
Google-Spreadsheet-Agent
Grades
Graphics-Primitive-Driver-Cairo
Graphics-Primitive-Driver-CairoPango
HTML-FormHandler
HTML-FormHandler-Model-DBIC
HTML-TreeBuilderX-ASP_NET
Hobocamp
Horris
IM-Engine-Plugin-Dispatcher
IMS-CP-Manifest
IO-Multiplex-Intermediary
Image-Placeholder
JavaScript-Framework-jQuery
Jungle
Kafka-Client
Kamaitachi
KiokuDB-Backend-BDB
KiokuDB-Backend-Files
LWP-UserAgent-OfflineCache
Locale-Handle-Pluggable
Locale-MO-File
Log-Dispatch-Gtk2-Notify
MSWord-ToHTML
Mail-Summary-Tools
Mason
MediaWiki-USERINFO
Mildew
MooseX-APIRole
MooseX-Attribute-Prototype
MooseX-AutoImmute
MooseX-DBIC-Scaffold
MooseX-DOM
MooseX-Declare
MooseX-Documenter
MooseX-Error-Exception-Class
MooseX-Meta-Attribute-Index
MooseX-Meta-Attribute-Lvalue
MooseX-Method-Signatures
MooseX-MultiMethods
MooseX-MultiObject
MooseX-POE
MooseX-Params
MooseX-Struct
MooseX-TrackDirty-Attributes
MooseX-Workers
Net-Douban
Net-Dropbox
Net-FluidDB
Net-Fluidinfo
Net-HTTP-Factual
Net-Journyx
Net-Parliament
Net-Plurk
Net-Recurly
Net-StackExchange
Net-Topsy
NetHack-Item
NetHack-Monster-Spoiler
Nginx-Control
ODG-Record
POE-Component-Client-MPD
POE-Component-DirWatch
POE-Component-DirWatch-Object
POE-Component-IRC-Plugin-Role
POE-Component-MessageQueue
POE-Component-ResourcePool
POE-Component-Server-MySQL
POE-Component-Server-PSGI
POE-Component-Server-SimpleHTTP
POE-Test-Helpers
POEx-ProxySession
POEx-PubSub
POEx-WorkerPool
Paludis-UseCleaner
Parse-CPAN-Ratings
Parse-FixedRecord
Perlanet
Perlbal-Control
Pg-BulkCopy
Pod-Weaver-Section-Encoding
Proc-Safetynet
Queue-Leaky
RDF-Server
RPC-Any
Random-Quantum
Reaction
Reflex
Reflexive-Role-Collective
Reflexive-Role-DataMover
Reflexive-Role-TCPServer
Reflexive-Stream-Filtering
SRS-EPP-Proxy
STD
Scene-Graph
Schedule-Pluggable
SchemaEvolution
Server-Control
SilkiX-Converter-Kwiki
SimpleDB-Class
String-Blender
TAEB
Tail-Tool
Tapper-Installer
Tapper-MCP
Tapper-MCP-MessageReceiver
Tapper-Reports-API
Telephone-Mnemonic-US
Template-Plugin-Heritable
Test-A8N
Test-BDD-Cucumber
Test-Sweet
Test-System
Thorium
Tk-Role-Dialog
TryCatch
TryCatch-Error
VANAMBURG-SEMPROG-SimpleGraph
VCI
Verby
W3C-XMLSchema
WWW-FMyLife
WWW-Fandango
WWW-Getsy
WWW-Getsy
WWW-Mechanize-Cached
WWW-MenuGrinder
WWW-Metalgate
WWW-Scramble
WWW-StaticBlog
WWW-Yahoo-Lyrics-JP
Weaving-Tablet
WebNano-Controller-CRUD
WebService-Buxfer
WebService-CloudFlare-Host
WebService-SlimTimer
WebService-Yes24
WiX3
XIRCD
XML-Ant-BuildFile
XML-EPP
XML-LibXSLT-Easy
XML-Rabbit
XML-Schematron
YUM-RepoQuery
Yukki
mobirc
namespace-alias
