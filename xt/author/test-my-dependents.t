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
# not in cpan index
Black-Board                            # not found on cpan because of mxd
Hopkins                                # not found on cpan (?)
PostScript-Barcode                     # not found on cpan (?)
VirtualBox-Manage                      # not found on cpan because of mxd

# no tests
AI-ExpertSystem-Advanced
API-Assembla
App-mkfeyorm
Bot-Applebot
Catalyst-Authentication-Credential-Facebook-OAuth2
Catalyst-Authentication-Store-Fey-ORM
Catalyst-Controller-MovableType
Catalyst-Model-MenuGrinder
Chef
Data-SearchEngine-ElasticSearch
Dist-Zilla-Plugin-DualLife
Dist-Zilla-Plugin-GitFlow
Dist-Zilla-Plugin-MetaResourcesFromGit
Dist-Zilla-Plugin-Rsync
Dist-Zilla-PluginBundle-ARODLAND
Dist-Zilla-PluginBundle-Author-OLIVER
Dist-Zilla-PluginBundle-NUFFIN
Games-HotPotato
Kafka-Client
LWP-UserAgent-OfflineCache
Net-Dropbox
Net-Recurly
Pod-Weaver-Section-Encoding
POE-Component-Server-MySQL
Random-Quantum
SchemaEvolution
STD
Test-System
WebService-Buxfer
WebService-CloudFlare-Host
WWW-MenuGrinder

