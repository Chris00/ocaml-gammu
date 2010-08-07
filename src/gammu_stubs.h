/* File: gammu_stubs.h

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     Noémie Meunier <Noemie.Meunier@student.umons.ac.be>
     Pierre Hauweele <Pierre.Hauweele@student.umons.ac.be>

     WWW: http://math.umons.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License version 3 or
   later as published by the Free Software Foundation.  See the file
   LICENCE for more details.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. */

#ifndef __GAMMU_STUBS_H__
#define __GAMMU_STUBS_H__


#include <caml/mlvalues.h>

#include <gammu.h>

#define BUFFER_LENGTH 255

/* Check Gammu version. TODO: Check versions more precisely. */
#if VERSION_NUM >= 12792
  /* OK*/
#elif VERSION_NUM <= 12400
  /* OK */
#else
# warning "Your version of libGammu was totally not tested\n"   \
    "If compilation fails, please report your version number\n" \
    "and if possible attach the error log."
#endif

/* Assume that gammu-types.h deals with glib correctly.
// typedef int gboolean;
But in some versions, it doesn't : */
#if VERSION_NUM < 12792
typedef int gboolean;
#endif
#ifndef FALSE
# define FALSE (0)
#endif
#ifndef TRUE
# define TRUE (!FALSE)
#endif


/************************************************************************/
/* Init */
GSM_Debug_Info *global_debug;

void gammu_caml_init();


/************************************************************************/
/* Utils functions and macros. */

/* Copy string represented by the value v to dst, and trim if too long. */
#define CPY_TRIM_STRING_VAL(dst, v)                        \
  do {                                                     \
    strncpy((char *) dst, String_val(v), sizeof(dst));     \
    dst[sizeof(dst)] = '\0';                               \
  } while (0)

/* signed or unsigned type char definition is not constant across versions.
   TODO: use version checking instead of that bruteforce way. */
#define CAML_COPY_SUSTRING(str) caml_copy_string((char *) str)

#define CHAR_VAL(v) ((char) Int_val(v))
#define VAL_CHAR(c) (Val_int(c))
#define UCHAR_VAL(v) ((unsigned char) Int_val(v))
#define VAL_UCHAR(c) (Val_int(c))

#if VERSION_NUM < 12792
static gboolean is_true(const char *str)
static char *yesno_bool(gboolean b)
#endif


/************************************************************************/
/* Error handling */

/* Error codes added by our bindings implementation. */
typedef enum {
  ERR_INI_KEY_NOT_FOUND = 71,
  ERR_COULD_NOT_DECODE,
  ERR_INVALID_CONFIG_NUM
} CAML_GAMMU_Error;

#define GSM_ERROR_VAL(v) (Int_val(v) + 1)
#define VAL_GSM_ERROR(v) Val_int(v - 1)

static void caml_gammu_raise_Error(int err);

CAMLexport
value caml_gammu_GSM_ErrorString(value verr);


/************************************************************************/
/* Debugging handling */

/* A Debug.info is either the global_debug pointer or the associated state
   machine. */
static GSM_Debug_Info *GSM_Debug_Info_val(value vdi);
/* di can be global_debug or a state machine value. */
#define VAL_GSM_DEBUG_INFO(di) ((value) di)

CAMLexport
value caml_gammu_GSM_GetGlobalDebug(value vunit);

CAMLexport
void caml_gammu_GSM_SetDebugGlobal(value vinfo, value vdi);

static FILE *FILE_val(value vchannel, const char *mode);

CAMLexport
void caml_gammu_GSM_SetDebugFileDescriptor(value vchannel, value vdi);

CAMLexport
void caml_gammu_GSM_SetDebugLevel(value vlevel, value vdi);


/************************************************************************/
/* INI files */

#define INI_SECTION_VAL(v) (*(INI_Section **) (Data_custom_val(v)))

static void caml_gammu_ini_section_finalize(value vini_section);

