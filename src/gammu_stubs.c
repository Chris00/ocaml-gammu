/* File: gammu_stubs.c

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

/* Todo: Handle unicode. */

#include <stdio.h>
#include <string.h>
#include <assert.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/custom.h>
#include <caml/intext.h>

#include <gammu.h>

#include "gammu_stubs.h"
#include "io.h"


/************************************************************************/
/* Utils functions and macros. */

#if VERSION_NUM < 12792
static gboolean is_true(const char *str)
{
  if (strcasecmp(str, "true") == 0) return TRUE;
  if (strcasecmp(str, "yes") == 0) return TRUE;
  if (strcasecmp(str, "1") == 0) return TRUE;
  return FALSE;
}

static char *yesno_bool(gboolean b)
{
  if (b) return "yes";
  return "no";
}
#endif

/************************************************************************/
/* Error handling */

/* raise [Error] if the error code doesn't indicates no error. */
static void caml_gammu_raise_Error(int err)
{
  static value *exn = NULL;

  if (err != ERR_NONE) {
    if (exn == NULL) {
      /* First time around, look up by name */
      exn = caml_named_value("Gammu.GSM_Error");
    }
    caml_raise_with_arg(*exn, VAL_GSM_ERROR(err));
  }
}

CAMLexport
value caml_gammu_GSM_ErrorString(value verr)
{
  CAMLparam1(verr);
  const char *msg = GSM_ErrorString(GSM_ERROR_VAL(verr));
  assert(msg != NULL);
  CAMLreturn(CAML_COPY_SUSTRING(msg));
}


/************************************************************************/
/* Debuging handling */

static GSM_Debug_Info *safe_GSM_GetDebug(GSM_StateMachine *sm)
{
  GSM_Debug_Info *res;
  res = GSM_GetDebug(sm);
  if (res  == NULL)
    res = GSM_GetGlobalDebug();
  return res;
}

CAMLexport
value caml_gammu_GSM_GetGlobalDebug(value vunit)
{
  CAMLparam1(vunit);
  CAMLreturn(VAL_GSM_DEBUG_INFO(GSM_GetGlobalDebug()));
}

CAMLexport
void caml_gammu_GSM_SetDebugGlobal(value vinfo, value vdi)
{
  CAMLparam2(vinfo, vdi);
  GSM_SetDebugGlobal(Bool_val(vinfo), GSM_DEBUG_INFO_VAL(vdi));
  CAMLreturn0;
}

/* TODO: It should work on Windows, but have to check. */
static FILE *FILE_val(value vchannel, const char *mode)
{
  int fd;
  FILE *res;
  struct channel *channel = Channel(vchannel);
  assert(channel != NULL);

  /* Duplicate channel's file descriptor so that the user can close the
     channel without affecting us and inversely. */
  fd = dup(channel->fd);
  if (fd == -1)
    /* TODO: raise exception */
    return NULL;
  res = fdopen(fd, mode);

  return res;
}

CAMLexport
void caml_gammu_GSM_SetDebugFileDescriptor(value vchannel, value vdi)
{
  CAMLparam2(vchannel, vdi);
  GSM_Error error;
  error = GSM_SetDebugFileDescriptor(FILE_val(vchannel, "a"),
                                     TRUE, // file descr is closable
                                     GSM_DEBUG_INFO_VAL(vdi));
  caml_gammu_raise_Error(error);
  CAMLreturn0;
}

CAMLexport
void caml_gammu_GSM_SetDebugLevel(value vlevel, value vdi)
{
  CAMLparam2(vlevel, vdi);
  if (!GSM_SetDebugLevel(String_val(vlevel), GSM_DEBUG_INFO_VAL(vdi)))
    caml_invalid_argument("Gammu.set_debug_level: "             \
                          "invalid debug level identifier.");
  CAMLreturn0;
}

/************************************************************************/
/* INI files */

static void caml_gammu_ini_section_finalize(value vini_section)
{
  INI_Free(INI_SECTION_VAL(vini_section));
}

static value alloc_INI_Section()
{
  /* TODO: Can alloc_custom fail ? */
  return alloc_custom(&caml_gammu_ini_section_ops, sizeof(INI_Section *),
                      1, 100);
}

static value Val_INI_Section(INI_Section *ini_section)
{
  CAMLparam0();
  CAMLlocal1(res);

  res = alloc_INI_Section();
  INI_SECTION_VAL(res) = ini_section;

  CAMLreturn(res);
}

CAMLexport
value caml_gammu_INI_ReadFile(value vfilename, value vunicode)
{
  CAMLparam2(vfilename, vunicode);
  INI_Section *cfg;

  caml_gammu_raise_Error(INI_ReadFile(String_val(vfilename),
                                      Bool_val(vunicode),
                                      &cfg));

  CAMLreturn(Val_INI_Section(cfg));
}

CAMLexport
value caml_gammu_INI_GetValue(value vfile_info, value vsection, value vkey,
                              value vunicode)
{
  CAMLparam4(vfile_info, vsection, vkey, vunicode);
  unsigned char* res;

  res = INI_GetValue(INI_SECTION_VAL(vfile_info),
                     (unsigned char *) String_val(vsection),
                     (unsigned char *) String_val(vkey),
                     Bool_val(vunicode));
  if (res == NULL)
    caml_gammu_raise_Error(ERR_INI_KEY_NOT_FOUND);

  CAMLreturn(CAML_COPY_SUSTRING(res));
}


/************************************************************************/
/* State machine */

static void caml_gammu_state_machine_finalize(value s)
{
  State_Machine *state_machine = STATE_MACHINE_VAL(s);

  GSM_FreeStateMachine(state_machine->sm);
  /* Allow GC to collect the callback closure value now. */
  if (state_machine->incoming_sms_callback)
    caml_remove_global_root(&state_machine->incoming_sms_callback);

  free(state_machine);
}

