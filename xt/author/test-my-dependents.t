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
use Test::DependentModules qw( test_module );

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

my %todo_reasons = map {
    chomp;
    /^(\S*)\s*(?:#\s*(.*)\s*)?$/;
    defined($1) && length($1) ? ($1 => $2) : ()
} <DATA>;
my %todo = map { $_ => 1 } keys %todo_reasons;

my @skip_prefix = qw(Acme Task Bundle);
my %skip = map { $_ => 1 } (
    'App-CPAN2Pkg',                 # tk tests are graphical
    'App-USBKeyCopyCon',            # gtk tests are graphical
    'CatalystX-Restarter-GTK',      # gtk tests are graphical
    'CM-Permutation',               # OpenGL uses graphics in Makefile.PL
    'Dackup',                       # depends on running ssh
    'Data-Collector',               # depends on running ssh
    'Date-Biorhythm',               # Date::Business prompts in Makefile.PL
    'Forest-Tree-Viewer-Gtk2',      # gtk tests are graphical
    'Games-Pandemic',               # tk tests are graphical
    'Games-RailRoad',               # tk tests are graphical
    'Games-Risk',                   # tk tests are graphical
    'Gearman-Driver',               # spews tar errors
    'helm',                         # depends on running ssh
    'Log-Dispatch-Gtk2-Notify',     # gtk tests are graphical
    'LPDS',                         # gtk tests are graphical
    'Net-SFTP-Foreign-Exceptional', # depends on running ssh
    'Periscope',                    # gtk tests are graphical
    'POE-Component-OpenSSH',        # depends on running ssh
    'RDF-TrineX-RuleEngine-Jena',   # prompts in Makefile.PL
    'Test-SFTP',                    # Term::ReadPassword prompts in tests
    'Tk-Role-Dialog',               # tk tests are graphical
    'Weaving-Tablet',               # tk tests are graphical
    'WWW-Hashdb',                   # test hangs, pegging cpu
    'Zucchini',                     # File::Rsync prompts in Makefile.PL
);

my %name_fix = (
    'App-PipeFilter'                 => 'App::PipeFilter::Generic',
    'Constructible'                  => 'Constructible::Maxima',
    'DCOLLINS-ANN-Locals'            => 'DCOLLINS::ANN::Robot',
    'Dist-Zilla-Deb'                 => 'Dist::Zilla::Plugin::Deb::VersionFromChangelog',
    'Dist-Zilla-Plugins-CJM'         => 'Dist::Zilla::Plugin::TemplateCJM',
    'Dist-Zilla-Plugin-TemplateFile' => 'Dist::Zilla::Plugin::TemplateFiles',
    'helm'                           => 'Helm',
    'marc-moose'                     => 'MARC::Moose',
    'mobirc'                         => 'App::Mobirc',
    'OWL-Simple'                     => 'OWL::Simple::Class',
    'Patterns-ChainOfResponsibility' => 'Patterns::ChainOfResponsibility::Application',
    'Role-Identifiable'              => 'Role::Identifiable::HasIdent',
    'smokebrew'                      => 'App::SmokeBrew',
    'v6-alpha'                       => 'v6',
    'X11-XCB'                        => 'X11::XCB::Connection',
    'XML-Ant-BuildFile'              => 'XML::Ant::BuildFile::Project',
);
my @modules = map  { exists $name_fix{$_} ? $name_fix{$_} : $_ }
              sort
              grep { !$skip{$_} }
              grep { my $dist = $_; !any { $dist =~ /^$_-/ } @skip_prefix }
              map  { $_->{fields}{distribution} }
              @{ $res->{hits}{hits} };

plan tests => scalar @modules;
for my $module (@modules) {
    note($module);
    if ($todo{$module}) {
        my $reason = $todo_reasons{$module};
        $reason = '???' unless defined $reason;
        local $TODO = $reason;
        eval { test_module($module); 1 }
            or fail("Died when testing $module: $@");
    }
    else {
        eval { test_module($module); 1 }
            or fail("Died when testing $module: $@");
    }
}

__DATA__
# weird errors
Alice                                  # can't resolve distribution
Config-Model-Backend-Augeas            # deps on Config::Model
Config-Model                           # can't run tests
Config-Model-OpenSsh                   # deps on Config::Model
CPAN-Patches                           # can't run tests
CPAN-Patches-Plugin-Debian             # can't run tests
KiokuDB-Backend-BDB                    # can't run tests
Net-Azure-BlobService                  # ???
Pod-Weaver-Section-Consumes            # ???
Pod-Weaver-Section-Extends             # ???
TryCatch                               # can't run tests
XML-Rabbit                             # can't run tests

# Test::DM doesn't install deps properly (???)
App-Benchmark-Accessors                # deps aren't installed correctly (???)
Bot-BasicBot-Pluggable                 # deps aren't installed correctly (???)
Code-Statistics                        # deps aren't installed correctly (???)
Dist-Zilla-PluginBundle-Author-MELO    # deps aren't installed correctly (???)
Dist-Zilla-PluginBundle-MITHALDU       # deps aren't installed correctly (???)
Dist-Zilla-Util-FileGenerator          # deps aren't installed correctly (???)
EBI-FGPT-FuzzyRecogniser               # deps aren't installed correctly (???)
Erlang-Parser                          # deps aren't installed correctly (???)
Foorum                                 # deps aren't installed correctly (???)
Graphics-Primitive-Driver-CairoPango   # deps aren't installed correctly (???)
Grimlock                               # deps aren't installed correctly (???)
IMS-CP-Manifest                        # deps aren't installed correctly (???)
Locale-Handle-Pluggable                # deps aren't installed correctly (???)
marc-moose                             # deps aren't installed correctly (???)
Method-Signatures                      # deps aren't installed correctly (???)
mobirc                                 # deps aren't installed correctly (???)
MooseX-APIRole                         # deps aren't installed correctly (???)
MooseX-MultiObject                     # deps aren't installed correctly (???)
Net-Bamboo                             # deps aren't installed correctly (???)
Net-Stripe                             # deps aren't installed correctly (???)
Number-Phone-NANP-Vanity               # deps aren't installed correctly (???)
Perl-Achievements                      # deps aren't installed correctly (???)
Tatsumaki-Template-Markapl             # deps aren't installed correctly (???)
Text-TEI-Collate                       # deps aren't installed correctly (???)
Text-Tradition                         # deps aren't installed correctly (???)
WebService-SOS                         # deps aren't installed correctly (???)
WWW-Mechanize-Cached                   # deps aren't installed correctly (???)
XML-Ant-BuildFile                      # deps aren't installed correctly (???)

# no tests
AI-ExpertSystem-Advanced               # no tests
API-Assembla                           # no tests
App-mkfeyorm                           # no tests
Bot-Applebot                           # no tests
Catalyst-Authentication-Credential-Facebook-OAuth2 # no tests
Catalyst-Authentication-Store-Fey-ORM  # no tests
Catalyst-Controller-MovableType        # no tests
Catalyst-Model-MenuGrinder             # no tests
Chef                                   # no tests
Data-SearchEngine-ElasticSearch        # no tests
Dist-Zilla-MintingProfile-Author-ARODLAND # no tests
Dist-Zilla-PluginBundle-ARODLAND       # no tests
Dist-Zilla-PluginBundle-Author-OLIVER  # no tests
Dist-Zilla-PluginBundle-NUFFIN         # no tests
Dist-Zilla-Plugin-DualLife             # no tests
Dist-Zilla-Plugin-GitFlow              # no tests
Dist-Zilla-Plugin-GitFmtChanges        # no tests
Dist-Zilla-Plugin-MetaResourcesFromGit # no tests
Dist-Zilla-Plugin-ModuleBuild-OptionalXS # no tests
Dist-Zilla-Plugin-Rsync                # no tests
Dist-Zilla-Plugin-TemplateFile         # no tests
Dist-Zilla-Plugin-UploadToDuckPAN      # no tests
Finance-Bank-SuomenVerkkomaksut        # no tests
Games-HotPotato                        # no tests
IO-Storm                               # no tests
JIRA-Client-REST                       # no tests
Kafka-Client                           # no tests
LWP-UserAgent-OfflineCache             # no tests
Markdown-Pod                           # no tests
MooseX-Types-DateTimeX                 # no tests
Net-Dropbox                            # no tests
Net-Flowdock                           # no tests
Net-OpenStack-Attack                   # no tests
Net-Ostrich                            # no tests
Net-Recurly                            # no tests
OpenDocument-Template                  # no tests
Pod-Weaver-Section-Encoding            # no tests
POE-Component-Server-MySQL             # no tests
Random-Quantum                         # no tests
SchemaEvolution                        # no tests
STD                                    # no tests
Test-System                            # no tests
Test-WWW-Mechanize-Dancer              # no tests
WebService-Buxfer                      # no tests
WebService-CloudFlare-Host             # no tests
WWW-MenuGrinder                        # no tests
WWW-WuFoo                              # no tests

# external dependencies
Alien-ActiveMQ                         # requires activemq
AnyEvent-ZeroMQ                        # requires zeromq installation
AnyMQ-ZeroMQ                           # requires zeromq installation
Apache2-HttpEquiv                      # requires apache (for mod_perl)
App-Mimosa                             # requires fastacmd
App-PgCryobit                          # requires postgres installation
Archive-RPM                            # requires cpio
Catalyst-Engine-Stomp                  # depends on alien::activemq
Cave-Wrapper                           # requires cave to be installed
CHI-Driver-Redis                       # requires redis server
Crypt-Random-Source-Strong-Win32       # windows only
Dackup                                 # requires ssh
Data-Collector                         # requires ssh
DBIx-PgLink                            # requires postgres installation
Dist-Zilla-Plugin-Subversion           # requires svn bindings
Dist-Zilla-Plugin-SVK                  # requires svn bindings
Dist-Zilla-Plugin-SvnObtain            # requires svn bindings
Fedora-App-MaintainerTools             # requires rpm to be installed
Fedora-App-ReviewTool                  # requires koji to be installed
Games-HotPotato                        # requires sdl
Games-Tetris-Complete                  # requires threads
helm                                   # requires ssh
HTML-Barcode-QRCode                    # requires libqrencode
JavaScript-Sprockets                   # requires sprocketize
JavaScript-V8x-TestMoreish             # requires v8
Koha-Contrib-Tamil                     # requires yaz
K                                      # requires kx
Lighttpd-Control                       # requires lighttpd
Lingua-TreeTagger                      # requires treetagger to be installed
Math-Lsoda                             # requires f77
MongoDBI                               # requires mongo
MongoDB                                # requires mongo
MSWord-ToHTML                          # requires abiword to be installed
Net-Route                              # requires route
Nginx-Control                          # requires nginx to be installed
NLP-Service                            # requires javac
Padre-Plugin-Moose                     # requires threaded perl
Padre-Plugin-PDL                       # requires threaded perl
Padre-Plugin-Snippet                   # requires threaded perl
Paludis-UseCleaner                     # depends on cave::wrapper
Perlanet                               # HTML::Tidy requires tidyp
Perl-Dist-Strawberry-BuildPerl-5123    # windows only
Perl-Dist-Strawberry-BuildPerl-5123    # windows only
Perl-Dist-WiX-BuildPerl-5123           # windows only
Perl-Dist-WiX                          # windows only
Perl-Dist-WiX                          # windows only
POE-Component-OpenSSH                  # requires ssh
RDF-TrineX-RuleEngine-Jena             # requires Jena
SimpleDB-Class                         # requires memcached
SVN-Simple-Hook                        # requires svn
SVN-Tree                               # requires svn
Template-JavaScript                    # requires v8
ZeroMQ-PubSub                          # requires zmq
ZMQ-Declare                            # requires zmq

# graphical
App-CPAN2Pkg                           # tk tests are graphical
App-USBKeyCopyCon                      # gtk tests are graphical
CatalystX-Restarter-GTK                # gtk tests are graphical
Forest-Tree-Viewer-Gtk2                # gtk tests are graphical
Games-Pandemic                         # tk tests are graphical
Games-RailRoad                         # tk tests are graphical
Games-Risk                             # tk tests are graphical
Log-Dispatch-Gtk2-Notify               # gtk tests are graphical
LPDS                                   # gtk tests are graphical
Periscope                              # gtk tests are graphical
Tk-Role-Dialog                         # tk tests are graphical
Weaving-Tablet                         # tk tests are graphical

# failing for a reason
Algorithm-KernelKMeans                 # mx-types-common changes broke it
AnyEvent-BitTorrent                    # broken
AnyEvent-Cron                          # intermittent failures
AnyEvent-Inotify-Simple                # ??? (maybe issue with test::sweet)
AnyEvent-JSONRPC                       # tests require recommended deps
AnyEvent-Retry                         # mx-types-common changes broke it
AnyMongo                               # doesn't compile
App-ArchiveDevelCover                  # depends on nonexistent testdata::setup
App-Dataninja                          # bad M::I install in inc/
App-Fotagger                           # Imager doesn't compile
App-HistHub                            # missing dep on JSON.pm
App-Magpie                             # deps on URPM which doesn't exist
App-MediaWiki2Git                      # git::repository is broken
App-Munchies                           # depends on XML::DTD
App-TemplateServer                     # broken use of types
App-TemplateServer-Provider-HTML-Template  # dep on app-templateserver
App-TemplateServer-Provider-Mason      # dep on app-templateserver
App-TemplateServer-Provider-TD         # dep on app-templateserver
App-TimeTracker                        # git::repository is broken
App-Twimap                             # dep on Web::oEmbed::Common
App-Validation-Automation              # dep on Switch
App-Wubot                              # broken
Beagle                                 # depends on term::readline::perl
Bio-MAGETAB                            # datetime-format-datemanip is broken
Bot-Backbone                           # poe-loop-ev prompts
Cache-Profile                          # broken
Catalyst-Authentication-Store-LDAP-AD-Class  # pod coverage fail
Catalyst-Controller-Resources          # broken
Catalyst-Controller-SOAP               # broken
Catalyst-Model-Sedna                   # deps on Alien-Sedna which doesn't exist
Catalyst-Plugin-Continuation           # undeclared dep
Catalyst-Plugin-ErrorCatcher-ActiveMQ-Stomp  # pod coverage fail
Catalyst-Plugin-Session-State-Cookie   # broken
Catalyst-Plugin-Session-Store-TestMemcached # dep with corrupt archive
Catalyst-Plugin-SwiffUploaderCookieHack  # undeclared dep
Catalyst-TraitFor-Request-PerLanguageDomains # dep on ::State::Cookie
CatalystX-I18N                         # dep on ::State::Cookie
CatalystX-MooseComponent               # broken
CatalystX-SimpleAPI                    # depends on mxms
CatalystX-SimpleLogin                  # broken
CatalystX-Usul                         # proc::processtable doesn't load
Cheater                                # parse::randgen is broken
Class-OWL                              # uses CMOP::Class without loading cmop
CM-Permutation                         # OpenGL uses graphics in Makefile.PL
Cogwheel                               # uses ancient moose apis
Constructible                          # GD::SVG is a broken dist
Constructible-Maxima                   # GD::SVG is a broken dist
Coro-Amazon-SimpleDB                   # amazon::simpledb::client doesn't exist
CPAN-Digger                            # requires DBD::SQLite
Data-AMF                               # missing dep on YAML
Data-Apache-mod_status                 # invalid characters in type name
Data-Edit                              # dist is missing some modules
Data-PackageName                       # broken
Data-Pipeline                          # uses ancient moose apis
Data-SCORM                             # pod coverage fail
Date-Biorhythm                         # Date::Business prompts in Makefile.PL
DayDayUp                               # MojoX-Fixup-XHTML doesn't exist
DBICx-Modeler-Generator                # broken (weirdly)
DBIx-Class-Migration                   # missing dep on Log::Contextual
DBIx-SchemaChecksum                    # broken
Debian-Apt-PM                          # configure time failures
Devel-Events                           # broken (role conflict)
Dist-Zilla-Deb                         # pod coverage fail
Dist-Zilla-Plugin-ChangelogFromGit-Debian # git::repository is broken
Dist-Zilla-Plugin-ProgCriticTests      # broken
DustyDB                                # uses old moose apis
Dwimmer                                # broken
ELF-Extract-Sections                   # depends on mxms
ETLp                                   # depends on mxms
Facebook-Graph                         # broken
Fedora-Bugzilla                        # deps on nonexistent things
FFmpeg-Thumbnail                       # undeclared dep
File-DataClass                         # XML::DTD is a broken dist
File-Stat-Moose                        # old moose apis
Finance-Bank-SentinelBenefits-Csv401kConverter  # depends on mxms
Form-Factory                           # uses old moose apis
FormValidator-Nested                   # broken
Frost                                  # broken
Gitalist                               # deps on mxms
Git-CPAN-Patch                         # system::command is broken
GOBO                                   # coerce with no coercion
Google-Chart                           # recreating type constraints
Google-Spreadsheet-Agent               # pod::coverage fail
Hobocamp                               # configure_requires needs EU::CChecker
Horris                                 # App::Horris isn't on cpan
HTML-Grabber                           # pod::coverage fail
HTML-TreeBuilderX-ASP_NET              # broken
HTTP-Engine-Middleware                 # missing dep on yaml
Image-Robohash                         # Graphics::Magick doesn't exist
IM-Engine-Plugin-Dispatcher            # p::d::declarative changed dists
JavaScript-Framework-jQuery            # coerce with no coercion
Jifty                                  # Test::WWW::Selenium needs devel::repl
JSORB                                  # broken
Jungle                                 # broken
Kamaitachi                             # pod::coverage fail
KiokuDB-Backend-Files                  # broken
Mail-Summary-Tools                     # DT::Format::DateManip is broken
MediaWiki-USERINFO                     # broken
Mildew                                 # depends on mxms
mobirc                                 # http::engine broken
MooseX-Attribute-Prototype             # uses old moose apis
MooseX-DBIC-Scaffold                   # needs unreleased sql-translator
MooseX-Documenter                      # broken
MooseX-DOM                             # "no Moose" unimports confess
MooseX-Error-Exception-Class           # metaclass compat breakage
MooseX-Getopt-Usage                    # missing dep on Test::Class
MooseX-Meta-Attribute-Index            # old moose apis
MooseX-Meta-Attribute-Lvalue           # old moose apis
MooseX-Method-Signatures               # broken
MooseX-Struct                          # ancient moose apis
MooseX-Types-Parameterizable           # broken
MySQL-Util                             # pod-coverage fail
Nagios-Passive                         # broken
Net-FluidDB                            # broken
Net-Fluidinfo                          # broken
Net-Google-Blogger                     # broken
Net-Google-FederatedLogin              # broken
NetHack-Item                           # NH::Monster::Spoiler is broken
NetHack-Monster-Spoiler                # broken (MX::CA issues)
Net-HTTP-Factual                       # broken
Net-Journyx                            # broken
Net-Mollom                             # broken
Net-Parliament                         # broken
Net-Plurk                              # broken
Net-StackExchange                      # broken
ODG-Record                             # Test::Benchmark broken
Perlbal-Control                        # proc::processtable doesn't load
Pg-BulkCopy                            # hardcodes /usr/bin/perl
Pinto-Common                           # broken
Pinto-Server                           # deps on pinto::common
Plack-Middleware-Image-Scale           # Image::Scale is broken
POE-Component-CPAN-Mirror-Multiplexer  # broken
POE-Component-ResourcePool             # broken
POE-Component-Server-PSGI              # broken deps
POE-Component-Server-SimpleHTTP-PreFork  # broken deps
POEx-ProxySession                      # broken deps
POEx-PubSub                            # broken deps
POEx-WorkerPool                        # broken deps
PostScript-ScheduleGrid-XMLTV          # XMLTV doesn't exist
PRANG                                  # broken
Prophet                                # depends on term::readline::perl
Queue-Leaky                            # broken
Railsish                               # dep on nonexistent dist
RDF-Server                             # "no Moose" unimports confess
Reaction                               # signatures is broken
Reflexive-Role-DataMover               # broken (reflex::role changes?)
Reflexive-Role-TCPServer               # broken (reflex::role changes?)
Reflexive-Stream-Filtering             # broken
RPC-Any                                # broken
Scene-Graph                            # has '+attr' in roles
Server-Control                         # proc::processtable doesn't load
Silki                                  # image::magick is broken
SilkiX-Converter-Kwiki                 # file::mimeinfo expects (?-xism:
Sloth                                  # rest::utils is broken
SRS-EPP-Proxy                          # depends on xml::epp
String-Blender                         # broken
TAEB                                   # broken
Tail-Tool                              # Getopt::Alt doesn't exist
Tapper-CLI                             # sys::info::driver::linux is broken
Tapper-Installer                       # sys::info::driver::linux is broken
Tapper-MCP-MessageReceiver             # sys::info::driver::linux is broken
Tapper-MCP                             # sys::info::driver::linux is broken
Tapper-Reports-API                     # sys::info::driver::linux is broken
Tapper-Testplan                        # sys::info::driver::linux is broken
Telephone-Mnemonic-US                  # rpm-build-perl is broken
Test-A8N                               # broken
Test-BDD-Cucumber                      # clone::fast is broken
Test-Daily                             # configure errors
Test-Pockito                           # broken
Test-SFTP                              # Term::ReadPassword prompts in tests
Test-WWW-Selenium-More                 # Test::WWW::Selenium needs devel::repl
Text-Clevery                           # broken
Thorium                                # depends on Hobocamp
TryCatch-Error                         # broken
Verby                                  # deps on poe::component::resourcepool
Weather-TW                             # missing dep on Mojo::DOM
Web-API-Mapper                         # broken
WebNano-Controller-CRUD                # broken
WebService-SlimTimer                   # depends on mxms
WebService-Yes24                       # broken
WiX3                                   # broken
WWW-Alltop                             # XML::SimpleObject configure fail
WWW-DataWiki                           # depends on mxms
WWW-Fandango                           # bad dist
WWW-FMyLife                            # broken
WWW-Hashdb                             # test hangs, pegging cpu
WWW-Metalgate                          # Cache is broken
WWW-Scramble                           # pod::coverage fail
WWW-Sitemapper                         # broken
WWW-StaticBlog                         # time::sofar is broken
WWW-WebKit                             # missing configure_req on EU::PkgConfig
WWW-Yahoo-Lyrics-JP                    # broken
XIRCD                                  # undeclared deps
XML-EPP                                # coerce without coercion
XML-LibXSLT-Easy                       # missing dep on mx-getopt, deps on mxms
XML-SRS                                # deps on prang
Yukki                                  # git::repository is broken
Zucchini                               # File::Rsync prompts in Makefile.PL
