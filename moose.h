#ifndef PERL_MOOSE_H
#define PERL_MOOSE_H

#include "mop.h"

#ifndef __attribute__format__
#define __attribute__format__(name, ifmt, iargs)
#endif

void
moose_throw_error(SV* const metaobject, SV* const data, const char* const fmt, ...)
    __attribute__format__(__printf__, 3, 4);


XS(moose_xs_accessor);
XS(moose_xs_reader);
XS(moose_xs_writer);

CV* moose_instantiate_xs_accessor(pTHX_ SV* const accessor, XSPROTO(accessor_impl), const mop_instance_vtbl* const instance_vtbl);



#ifdef DEBUGGING
#define MOOSE_mi_access(mi, a)  *moose_debug_mi_access(aTHX_ (mi) , (a))
SV** moose_debug_mi_access(pTHX_ AV* const mi, I32 const attr_ix);
#else
#define MOOSE_mi_access(mi, a)  AvARRAY((mi))[(a)]
#endif


#endif /* !PERL_MOOSE_H */