static value Val_GSM_Config(const GSM_Config *config)
{
  CAMLparam0();
  CAMLlocal1(res);

  res = caml_alloc(14, 0);
  Store_field(res, 0, CAML_COPY_SUSTRING(config->Model));
  Store_field(res, 1, CAML_COPY_SUSTRING(config->DebugLevel));
  Store_field(res, 2, CAML_COPY_SUSTRING(config->Device));
  Store_field(res, 3, CAML_COPY_SUSTRING(config->Connection));
  #if VERSION_NUM >= 12792
  Store_field(res, 4, Val_bool(config->SyncTime));
  Store_field(res, 5, Val_bool(config->LockDevice));
  Store_field(res, 7, Val_bool(config->StartInfo));
  #else
  /* for VERSION_NUM <= 12400, those are strings. */
  Store_field(res, 4, Val_bool(is_true(config->SyncTime)));
  Store_field(res, 5, Val_bool(is_true(config->LockDevice)));
  Store_field(res, 7, Val_bool(is_true(config->StartInfo)));
  #endif
  Store_field(res, 6, CAML_COPY_SUSTRING(config->DebugFile));
  Store_field(res, 8, Val_bool(config->UseGlobalDebugFile));
  Store_field(res, 9, CAML_COPY_SUSTRING(config->TextReminder));
  Store_field(res, 10, CAML_COPY_SUSTRING(config->TextMeeting));
  Store_field(res, 11, CAML_COPY_SUSTRING(config->TextCall));
  Store_field(res, 12, CAML_COPY_SUSTRING(config->TextBirthday));
  Store_field(res, 13, CAML_COPY_SUSTRING(config->TextMemo));
  /* (+) GSM_Features PhoneFeatures */

  CAMLreturn(res);
}

/* Set values of config according to those from vconfig. */
static void GSM_Config_val(GSM_Config *config, value vconfig)
{
  CPY_TRIM_STRING_VAL(config->Model, String_val(Field(vconfig, 0)));
  CPY_TRIM_STRING_VAL(config->DebugLevel, String_val(Field(vconfig, 1)));
  config->Device = String_val(Field(vconfig, 2));
  config->Connection = String_val(Field(vconfig, 3));
  #if VERSION_NUM >= 12792
  config->SyncTime = Bool_val(Field(vconfig, 4));
  config->LockDevice = Bool_val(Field(vconfig, 5));
  config->StartInfo = Bool_val(Field(vconfig, 7));
  #else
  /* for VERSION_NUM <= 12400, those are strings.
     we don't know about versions between 12400 and 12792 */
  config->SyncTime = yesno_bool(Bool_val(Field(vconfig, 4)));
  config->LockDevice = yesno_bool(Bool_val(Field(vconfig, 5)));
  config->StartInfo = yesno_bool(Bool_val(Field(vconfig, 7)));
  #endif
  config->DebugFile = String_val(Field(vconfig, 6));
  config->UseGlobalDebugFile = Bool_val(Field(vconfig, 8));
  CPY_TRIM_STRING_VAL(config->TextReminder, String_val(Field(vconfig, 9)));
  CPY_TRIM_STRING_VAL(config->TextMeeting, String_val(Field(vconfig, 10)));
  CPY_TRIM_STRING_VAL(config->TextCall, String_val(Field(vconfig, 11)));
  CPY_TRIM_STRING_VAL(config->TextBirthday, String_val(Field(vconfig, 12)));
  CPY_TRIM_STRING_VAL(config->TextMemo, String_val(Field(vconfig, 13)));
}

CAMLexport
value caml_gammu_GSM_GetDebug(value s)
{
  CAMLparam1(s);

  CAMLreturn(VAL_GSM_DEBUG_INFO(safe_GSM_GetDebug(GSM_STATEMACHINE_VAL(s))));
}

CAMLexport
void caml_gammu_GSM_InitLocales(value vpath)
{
  CAMLparam1(vpath);

  GSM_InitLocales(String_val(vpath));

  CAMLreturn0;
}

CAMLexport
void caml_gammu_GSM_InitDefaultLocales()
{
  CAMLparam0();

  GSM_InitLocales(NULL);

  CAMLreturn0;
}

CAMLexport
value caml_gammu_GSM_AllocStateMachine(value vunit)
{
  CAMLparam1(vunit);
  CAMLlocal2(res, vsm);
  State_Machine *state_machine = malloc(sizeof(State_Machine));
  GSM_StateMachine *sm = GSM_AllocStateMachine();

  if (sm == NULL || state_machine == NULL)
    caml_raise_out_of_memory();

  res = alloc_custom(&caml_gammu_state_machine_ops,
                     sizeof(State_Machine *), 1, 100);
  STATE_MACHINE_VAL(res) = state_machine;

  CAMLreturn(res);
}

CAMLexport
value caml_gammu_GSM_FindGammuRC_force(value vpath)
{
  CAMLparam1(vpath);
  INI_Section *res;

  caml_gammu_raise_Error(GSM_FindGammuRC(&res, String_val(vpath)));

  CAMLreturn(Val_INI_Section(res));
}

CAMLexport
value caml_gammu_GSM_FindGammuRC(value vunit)
{
  CAMLparam1(vunit);
  INI_Section *res;

  caml_gammu_raise_Error(GSM_FindGammuRC(&res, NULL));

  CAMLreturn(Val_INI_Section(res));
}

CAMLexport
value caml_gammu_GSM_ReadConfig(value vcfg_info, value vnum)
{
  CAMLparam2(vcfg_info, vnum);
  GSM_Config cfg;
  INI_Section *cfg_info = INI_SECTION_VAL(vcfg_info);

  caml_gammu_raise_Error(GSM_ReadConfig(cfg_info, &cfg, Int_val(vnum)));

  CAMLreturn(Val_GSM_Config(&cfg));
}

CAMLexport
value caml_gammu_GSM_GetConfig(value s, value vnum)
{
  CAMLparam2(s, vnum);
  GSM_Config *cfg = GSM_GetConfig(GSM_STATEMACHINE_VAL(s), Int_val(vnum));

  if (cfg == NULL)
    caml_gammu_raise_Error(ERR_INVALID_CONFIG_NUM);

  CAMLreturn(Val_GSM_Config(cfg));
}

/* set_config */

CAMLexport
void caml_gammu_push_config(value s, value vcfg)
{
  CAMLparam2(s, vcfg);
  GSM_StateMachine *sm = GSM_STATEMACHINE_VAL(s);
  int cfg_num = GSM_GetConfigNum(sm);
  GSM_Config *dest_cfg = GSM_GetConfig(sm, cfg_num);

  if (dest_cfg != NULL)
    GSM_Config_val(dest_cfg, vcfg);
  else
    /* To many configs (more than MAX_CONFIG_NUM+1 (=6),
       unfortunately this const is not exported) */
    caml_gammu_raise_Error(ERR_INVALID_CONFIG_NUM);

  CAMLreturn0;
}

CAMLexport
void caml_gammu_remove_config(value s)
{
  CAMLparam1(s);
  GSM_StateMachine *sm = GSM_STATEMACHINE_VAL(s);
  int cfg_num = GSM_GetConfigNum(sm);

  if (cfg_num > 0)
    GSM_SetConfigNum(sm, cfg_num - 1);
  else
    /* Empty stack, can't remove */
    caml_gammu_raise_Error(ERR_INVALID_CONFIG_NUM);

  CAMLreturn0;
}

