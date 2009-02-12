use Test::Spelling;
my @stopwords;
for (<DATA>) {
    chomp;
    push @stopwords, $_
      unless /\A (?: \# | \s* \z)/msx;    # skip comments, whitespace
};
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
datetimes
definedness
destructor
destructors
DWIM
hashrefs
immutabilize
immutabilized
inline
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
OO
OOP
ORM
overridable
parameterizable
parameterize
parameterized
parameterizes
pluggable
prechecking
prepends
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
Whitelist

## other jargon
bey
gey

## neologisms
breakability
delegatee
hackery
ungloriously
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
