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
DBICx-Modeler-Generator                # broken (weirdly)
DBIx-PgLink                            # requires postgres installation
DBIx-SchemaChecksum                    # broken
Data-Apache-mod_status                 # invalid characters in type name
Data-PackageName                       # broken
Data-Pipeline                          # uses ancient moose apis
DayDayUp                               # MojoX-Fixup-XHTML doesn't exist
Devel-Events                           # broken (role conflict)
Dist-Zilla-Plugin-ProgCriticTests      # broken
Dist-Zilla-Plugin-SVK                  # requires svn bindings
DustyDB                                # uses old moose apis
ELF-Extract-Sections                   # uses stash entries with ::
ETLp                                   # uses stash entries with ::
FFmpeg-Thumbnail                       # undeclared dep
Fedora-App-MaintainerTools             # requires rpm to be installed
Fedora-App-ReviewTool                  # requires koji to be installed
File-DataClass                         # XML::DTD is a broken dist
Finance-Bank-SentinelBenefits-Csv401kConverter  # uses stash entries with ::
Forest-Tree-Viewer-Gtk2                # gtk tests are graphical
Form-Factory                           # uses old moose apis
Frost                                  # broken
GOBO                                   # coerce with no coercion
Games-Pandemic                         # tk doesn't build
Games-RailRoad                         # tk doesn't build
Games-Risk                             # tk doesn't build
Games-Tetris-Complete                  # requires threads
Getopt-Chain                           # p::d::builder changed dists
Google-Spreadsheet-Agent               # pod::coverage fail
HTML-TreeBuilderX-ASP_NET              # broken
Hobocamp                               # configure_requires needs EU::CChecker
Horris                                 # App::Horris isn't on cpan
IM-Engine-Plugin-Dispatcher            # p::d::declarative changed dists
JavaScript-Framework-jQuery            # coerce with no coercion
Jungle                                 # broken
Kamaitachi                             # pod::coverage fail
KiokuDB-Backend-Files                  # broken
Locale-MO-File                         # broken
Log-Dispatch-Gtk2-Notify               # gtk tests are graphical
MSWord-ToHTML                          # requires abiword to be installed
Mail-Summary-Tools                     # DT::Format::DateManip is broken
MediaWiki-USERINFO                     # broken
MooseX-Attribute-Prototype             # uses old moose apis
MooseX-DBIC-Scaffold                   # needs unreleased sql-translator
MooseX-DOM                             # "no Moose" unimports confess
MooseX-Documenter                      # broken
MooseX-Error-Exception-Class           # metaclass compat breakage
MooseX-Meta-Attribute-Index            # old moose apis
MooseX-Meta-Attribute-Lvalue           # old moose apis
MooseX-Struct                          # ancient moose apis
MooseX-TrackDirty-Attributes           # old moose apis
Net-Douban                             # broken
Net-Dropbox                            # no tests
Net-FluidDB                            # broken
Net-Fluidinfo                          # broken
Net-HTTP-Factual                       # broken
Net-Journyx                            # broken
Net-Parliament                         # broken
Net-Plurk                              # broken
Net-Recurly                            # no tests
Net-StackExchange                      # broken
NetHack-Item                           # NH::Monster::Spoiler is broken
NetHack-Monster-Spoiler                # broken (MX::CA issues)
Nginx-Control                          # requires nginx to be installed
ODG-Record                             # Test::Benchmark broken
POE-Component-DirWatch-Object          # broken
POE-Component-ResourcePool             # broken
POE-Component-Server-MySQL             # no tests
POE-Component-Server-PSGI              # broken deps
POEx-ProxySession                      # broken deps
POEx-PubSub                            # broken deps
POEx-WorkerPool                        # broken deps
Paludis-UseCleaner                     # needs cave::wrapper
Parse-FixedRecord                      # broken
Perlanet                               # HTML::Tidy requires tidyp
Perlbal-Control                        # proc::processtable doesn't load
Pg-BulkCopy                            # hardcodes /usr/bin/perl
Queue-Leaky                            # broken
Random-Quantum                         # no tests
RDF-Server                             # "no Moose" unimports confess
RPC-Any                                # broken
Reaction                               # signatures is broken
Reflexive-Role-Collective              # broken (reflex::role changes?)
Reflexive-Role-DataMover               # broken (reflex::role changes?)
Reflexive-Role-TCPServer               # broken (reflex::role changes?)
SRS-EPP-Proxy                          # depends on xml::epp
STD                                    # no tests
Scene-Graph                            # has '+attr' in roles
SchemaEvolution                        # no tests
Server-Control                         # proc::processtable doesn't load
SilkiX-Converter-Kwiki                 # file::mimeinfo expects (?-xism:
SimpleDB-Class                         # requires memcached
String-Blender                         # broken
TAEB                                   # broken
Tail-Tool                              # Getopt::Alt doesn't exist
Tapper-Installer                       # sys::info::driver::linux is broken
Tapper-MCP                             # sys::info::driver::linux is broken
Tapper-MCP-MessageReceiver             # sys::info::driver::linux is broken
Tapper-Reports-API                     # sys::info::driver::linux is broken
Telephone-Mnemonic-US                  # rpm-build-perl is broken
Test-A8N                               # broken
Thorium                                # requires Hobocamp
Tk-Role-Dialog                         # tk won't compile
TryCatch-Error                         # broken
Verby                                  # requires poe::component::resourcepool
WWW-FMyLife                            # broken
WWW-Fandango                           # bad dist
WWW-Metalgate                          # Cache is broken
WWW-Scramble                           # pod::coverage fail
WWW-StaticBlog                         # time::sofar is broken
WWW-Yahoo-Lyrics-JP                    # broken
Weaving-Tablet                         # tk doesn't compile
WebService-Buxfer                      # no tests
WebService-CloudFlare-Host             # no tests
WebService-Yes24                       # broken
WiX3                                   # broken
XIRCD                                  # undeclared deps
XML-EPP                                # coerce without coercion
Yukki                                  # git::repository is broken
mobirc                                 # http::engine broken
namespace-alias                        # won't compile

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
DBIx-Class-DeploymentHandler
Data-SearchEngine-ElasticSearch
Devel-IntelliPerl
Dist-Zilla-Plugin-DualLife
Dist-Zilla-Plugin-GitFlow
Dist-Zilla-Plugin-MetaResourcesFromGit
Dist-Zilla-Plugin-Rsync
Dist-Zilla-Plugin-Test-CPAN-Changes
Dist-Zilla-Plugin-Test-Kwalitee
Dist-Zilla-PluginBundle-ARODLAND
Dist-Zilla-PluginBundle-Author-OLIVER
Dist-Zilla-PluginBundle-FLORA
Dist-Zilla-PluginBundle-NIGELM
Dist-Zilla-PluginBundle-NUFFIN
Dist-Zilla-PluginBundle-RBUELS
FCGI-Engine
Fey-SQL-Pg
Finance-Bank-SuomenVerkkomaksut
Games-AssaultCube
Games-HotPotato
Gearman-Driver
Geo-Calc
Gitalist
Grades
Graphics-Primitive-Driver-Cairo
Graphics-Primitive-Driver-CairoPango
HTML-FormHandler
HTML-FormHandler-Model-DBIC
IMS-CP-Manifest
IO-Multiplex-Intermediary
Image-Placeholder
Kafka-Client
KiokuDB-Backend-BDB
LWP-UserAgent-OfflineCache
Locale-Handle-Pluggable
Mason
Mildew
MooseX-APIRole
MooseX-AutoImmute
MooseX-Declare
MooseX-Method-Signatures
MooseX-MultiMethods
MooseX-MultiObject
MooseX-POE
MooseX-Params
MooseX-Workers
Net-Topsy
POE-Component-Client-MPD
POE-Component-DirWatch
POE-Component-IRC-Plugin-Role
POE-Component-MessageQueue
POE-Component-Server-SimpleHTTP
POE-Test-Helpers
Parse-CPAN-Ratings
Pod-Weaver-Section-Encoding
Proc-Safetynet
Reflex
Reflexive-Stream-Filtering
Schedule-Pluggable
Template-Plugin-Heritable
Test-BDD-Cucumber
Test-Sweet
Test-System
TryCatch
VANAMBURG-SEMPROG-SimpleGraph
VCI
W3C-XMLSchema
WWW-Getsy
WWW-Mechanize-Cached
WWW-MenuGrinder
WebNano-Controller-CRUD
WebService-SlimTimer
XML-Ant-BuildFile
XML-LibXSLT-Easy
XML-Rabbit
XML-Schematron
YUM-RepoQuery