CAMLexport
value caml_gammu_GSM_GetConfigNum(value s)
{
  CAMLparam1(s);
  CAMLreturn(Val_int( GSM_GetConfigNum(GSM_STATEMACHINE_VAL(s)) ));
}

CAMLexport
void caml_gammu_GSM_InitConnection(value s, value vreply_num)
{
  CAMLparam2(s, vreply_num);
  GSM_Error error;
  
  error = GSM_InitConnection(GSM_STATEMACHINE_VAL(s), Int_val(vreply_num));
  caml_gammu_raise_Error(error);

  CAMLreturn0;
}

static void log_function_callback(const char *text, void *data)
{
  CAMLparam0();
  CAMLlocal1(f);

  /* The caml function value was saved as user data for the callback. */
  f = *((value *) data);
  caml_callback(f, CAML_COPY_SUSTRING(text));

  CAMLreturn0;
}

CAMLexport
void caml_gammu_GSM_InitConnection_Log(value s, value vreply_num,
                                       value vlog_func)
{
  CAMLparam3(s, vreply_num, vlog_func);
  GSM_Error error;

  /* TODO:?? vlog_func should not be freed until TerminateConnection. But
     the GC could forget about her through the side effect and free it. */
  error = GSM_InitConnection_Log(GSM_STATEMACHINE_VAL(s),
                                 Int_val(vreply_num),
                                 log_function_callback, (void *) &vlog_func);
  caml_gammu_raise_Error(error);

  CAMLreturn0;
}

CAMLexport
void caml_gammu_GSM_TerminateConnection(value s)
{
  CAMLparam1(s);

  caml_gammu_raise_Error(GSM_TerminateConnection(GSM_STATEMACHINE_VAL(s)));

  CAMLreturn0;
}

CAMLexport
value caml_gammu_GSM_IsConnected(value s)
{
  CAMLparam1(s);

  CAMLreturn(Val_bool(GSM_IsConnected(GSM_STATEMACHINE_VAL(s))));
}

CAMLexport
value caml_gammu_GSM_GetUsedConnection(value s)
{
  CAMLparam1(s);
  GSM_StateMachine *sm = GSM_STATEMACHINE_VAL(s);
  GSM_ConnectionType conn_type = GSM_GetUsedConnection(sm);

  CAMLreturn(VAL_GSM_CONNECTIONTYPE(conn_type));
}

CAMLexport
value caml_gammu_GSM_ReadDevice(value s, value vwait_for_reply)
{
  CAMLparam2(s, vwait_for_reply);
  GSM_StateMachine *sm = GSM_STATEMACHINE_VAL(s);
  int read_bytes;

  /* Bug in GSM_ReadDevice, the function already checks for connection, but
     one can't make the difference between a GSM not connected or 33 bytes
     read.  TODO: Send a bug report. */
  if (!GSM_IsConnected(sm))
    caml_gammu_raise_Error(ERR_NOTCONNECTED);

  read_bytes = GSM_ReadDevice(sm, Bool_val(vwait_for_reply));

  CAMLreturn(Val_int(read_bytes));
}

/************************************************************************/
/* Security related operations with phone */

CAMLexport
void caml_gammu_GSM_EnterSecurityCode(value s, value vcode_type, value vcode)
{
  CAMLparam2(s, vcode);
  GSM_Error error;
  GSM_SecurityCode security_code;
  
  security_code.Type = GSM_SECURITYCODETYPE_VAL(vcode_type);
  CPY_TRIM_STRING_VAL(security_code.Code, vcode);

  error = GSM_EnterSecurityCode(GSM_STATEMACHINE_VAL(s),
                                security_code);
  caml_gammu_raise_Error(error);

  CAMLreturn0;
}

CAMLexport
value caml_gammu_GSM_GetSecurityStatus(value s)
{
  CAMLparam1(s);
  GSM_Error error;
  GSM_SecurityCodeType status;

  error = GSM_GetSecurityStatus(GSM_STATEMACHINE_VAL(s), &status);
  caml_gammu_raise_Error(error);

  CAMLreturn(VAL_GSM_SECURITYCODETYPE(&status));
}

/************************************************************************/
/* Informations on the phone */

/* Unused
static GSM_BatteryCharge *GSM_BatteryCharge_val(value vbattery_charge)
{
  GSM_BatteryCharge *battery_charge = malloc(sizeof(GSM_BatteryCharge));
  battery_charge->BatteryType = GSM_BATTERYTYPE_VAL(Field(vbattery_charge, 0));
  battery_charge->BatteryCapacity = Int_val(Field(vbattery_charge, 1));
  battery_charge->BatteryPercent = Int_val(Field(vbattery_charge, 2));
  battery_charge->ChargeState = GSM_CHARGESTATE_VAL(Field(vbattery_charge, 3));
  battery_charge->BatteryVoltage = Int_val(Field(vbattery_charge, 4));
  battery_charge->ChargeVoltage = Int_val(Field(vbattery_charge, 5));
  battery_charge->ChargeCurrent = Int_val(Field(vbattery_charge, 6));
  battery_charge->PhoneCurrent = Int_val(Field(vbattery_charge, 7));
  battery_charge->BatteryTemperature = Int_val(Field(vbattery_charge, 8));
  battery_charge->PhoneTemperature = Int_val(Field(vbattery_charge, 9));
  return battery_charge;
}
*/

static value Val_GSM_BatteryCharge(GSM_BatteryCharge *battery_charge)
{
  CAMLparam0();
  CAMLlocal1(res);

  res = caml_alloc(10, 0);
  Store_field(res, 0, VAL_GSM_BATTERYTYPE(battery_charge->BatteryType));
  Store_field(res, 1, Val_int(battery_charge->BatteryCapacity));
  Store_field(res, 2, Val_int(battery_charge->BatteryPercent));
  Store_field(res, 3, VAL_GSM_CHARGESTATE(battery_charge->ChargeState));
  Store_field(res, 4, Val_int(battery_charge->BatteryVoltage));
  Store_field(res, 5, Val_int(battery_charge->ChargeVoltage));
  Store_field(res, 6, Val_int(battery_charge->ChargeCurrent));
  Store_field(res, 7, Val_int(battery_charge->PhoneCurrent));
  Store_field(res, 8, Val_int(battery_charge->BatteryTemperature));
  Store_field(res, 9, Val_int(battery_charge->PhoneTemperature));

  CAMLreturn(res);
}

