#ifndef PERL_MOOSE_H
#define PERL_MOOSE_H

#include "mop.h"

#ifndef __attribute__format__
#define __attribute__format__(name, ifmt, iargs)
#endif

/* Moose.xs */
void
moose_throw_error(SV* const metaobject, SV* const data, const char* const fmt, ...)
    __attribute__format__(__printf__, 3, 4);

/* Accessor.xs */
XS(moose_xs_accessor);
XS(moose_xs_reader);
XS(moose_xs_writer);

CV* moose_instantiate_xs_accessor(pTHX_ SV* const accessor, XSUBADDR_t const accessor_impl, mop_instance_vtbl* const instance_vtbl);

/* optimized_tc.c */

typedef enum moose_tc{
     MOOSE_TC_ANY,
     MOOSE_TC_ITEM,
     MOOSE_TC_UNDEF,
     MOOSE_TC_DEFINED,
     MOOSE_TC_BOOL,
     MOOSE_TC_VALUE,
     MOOSE_TC_REF,
     MOOSE_TC_STR,
     MOOSE_TC_NUM,
     MOOSE_TC_INT,
     MOOSE_TC_SCALAR_REF,
     MOOSE_TC_ARRAY_REF,
     MOOSE_TC_HASH_REF,
     MOOSE_TC_CODE_REF,
     MOOSE_TC_GLOB_REF,
     MOOSE_TC_FILEHANDLE,
     MOOSE_TC_REGEXP_REF,
     MOOSE_TC_OBJECT,
     MOOSE_TC_CLASS_NAME,
     MOOSE_TC_ROLE_NAME,

     MOOSE_TC_last
} moose_tc;

int moose_tc_check(pTHX_ moose_tc const tc, SV* sv);

int moose_tc_Any       (pTHX_ SV* const sv);
int moose_tc_Bool      (pTHX_ SV* const sv);
int moose_tc_Undef     (pTHX_ SV* const sv);
int moose_tc_Defined   (pTHX_ SV* const sv);
int moose_tc_Value     (pTHX_ SV* const sv);
int moose_tc_Num       (pTHX_ SV* const sv);
int moose_tc_Int       (pTHX_ SV* const sv);
int moose_tc_Str       (pTHX_ SV* const sv);
int moose_tc_ClassName (pTHX_ SV* const sv);
int moose_tc_RoleName  (pTHX_ SV* const sv);
int moose_tc_Ref       (pTHX_ SV* const sv);
int moose_tc_ScalarRef (pTHX_ SV* const sv);
int moose_tc_ArrayRef  (pTHX_ SV* const sv);
int moose_tc_HashRef   (pTHX_ SV* const sv);
int moose_tc_CodeRef   (pTHX_ SV* const sv);
int moose_tc_RegexpRef (pTHX_ SV* const sv);
int moose_tc_GlobRef   (pTHX_ SV* const sv);
int moose_tc_FileHandle(pTHX_ SV* const sv);
int moose_tc_Object    (pTHX_ SV* const sv);

#endif /* !PERL_MOOSE_H */
