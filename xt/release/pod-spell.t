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
Buels
Debolaz
Deltac
Goro
Goulah
Hardison
Kinyon
Kinyon's
Kogman
Lanyon
Luehrs
McWhirter
Pearcey
Prather
Ragwitz
Reis
Rockway
Roditi
Rolsky
Roszatycki
Roszatycki's
SL
Sedlacek
Shlomi
Stevan
Vilain
Yuval
autarch
backported
backports
blblack
chansen
chromatic's
dexter
doy
ewilhelm
frodwith
gphat
groditi
jrockway
kolibrie
konobi
lbr
merlyn
mst
nothingmuch
perigrin
phaylon
rafl
rindolf
rlb
robkinyon
sartak
tozt
wreis

## proper names
AOP
CLOS
CPAN
OCaml
SVN
ohloh

## Moose
AttributeHelpers
BUILDALL
BUILDARGS
BankAccount
BankAccount's
BinaryTree
CLR
CheckingAccount
DEMOLISHALL
Debuggable
JVM
METACLASS
MOPs
MetaModel
MetaObject
Metalevel
MooseX
Num
OtherName
PosInt
PositiveInt
RoleSummation
Str
TypeContraints
clearers
composable
hardcode
immutabilization
immutabilize
introspectable
metaclass's
metadata
metaprogrammer
metarole
metaroles
metatraits
mixins
oose
ro
rw

## computerese
API
APIs
Baz
Changelog
DUCKTYPE
DWIM
GitHub
IRC
Immutabilization
Inlinable
JSON
O'Caml
OO
OOP
ORM
ROLETYPE
TODO
UNIMPORTING
Unported
Whitelist
arity
arrayrefs
clearers
codebase
committer
committers
compat
continutation
datetimes
dec
definedness
deinitialized
destructor
destructors
destructuring
dev
env
eval'ing
hashrefs
hotspots
immutabilize
immutabilized
immutabilizes
inline
inlines
invocant
invocant's
isa
kv
login
metadata
mixin
mixins
mul
munge
namespace
namespace's
namespaced
namespaces
namespacing
# as in required-ness
ness
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
rebless
reblesses
reblessing
refactored
refactoring
rethrows
runtime
serializer
sigil
sigils
stacktrace
stacktraces
subclassable
subname
subtyping
unblessed
unexport
uninitialize
unsets
unsettable
utils
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
unintrusive

## misspelt on purpose
emali
uniq