// Unused
//static GSM_PhoneModel *GSM_PhoneModel_val(value vphone_model)
// {
//  /* Check alloc */
//  GSM_PhoneModel *phone_model = malloc(sizeof(GSM_PhoneModel));
//  /* TODO: implement that.
//    phone_model->features = NULL; */
//  phone_model->model = String_val(Field(vphone_model, 0));
//  phone_model->number = String_val(Field(vphone_model, 1));
//  phone_model->irdamodel = String_val(Field(vphone_model, 2));
//  return phone_model;
//}

static value Val_GSM_PhoneModel(GSM_PhoneModel *phone_model)
{
  CAMLparam0();
  CAMLlocal1(res);

  res = caml_alloc(3, 0);
  Store_field(res, 0, CAML_COPY_SUSTRING(phone_model->model));
  Store_field(res, 1, CAML_COPY_SUSTRING(phone_model->number));
  Store_field(res, 2, CAML_COPY_SUSTRING(phone_model->irdamodel));

  CAMLreturn(res);
}

/* broken code, never used
static GSM_NetworkInfo *GSM_NetworkInfo_val(value vnetwork)
{
  GSM_NetworkInfo *network = malloc(sizeof(GSM_NetworkInfo));
  if (network == NULL)
    return NULL
  network->CID = String_val(Field(vnetwork, 0));
  network->NetworkCode = String_val(Field(vnetwork, 1));
  network->State = GSM_NETWORKINFO_STATE_VAL(Field(vnetwork, 2));
  network->LAC = String_val(Field(vnetwork, 3));
  network->NetworkName = String_val(Field(vnetwork, 4));
  network->GPRS = GSM_GPRS_STATE_VAL(Field(vnetwork, 5));
  network->PacketCID = String_val(Field(vnetwork, 6));
  network->PacketState = GSM_NETWORKINFO_STATE_VAL(Field(vnetwork, 7));
  network->PacketLAC = String_val(Field(vnetwork, 8));
  return network;
}*/

static value Val_GSM_NetworkInfo(GSM_NetworkInfo *network)
{
  CAMLparam0();
  CAMLlocal1(res);

  res = caml_alloc(9, 0);
  Store_field(res, 0, CAML_COPY_SUSTRING(network->CID));
  Store_field(res, 1, CAML_COPY_SUSTRING(network->NetworkCode));
  Store_field(res, 2, VAL_GSM_NETWORKINFO_STATE(network->State));
  Store_field(res, 3, CAML_COPY_SUSTRING(network->LAC));
  Store_field(res, 4, CAML_COPY_SUSTRING(network->NetworkName));
  /* Some fields weren't present yet in older versions, give them unknown
     values */
  #if VERSION_NUM >= 12792
  Store_field(res, 5, VAL_GSM_GPRS_STATE(network->GPRS));
  #else
  Store_field(res, 5, Val_int(2) /* grps_state = Unknown */);
  #endif
  #if VERSION_NUM >= 12796
  Store_field(res, 6, CAML_COPY_SUSTRING(network->PacketCID));
  Store_field(res, 7, VAL_GSM_NETWORKINFO_STATE(network->PacketState));
  Store_field(res, 8, CAML_COPY_SUSTRING(network->PacketLAC));
  #else
  Store_field(res, 6, CAML_COPY_SUSTRING("Unknown"));
  Store_field(res, 7, Val_int(4) /* network_state = Unknown */);
  Store_field(res, 8, CAML_COPY_SUSTRING("Unknown"));
  #endif

  CAMLreturn(res);
}

/* Unused
static GSM_SignalQuality *GSM_SignalQuality_val(value vsignal_quality)
{
  GSM_SignalQuality *signal_quality = malloc(sizeof(GSM_SignalQuality));
  signal_quality->SignalStrength = Int_val(Field(vsignal_quality, 0));
  signal_quality->SignalPercent = Int_val(Field(vsignal_quality, 1));
  signal_quality->BitGSM_ErrorRate = Int_val(Field(vsignal_quality, 2));
  return signal_quality;
}
*/

static value Val_GSM_SignalQuality(GSM_SignalQuality *signal_quality)
{
  CAMLparam0();
  CAMLlocal1(res);

  res = caml_alloc(3, 0);
  Store_field(res, 0, Val_int(signal_quality->SignalStrength));
  Store_field(res, 1, Val_int(signal_quality->SignalPercent));
  Store_field(res, 2, Val_int(signal_quality->BitErrorRate));

  CAMLreturn(res);
}

GSM_TYPE_GET(BatteryCharge)

CAMLexport
value caml_gammu_GSM_GetFirmWare(value s)
{
  CAMLparam1(s);
  CAMLlocal1(res);
  GSM_Error error;
  char val[GSM_MAX_VERSION_LENGTH + 1];
  char date[GSM_MAX_VERSION_DATE_LENGTH + 1];
  double num;

  error = GSM_GetFirmware(GSM_STATEMACHINE_VAL(s), val, date, &num);
  caml_gammu_raise_Error(error);

  res = caml_alloc(3, 0);
  Store_field(res, 0, CAML_COPY_SUSTRING(&val));
  Store_field(res, 1, CAML_COPY_SUSTRING(&date));
  Store_field(res, 2, caml_copy_double(num));

  CAMLreturn(res);
}

GSM_STR_GET(Hardware, BUFFER_LENGTH)

GSM_STR_GET(IMEI, GSM_MAX_IMEI_LENGTH + 1)

GSM_STR_GET(ManufactureMonth, BUFFER_LENGTH)

GSM_STR_GET(Manufacturer, GSM_MAX_MANUFACTURER_LENGTH + 1)

GSM_STR_GET(Model, GSM_MAX_MODEL_LENGTH + 1)

CAMLexport
value caml_gammu_GSM_GetModelInfo(value s)
{
  CAMLparam1(s);

  GSM_PhoneModel *phone_model = GSM_GetModelInfo(GSM_STATEMACHINE_VAL(s));

  CAMLreturn(Val_GSM_PhoneModel(phone_model));
}

GSM_TYPE_GET(NetworkInfo)

GSM_STR_GET(ProductCode, BUFFER_LENGTH)

GSM_TYPE_GET(SignalQuality)


/************************************************************************/
/* Date and time */

static GSM_DateTime *GSM_DateTime_val(GSM_DateTime *date_time, value vdate_time)
{
  date_time->Timezone = Int_val(Field(vdate_time, 0));
  date_time->Second = Int_val(Field(vdate_time, 1));
  date_time->Minute = Int_val(Field(vdate_time, 2));
  date_time->Hour = Int_val(Field(vdate_time, 3));
  date_time->Day = Int_val(Field(vdate_time, 4));
  date_time->Month = Int_val(Field(vdate_time, 5));
  date_time->Year = Int_val(Field(vdate_time, 6));

  return date_time;
}