# failing for a reason
Algorithm-KernelKMeans                 # mx-types-common changes broke it
Alien-ActiveMQ                         # can't install activemq
AnyEvent-Inotify-Simple                # ??? (maybe issue with test::sweet)
AnyEvent-JSONRPC                       # tests require recommended deps
AnyEvent-Retry                         # mx-types-common changes broke it
AnyEvent-ZeroMQ                        # requires zeromq installation
App-CPAN2Pkg                           # Tk doesn't compile
App-Dataninja                          # bad M::I install in inc/
App-ForExample                         # getopt::chain is broken
App-Fotagger                           # Imager doesn't compile
App-HistHub                            # missing dep on JSON.pm
App-Magpie                             # deps on URPM which doesn't exist
App-PgCryobit                          # requires postgres installation
App-TemplateServer                     # broken use of types
App-TemplateServer-Provider-HTML-Template  # dep on app-templateserver
App-TemplateServer-Provider-Mason      # dep on app-templateserver
App-TemplateServer-Provider-TD         # dep on app-templateserver
App-TimeTracker                        # git::repository is broken
App-USBKeyCopyCon                      # gtk tests are graphical
Archive-RPM                            # requires cpio
Bio-MAGETAB                            # datetime-format-datemanip is broken
Bot-Backbone                           # broken deps
Business-UPS-Tracking                  # broken
Cache-Profile                          # broken
Catalyst-Authentication-Store-LDAP-AD-Class  # pod coverage fail
Catalyst-Controller-Resources          # broken
Catalyst-Engine-Stomp                  # requires alien::activemq
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
CHI-Driver-Redis                       # requires redis server
Class-OWL                              # uses CMOP::Class without loading cmop
CM-Permutation                         # OpenGL uses graphics in Makefile.PL
Cogwheel                               # uses ancient moose apis
Constructible                          # GD::SVG is a broken dist
Coro-Amazon-SimpleDB                   # amazon::simpledb::client doesn't exist
CPAN-Digger                            # requires DBD::SQLite
CPAN-Mini-Webserver                    # undeclared dep on lingua-stopwords
CPAN-Patches-Plugin-Debian             # configure time failures
Dackup                                 # depends on running ssh
Data-Apache-mod_status                 # invalid characters in type name
Data-Collector                         # depends on running ssh
Data-PackageName                       # broken
Data-Pipeline                          # uses ancient moose apis
Date-Biorhythm                         # Date::Business prompts in Makefile.PL
DayDayUp                               # MojoX-Fixup-XHTML doesn't exist
DBICx-Modeler-Generator                # broken (weirdly)
DBIx-PgLink                            # requires postgres installation
DBIx-SchemaChecksum                    # broken
Debian-Apt-PM                          # configure time failures
Devel-Events                           # broken (role conflict)
Dist-Zilla-Plugin-ProgCriticTests      # broken
Dist-Zilla-Plugin-SVK                  # requires svn bindings
DustyDB                                # uses old moose apis
ELF-Extract-Sections                   # uses stash entries with ::
ETLp                                   # uses stash entries with ::
Fedora-App-MaintainerTools             # requires rpm to be installed
Fedora-App-ReviewTool                  # requires koji to be installed
FFmpeg-Thumbnail                       # undeclared dep
File-DataClass                         # XML::DTD is a broken dist
Finance-Bank-SentinelBenefits-Csv401kConverter  # uses stash entries with ::
Forest-Tree-Viewer-Gtk2                # gtk tests are graphical
Form-Factory                           # uses old moose apis
Frost                                  # broken
Games-Pandemic                         # tk doesn't build
Games-RailRoad                         # tk doesn't build
Games-Risk                             # tk doesn't build
Games-Tetris-Complete                  # requires threads
Getopt-Chain                           # p::d::builder changed dists
GOBO                                   # coerce with no coercion
Google-Spreadsheet-Agent               # pod::coverage fail
helm                                   # depends on running ssh
Hobocamp                               # configure_requires needs EU::CChecker
Horris                                 # App::Horris isn't on cpan
HTML-TreeBuilderX-ASP_NET              # broken
IM-Engine-Plugin-Dispatcher            # p::d::declarative changed dists
JavaScript-Framework-jQuery            # coerce with no coercion
Jungle                                 # broken
Kamaitachi                             # pod::coverage fail
KiokuDB-Backend-Files                  # broken
Lingua-TreeTagger                      # requires treetagger to be installed
Locale-MO-File                         # broken
Log-Dispatch-Gtk2-Notify               # gtk tests are graphical
Mail-Summary-Tools                     # DT::Format::DateManip is broken
MediaWiki-USERINFO                     # broken
Mildew                                 # regexp::grammars needs class::accessor
mobirc                                 # http::engine broken
MooseX-Attribute-Prototype             # uses old moose apis
MooseX-DBIC-Scaffold                   # needs unreleased sql-translator
MooseX-Documenter                      # broken
MooseX-DOM                             # "no Moose" unimports confess
MooseX-Error-Exception-Class           # metaclass compat breakage
MooseX-Meta-Attribute-Index            # old moose apis
MooseX-Meta-Attribute-Lvalue           # old moose apis
MooseX-Struct                          # ancient moose apis
MooseX-TrackDirty-Attributes           # old moose apis
MSWord-ToHTML                          # requires abiword to be installed
namespace-alias                        # won't compile
Net-Douban                             # broken
Net-FluidDB                            # broken
Net-Fluidinfo                          # broken
NetHack-Item                           # NH::Monster::Spoiler is broken
NetHack-Monster-Spoiler                # broken (MX::CA issues)
Net-HTTP-Factual                       # broken
Net-Journyx                            # broken
Net-Parliament                         # broken
Net-Plurk                              # broken
Net-StackExchange                      # broken
Nginx-Control                          # requires nginx to be installed
ODG-Record                             # Test::Benchmark broken
Paludis-UseCleaner                     # needs cave::wrapper
Parse-FixedRecord                      # broken
Perlanet                               # HTML::Tidy requires tidyp
Perlbal-Control                        # proc::processtable doesn't load
Perl-Dist-Strawberry-BuildPerl-5123    # windows only
Perl-Dist-WiX-BuildPerl-5123           # windows only
Perl-Dist-WiX                          # windows only
Pg-BulkCopy                            # hardcodes /usr/bin/perl
POE-Component-CPAN-Mirror-Multiplexer  # broken
POE-Component-DirWatch-Object          # broken
POE-Component-OpenSSH                  # depends on running ssh
POE-Component-ResourcePool             # broken
POE-Component-Server-PSGI              # broken deps
POE-Component-Server-SimpleHTTP-PreFork  # broken deps
POEx-ProxySession                      # broken deps
POEx-PubSub                            # broken deps
POEx-WorkerPool                        # broken deps
Queue-Leaky                            # broken
RDF-Server                             # "no Moose" unimports confess
Reaction                               # signatures is broken
Reflexive-Role-Collective              # broken (reflex::role changes?)
Reflexive-Role-DataMover               # broken (reflex::role changes?)
Reflexive-Role-TCPServer               # broken (reflex::role changes?)
RPC-Any                                # broken
Scene-Graph                            # has '+attr' in roles
Server-Control                         # proc::processtable doesn't load
SilkiX-Converter-Kwiki                 # file::mimeinfo expects (?-xism:
SimpleDB-Class                         # requires memcached
SRS-EPP-Proxy                          # depends on xml::epp
String-Blender                         # broken
TAEB                                   # broken
Tail-Tool                              # Getopt::Alt doesn't exist
Tapper-Installer                       # sys::info::driver::linux is broken
Tapper-MCP-MessageReceiver             # sys::info::driver::linux is broken
Tapper-MCP                             # sys::info::driver::linux is broken
Tapper-Reports-API                     # sys::info::driver::linux is broken
Tapper-Testplan                        # sys::info::driver::linux is broken
Telephone-Mnemonic-US                  # rpm-build-perl is broken
Test-A8N                               # broken
Test-Daily                             # configure errors
Test-SFTP                              # Term::ReadPassword prompts in tests
Thorium                                # requires Hobocamp
Tk-Role-Dialog                         # tk won't compile
TryCatch-Error                         # broken
Verby                                  # requires poe::component::resourcepool
Weaving-Tablet                         # tk doesn't compile
WebService-SlimTimer                   # weird mxms error
WebService-Yes24                       # broken
WiX3                                   # broken
WWW-Alltop                             # XML::SimpleObject configure fail
WWW-Fandango                           # bad dist
WWW-FMyLife                            # broken
WWW-Hashdb                             # test hangs, pegging cpu
WWW-Metalgate                          # Cache is broken
WWW-Scramble                           # pod::coverage fail
WWW-StaticBlog                         # time::sofar is broken
WWW-Yahoo-Lyrics-JP                    # broken
XIRCD                                  # undeclared deps
XML-EPP                                # coerce without coercion
XML-LibXSLT-Easy                       # missing dep on mx-getopt
Yukki                                  # git::repository is broken
Zucchini                               # File::Rsync prompts in Makefile.PL
