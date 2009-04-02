use strict;
use warnings;

use Test::Spelling;

my @stopwords;
for (<DATA>) {
    chomp;
    push @stopwords, $_
        unless /\A (?: \# | \s* \z)/msx;    # skip comments, whitespace
}

add_stopwords(@stopwords);
set_spell_cmd('aspell list -l en');
all_pod_files_spelling_ok;

__DATA__
## personal names
Aankhen
Aran
autarch
chansen
chromatic's
Debolaz
Deltac
dexter
ewilhelm
Goulah
gphat
groditi
jrockway
Kinyon's
Kogman
kolibrie
konobi
lbr
McWhirter
merlyn
mst
nothingmuch
Pearcey
perigrin
phaylon
Prather
Reis
rindolf
rlb
Rockway
Roditi
Rolsky
Roszatycki
Roszatycki's
sartak
Sedlacek
Shlomi
SL
stevan
Stevan
Vilain
wreis
Yuval

## proper names
AOP
CLOS
cpan
CPAN
OCaml
ohloh
SVN

## Moose
BankAccount
BankAccount's
BinaryTree
BUILDALL
BUILDARGS
CheckingAccount
clearers
composable
Debuggable
DEMOLISHALL
hardcode
immutabilization
immutabilize
introspectable
metaclass
Metaclass
METACLASS
metaclass's
metadata
MetaObject
metaprogrammer
metarole
mixins
MooseX
Num
oose
OtherName
PosInt
PositiveInt
ro
rw
Str
TypeContraints

## computerese
API
APIs
Baz
Changelog
compat
datetimes
definedness
destructor
destructors
dev
DWIM
hashrefs
immutabilize
immutabilized
inline
inlines
invocant
invocant's
irc
IRC
isa
login
namespace
namespaced
namespaces
namespacing
# as in required-ness
ness
OO
OOP
ORM
overridable
parameterizable
parameterization
parameterize
parameterized
parameterizes
pluggable
prechecking
prepends
refactored
refactoring
runtime
stacktrace
subclassable
subtyping
TODO
unblessed
unexport
UNIMPORTING
Unported
unsets
unsettable
whitelist
Whitelist

## other jargon
bey
gey

## neologisms
breakability
delegatee
hackery
hacktern
wrappee

## compound
# half-assed
assed
# role-ish, Ruby-ish, medium-to-large-ish
ish
# kool-aid
kool
# pre-5.10
pre
# vice versa
versa
lookup

## slang
C'mon
might've
Nuff

## things that should be in the dictionary, but are not
attribute's
declaratively
everyone's
human's
initializers
newfound
reimplements
reinitializes
specializer

## misspelt on purpose
emali