static value Val_GSM_DateTime(GSM_DateTime *date_time)
{
  CAMLparam0();
  CAMLlocal1(res);

  res = caml_alloc(7, 0);
  Store_field(res, 0, Val_int(date_time->Timezone));
  Store_field(res, 1, Val_int(date_time->Second));
  Store_field(res, 2, Val_int(date_time->Minute));
  Store_field(res, 3, Val_int(date_time->Hour));
  Store_field(res, 4, Val_int(date_time->Day));
  Store_field(res, 5, Val_int(date_time->Month));
  Store_field(res, 6, Val_int(date_time->Year));

  CAMLreturn(res);
}

CAMLexport
value caml_gammu_GSM_CheckDate(value vdate)
{
  CAMLparam1(vdate);
  GSM_DateTime dt;
  gboolean date_ok;

  date_ok = CheckDate(GSM_DateTime_val(&dt, vdate));

  CAMLreturn(Val_bool(date_ok));
}

CAMLexport
value caml_gammu_GSM_CheckTime(value vdate)
{
  CAMLparam1(vdate);
  GSM_DateTime dt;

  GSM_DateTime_val(&dt, vdate);

  CAMLreturn(Val_bool(CheckTime(&dt)));
}

CAMLexport
value caml_gammu_GSM_OSDate(value vdt)
{
  CAMLparam1(vdt);
  GSM_DateTime dt;
  char *os_date;

  /* TODO: Ask why does OSDate takes value instead of pointer ? */
  GSM_DateTime_val(&dt, vdt);
  os_date = OSDate(dt);

  CAMLreturn(CAML_COPY_SUSTRING(os_date));
}

CAMLexport
value caml_gammu_GSM_OSDateTime(value vdt, value vtimezone)
{
  CAMLparam2(vdt, vtimezone);
  GSM_DateTime dt;
  char *os_date_time;

  GSM_DateTime_val(&dt, vdt);
  os_date_time = OSDateTime(dt, Bool_val(vtimezone));

  CAMLreturn(CAML_COPY_SUSTRING(os_date_time));
}

/************************************************************************/
/* Memory */

/* Unused
static GSM_SubMemoryEntry *GSM_SubMemoryEntry_val(value vsub_mem_entry)
{
  value vsms_list;
  GSM_SubMemoryEntry *res = malloc(sizeof(GSM_SubMemoryEntry));
  int i;
  res->EntryType = GSM_ENTRYTYPE_VAL(Field(vsub_mem_entry, 0));
  res->Date = *GSM_DateTime_val(Field(vsub_mem_entry, 1));
  res->Number = Int_val(Field(vsub_mem_entry, 2));
  res->VoiceTag = Int_val(Field(vsub_mem_entry, 3));
  vsms_list = Field(vsub_mem_entry, 4);
  if (Wosize_val(vsms_list) != 20)
    return NULL; // TODO: Raise error !
  for (i=0; i < 20; i++)
    res->SMSList[i] = Field(vsms_list, i);
  res->CallLength = Int_val(Field(vsub_mem_entry, 5));
  res->AddError = GSM_ERROR_VAL(Field(vsub_mem_entry, 6));
  CPY_TRIM_STRING_VAL(res->Text, Field(vsub_mem_entry, 7));
  return res;
}
*/

static value Val_GSM_SubMemoryEntry(GSM_SubMemoryEntry *sub_mem_entry)
{
  CAMLparam0();
  CAMLlocal2(res, vsms_list);
  int i;

  Store_field(res, 0, VAL_GSM_ENTRYTYPE(sub_mem_entry->EntryType));
  Store_field(res, 1, Val_GSM_DateTime(&sub_mem_entry->Date));
  Store_field(res, 2, Val_int(sub_mem_entry->Number));
  Store_field(res, 3, Val_int(sub_mem_entry->VoiceTag));
  vsms_list = caml_alloc(20, 0);
  for (i=0; i < 20; i++)
    Store_field(vsms_list, i, sub_mem_entry->SMSList[i]);
  Store_field(res, 4, vsms_list);
  Store_field(res, 5, Val_int(sub_mem_entry->CallLength));
  Store_field(res, 6, VAL_GSM_ERROR(sub_mem_entry->AddError));
  Store_field(res, 7, CAML_COPY_SUSTRING(sub_mem_entry->Text));

  CAMLreturn(res);
}

/* Unused
static GSM_MemoryEntry *GSM_MemoryEntry_val(value vmem_entry)
{
  value ventries;
  GSM_MemoryEntry *mem_entry = malloc(sizeof(GSM_MemoryEntry));
  int length;
  int i;
  ventries = Field(vmem_entry, 2);
  length = Wosize_val(ventries);
  mem_entry->MemoryType = GSM_MEMORYTYPE_VAL(Field(vmem_entry, 0));
  mem_entry->Location = Int_val(Field(vmem_entry, 1));
  // TODO: raise exception if too many entries.
  if (length > GSM_PHONEBOOK_ENTRIES)
    length = GSM_PHONEBOOK_ENTRIES;
  for (i=0; i < length; i++)
    mem_entry->Entries[i] = *GSM_SubMemoryEntry_val(Field(ventries, i));
  mem_entry->EntriesNum = length;
  return mem_entry;
}
*/

static value Val_GSM_MemoryEntry(GSM_MemoryEntry *mem_entry)
{
  CAMLparam0();
  CAMLlocal2(res, ventries);
  res = alloc(3, 0);
  int length = mem_entry->EntriesNum;
  int i;

  Store_field(res, 0, VAL_GSM_MEMORYTYPE(mem_entry->MemoryType));
  Store_field(res, 1, Val_int(mem_entry->Location));
  ventries = caml_alloc(length, 0);
  for (i=0; i < length; i++)
    Store_field(ventries, i, Val_GSM_SubMemoryEntry(&mem_entry->Entries[i]));
  Store_field(res, 2, ventries);

  CAMLreturn(res);
}

/************************************************************************/
/* Messages */

static GSM_UDHHeader *GSM_UDHHeader_val(GSM_UDHHeader *udh_header,
                                        value vudh_header)
{
  udh_header->Type = GSM_UDH_VAL(Field(vudh_header, 0));
  CPY_TRIM_STRING_VAL(udh_header->Text, Field(vudh_header, 1));
  udh_header->ID8bit = Int_val(Field(vudh_header, 2));
  udh_header->ID16bit = Int_val(Field(vudh_header, 3));
  udh_header->PartNumber = Int_val(Field(vudh_header, 4));
  udh_header->AllParts = Int_val(Field(vudh_header, 5));

  return udh_header;
}

