
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

static bool ck_sv_defined(SV*);
static bool ck_sv_is_ref(SV*);
static bool ck_sv_ref_type(SV*, int);

static bool
ck_sv_defined(SV* value){
  return SvOK(value) ? 1 : 0; 
}

static bool
ck_sv_is_ref(SV* value){
  bool retval = 0;
  if( ck_sv_defined(value) && SvROK(value) ){
    retval = 1;  
  }
  return retval;
}

static bool
ck_sv_ref_type(SV* value, int sv_type){
  bool retval = 0;
  if( ck_sv_is_ref(value) && SvTYPE( SvRV(value) ) == sv_type){
    retval = 1;
  }
  return retval;
}

static const char *regclass = "Regexp";

MODULE = Moose	PACKAGE = Moose::Util::TypeConstraints::OptimizedConstraints
PROTOTYPES: ENABLE

bool
Undef(value)
  SV* value
  CODE:
    RETVAL = !ck_sv_defined(value);
  OUTPUT:
    RETVAL

bool
Defined(value)
  SV* value
  CODE:
    RETVAL = ck_sv_defined(value);
  OUTPUT:
    RETVAL

bool
Value(value)
  SV* value
  CODE:
    RETVAL = (ck_sv_defined(value) && !ck_sv_is_ref(value)) ? 1 : 0;
  OUTPUT:
    RETVAL

bool
Str(value)
  SV* value
  CODE:
    RETVAL = (ck_sv_defined(value) && !ck_sv_is_ref(value)) ? 1 : 0;
  OUTPUT:
    RETVAL

bool
Ref(value)
  SV* value
  CODE:
    RETVAL = ck_sv_is_ref(value);
  OUTPUT:
    RETVAL

bool
ScalarRef(value)
  SV* value
  CODE:
    RETVAL = 0;
    if(
      SvOK(value) && SvROK(value)
    ){
      int type = SvTYPE(SvRV(value));
      if( 
        type == SVt_IV || 
        type == SVt_NV || 
        type == SVt_PV ||
        type == SVt_NULL
      ){
        RETVAL = 1;
      }
    }
  OUTPUT:
    RETVAL

bool
ArrayRef(value)
  SV* value
  CODE:
    RETVAL = ck_sv_ref_type(value, SVt_PVAV);
  OUTPUT:
    RETVAL

bool
HashRef(value)
  SV* value
  CODE:
    RETVAL = (ck_sv_ref_type(value, SVt_PVHV) && !sv_isobject(value)) ? 1 : 0;
  OUTPUT:
    RETVAL

bool
CodeRef(value)
  SV* value
  CODE:
    RETVAL = ck_sv_ref_type(value, SVt_PVCV);
  OUTPUT:
    RETVAL

bool
GlobRef(value)
  SV* value
  CODE:
    RETVAL = ck_sv_ref_type(value, SVt_PVGV);
  OUTPUT:
    RETVAL

bool
Object(value)
  SV* value
  CODE:
    RETVAL = 0;
    if( ck_sv_is_ref(value) 
        && sv_isobject(value)
        && !sv_isa(value, regclass)
      ){
      RETVAL = 1;  
    }
  OUTPUT:
    RETVAL

bool
ObjectOfType(value, class)
  SV* value
  SV* class
  PREINIT:
    const char* classname;
  CODE:
    RETVAL = 0;

    classname = SvPV_nolen(class);
    if(!classname){
      RETVAL = 0;  
    }

    if( ck_sv_is_ref(value) 
        && sv_isobject(value)
        && sv_derived_from(value, classname)
      ){
      RETVAL = 1;  
    }
  OUTPUT:
    RETVAL

bool
RegexpRef(value)
  SV* value
  CODE:
    RETVAL = 0;
    if( ck_sv_is_ref(value)
        && sv_isobject(value)
        && sv_isa(value, regclass)
      ){
      RETVAL = 1;  
    }
  OUTPUT:
    RETVAL


