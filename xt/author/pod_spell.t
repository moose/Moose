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
local $ENV{LC_ALL} = 'C';
set_spell_cmd('aspell list -l en');
all_pod_files_spelling_ok;

__DATA__
## personal names
Aankhen
Aran
autarch
Buels
chansen
chromatic's
Debolaz
Deltac
dexter
doy
ewilhelm
frodwith
Goulah
gphat
groditi
Hardison
jrockway
Kinyon's
Kogman
kolibrie
konobi
Lanyon
lbr
Luehrs
McWhirter
merlyn
mst
nothingmuch
Pearcey
perigrin
phaylon
Prather
Ragwitz
Reis
rafl
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
tozt
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
AttributeHelpers
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
metaroles
metatraits
mixins
MooseX
Num
oose
OtherName
PosInt
PositiveInt
ro
rw
RoleSummation
Str
TypeContraints

## computerese
API
APIs
arrayrefs
arity
Baz
Changelog
codebase
committer
committers
compat
datetimes
dec
definedness
destructor
destructors
destructuring
dev
DWIM
DUCKTYPE
env
GitHub
hashrefs
hotspots
immutabilize
immutabilizes
immutabilized
inline
inlines
invocant
invocant's
irc
IRC
isa
JSON
kv
login
mul
namespace
namespaced
namespaces
namespacing
# as in required-ness
ness
O'Caml
OO
OOP
ORM
overridable
parameterizable
parameterization
parameterize
parameterized
parameterizes
params
pluggable
prechecking
prepends
pu
rebase
rebased
rebasing
reblesses
refactored
refactoring
rethrows
ROLETYPE
runtime
serializer
stacktrace
stacktraces
subclassable
subname
subtyping
TODO
unblessed
unexport
UNIMPORTING
unimporting
Unported
unsets
unsettable
utils
whitelist
Whitelist
whitelisted
workflow

## other jargon
bey
gey

## neologisms
breakability
delegatee
featureful
hackery
hacktern
undeprecate
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
# co-maint
maint

## slang
C'mon
might've
Nuff

## things that should be in the dictionary, but are not
attribute's
declaratively
everybody's
everyone's
human's
indices
initializers
newfound
reimplements
reinitializes
specializer

## misspelt on purpose
emali
uniq