static value VAL_GSM_UDHHeader(GSM_UDHHeader *udh_header)
{
  CAMLparam0();
  CAMLlocal1(res);

  res = caml_alloc(6, 0);
  Store_field(res, 0, VAL_GSM_UDH(udh_header->Type));
  Store_field(res, 1, CAML_COPY_SUSTRING(udh_header->Text));
  Store_field(res, 2, Val_int(udh_header->ID8bit));
  Store_field(res, 3, Val_int(udh_header->ID16bit));
  Store_field(res, 4, Val_int(udh_header->PartNumber));
  Store_field(res, 5, Val_int(udh_header->AllParts));

  CAMLreturn(res);
}

static GSM_SMSMessage *GSM_SMSMessage_val(GSM_SMSMessage *sms, value vsms)
{
  value vother_numbers = Field(vsms, 4);
  value vtext = Field(vsms, 12);
  int length = Wosize_val(vother_numbers);
  int i;

  sms->ReplaceMessage = UCHAR_VAL(Field(vsms, 0));
  sms->RejectDuplicates = Bool_val(Field(vsms, 1));
  GSM_UDHHeader_val(&sms->UDH, Field(vsms, 2));
  CPY_TRIM_STRING_VAL(sms->Number, Field(vsms, 3));
  if (length > sizeof(sms->OtherNumbers))
    length = sizeof(sms->OtherNumbers);
  for (i=0; i < length; i++)
    CPY_TRIM_STRING_VAL(sms->OtherNumbers[i], Field(vother_numbers, i));
  sms->OtherNumbersNum = length;
  /* sms->SMSC = GSM_SMSC_val(Field(vsms, 5)); NYI*/
  sms->Memory = GSM_MEMORYTYPE_VAL(Field(vsms, 6));
  sms->Location = Int_val(Field(vsms, 7));
  sms->Folder = Int_val(Field(vsms, 8));
  sms->InboxFolder = Bool_val(Field(vsms, 9));
  sms->Length = caml_string_length(vtext);
  sms->State = GSM_SMS_STATE_VAL(Field(vsms, 10));
  CPY_TRIM_STRING_VAL(sms->Name, String_val(Field(vsms, 11)));
  CPY_TRIM_STRING_VAL(sms->Text, String_val(vtext));
  sms->PDU = GSM_SMSMESSAGETYPE_VAL(Field(vsms, 13));
  sms->Coding = GSM_CODING_TYPE_VAL(Field(vsms, 14));
  GSM_DateTime_val(&sms->DateTime, Field(vsms, 15));
  GSM_DateTime_val(&sms->SMSCTime, Field(vsms, 16));
  sms->DeliveryStatus = UCHAR_VAL(Field(vsms, 17));
  sms->ReplyViaSameSMSC = Bool_val(Field(vsms, 18));
  sms->Class = CHAR_VAL(Field(vsms, 19));
  sms->MessageReference = UCHAR_VAL(Field(vsms, 20));

  return sms;
}

static value Val_GSM_SMSMessage(GSM_SMSMessage *sms)
{
  CAMLparam0();
  CAMLlocal2(res, vother_numbers);
  res = caml_alloc(21, 0);
  int length = sms->OtherNumbersNum;
  int i;

  Store_field(res, 0, VAL_UCHAR(sms->ReplaceMessage));
  Store_field(res, 1, Val_bool(sms->RejectDuplicates));
  Store_field(res, 2, VAL_GSM_UDHHeader(&sms->UDH));
  Store_field(res, 3, CAML_COPY_SUSTRING(sms->Number));
  vother_numbers = caml_alloc(length, 0);
  for (i=0; i < length; i++)
    Store_field(vother_numbers, i, CAML_COPY_SUSTRING(sms->OtherNumbers[i]));
  Store_field(res, 4, vother_numbers);
  /* Store_field(res, 5, Val_GSM_SMSC(sms->SMSC)); NYI */
  Store_field(res, 6, VAL_GSM_MEMORYTYPE(sms->Memory));
  Store_field(res, 7, Val_int(sms->Location));
  Store_field(res, 8, Val_int(sms->Folder));
  Store_field(res, 9, Val_bool(sms->InboxFolder));
  Store_field(res, 10, VAL_GSM_SMS_STATE(sms->State));
  Store_field(res, 11, CAML_COPY_SUSTRING(sms->Name));
  /* TODO: Check if it's null terminated */
  Store_field(res, 12, CAML_COPY_SUSTRING(sms->Text));
  Store_field(res, 13, VAL_GSM_SMSMESSAGETYPE(sms->PDU));
  Store_field(res, 14, VAL_GSM_CODING_TYPE(sms->Coding));
  Store_field(res, 15, Val_GSM_DateTime(&sms->DateTime));
  Store_field(res, 16, Val_GSM_DateTime(&sms->SMSCTime));
  Store_field(res, 17, VAL_UCHAR(sms->DeliveryStatus));
  Store_field(res, 18, Val_bool(sms->ReplyViaSameSMSC));
  Store_field(res, 19, VAL_CHAR(sms->Class));
  Store_field(res, 20, VAL_UCHAR(sms->MessageReference));

  CAMLreturn(res);
}

static GSM_MultiSMSMessage *GSM_MultiSMSMessage_val(
    value vmulti_sms, GSM_MultiSMSMessage *multi_sms)
{
  int length = Wosize_val(vmulti_sms);;
  int i;

  /* We truncate the array if it's too big. TODO: issue a warning ? */
  if (length > sizeof(multi_sms->SMS))
    length = sizeof(multi_sms->SMS);
  for (i=0; i < length; i++)
    GSM_SMSMessage_val(&(multi_sms->SMS[i]), Field(vmulti_sms, i));
  multi_sms->Number = length;

  return multi_sms;
}

static value Val_GSM_MultiSMSMessage(GSM_MultiSMSMessage *multi_sms)
{
  CAMLparam0();
  CAMLlocal1(res);
  int length = multi_sms->Number;
  int i;

  res = caml_alloc(length, 0);
  for (i=0; i < length; i++)
    Store_field(res, i, Val_GSM_SMSMessage(&multi_sms->SMS[i]));

  CAMLreturn(res);
}