static struct custom_operations caml_gammu_ini_section_ops = {
  "ml-gammu.Gammu.ini_section",
  caml_gammu_ini_section_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static value alloc_INI_Section();

static value Val_INI_Section(INI_Section *ini_section);

CAMLexport
value caml_gammu_INI_ReadFile(value vfilename, value vunicode);

CAMLexport
value caml_gammu_INI_GetValue(value vfile_info, value vsection, value vkey,
                              value vunicode);


/************************************************************************/
/* State machine */

/* Define a struct to put, caml side, state machine related stuff in C heap in
   order to deal with GC. */
typedef struct {
  GSM_StateMachine *sm;
  value log_function;
  value incoming_sms_callback;
} State_Machine;

#define STATE_MACHINE_VAL(v) (*((State_Machine **) Data_custom_val(v)))
#define GSM_STATEMACHINE_VAL(v) (STATE_MACHINE_VAL(v)->sm)

static void caml_gammu_state_machine_finalize(value s);

static struct custom_operations caml_gammu_state_machine_ops = {
  "ml-gammu.Gammu.state_machine",
  caml_gammu_state_machine_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

/* TODO: Is it acceptable for a global root to be a pointer to NULL ? If so,
   we would only need to register state_machine->val as global root once at
   state machine allocation. */
#define REGISTER_SM_GLOBAL_ROOT(state_machine, field, v)        \
  do {                                                          \
    state_machine->field = v;                                   \
    if (!state_machine->field)                                  \
      caml_register_global_root(&state_machine->field);         \
  } while (0)

/* TODO: If it is acceptable for a global root to be a pointer to NULL, remove
   the caml_remove_global_root statement. */
#define UNREGISTER_SM_GLOBAL_ROOT(state_machine, field) \
  do {                                                  \
    if (state_machine->field) {                         \
      caml_remove_global_root(&state_machine->field);   \
      state_machine->field = 0;                         \
    }                                                   \
  } while(0)

static value Val_GSM_Config(const GSM_Config *config);

static void GSM_Config_val(GSM_Config *config, value vconfig);

#define VAL_GSM_CONNECTIONTYPE(ct) Val_int(ct - 1)

CAMLexport
value caml_gammu_GSM_GetDebug(value s);

CAMLexport
void caml_gammu_GSM_InitLocales(value vpath);

CAMLexport
void caml_gammu_GSM_InitDefaultLocales();

CAMLexport
value caml_gammu_GSM_AllocStateMachine(value vunit);

CAMLexport
value caml_gammu_GSM_FindGammuRC_force(value vpath);

CAMLexport
value caml_gammu_GSM_FindGammuRC(value vunit);

CAMLexport
value caml_gammu_GSM_ReadConfig(value vcfg_info, value vnum);

CAMLexport
value caml_gammu_GSM_GetConfig(value s, value vnum);

CAMLexport
void caml_gammu_push_config(value s, value vcfg);

CAMLexport
void caml_gammu_remove_config(value s);

CAMLexport
value caml_gammu_GSM_GetConfigNum(value s);

CAMLexport
void caml_gammu_GSM_InitConnection(value s, value vreply_num);

static void log_function_callback(const char *text, void *data);

CAMLexport
void caml_gammu_GSM_InitConnection_Log(value s, value vreply_num,
                                       value vlog_func);

CAMLexport
void caml_gammu_GSM_TerminateConnection(value s);

CAMLexport
value caml_gammu_GSM_IsConnected(value s);

CAMLexport
value caml_gammu_GSM_GetUsedConnection(value s);

CAMLexport
value caml_gammu_GSM_ReadDevice(value s, value vwait_for_reply);


/************************************************************************/
/* Security related operations with phone */

#define GSM_SECURITYCODETYPE_VAL(v) (Int_val(v) + 1)
#define VAL_GSM_SECURITYCODETYPE(sct) Val_int(sct - 1)

CAMLexport
void caml_gammu_GSM_EnterSecurityCode(value s, value vcode_type, value vcode);

CAMLexport
value caml_gammu_GSM_GetSecurityStatus(value s);


/************************************************************************/
/* Informations on the phone */

#define CHARGESTATE_VAL(v) (Int_val(v) + 1)
#define VAL_GSM_CHARGESTATE(cs) Val_int(cs - 1)
#define GSM_BATTERYTYPE_VAL(v) (Int_val(v) + 1)
#define VAL_GSM_BATTERYTYPE(bt) Val_int(bt - 1)
#define GSM_GPRS_STATE_VAL(v) (Int_val(v) + 1)
#define VAL_GSM_GPRS_STATE(gprss) Val_int(gprss - 1)
#define GSM_NETWORKINFO_STATE_VAL(v) (Int_val(v) + 1)
#define VAL_GSM_NETWORKINFO_STATE(nis) Val_int(nis - 1)

static value Val_GSM_BatteryCharge(GSM_BatteryCharge *battery_charge);

static value Val_GSM_PhoneModel(GSM_PhoneModel *phone_model);

static value Val_GSM_NetworkInfo(GSM_NetworkInfo *network);

static value Val_GSM_SignalQuality(GSM_SignalQuality *signal_quality);

#define GSM_STR_GET_PROTOTYPE(name, buf_length)                         \
  CAMLexport                                                            \
  value caml_gammu_GSM_Get##name(value s)
#define GSM_STR_GET(name, buf_length)                                   \
  GSM_STR_GET_PROTOTYPE(name, buf_length)                               \
  {                                                                     \
    CAMLparam1(s);                                                      \
    GSM_Error error;                                                    \
    char val[buf_length];                                               \
    error = GSM_Get##name(GSM_STATEMACHINE_VAL(s), val);                \
    caml_gammu_raise_Error(error);                                      \
    CAMLreturn(CAML_COPY_SUSTRING(val));                                \
  }

#define GSM_TYPE_GET_PROTOTYPE(name)                                    \
  CAMLexport                                                            \
  value caml_gammu_GSM_Get##name(value s)
#define GSM_TYPE_GET(name)                                              \
  GSM_TYPE_GET_PROTOTYPE(name)                                          \
  {                                                                     \
    CAMLparam1(s);                                                      \
    GSM_##name res;                                                     \
    GSM_Get##name(GSM_STATEMACHINE_VAL(s), &res);                       \
    CAMLreturn(Val_GSM_##name(&res));                                   \
  }

GSM_TYPE_GET_PROTOTYPE(BatteryCharge);

CAMLexport
value caml_gammu_GSM_GetFirmWare(value s);

GSM_STR_GET_PROTOTYPE(Hardware, BUFFER_LENGTH);

GSM_STR_GET_PROTOTYPE(IMEI, GSM_MAX_IMEI_LENGTH + 1);

GSM_STR_GET_PROTOTYPE(ManufactureMonth, BUFFER_LENGTH);

GSM_STR_GET_PROTOTYPE(Manufacturer, GSM_MAX_MANUFACTURER_LENGTH + 1);

GSM_STR_GET_PROTOTYPE(Model, GSM_MAX_MODEL_LENGTH + 1);

CAMLexport
value caml_gammu_GSM_GetModelInfo(value s);

GSM_TYPE_GET_PROTOTYPE(NetworkInfo);

GSM_STR_GET_PROTOTYPE(ProductCode, BUFFER_LENGTH);

GSM_TYPE_GET_PROTOTYPE(SignalQuality);


/************************************************************************/
/* Date and time */

static GSM_DateTime *GSM_DateTime_val(GSM_DateTime *date_time, value vdate_time);

static value Val_GSM_DateTime(GSM_DateTime *date_time);

CAMLexport
value caml_gammu_GSM_CheckDate(value vdate);

CAMLexport
value caml_gammu_GSM_CheckTime(value vdate);

CAMLexport
value caml_gammu_GSM_OSDate(value vdt);

CAMLexport
value caml_gammu_GSM_OSDateTime(value vdt, value vtimezone);


/************************************************************************/
/* Memory */

#define GSM_MEMORYTYPE_VAL(v) (Int_val(v) + 1)
#define VAL_GSM_MEMORYTYPE(mt) Int_val(mt - 1)
#define VAL_GSM_ENTRYTYPE(et) Val_int(et - 1)

static value Val_GSM_SubMemoryEntry(GSM_SubMemoryEntry *sub_mem_entry);

static value Val_GSM_MemoryEntry(GSM_MemoryEntry *mem_entry);


/************************************************************************/
/* Messages */

#define GSM_SMS_STATE_VAL(v) (Int_val(v) + 1)
#define VAL_GSM_SMS_STATE(sms_state) Val_int(sms_state - 1)
#define GSM_UDH_VAL(v) (Int_val(v) + 1)
#define VAL_GSM_UDH(udh) Val_int(udh - 1)

static GSM_UDHHeader *GSM_UDHHeader_val(GSM_UDHHeader *udh_header,
                                        value vudh_header);

static value VAL_GSM_UDHHeader(GSM_UDHHeader *udh_header);

#define GSM_SMSMESSAGETYPE_VAL(v) (Int_val(v) + 1)
#define VAL_GSM_SMSMESSAGETYPE(mt) Val_int(mt - 1)
#define GSM_CODING_TYPE_VAL(v) (Int_val(v) + 1)
#define VAL_GSM_CODING_TYPE(ct) Val_int(ct - 1)

static GSM_SMSMessage *GSM_SMSMessage_val(GSM_SMSMessage *sms, value vsms);

static value Val_GSM_SMSMessage(GSM_SMSMessage *sms);

static GSM_MultiSMSMessage *GSM_MultiSMSMessage_val(
  value vmulti_sms, GSM_MultiSMSMessage *multi_sms);

static value Val_GSM_MultiSMSMessage(GSM_MultiSMSMessage *multi_sms);

CAMLexport
value caml_gammu_GSM_GetSMS(value s, value vlocation, value vfolder);

CAMLexport
value caml_gammu_GSM_GetNextSMS(value s, value vlocation, value vfolder,
                                value vstart);

static value Val_GSM_SMSMemoryStatus(GSM_SMSMemoryStatus *sms_mem);

CAMLexport
value caml_gammu_GSM_GetSMSStatus(value s);

CAMLexport
void caml_gammu_GSM_DeleteSMS(value s, value vlocation, value vfolder);

#define VAL_GSM_ENCODEMULTIPARTSMSID(v) Val_int(v - 1)

static value Val_GSM_MultiPartSMSEntry(GSM_MultiPartSMSEntry mult_part_sms);

static value Val_GSM_MultiPartSMSInfo(
  GSM_MultiPartSMSInfo *multipart_sms_info);

CAMLexport
value caml_gammu_GSM_DecodeMultiPartSMS(value vdi, value vsms,
                                        value vems);


/************************************************************************/
/* Events */

static void incoming_sms_callback(GSM_StateMachine *sm, GSM_SMSMessage sms,
                                  void *user_data);

CAMLexport
void caml_gammu_GSM_SetIncomingSMS(value s, value vf);

CAMLexport
void caml_gammu_disable_incoming_sms(value s);

#endif /* __GAMMU_STUBS_H__ */
