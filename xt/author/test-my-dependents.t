use strict;
use warnings;

use Cwd qw( abs_path );
use Test::More;

BEGIN {
    my $help = <<'EOF';
This test will not run unless you set MOOSE_TEST_MD to a true value.

  Valid values are:

     all                  Test every dist which depends on Moose except those
                          that we know cannot be tested. This is a lot of
                          distros (thousands).

     Dist::1,Dist::2,...  Test the individual dists listed.

     MooseX               Test all Moose extension distros
                          (MooseX modules plus a few others).

     1                    Run the default tests. We pick 200 random dists and
                          test them.

EOF

    plan skip_all => $help
        unless $ENV{MOOSE_TEST_MD};
}

use Test::Requires {
    'Archive::Zip' => 0,    # or else .zip dists won't be able to be installed
    'Test::DependentModules' => '0.13',
    'MetaCPAN::API'          => '0.33',
};

use Test::DependentModules qw( test_module );

use DateTime;
use List::Util 1.33 qw(any);
use Moose ();

diag(     'Test run performed at: '
        . DateTime->now
        . ' with Moose '
        . (Moose->VERSION || 'git repo') );

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

my @skip_prefix = qw(Acme Task Bundle);
my %skip;
my %todo;

my $hash;
for my $line (<DATA>) {
    chomp $line;
    next unless $line =~ /\S/;
    if ( $line =~ /^# (\w+)/ ) {
        die "Invalid action in DATA section ($1)"
            unless $1 eq 'SKIP' || $1 eq 'TODO';
        $hash = $1 eq 'SKIP' ? \%skip : \%todo;
    }

    my ( $dist, $reason ) = $line =~ /^(\S*)\s*(?:#\s*(.*)\s*)?$/;
    next unless defined $dist && length $dist;

    $hash->{$dist} = $reason;
}

my %name_fix = (
    'AI-Classifier'                  => 'AI::Classifier::Text',
    'Algorithm-DependencySolver'     => 'Algorithm::DependencySolver::Solver',
    'Alice'                          => 'Alice::HTTP::WebSocket',
    'App-Foca'                       => 'App::Foca::Server',
    'App-passmanager'                => 'App::PassManager',
    'App-PipeFilter'                 => 'App::PipeFilter::Generic',
    'Bio_AssemblyImprovement'        => 'Bio::AssemblyImprovement',
    'Business-PaperlessTrans'        => 'Business::PaperlessTrans::Client',
    'BuzzSaw'                        => 'App::BuzzSaw',
    'Constructible'                  => 'Constructible::Maxima',
    'CTKlib'                         => 'CTK',
    'DCOLLINS-ANN-Locals'            => 'DCOLLINS::ANN::Robot',
    'Dist-Zilla-Deb'                 => 'Dist::Zilla::Plugin::Deb::VersionFromChangelog',
    'Dist-Zilla-Plugins-CJM'         => 'Dist::Zilla::Plugin::TemplateCJM',
    'Dist-Zilla-Plugin-TemplateFile' => 'Dist::Zilla::Plugin::TemplateFiles',
    'DSL-Tiny'                       => 'DSL::Tiny::Role',
    'Google-Directions'              => 'Google::Directions::Client',
    'GoogleMapsHeatmap'              => 'Geo::Heatmap',
    'helm'                           => 'Helm',
    'HTML-Untemplate'                => 'HTML::Linear',
    'marc-moose'                     => 'MARC::Moose',
    'mobirc'                         => 'App::Mobirc',
    'Net-Amazon-EMR'                 => 'Net::Amazon::EMR::AddInstanceGroupsResult',
    'OWL-Simple'                     => 'OWL::Simple::Class',
    'Patterns-ChainOfResponsibility' => 'Patterns::ChainOfResponsibility::Application',
    'PkgForge'                       => 'PkgForge::App',
    'PkgForge-Server'                => 'PkgForge::Builder',
    'Pod-Elemental-Transfomer-VimHTML' => 'Pod::Elemental::Transformer::VimHTML',
    'Role-Identifiable'              => 'Role::Identifiable::HasIdent',
    'smokebrew'                      => 'App::SmokeBrew',
    'Treex-Parser-MSTperl'           => 'Treex::Tool::Parser::MSTperl',
    'v6-alpha'                       => 'v6',
    'WebService-LOC-CongRec'         => 'WebService::LOC::CongRec::Crawler',
    'X11-XCB'                        => 'X11::XCB::Connection',
    'XML-Ant-BuildFile'              => 'XML::Ant::BuildFile::Project',
);

my @dists = sort
            grep { !$skip{$_} }
            grep { my $dist = $_; !any { $dist =~ /^$_-/ } @skip_prefix }
            map  { $_->{fields}{distribution} }
            @{ $res->{hits}{hits} };

if ( $ENV{MOOSE_TEST_MD} eq 'MooseX' ) {
    @dists = grep {
        /^(?:MooseX-|(?:Fey-ORM|KiokuDB|Bread-Board|Catalyst-Runtime|Reflex)$)/
    } @dists;
}
elsif ( $ENV{MOOSE_TEST_MD} eq '1' ) {
    diag(
        <<'EOF'
  Picking 200 random dependents to test. Set MOOSE_TEST_MD=all to test all
  dependents or MOOSE_TEST_MD=MooseX to test extension modules only.
EOF
    );

    my %indexes;
    while ( keys %indexes < 200 ) {
        $indexes{ int rand( scalar @dists ) } = 1;
    }

    @dists = @dists[ sort keys %indexes ];
}
elsif ( $ENV{MOOSE_TEST_MD} ne 'all' ) {
    my @chosen = split /,/, $ENV{MOOSE_TEST_MD};
    my %dists = map { $_ => 1 } @dists;
    if (my @unknown = grep { !$dists{$_} } @chosen) {
        die "Unknown dists: @unknown";
    }
    @dists = @chosen;
}

plan tests => scalar @dists;
for my $dist (@dists) {
    note($dist);
    my $module = $dist;
    $module = $name_fix{$module} if exists $name_fix{$module};
    if ($todo{$dist}) {
        my $reason = $todo{$dist};
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
# SKIP: doesn't install deps properly (test::dm bugs?)
App-Benchmark-Accessors                # Mojo::Base isn't installed
Bot-BasicBot-Pluggable                 # Crypt::SaltedHash isn't installed
Chart-Clicker                          # Layout::Manager::Compass isn't installed
Chart-Weather-Forecast                 # Layout::Manager::Compass isn't installed
Code-Statistics                        # MooseX::HasDefaults::RO isn't installed
Connector                              # Config::Versioned isn't installed
Context-Set                            # Lingua::EN::Words2Nums isn't installed
DBIx-Class-DeploymentHandler           # Lingua::EN::Words2Nums isn't installed
DBIx-Class-Migration                   # Lingua::EN::Words2Nums isn't installed
DBIx-Class-Migration-RunScript-Trait-AuthenPassphrase  # Lingua::EN::Words2Nums isn't installed
DBIx-Class-Schema-Loader               # Lingua::EN::Words2Nums isn't installed
DBIx-ObjectMapper                      # Class::Accessor::Chained::Fast isn't installed
Dependencies-Searcher                  # ack binary isn't installed, because test::dm doesn't set up $PATH
Dist-Zilla-PluginBundle-AJGB           # Dist::Zilla::Plugin::KwaliteeTests isn't installed
Dist-Zilla-PluginBundle-Author-BBYRD   # Dist::Zilla::Plugin::ReportPhase isn't installed
Dist-Zilla-PluginBundle-JQUELIN        # Dist::Zilla::Plugin::CompileTests isn't installed
Dist-Zilla-PluginBundle-MITHALDU       # List::AllUtils isn't installed
Dist-Zilla-PluginBundle-NIGELM         # Dist::Zilla::Plugin::KwaliteeTests isn't installed
Dist-Zilla-PluginBundle-PDONELAN       # Dist::Zilla::Plugin::CompileTests isn't installed
Dist-Zilla-Util-FileGenerator          # MooseX::HasDefaults::RO isn't installed
EBI-FGPT-FuzzyRecogniser               # GO::Parser isn't installed
Erlang-Parser                          # Parse::Yapp::Driver isn't installed
Foorum                                 # Sphinx::Search isn't installed
Grimlock                               # DBIx::Class::EncodedColumn isn't installed
Locale-Handle-Pluggable                # MooseX::Types::VariantTable::Declare isn't installed
Message-Passing-STOMP                  # Message::Passing isn't installed
mobirc                                 # HTTP::Session::State::GUID isn't installed
Net-Bamboo                             # XML::Tidy isn't installed
OpenERP-OOM                            # OpenERP::XMLRPC::Client isn't installed
Tatsumaki-Template-Markapl             # Tatsumaki::Template isn't installed
Text-Tradition                         # Bio::Phylo::IO isn't installed
Text-Tradition-Analysis                # Bio::Phylo::IO isn't installed
WebService-Strava                      # Any::URI::Escape isn't installed

# SKIP: index issues (test::dm bugs?)
Hopkins                                # can't find on cpan
PostScript-Barcode                     # can't find on cpan

# SKIP: no tests
AI-ExpertSystem-Advanced               # no tests
API-Assembla                           # no tests
App-mkfeyorm                           # no tests
App-passmanager                        # no tests
App-Scrobble                           # no tests
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
Dist-Zilla-Plugin-Git-Describe         # no tests
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
meon-Web                               # no tests
MooseX-Types-DateTimeX                 # no tests
MooseX-Types-DateTime-MoreCoercions    # no tests unless DateTime::Format::DateManip is installed
Net-Azure-BlobService                  # no tests
Net-Dropbox                            # no tests
Net-Flowdock                           # no tests
Net-OpenStack-Attack                   # no tests
Net-Ostrich                            # no tests
Net-Recurly                            # no tests
OpenDocument-Template                  # no tests
Pod-Weaver-Section-Consumes            # no tests
Pod-Weaver-Section-Encoding            # no tests
Pod-Weaver-Section-Extends             # no tests
P50Tools                               # no tests
POE-Component-Server-MySQL             # no tests
Prophet-Devel                          # no tests
Random-Quantum                         # no tests
SchemaEvolution                        # no tests
STD                                    # no tests
Test-System                            # no tests
Test-WWW-Mechanize-Dancer              # no tests
WebService-Buxfer                      # no tests
WebService-CloudFlare-Host             # no tests
WWW-MenuGrinder                        # no tests
WWW-UsePerl-Server                     # no tests
WWW-WuFoo                              # no tests

# SKIP: external dependencies
Alien-Ditaa                            # runs java code
Ambrosia                               # required mod_perl
AnyEvent-MSN                           # requires Net::SSLeay (which requires libssl)
AnyEvent-Multilog                      # requires multilog
AnyEvent-Net-Curl-Queued               # requires libcurl
AnyEvent-ZeroMQ                        # requires zeromq installation
AnyMQ-ZeroMQ                           # requires zeromq installation
Apache2-HttpEquiv                      # requires apache (for mod_perl)
App-Fotagger                           # requires sdl
App-Mimosa                             # requires fastacmd
App-PgCryobit                          # requires postgres installation
App-SimplenoteSync                     # requires File::ExtAttr which requires libattr
App-WIoZ                               # requires cairo
Archive-RPM                            # requires cpio
Bio-MLST-Check                         # requires makeblastdb, etc
Bio-Pipeline-Comparison                # requires bgzip, tabix, etc
Bot-Jabbot                             # requires libidn
Catalyst-Authentication-Store-CouchDB  # requires couchdb
Catalyst-Engine-Stomp                  # depends on alien::activemq
Catalyst-Plugin-Session-Store-Memcached # requires memcached
Catalyst-View-SVG-TT-Graph             # requires librsvg
Catalyst-View-Template-PHP             # requires php
Cave-Wrapper                           # requires cave to be installed
CHI-Driver-Redis                       # requires redis server
Crypt-Random-Source-Strong-Win32       # windows only
Curses-Toolkit                         # requires Curses which requires ncurses library
Dackup                                 # requires ssh
Dancer2-Plugin-Queue-MongoDB           # requires mongo
Data-Collector                         # requires ssh
Data-Riak                              # requires riak
Database-Migrator-mysql                # requires mysql installation
DBIx-MySQL-Replication-Slave           # requires mysql installation
DBIx-PgLink                            # requires postgres installation
Device-SMBus                           # requires libi2c
Device-ZyXEL-IES                       # SNMP requires net-snmp
Dist-Zilla-Plugin-ChangelogFromGit-Debian-Sequential  # requires dpkg
Dist-Zilla-Plugin-Subversion           # requires svn bindings
Dist-Zilla-Plugin-SVK                  # requires svn bindings
Dist-Zilla-Plugin-SvnObtain            # requires svn bindings
Dist-Zilla-Plugin-Upload-SCP           # requires ssh
Fedora-App-MaintainerTools             # requires rpm to be installed
Fedora-App-ReviewTool                  # requires koji to be installed
Fuse-Template                          # requires libfuse
Games-HotPotato                        # requires sdl
Games-Tetris-Complete                  # requires threads
Gapp                                   # requires gtk2
GappX-NoticeBox                        # requires gtk2
GnuPG-Interface                        # requires gpg
GoogleMapsHeatmap                      # requires imagemagick
Graphics-DZI                           # requires imagemagick
Graphics-Primitive-Driver-Cairo        # requires cairo
Graphics-Primitive-Driver-CairoPango   # requires cairo
helm                                   # requires ssh
HTML-Barcode-QRCode                    # requires libqrencode
Hypatia-Chart-Clicker                  # requires cairo
Hypatia-GraphViz2                      # requires graphviz
Image-Placeholder                      # requires gd
Image-TextMode                         # requires gd
IRC-RemoteControl                      # requires libssh2
JavaScript-Sprockets                   # requires sprocketize
JavaScript-V8x-TestMoreish             # requires v8
Koha-Contrib-Tamil                     # requires yaz
K                                      # requires kx
Lighttpd-Control                       # requires lighttpd
Lingua-TreeTagger                      # requires treetagger to be installed
Lorem                                  # requires cairo
Math-Lsoda                             # requires f77
Message-Passing-PSGI                   # requires zeromq installation
Message-Passing-ZeroMQ                 # requires zeromq installation
MongoDBI                               # requires mongo
MongoDB                                # requires mongo
MongoDB-Async                          # requires mongo
MSWord-ToHTML                          # requires abiword to be installed
MySQL-Slurp                            # requires mysql
Net-DBus-Skype                         # requires dbus
Net-Route                              # requires route
Net-SFTP-Foreign-Exceptional           # depends on running ssh
Net-UpYun                              # requires curl
Net-ZooTool                            # requires curl
Nginx-Control                          # requires nginx to be installed
NLP-Service                            # requires javac
Padre-Plugin-Cookbook                  # requires Wx
Padre-Plugin-Moose                     # requires threaded perl
Padre-Plugin-PDL                       # requires threaded perl
Padre-Plugin-Snippet                   # requires threaded perl
Paludis-UseCleaner                     # depends on cave::wrapper
Pantry                                 # requires ssh
Perlanet                               # HTML::Tidy requires tidyp
Perl-Dist-Strawberry-BuildPerl-5123    # windows only
Perl-Dist-Strawberry-BuildPerl-5123    # windows only
Perl-Dist-WiX-BuildPerl-5123           # windows only
Perl-Dist-WiX                          # windows only
Perl-Dist-WiX                          # windows only
Physics-UEMColumn                      # requires gsl
PkgForge                               # requires rpm
PkgForge-Registry                      # requires rpm
PkgForge-Server                        # requires rpm
Plack-App-FakeApache                   # requires mod_perl
POE-Component-OpenSSH                  # requires ssh
PulseAudio                             # requires pulseaudio
RDF-TrineX-RuleEngine-Jena             # requires Jena
Reflexive-ZmqSocket                    # requires zmq
SDLx-Betweener                         # requires sdl
SDLx-GUI                               # requires sdl
Siebel-COM                             # windows only
SimpleDB-Class                         # requires memcached
SVN-Simple-Hook                        # requires svn
SVN-Tree                               # requires svn
Tapper-Cmd                             # requires ssh
Tapper-MCP                             # depends on everything under the sun - some of which is broken
Template-JavaScript                    # requires v8
Test-Approvals                         # windows only
Test-DBIx-Class                        # requires mysql
Test-Gearman                           # requires gearman
TheSchwartz-Moosified                  # requires DBI::Pg ?
UAV-Pilot                              # requires sdl
WebService-SendGrid                    # requires curl
WebService-Tesco-API                   # requires curl
WWW-Contact                            # depends on curl
WWW-Curl-Simple                        # requires curl
ZeroMQ-PubSub                          # requires zmq
ZMQ-Declare                            # requires zmq
ZMQx-Class                             # requires zmq

# SKIP: flaky internet tests
iTransact-Lite                         # tests rely on internet site
Unicode-Emoji-E4U                      # tests rely on internet site
WWW-eNom                               # tests rely on internet site
WWW-Finances-Bovespa                   # tests rely on internet site
WWW-Vimeo-Download                     # tests rely on internet site
WWW-YouTube-Download-Channel           # tests rely on internet site

# SKIP: graphical
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

# SKIP: prompts (or a dep prompts) or does something else dumb
AI-Nerl                                # pdl has weird memory errors and hangs
Bio-Tradis                             # Bio::DB::Sam prompts in Makefile.PL
Bot-Backbone                           # poe-loop-ev prompts
Cache-Ehcache                          # hangs if server exists on port 8080
Cache-Memcached-Queue                  # Makefile.PL tries to auto-install deps manually
CM-Permutation                         # OpenGL uses graphics in Makefile.PL
Date-Biorhythm                         # Date::Business prompts in Makefile.PL
DBIx-VersionedDDL                      # runs a script with /usr/bin/perl in the shbang line
File-Tail-Scribe                       # tests hang
Gearman-Driver                         # spews tar errors
Gearman-SlotManager                    # tests hang
IPC-AnyEvent-Gearman                   # tests hang
Lingua-YALI                            # runs scripts with /usr/bin/env perl in the shbang line
Net-SSH-Mechanize                      # the mock-ssh script it runs seems to spin endlessly
POE-Component-Server-SimpleHTTP-PreFork # tests hang
Test-SFTP                              # Term::ReadPassword prompts in tests
WebService-FogBugz-XML                 # prompts
WWW-Hashdb                             # test hangs, pegging cpu
Zucchini                               # File::Rsync prompts in Makefile.PL

# SKIP: broken configure
Module-Install-ProvidesClass           # broken Makefile.PL
Nagios-Interface                       # broken Makefile.PL
TAP-Runner                             # Math::Cartesian::Product is broken

# TODO: failing for a reason
Algorithm-KernelKMeans                 # mx-types-common changes broke it
Alien-BWIPP                            # given is experimental
AnyEvent-BitTorrent                    # broken
AnyEvent-Cron                          # intermittent failures
AnyEvent-Inotify-Simple                # ??? (maybe issue with test::sweet)
AnyEvent-JSONRPC                       # tests require recommended deps
AnyEvent-Retry                         # mx-types-common changes broke it
AnyMongo                               # doesn't compile
App-ArchiveDevelCover                  # depends on nonexistent testdata::setup
App-Dataninja                          # bad M::I install in inc/
App-Foca                               # pod coverage fail
App-HistHub                            # missing deps
App-iTan                               # given is experimental
App-Magpie                             # deps on URPM which doesn't exist
App-MediaWiki2Git                      # git::repository is broken
App-Munchies                           # depends on XML::DTD
App-PM-Announce                        # deps on WWW::UsePerl::Journal::Post which doesn't exist
App-Rssfilter                          # given is experimental
App-Services                           # misnamed package
App-TemplateServer                     # broken use of types
App-TemplateServer-Provider-HTML-Template  # dep on app-templateserver
App-TemplateServer-Provider-Mason      # dep on app-templateserver
App-TemplateServer-Provider-TD         # dep on app-templateserver
App-TimeTracker                        # missing dep on IO::Capture::Stdout
App-Twimap                             # dep on Web::oEmbed::Common
App-Twitch                             # given is experimental
App-Validation-Automation              # dep on Switch
App-Wubot                              # broken
Archive-BagIt                          # pod coverage fail
Argon                                  # missin dep on IO::Capture::Stderr
Autocache                              # hash randomization
Beagle                                 # depends on term::readline::perl
Beam-Wire-Moose                        # broken
Bio-MAGETAB                            # pod coverage fail and possibly hash randomization
Bio_AssemblyImprovement                # broken
BPM-Engine                             # incorrect deps
Business-RO-CNP                        # broken
Business-UPS-Tracking                  # given is experimental
Cache-Profile                          # broken
Catalyst-Action-Serialize-Data-Serializer  # looks like changes in opcode structure
Catalyst-ActionRole-BuildDBICResult    # broken
Catalyst-Authentication-Store-LDAP-AD-Class  # pod coverage fail
Catalyst-Controller-AutoAssets         # broken
Catalyst-Controller-Resources          # broken
Catalyst-Controller-SOAP               # broken
Catalyst-Engine-Embeddable             # broken
Catalyst-Model-Akismet                 # broken (fake key no longer works)
Catalyst-Model-FormFu                  # missing deps
Catalyst-Model-Sedna                   # deps on Alien-Sedna which doesn't exist
Catalyst-Plugin-Continuation           # undeclared dep
Catalyst-Plugin-I18N-DBI               # pod coverage fail
Catalyst-Plugin-Session-State-Cookie   # broken
Catalyst-Plugin-Session-Store-TestMemcached # dep with corrupt archive
Catalyst-Plugin-SwiffUploaderCookieHack  # undeclared dep
Catalyst-TraitFor-Component-ConfigPerSite  # broken
Catalyst-TraitFor-Request-PerLanguageDomains # dep on ::State::Cookie
CatalystX-Declare                      # flaky tests (hash randomization?)
CatalystX-ExtJS-Direct                 # broken
CatalystX-ExtJS-REST                   # broken
CatalystX-I18N                         # dep on ::State::Cookie
CatalystX-MooseComponent               # broken
CatalystX-OAuth2                       # deps on CatalystX::Test::MockContent, which doesn't exist
CatalystX-SimpleLogin                  # broken
CatalystX-Usul                         # proc::processtable doesn't load
Chart-OFC2                             # coerce without a coercion
Cheater                                # parse::randgen is broken
CHI-Driver-SharedMem                   # hash randomization
Class-OWL                              # uses CMOP::Class without loading cmop
CloudApp-REST                          # pod coverage fail
Cogwheel                               # uses ancient moose apis
Config-Model                           # broken
Config-Model-Backend-Augeas            # deps on Config::Model
Config-Model-OpenSsh                   # deps on Config::Model
Constructible                          # GD::SVG is a broken dist
Constructible-Maxima                   # GD::SVG is a broken dist
Coro-Amazon-SimpleDB                   # amazon::simpledb::client doesn't exist
CPAN-Digger                            # requires DBD::SQLite
CPAN-Source                            # missing deps
Data-AMF                               # missing dep on YAML
Data-Apache-mod_status                 # invalid characters in type name
Data-Edit                              # dist is missing some modules
Data-Feed                              # broken (only sometimes?)
Data-Keys                              # hash randomization
Data-PackageName                       # broken
Data-Pensieve                          # missing deps
Data-Pipeline                          # uses ancient moose apis
Data-SCORM                             # pod coverage fail
Data-Valve                             # for qw()
DayDayUp                               # MojoX-Fixup-XHTML doesn't exist
DBICx-Modeler-Generator                # broken (weirdly)
DBIx-Class-FormTools                   # hash randomization
DBIx-NoSQL-Store-Manager               # flaky tests (hash randomization?)
DBIx-SchemaChecksum                    # broken
Debian-Apt-PM                          # configure time failures
Devel-Events                           # broken (role conflict)
Dist-Zilla-Deb                         # pod coverage fail
Dist-Zilla-Plugin-ChangelogFromGit-Debian # git::repository is broken
Dist-Zilla-Plugin-CheckChangesHasContent  # broken
Dist-Zilla-Plugin-Git                  # tests fail when run in a temp dir
Dist-Zilla-Plugin-LaunchpadPPA         # depends on Dpkg::Changelog::Parse which doesn't exist
Dist-Zilla-Plugin-PerlTidy             # expects to find dzil in the path
Dist-Zilla-Plugin-Pinto-Add            # deps on Pinto::Common
Dist-Zilla-Plugin-ProgCriticTests      # broken
Dist-Zilla-Plugin-Test-ReportPrereqs   # broken
DustyDB                                # uses old moose apis
Dwimmer                                # broken
ElasticSearchX-Model                   # hash randomization
Facebook-Graph                         # broken
FCGI-Engine                            # runs scripts without using $^X
Fedora-Bugzilla                        # deps on nonexistent things
Fey-Loader                             # broken
FFmpeg-Thumbnail                       # undeclared dep
File-Corresponding                     # broken
File-DataClass                         # XML::DTD is a broken dist
File-Stat-Moose                        # old moose apis
File-Tail-Dir                          # intermittent fails (i think)
FilmAffinity-UserRating                # hash randomization
Finance-Bank-SentinelBenefits-Csv401kConverter  # hash randomization
Form-Factory                           # uses old moose apis
Form-Sensible                          # broken
FormValidator-Nested                   # broken
Frost                                  # broken
Games-Dice-Loaded                      # flaky tests
Geometry-Primitive                     # coerce with no coercion
Gideon                                 # broken
Git-PurePerl                           # for qw()
Git-Release                            # undeclared dep on Mo
Github-Score                           # broken tests
Gitalist                               # broken
GOBO                                   # coerce with no coercion
Google-AJAX-Library                    # hash randomization
Google-Chart                           # recreating type constraints
Google-Spreadsheet-Agent               # pod::coverage fail
Graph-Similarity                       # perlcritic fail
Hailo                                  # given/when is experimental
Hessian-Translator                     # perlcritic fail
Hobocamp                               # configure_requires needs EU::CChecker
Horris                                 # App::Horris isn't on cpan
HPPPM-Demand-Management                # pod::coverage fail
HTML-Element-Replacer                  # hash randomization
HTML-FormFu-ExtJS                      # hash randomization
HTML-FormHandlerX-Field-DateTimeNatural  # broken
HTML-FormHandlerX-Field-URI-HTTP       # broken
HTML-Grabber                           # pod::coverage fail
HTML-TreeBuilderX-ASP_NET              # broken
HTTP-Balancer                          # weird issue with proc::processtable
HTTP-Engine                            # hash randomization
HTTP-Engine-Middleware                 # missing dep on yaml
Image-Robohash                         # Graphics::Magick doesn't exist
JavaScript-Framework-jQuery            # coerce with no coercion
Jenkins-NotificationListener           # missing dep on File::Read
Jifty                                  # Test::WWW::Selenium needs devel::repl
jQuery-Loader                          # for qw()
JS-YUI-Loader                          # broken
JSON-RPC-Common                        # for qw()
JSORB                                  # broken
Jungle                                 # broken
Kamaitachi                             # pod::coverage fail
KiokuDB-Backend-Files                  # broken
KiokuDB-Backend-MongoDB                # pod fail
LaTeX-TikZ                             # broken (with moose)
LCFG-Build-PkgSpec                     # flaky tests (time zones?)
Lingua-Diversity                       # pod fail
marc-moose                             # broken (only sometimes?)
Mac-iPhoto-Exif                        # smartmatch is experimental
Magpie                                 # broken
Mail-Summary-Tools                     # DT::Format::DateManip is broken
MediaWiki-USERINFO                     # broken
Metabase-Backend-MongoDB               # broken
Metabase-Backend-SQL                   # broken (I think)
Method-Signatures                      # doesn't like ANY_MOOSE=Moose
Mildew                                 # Regexp::Grammars is broken on 5.18
mobirc                                 # http::engine broken
MooseX-App-Cmd-Command-BashComplete    # pod fail
MooseX-Attribute-Prototype             # uses old moose apis
MooseX-AttributeHelpers                # broken
MooseX-Compile                         # broken
MooseX-DBIC-Scaffold                   # needs unreleased sql-translator
MooseX-Documenter                      # broken
MooseX-DOM                             # "no Moose" unimports confess
MooseX-Error-Exception-Class           # metaclass compat breakage
MooseX-FSM                             # broken
MooseX-Getopt-Usage                    # missing dep on Test::Class
MooseX-GTIN                            # broken (under jenkins, at least)
MooseX-InlineTypes                     # coerce without coercion
MooseX-Meta-Attribute-Index            # old moose apis
MooseX-Meta-Attribute-Lvalue           # old moose apis
MooseX-Net-API                         # hash randomization
MooseX-Q4MLog                          # Queue::Q4MLog is broken
MooseX-Role-XMLRPC-Client              # requires LWP::Protocol::http which requires libssl
MooseX-Scaffold                        # broken
MooseX-Semantic                        # hash randomization
MooseX-Struct                          # ancient moose apis
MooseX-TrackDirty-Attributes           # broken
MooseX-Types-Parameterizable           # broken
MooseX-Types-Set-Object                # coerce without coercion
MooseX-Validation-Doctypes             # _process_isa_option
MooseX-WithCache                       # broken
MouseX-Types                           # broken (with moose)
MooseX-XSAccessor                      # coerce without coercion, etc
MySQL-Util                             # pod-coverage fail
Mvalve                                 # for qw()
Nagios-Passive                         # broken
Net-APNS                               # broken (with moose)
Net-FluidDB                            # broken
Net-Fluidinfo                          # broken
Net-FreshBooks-API                     # broken
Net-Google-Blogger                     # broken
Net-Google-FederatedLogin              # broken
Net-Google-PicasaWeb                   # broken
NetHack-Item                           # NH::Monster::Spoiler is broken
NetHack-Monster-Spoiler                # broken (MX::CA issues)
Net-HTTP-API                           # hash randomization
Net-HTTP-Factual                       # broken
Net-ISC-DHCPd                          # hash randomization
Net-Jabber-Bot                         # broken
Net-Journyx                            # broken
Net-Magrathea                          # pod fail
Net-Mollom                             # broken
Net-Parliament                         # broken
Net-Plurk                              # broken
Net-Rexster-Client                     # pod fail
Net-SSLeay-OO                          # broken
Net-StackExchange                      # broken
Norma                                  # fails when trying to write to a read-only SQLite db file under jenkins, also fails when run manually
NSMS-API                               # pod fail
ODG-Record                             # Test::Benchmark broken
OpenXML-Properties                     # incorrect deps
Orochi                                 # for qw()
Parallel-QueueWorker                   # flaky test (forking issues)
Parse-CPAN-Perms                       # flaky tests (hash randomization?)
PDF-TableX                             # for qw()
Perlbal-Control                        # proc::processtable doesn't load
Pg-BulkCopy                            # hardcodes /usr/bin/perl
Pinto-Common                           # broken
Pinto-Remove                           # deps on Pinto::Common
Pinto-Server                           # deps on Pinto::Common
Plack-Middleware-Image-Scale           # Image::Scale is broken
Pod-Parser-I18N                        # missing dep on Data::Localize
POE-Component-CPAN-Mirror-Multiplexer  # broken
POE-Component-DirWatch                 # intermittent failures
POE-Component-DirWatch-Object          # intermittent failures
POE-Component-ResourcePool             # broken
POE-Component-Server-PSGI              # broken deps
POE-Component-Server-SimpleHTTP-PreFork  # broken deps
Poet                                   # missing dep on Log::Any::Adapter::Log4perl
POEx-ProxySession                      # broken deps
POEx-PubSub                            # broken deps
POEx-WorkerPool                        # broken deps
PostScript-ScheduleGrid-XMLTV          # XMLTV doesn't exist
PRANG                                  # broken
Prophet                                # depends on term::readline::perl
Queue-Leaky                            # broken
Queue-Q4M                              # for qw()
RackMan                                # kwalitee fail
Railsish                               # dep on nonexistent dist
RDF-Helper                             # for qw()
RDF-Server                             # "no Moose" unimports confess
Reaction                               # signatures is broken
Reflexive-Role-DataMover               # broken (reflex::role changes?)
Reflexive-Role-TCPServer               # broken (reflex::role changes?)
Reflexive-Stream-Filtering             # broken
RPC-Any                                # broken
RPM-Spec                               # coerce with no coercion
RT-ClientX-GrabBugs                    # scalar::does doesn't specify deps properly
RTDevSys                               # pod fail
Scene-Graph                            # has '+attr' in roles
Scrappy                                # hash randomization
Server-Control                         # proc::processtable doesn't load
Shipment                               # locale::subcountry is broken
Silki                                  # image::magick is broken
SilkiX-Converter-Kwiki                 # file::mimeinfo expects (?-xism:
SIOC                                   # for qw()
Sloth                                  # rest::utils is broken
Sque                                   # couldn't fork server for testing
SRS-EPP-Proxy                          # depends on xml::epp
String-Blender                         # broken
Sys-RotateBackup                       # broken
System-Wrapper                         # pod coverage fail
TAEB                                   # broken
TAP-Formatter-Bamboo                   # hash randomization
TAP-Formatter-JUnit                    # hash randomization
Tail-Tool                              # Getopt::Alt doesn't exist
Tapper-Action                          # broken
Tapper-CLI                             # sys::info::driver::linux is broken
Tapper-Installer                       # sys::info::driver::linux is broken
Tapper-MCP-MessageReceiver             # sys::info::driver::linux is broken
Tapper-Reports-API                     # sys::info::driver::linux is broken
Tapper-Reports-Receiver                # flaky tests (timeouts)
Tapper-Testplan                        # sys::info::driver::linux is broken
Telephone-Mnemonic-US                  # rpm-build-perl is broken
Template-Plugin-Heritable              # weird dep issues (not test::dm related)
Test-A8N                               # broken
Test-Daily                             # configure errors
Test-HTML-Spelling                     # broken
Test-Moose-More                        # coerce without coercion
Test-Pockito                           # broken
Test-WWW-Selenium-More                 # Test::WWW::Selenium needs devel::repl
Text-Clevery                           # broken
Text-TEI-Collate                       # pod fail
Text-Zilla                             # broken
Thorium                                # depends on Hobocamp
TPath                                  # regexp::grammars is broken on 5.18
TPath-Forester-File                    # regexp::grammars is broken on 5.18
TPath-Forester-Ref                     # regexp::grammars is broken on 5.18
TryCatch-Error                         # broken
UnRTF                                  # broken
VCI                                    # for qw()
Verby                                  # deps on poe::component::resourcepool
W3C-SOAP                               # broken
W3C-SOAP-WADL                          # broken
Weather-TW                             # missing dep on Mojo::DOM
Web-API-Mapper                         # broken
WebNano-Controller-CRUD                # broken
WebService-E4SE                        # pod coverage fail
WebService-Embedly                     # broken
Webservice-InterMine                   # hash randomization
WebService-LOC-CongRec                 # broken
WebService-Mirth                       # broken
WebService-Uptrack                     # perlcritic fail
WebService-Yes24                       # broken
WiX3                                   # broken
WSDL-Compile                           # flaky tests (hash randomization?)
WWW-3Taps-API                          # pod fail
WWW-Alltop                             # XML::SimpleObject configure fail
WWW-Comix                              # uses ancient Moose::Policy stuff
WWW-DataWiki                           # broken
WWW-EFA                                # pod fail
WWW-Fandango                           # bad dist
WWW-FMyLife                            # broken
WWW-Google-Moderator                   # hash randomization
WWW-Google-Places                      # hash randomization
WWW-Mechanize-Cached                   # tries to read from wrong build dir?
WWW-Mechanize-Query                    # wrong deps (Mojo::DOM vs Mojo::Dom)
WWW-Metalgate                          # Cache is broken
WWW-Scramble                           # pod::coverage fail
WWW-SearchWikipedia                    # hash randomization
WWW-Sitemapper                         # broken
WWW-StaticBlog                         # time::sofar is broken
WWW-WebKit                             # missing configure_req on EU::PkgConfig
WWW-Wookie                             # kwalitee fail
WWW-Yahoo-Lyrics-JP                    # broken
XIRCD                                  # undeclared deps
XML-Compare                            # pod fail
XML-EPP                                # coerce without coercion
XML-SRS                                # deps on prang
XML-Writer-Compiler                    # broken tests
YellowBot-API                          # pod fail
YUI-Loader                             # hash randomization
Yukki                                  # git::repository is broken