CAMLexport
value caml_gammu_GSM_GetSMS(value s, value vlocation, value vfolder)
{
  CAMLparam3(s, vlocation, vfolder);
  CAMLlocal1(vsms);
  GSM_MultiSMSMessage sms;
  int i;

  /* Clear SMS structure */
  for (i = 0; i < GSM_MAX_MULTI_SMS; i++)
    GSM_SetDefaultSMSData(&sms.SMS[i]);

  sms.SMS[0].Location = Int_val(vlocation);
  sms.SMS[0].Folder = Int_val(vfolder);
  /* TODO: Is that necessary ? */
  sms.Number = 0;

  caml_gammu_raise_Error(GSM_GetSMS(GSM_STATEMACHINE_VAL(s), &sms));

  CAMLreturn(Val_GSM_MultiSMSMessage(&sms));
}

CAMLexport
value caml_gammu_GSM_GetNextSMS(value s, value vlocation, value vfolder,
                                value vstart)
{
  CAMLparam4(s, vlocation, vfolder, vstart);
  GSM_MultiSMSMessage sms;
  int i;

  /* Clear SMS structure */
  for (i = 0; i < GSM_MAX_MULTI_SMS; i++)
    GSM_SetDefaultSMSData(&sms.SMS[i]);

  sms.SMS[0].Location = Int_val(vlocation);
  sms.SMS[0].Folder = Int_val(vfolder);
  /* TODO: Is that necessary ? */
  sms.Number = 0;

  caml_gammu_raise_Error(GSM_GetNextSMS(GSM_STATEMACHINE_VAL(s),
                                        &sms,
                                        Bool_val(vstart)));

  CAMLreturn(Val_GSM_MultiSMSMessage(&sms));
}

/* Unused
static GSM_OneSMSFolder *GSM_OneSMSFolder_val(value vfolder)
{
  GSM_OneSMSFolder *folder = malloc(sizeof(GSM_OneSMSFolder));
  folder->InboxFolder = Bool_val(Field(vfolder, 0));
  folder->OutboxFolder = Bool_val(Field(vfolder, 1));
  folder->Memory = GSM_MEMORYTYPE_VAL(Field(vfolder, 2));
  CPY_TRIM_STRING_VAL(folder->Name, String_val(Field(vfolder, 3)));
  return folder;
} */

/* Unused
static value Val_GSM_OneSMSFolder(GSM_OneSMSFolder *folder)
{
  CAMLparam0();
  CAMLlocal1(res);
  res = caml_alloc(4, 0);
  Store_field(res, 0, Val_bool(folder->InboxFolder));
  Store_field(res, 1, Val_bool(folder->OutboxFolder));
  Store_field(res, 2, VAL_GSM_MEMORYTYPE(folder->Memory));
  Store_field(res, 3, CAML_COPY_SUSTRING(folder->Name));
  CAMLreturn(res);
} */

/* folders */

/* Unused
static GSM_SMSMemoryStatus *GSM_SMSMemoryStatus_val(value vsms_mem)
{
  GSM_SMSMemoryStatus *sms_mem = malloc(sizeof(GSM_SMSMemoryStatus));
  sms_mem->SIMUnRead = Int_val(Field(vsms_mem, 0));
  sms_mem->SIMUsed = Int_val(Field(vsms_mem, 1));
  sms_mem->SIMSize = Int_val(Field(vsms_mem, 2));
  sms_mem->TemplatesUsed = Int_val(Field(vsms_mem, 3));
  sms_mem->PhoneUnRead = Int_val(Field(vsms_mem, 4));
  sms_mem->PhoneUsed = Int_val(Field(vsms_mem, 5));
  sms_mem->PhoneSize = Int_val(Field(vsms_mem, 6));
  return sms_mem;
}
*/

static value Val_GSM_SMSMemoryStatus(GSM_SMSMemoryStatus *sms_mem)
{
  CAMLparam0();
  CAMLlocal1(res);

  res = caml_alloc(7, 0);
  Store_field(res, 0, Val_int(sms_mem->SIMUnRead));
  Store_field(res, 1, Val_int(sms_mem->SIMUsed));
  Store_field(res, 2, Val_int(sms_mem->SIMSize));
  Store_field(res, 3, Val_int(sms_mem->TemplatesUsed));
  Store_field(res, 4, Val_int(sms_mem->PhoneUnRead));
  Store_field(res, 5, Val_int(sms_mem->PhoneUsed));
  Store_field(res, 6, Val_int(sms_mem->PhoneSize));

  CAMLreturn(res);
}

CAMLexport
value caml_gammu_GSM_GetSMSStatus(value s)
{
  CAMLparam1(s);
  GSM_SMSMemoryStatus status;

  GSM_GetSMSStatus(GSM_STATEMACHINE_VAL(s), &status);

  CAMLreturn(Val_GSM_SMSMemoryStatus(&status));
}

CAMLexport
void caml_gammu_GSM_DeleteSMS(value s, value vlocation, value vfolder)
{
  CAMLparam3(s, vlocation, vfolder);
  GSM_SMSMessage sms;
  /* TODO: do we need a one time (w/ sms static) :
     SetDefaultSMSData(sms); */

  sms.Location = Int_val(vlocation);
  sms.Folder = Int_val(vfolder);
  GSM_DeleteSMS(GSM_STATEMACHINE_VAL(s), &sms);

  CAMLreturn0;
}

/* Unused
static GSM_MultiPartSMSEntry GSM_MultiPartSMSEntry_val(value vmult_part_sms)
{
  GSM_MultiPartSMSEntry mult_part_sms;
  mult_part_sms.ID = GSM_ENCODEMULTIPARTSMSID_VAL(Field(vmult_part_sms, 0));
  mult_part_sms.Number = Int_val(Field(vmult_part_sms, 1));
  mult_part_sms.Phonebook = GSM_MemoryEntry_val(Field(vmult_part_sms, 2));
  mult_part_sms.Protected = Bool_val(Field(vmult_part_sms, 3));
  mult_part_sms.Buffer = (unsigned char*) String_val(Field(vmult_part_sms, 4));
  mult_part_sms.Left = Bool_val(Field(vmult_part_sms, 5));
  mult_part_sms.Right = Bool_val(Field(vmult_part_sms, 6));
  mult_part_sms.Center = Bool_val(Field(vmult_part_sms, 7));
  mult_part_sms.Large = Bool_val(Field(vmult_part_sms, 8));
  mult_part_sms.Small = Bool_val(Field(vmult_part_sms, 9));
  mult_part_sms.Bold = Bool_val(Field(vmult_part_sms, 10));
  mult_part_sms.Italic = Bool_val(Field(vmult_part_sms, 11));
  mult_part_sms.Underlined = Bool_val(Field(vmult_part_sms, 12));
  mult_part_sms.Strikethrough = Bool_val(Field(vmult_part_sms, 13));
  mult_part_sms.RingtoneNotes = Int_val(Field(vmult_part_sms, 14));
  return mult_part_sms;
}
*/

static value Val_GSM_MultiPartSMSEntry(GSM_MultiPartSMSEntry mult_part_sms)
{
  CAMLparam0();
  CAMLlocal1(res);

  res = caml_alloc(15, 0);
  Store_field(res, 0, VAL_GSM_ENCODEMULTIPARTSMSID(mult_part_sms.ID));
  Store_field(res, 1, Val_int(mult_part_sms.Number));
  Store_field(res, 2, Val_GSM_MemoryEntry(mult_part_sms.Phonebook));
  Store_field(res, 3, Val_bool(mult_part_sms.Protected));
  Store_field(res, 4, CAML_COPY_SUSTRING(mult_part_sms.Buffer));
  Store_field(res, 5, Val_bool(mult_part_sms.Left));
  Store_field(res, 6, Val_bool(mult_part_sms.Right));
  Store_field(res, 7, Val_bool(mult_part_sms.Center));
  Store_field(res, 8, Val_bool(mult_part_sms.Large));
  Store_field(res, 9, Val_bool(mult_part_sms.Small));
  Store_field(res, 10, Val_bool(mult_part_sms.Bold));
  Store_field(res, 11, Val_bool(mult_part_sms.Italic));
  Store_field(res, 12, Val_bool(mult_part_sms.Underlined));
  Store_field(res, 13, Val_bool(mult_part_sms.Strikethrough));
  Store_field(res, 9, Val_int(mult_part_sms.RingtoneNotes));

  CAMLreturn(res);
}

/*
static GSM_MultiPartSMSInfo *GSM_MultiPartSMSInfo_val(value vmult_part_sms)
{
  value ventries;
  GSM_MultiPartSMSInfo *mult_part_sms = malloc(sizeof(GSM_MultiPartSMSInfo));
  int length;
  int i;
  ventries = Field(vmult_part_sms, 4);
  length = Wosize_val(ventries);
  mult_part_sms->UnicodeCoding = Bool_val(Field(vmult_part_sms, 0));
  mult_part_sms->Class = Int_val(Field(vmult_part_sms, 1));
  mult_part_sms->ReplaceMessage =
    (unsigned char) GSM_Char_val(Field(vmult_part_sms, 2));
  mult_part_sms->Unknown = Bool_val(Field(vmult_part_sms, 3));
  if (length > (GSM_MAX_MULTI_SMS))
    length = GSM_MAX_MULTI_SMS;
  for (i=0; i < length; i++)
    mult_part_sms->Entries[i] = GSM_MultiPartSMSEntry_val(Field(ventries, i));
  mult_part_sms->EntriesNum = length;
  return mult_part_sms;
}
*/

static value Val_GSM_MultiPartSMSInfo(GSM_MultiPartSMSInfo *multipart_sms_info)
{
  CAMLparam0();
  CAMLlocal3(res, ventries, ventry);
  /* Todo: can caml_alloc fail ? */
  res = caml_alloc(5, 0);
  int length = multipart_sms_info->EntriesNum;
  int i;

  Store_field(res, 0, Val_bool(multipart_sms_info->UnicodeCoding));
  Store_field(res, 1, Val_int(multipart_sms_info->Class));
  Store_field(res, 2, VAL_CHAR(multipart_sms_info->ReplaceMessage));
  Store_field(res, 3, Val_bool(multipart_sms_info->Unknown));

  ventries = caml_alloc(length, 0);
  for (i=0; i < length; i++) {
    ventry = Val_GSM_MultiPartSMSEntry(multipart_sms_info->Entries[i]);
    Store_field(ventries, i, ventry);
  }
  Store_field(res, 4, ventries);

  CAMLreturn(res);
}

CAMLexport
value caml_gammu_GSM_DecodeMultiPartSMS(value vdi, value vsms,
                                        value vems)
{
  CAMLparam3(vdi, vsms, vems);
  CAMLlocal1(vmulti_sms);
  GSM_MultiSMSMessage sms;
  GSM_MultiPartSMSInfo info;
  GSM_Debug_Info *di = GSM_DEBUG_INFO_VAL(vdi);

  GSM_MultiSMSMessage_val(vsms, &sms);
  if (!GSM_DecodeMultiPartSMS(di, &info, &sms, Bool_val(vems))) {
    GSM_FreeMultiPartSMSInfo(&info);
    caml_gammu_raise_Error(ERR_COULD_NOT_DECODE);
  }
  vmulti_sms = Val_GSM_MultiPartSMSInfo(&info);

  GSM_FreeMultiPartSMSInfo(&info);

  CAMLreturn(vmulti_sms);
}

/************************************************************************/
/* Events */

static void incoming_sms_callback(GSM_StateMachine *sm, GSM_SMSMessage sms,
                                  void *user_data)
{
  CAMLparam0();
  CAMLlocal1(f);

  f = *((value *) user_data);
  caml_callback(f, Val_GSM_SMSMessage(&sms));

  CAMLreturn0;
}

CAMLexport
void caml_gammu_GSM_SetIncomingSMS(value s, value vf)
{
  CAMLparam2(s, vf);
  State_Machine *state_machine = STATE_MACHINE_VAL(s);
  gboolean globroot_unregistered = (!state_machine->incoming_sms_callback);

  /* TODO: Is it acceptable for a global root to be a pointer to NULL ? If
     so, we would only need to register state_machine->val as global root
     once at state machine allocation. */
  state_machine->incoming_sms_callback = vf;
  if (globroot_unregistered)
    /* Callback closure value wasn't registered, keep the new one and
       following safe. */
    caml_register_global_root(&state_machine->incoming_sms_callback);

  GSM_SetIncomingSMSCallback(state_machine->sm,
                             incoming_sms_callback,
                             (void *) &state_machine->incoming_sms_callback);

  CAMLreturn0;
}

CAMLexport
void caml_gammu_disable_incoming_sms(value s)
{
  CAMLparam1(s);
  State_Machine *state_machine = STATE_MACHINE_VAL(s);

  /* TODO: If it is acceptable for a global root to be a pointer to NULL,
     remove the following statement. */
  if (state_machine->incoming_sms_callback) {
    caml_remove_global_root(&state_machine->incoming_sms_callback);
    state_machine->incoming_sms_callback = 0;
  }

  GSM_SetIncomingSMSCallback(state_machine->sm, NULL, NULL);

  CAMLreturn0;
}
