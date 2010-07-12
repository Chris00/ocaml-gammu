/* File: gammu_stubs.c

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     No�mie Meunier <Noemie.Meunier@student.umons.ac.be>
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

#include <stdio.h>
#include <assert.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/custom.h>
#include <caml/intext.h>

#include <gammu.h>

#include "io.h"

/* Similar to strncpy but doesn't pad with nulls and ensure that destination
   string is null terminated. */
static inline char *strncpy2(char *dst, const char *src, size_t n)
{
  size_t i;

  for (i = 0; i < (n - 1) && src[i] != 0; i++)
    dst[i] = src[i];
  dst[i] = '\0';

  return dst;
}

/************************************************************************/
/* Error handling */

#define Error_val(v) (Int_val(v) + 1)
#define Val_Error(v) (Val_int(v - 1)

CAMLexport
value gammu_caml_ErrorString(value verr)
{
  CAMLparam1(verr);
  const char *msg = GSM_ErrorString(Error_val(verr));
  CAMLreturn(caml_copy_string(msg));
}


/************************************************************************/
/* Debuging handling */

/* The global Debug will never be freed and those from state machines are
   freed through them and should not be freed before the associated state
   machine. Thus, there's no need to wrap them in a finalized block. */
#define Debug_Info_val(v) ((GSM_Debug_Info *) v)
#define Val_Debug_Info(v) ((value) v)

CAMLexport
value gammu_caml_GetGlobalDebug()
{
  CAMLparam0();
  CAMLreturn(Val_Debug_Info(GSM_GetGlobalDebug()));
}

CAMLexport
void gammu_caml_SetDebugGlobal(value vinfo, value vdi)
{
  CAMLparam2(vinfo, vdi);
  GSM_SetDebugGlobal(Bool_val(vinfo), Debug_Info_val(vdi));
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
  res = fdopen(fd, mode);
  return res;
}

CAMLexport
void gammu_caml_SetDebugFileDescriptor(value vchannel, value vdi)
{
  CAMLparam2(vchannel, vdi);
  GSM_SetDebugFileDescriptor(FILE_val(vchannel, "a"),
                             TRUE, // file descriptor is closable
                             Debug_Info_val(vdi));
  CAMLreturn0;
}

CAMLexport
void gammu_caml_SetDebugLevel(value vlevel, value vdi)
{
  CAMLparam2(vlevel, vdi);
  GSM_SetDebugLevel(String_val(vlevel), Debug_Info_val(vdi));
  CAMLreturn0;
}

/************************************************************************/
/* INI files */

#define INI_Section_val(v) (*(INI_Section **) (Data_custom_val(v)))

static void gammu_caml_ini_section_finalize(value vini_section)
{
  INI_Free(INI_Section_val(vini_section));
}

static struct custom_operations gammu_caml_ini_section_ops = {
  "be.umons.ml-gammu.ini_section",
  gammu_caml_ini_section_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static value alloc_INI_Section()
{
  return alloc_custom(&gammu_caml_ini_section_ops, sizeof(INI_Section *),
                      1, 100);
}

static value Val_INI_Section(INI_Section *ini_section)
{
  CAMLlocal1(res);
  res = alloc_INI_Section();
  INI_Section_val(res) = ini_section;
  return res;
}

CAMLexport
value gammu_caml_INI_ReadFile(value vfilename, value vunicode)
{
  CAMLparam2(vfilename, vunicode);
  INI_Section *cfg;
  INI_ReadFile(String_val(vfilename), Bool_val(vunicode), &cfg);
  CAMLreturn(Val_INI_Section(cfg));
}

CAMLexport
value gammu_caml_INI_GetValue(value vfile_info, value vsection, value vkey,
                              value vunicode)
{
  CAMLparam4(vfile_info, vsection, vkey, vunicode);
  const unsigned char* res;
  /* TODO: are those casts safe ? */
  res = INI_GetValue(INI_Section_val(vfile_info),
                     (unsigned char *) String_val(vsection),
                     (unsigned char *) String_val(vkey),
                     Bool_val(vunicode));
  CAMLreturn(caml_copy_string((char *) res));
}


/************************************************************************/
/* State machine */

/* TODO: naming rule for state machines ? :
   "value s" for caml type t
   "value vsm" for caml type state_machine
   "GSM_StateMachine *sm" for libGammu's (GSM_StateMachine *).
   or maybe
   "value vsm" - type t (often used)
   "value vs" - type state_machine (nearly never used) */
#define StateMachine_vsm(v) (*((GSM_StateMachine **) Data_custom_val(v)))
#define StateMachine_val(v) StateMachine_vsm(Field(v, 0))

static void gammu_caml_sm_finalize(value s)
{
  GSM_FreeStateMachine(StateMachine_val(s));
}

static struct custom_operations gammu_caml_sm_ops = {
  "be.umons.ml-gammu.state_machine",
  gammu_caml_sm_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static value Val_StateMachine(GSM_StateMachine *sm)
{
  CAMLparam0();
  CAMLlocal2(res, vsm);
  res = caml_alloc(2, 0);
  vsm = alloc_custom(&gammu_caml_sm_ops, sizeof(GSM_StateMachine *), 1, 100);
  StateMachine_vsm(vsm) = sm;
  Store_field(res, 0, vsm);
  Store_field(res, 1, Val_Debug_Info(GSM_GetDebug(sm)));
  CAMLreturn(res);
}

static value Val_Config(const GSM_Config *config)
{
  CAMLlocal1(res);
  res = caml_alloc(14, 0);
  Store_field(res, 0, caml_copy_string(config->Model));
  Store_field(res, 1, caml_copy_string(config->DebugLevel));
  Store_field(res, 2, caml_copy_string(config->Device));
  Store_field(res, 3, caml_copy_string(config->Connection));
  Store_field(res, 4, Val_bool(config->SyncTime));
  Store_field(res, 5, Val_bool(config->LockDevice));
  Store_field(res, 6, caml_copy_string(config->DebugFile));
  Store_field(res, 7, Val_bool(config->StartInfo));
  Store_field(res, 8, Val_bool(config->UseGlobalDebugFile));
  Store_field(res, 9, caml_copy_string(config->TextReminder));
  Store_field(res, 10, caml_copy_string(config->TextReminder));
  Store_field(res, 11, caml_copy_string(config->TextMeeting));
  Store_field(res, 12, caml_copy_string(config->TextBirthday));
  Store_field(res, 13, caml_copy_string(config->TextMemo));
  return res;
}

/* Set values of config according to those from vconfig. */
static void set_config_val(GSM_Config *config, value vconfig)
{
  strncpy2(config->Model, String_val(Field(vconfig, 0)), 50);
  strncpy2(config->DebugLevel, String_val(Field(vconfig, 1)), 50);
  config->Device = String_val(Field(vconfig, 2));
  config->Connection = String_val(Field(vconfig, 3));
  config->SyncTime = Bool_val(Field(vconfig, 4));
  config->LockDevice = Bool_val(Field(vconfig, 5));
  config->DebugFile = String_val(Field(vconfig, 6));
  config->StartInfo = Bool_val(Field(vconfig, 7));
  config->UseGlobalDebugFile = Bool_val(Field(vconfig, 8));
  strncpy2(config->TextReminder, String_val(Field(vconfig, 9)), 32);
  strncpy2(config->TextMeeting, String_val(Field(vconfig, 10)), 32);
  strncpy2(config->TextCall, String_val(Field(vconfig, 11)), 32);
  strncpy2(config->TextBirthday, String_val(Field(vconfig, 12)), 32);
  strncpy2(config->TextMemo, String_val(Field(vconfig, 13)), 32);
}

#define ConnectionType_val(v) (Int_val(v) + 1)
#define Val_ConnectionType(v) Val_int(v - 1)

CAMLexport
value gammu_caml_GetDebug(value s)
{
  CAMLparam1(s);
  CAMLreturn((value) GSM_GetDebug(StateMachine_val(s)));
}

CAMLexport
void gammu_caml_InitLocales(value vpath)
{
  CAMLparam1(vpath);
  GSM_InitLocales(String_val(vpath));
  CAMLreturn0;
}

CAMLexport
void gammu_caml_InitDefaultLocales()
{
  CAMLparam0();
  GSM_InitLocales(NULL);
  CAMLreturn0;
}

CAMLexport
value gammu_caml_CreateStateMachine()
{
  CAMLparam0();
  CAMLreturn(Val_StateMachine(GSM_AllocStateMachine()));
}

CAMLexport
value gammu_caml_FindGammuRC_force(value vpath)
{
  CAMLparam1(vpath);
  INI_Section **res;
  GSM_FindGammuRC(res, String_val(vpath));
  CAMLreturn(Val_INI_Section(*res));
}

CAMLexport
value gammu_caml_FindGammuRC()
{
  CAMLparam0();
  INI_Section **res;
  GSM_FindGammuRC(res, NULL);
  CAMLreturn(Val_INI_Section(*res));
}

CAMLexport
value gammu_caml_ReadConfig(value vcfg_info, value vnum)
{
  CAMLparam2(vcfg_info, vnum);
  GSM_Config *cfg;
  INI_Section *cfg_info = INI_Section_val(vcfg_info);
  GSM_ReadConfig(cfg_info, cfg, Int_val(vnum));
  CAMLreturn(Val_Config(cfg));
}

CAMLexport
value gammu_caml_GetConfig(value s, value vnum)
{
  CAMLparam2(s, vnum);
  const GSM_Config *cfg = GSM_GetConfig(StateMachine_val(s), Int_val(vnum));
  CAMLreturn(Val_Config(cfg));
}

CAMLexport
void gammu_caml_PushConfig(value s, value vcfg)
{
  CAMLparam2(s, vcfg);
  GSM_StateMachine *sm = StateMachine_val(s);
  const int cfg_num = GSM_GetConfigNum(sm);
  GSM_Config *dest_cfg = GSM_GetConfig(sm, cfg_num);
  if (dest_cfg != NULL)
    set_config_val(dest_cfg, vcfg);
  /* else
       To many configs (more than MAX_CONFIG_NUM (=5),
       unfortunately this const is not exported)
  */
  CAMLreturn0;
}

CAMLexport
void gammu_caml_RemoveConfig(value s)
{
  CAMLparam1(s);
  GSM_StateMachine* sm = StateMachine_val(s);
  const int cfg_num = GSM_GetConfigNum(sm);
  if (cfg_num > 0)
    GSM_SetConfigNum(sm, cfg_num - 1);
  /* else
     Empty stack, can't remove
  */
  CAMLreturn0;
}

CAMLexport
value gammu_caml_GetConfigNum(value s)
{
  CAMLparam1(s);
  CAMLreturn(Val_int( GSM_GetConfigNum(StateMachine_val(s)) ));
}

CAMLexport
void gammu_caml_InitConnection(value s, value vreply_num)
{
  CAMLparam2(s, vreply_num);
  GSM_InitConnection(StateMachine_val(s), Int_val(vreply_num));
  CAMLreturn0;
}

#define Log_Function_val(v)

static void log_function_callback(const char *text, void *data)
{
  CAMLlocal1(f);
  f = *((value *) data);
  caml_callback(f, caml_copy_string(text));
}

CAMLexport
void gammu_caml_InitConnection_Log(value s, value vreply_num, value vlog_func)
{
  CAMLparam3(s, vreply_num, vlog_func);
  /* TODO:?? vlog_func should not be freed until TerminateConnection. But
     the GC could forget about her through the side effect and free it. */
  GSM_InitConnection_Log(StateMachine_val(s),
                        Int_val(vreply_num),
                        log_function_callback, (void *) &vlog_func);
  CAMLreturn0;
}

CAMLexport
void gammu_caml_TerminateConnection(value s)
{
  CAMLparam1(s);
  GSM_TerminateConnection(StateMachine_val(s));
  CAMLreturn0;
}

CAMLexport
value gammu_caml_IsConnected(value s)
{
  CAMLparam1(s);
  CAMLreturn(Val_bool(GSM_IsConnected(StateMachine_val(s))));
}

CAMLexport
value gammu_caml_GetUsedConnection(value s)
{
  CAMLparam1(s);
  GSM_StateMachine *sm = StateMachine_val(s);
  const GSM_ConnectionType conn_type = GSM_GetUsedConnection(sm);
  CAMLreturn(Val_ConnectionType(conn_type));
}

CAMLexport
value gammu_caml_ReadDevice(value s, value vwait_for_reply)
{
  CAMLparam2(s, vwait_for_reply);
  GSM_StateMachine *sm = StateMachine_val(s);
  int read_bytes = GSM_ReadDevice(sm, Bool_val(vwait_for_reply));
  CAMLreturn(Val_int(read_bytes));
}

/************************************************************************/
/* Security related operations with phone */

#define SecurityCodeType_val(v) (Int_val(v) + 1)
#define Val_SecurityCodeType(v) (Val_int(v - 1))

static GSM_SecurityCode SecurityCode_val(value vsecurity_code)
{
  GSM_SecurityCode security_code;
  security_code.Type = SecurityCodeType_val(Field(vsecurity_code, 0));
  strncpy2(security_code.Code,
           String_val(Field(vsecurity_code, 1)),
           GSM_SECURITY_CODE_LEN + 1);
  return security_code;
}

CAMLexport
void SecurityCode(value s, value vcode)
{
  CAMLparam2(s, vcode);
  GSM_EnterSecurityCode(StateMachine_val(s), SecurityCode_val(vcode));
  CAMLreturn0;
}

CAMLexport
value GetSecurityCode(value s)
{
  CAMLparam1(s);
  GSM_SecurityCodeType *status = malloc(sizeof(GSM_SecurityCodeType));
  GSM_GetSecurityStatus(StateMachine_val(s), status);
  CAMLreturn(Val_SecurityCodeType(status));
}

/************************************************************************/
/* Informations on the phone */

#define ChargeState_val(v) (Int_val(v) + 1)
#define Val_ChargeState(v) (Val_int(v - 1))
#define BatteryType_val(v) (Int_val(v) + 1)
#define Val_BatteryType(v) (Val_int(v - 1))

static GSM_BatteryCharge *BatteryCharge_val(value vbattery_charge)
{
  GSM_BatteryCharge *battery_charge = malloc(sizeof(GSM_BatteryCharge));
  battery_charge->BatteryType = BatteryType_val(Field(vbattery_charge, 0));
  battery_charge->BatteryCapacity = Int_val(Field(vbattery_charge, 1));
  battery_charge->BatteryPercent = Int_val(Field(vbattery_charge, 2));
  battery_charge->ChargeState = ChargeState_val(Field(vbattery_charge, 3));
  battery_charge->BatteryVoltage = Int_val(Field(vbattery_charge, 4));
  battery_charge->ChargeVoltage = Int_val(Field(vbattery_charge, 5));
  battery_charge->ChargeCurrent = Int_val(Field(vbattery_charge, 6));
  battery_charge->PhoneCurrent = Int_val(Field(vbattery_charge, 7));
  battery_charge->BatteryTemperature = Int_val(Field(vbattery_charge, 8));
  battery_charge->PhoneTemperature = Int_val(Field(vbattery_charge, 9));
  return battery_charge;
}

static value Val_BatteryCharge(GSM_BatteryCharge *battery_charge)
{
  CAMLlocal1(res);
  res = caml_alloc(10, 0);
  Store_field(res, 0, Val_BatteryType(battery_charge->BatteryType));
  Store_field(res, 1, Val_int(battery_charge->BatteryCapacity));
  Store_field(res, 2, Val_int(battery_charge->BatteryPercent));
  Store_field(res, 3, Val_ChargeState(battery_charge->ChargeState));
  Store_field(res, 4, Val_int(battery_charge->BatteryVoltage));
  Store_field(res, 5, Val_int(battery_charge->ChargeVoltage));
  Store_field(res, 6, Val_int(battery_charge->ChargeCurrent));
  Store_field(res, 7, Val_int(battery_charge->PhoneCurrent));
  Store_field(res, 8, Val_int(battery_charge->BatteryTemperature));
  Store_field(res, 9, Val_int(battery_charge->PhoneTemperature));
  return res;
}

static GSM_PhoneModel *PhoneModel_val(value vphone_model)
{
  /* Check alloc */
  GSM_PhoneModel *phone_model = malloc(sizeof(phone_model));
  /* TODO: implement that.
    phone_model->features = NULL; */
  phone_model->model = String_val(Field(vphone_model, 0));
  phone_model->number = String_val(Field(vphone_model, 1));
  phone_model->irdamodel = String_val(Field(vphone_model, 2));
 return phone_model;
}

static value Val_PhoneModel(GSM_PhoneModel *phone_model)
{
  CAMLlocal1(res);
  res = caml_alloc(3, 0);
  Store_field(res, 0, caml_copy_string(phone_model->model));
  Store_field(res, 1, caml_copy_string(phone_model->number));
  Store_field(res, 2, caml_copy_string(phone_model->irdamodel));
  return res;
}

static GSM_NetworkInfo *NetworkInfo_val(value vnetwork)
{
  /* Check alloc */
  GSM_NetworkInfo *network = malloc(sizeof(GSM_NetworkInfo));
  network->CID = String_val(Field(vnetwork, 0));
  network->NetworkCode = String_val(Field(vnetwork, 1));
  network->State = NetworkState_val(Field(vnetwork, 2));
  network->LAC = String_val(Field(vnetwork, 3));
  network->NetworkName = String_val(Field(vnetwork, 4));
  network->GRPS = GPRS_State_val(Field(vnetwork, 5));  
  network->PacketCID = String_val(Field(vnetwork, 6));
  network->PacketState = NetworkState_val(Field(vnetwork, 7));
  network->PacketLac = String_val(Field(vnetwork, 8));
  return network;
}

static value Val_NetworkInfo(GSM_NetworkInfo *network)
{
  CAMLlocal1(res);
  res = caml_alloc(9, 0);
  Store_field(res, 0, caml_copy_string(network->CID));
  Store_field(res, 1, caml_copy_string(network->NetworkCode));  
  Store_field(res, 2, Val_NetworkState(network->State));
  Store_field(res, 3, caml_copy_string(network->LAC));
  Store_field(res, 4, caml_copy_string(network->NetworkName));
  Store_field(res, 5, Val_GPRS_State(network->GRPS));  
  Store_field(res, 6, caml_copy_string(network->PacketCID));
  Store_field(res, 7, Val_NetworkState(network->PacketState));  
  Store_field(res, 8, caml_copy_string(network->PacketLAC));  
  return res; 
}

#define GPRS_Sate_val(v) (Int_val(v) + 1)
#define Val_GPRS_State(v) (Val_int(v) - 1)
#define NetworkState_val(v) (Int_val(v) + 1)
#define Val_NetworkState(v) (Val_int(v) - 1)

static GSM_SignalQuality *SignalQuality_val(value vsignal_quality)
{
  GSM_SignalQuality *signal_quality = malloc(sizeof(GSM_SignalQuality));
  signal_quality->signal_strength = Int_val(Field(vsignal_quality, 0));
  signal_quality->signal_percent = Int_val(Field(vsignal_quality, 1));
  signal_quality->bit_error_rate = Int_val(Field(vsignal_quality, 2));
  return signal_quality;
}

static value Val_SignalQuality(GSM_SignalQuality *signal_quality)
{
  CAMLlocal1(res);
  res = caml_alloc(3, 0);
  Store_field(res, 0, Val_int(signal_quality->SignalStrength));
  Store_field(res, 1, Val_int(signal_quality->SignalPercent));
  Store_field(res, 2, Val_int(signal_quality->BitErrorRate));
  return res;
}

CAMLexport
value gammu_caml_GetBatteryCharge(value s)
{
  CAMLparam1(s);
  GSM_BatteryCharge *bat;
  GSM_GetBatteryCharge(StateMachine_val(s), bat);
  CAMLreturn(Val_BatteryCharge(bat));
}

CAMLexport
value gammu_caml_GetFirmWare(value s)
{
  CAMLparam1(s);
  CAMLlocal1(res);
  char *value, *date;
  double *num;
  GSM_GetFirmware(StateMachine_val(s), value, date, num);
  res = caml_alloc(3, 0);
  Store_field(res, 0, caml_copy_string(value));
  Store_field(res, 1, caml_copy_string(date));
  Store_field(res, 2, caml_copy_double(*num));
  CAMLreturn(res);
}

CAMLexport
value gammu_caml_GetHardware(value s)
{
  CAMLparam1(s);
  char *val;
  GSM_GetHardware(StateMachine_val(s), val);
  CAMLreturn(caml_copy_string(val));
}

CAMLexport
value gammu_caml_GetIMEI(value s)
{
  CAMLparam1(s);
  char *val;
  GSM_GetIMEI(StateMachine_val(s), val);
  CAMLreturn(caml_copy_string(val));
}

CAMLexport
value gammu_caml_GetManufactureMonth(value s)
{
  CAMLparam1(s);
  char *val;
  GSM_GetManufactureMonth(StateMachine_val(s), val);
  CAMLreturn(caml_copy_string(val));
}

CAMLexport
value gammu_caml_GetManufacturer(value s)
{
  CAMLparam1(s);
  char *val;
  GSM_GetManufacturer(StateMachine_val(s), val);
  CAMLreturn(caml_copy_string(val));
}

CAMLexport
value gammu_caml_GetModel(value s)
{
  CAMLparam1(s);
  char *val;
  GSM_GetModel(StateMachine_val(s), val);
  CAMLreturn(caml_copy_string(val));
}

CAMLexport
value gammu_caml_GetModelInfo(value s)
{
  CAMLparam1(s);
  GSM_PhoneModel *phone_model = GSM_GetModelInfo(StateMachine_val(s));
  CAMLreturn(Val_PhoneModel(*phone_model));
}

CAMLexport
value gammu_caml_GetNetworkInfo(value s)
{
  CAMLparam1(s);
  GSM_NetworkInfo *netinfo;
  GSM_GetNetworkInfo(StateMachine_val(s), netinfo);
  CAMLreturn(Val_NetworkInfo(*netinfo));
}

CAMLexport
value gammu_caml_GetProductCode(value s)
{
  CAMLparam1(s);
  char *val;
  GSM_GetProductCode(StateMachine_val(s), val);
  CAMLreturn(caml_copy_string(val));
}

CAMLexport
value gammu_caml_GetSignalQuality(value s)
{
  CAMLparam1(s);
  GSM_SignalQuality *sig;
  GSM_GetSignalQuality(StateMachine_val(s), sig);
  CAMLreturn(Val_SignalQuality(*sig));
}

/************************************************************************/
/* Date and time */

static GSM_DateTime DateTime_val(value vdate_time)
{
  GSM_DateTime date_time;
  date_time.timezone = Int_val(Field(vdate_time, 0));
  date_time.second = Int_val(Field(vdate_time, 1));
  date_time.minute = Int_val(Field(vdate_time, 2));
  date_time.hour = Int_val(Field(vdate_time, 3));
  date_time.day = Int_val(Field(vdate_time, 4));
  date_time.month = Int_val(Field(vdate_time, 5));
  date_time.year = Int_val(Field(vdate_time, 6));
  return date_time;
}

static value Val_DateTime(GSM_DateTime date_time)
{
  CAMLlocal1(res);
  res = caml_alloc(7, 0);
  Store_field(res, 0, Val_int(date_time.timezone));
  Store_field(res, 1, Val_int(date_time.second));
  Store_field(res, 2, Val_int(date_time.minute));
  Store_field(res, 3, Val_int(date_time.hour));
  Store_field(res, 4, Val_int(date_time.day));
  Store_field(res, 5, Val_int(date_time.month));
  Store_field(res, 6, Val_int(date_time.year));
  return res;
}

CAMLexport
value gammu_caml_CheckDate(value date)
{
  CAMLparam1(date);
  bool date_ok = CheckDate(&DateTime_val(date));
  CAMLreturn(Val_bool(date_ok));
}

CAMLexport
value gammu_caml_CheckTime(value date)
{
  CAMLparam1(date);
  const bool time_ok = CheckTime(&DateTime_val(date));
  CAMLreturn(Val_bool(time_ok));
}

CAMLexport
value gammu_caml_OSDate(value dt)
{
  CAMLparam1(dt);
  const char *os_date = OSDate(DateTime_val(dt));
  CAMLreturn(caml_copy_string(os_date));
}

CAMLexport
value gammu_caml_OSDateTime(value dt, value timezone)
{
  CAMLparam2(dt, timezone);
  const char *os_date_time = OSDateTime(DateTime_val(dt), Bool_val(timezone));
  CAMLreturn(caml_copy_string(os_date_time));
}

/************************************************************************/
/* Memory */

#define MemoryType_val(v) (Int_val(v) + 1)
#define Val_MemoryType(v) Int_val(v - 1)

static GSM_MemoryEntry MemoryEntry_val(value vmem_entry)
{
  CAMLparam1(vmem_entry);
  CAMLlocal1(ventries)
  GSM_MemoryEntry mem_entry;
  const int length;
  int i;
  ventries = Field(vmem_entry, 2);
  length = wosize_val(ventries);
  mem_entry.MemoryType = MemoryType_val(Field(vmem_entry, 0));
  mem_entry.Location = Int_val(Field(vmem_entry, 1));
  /* TODO: raise exception if too many entries. */
  if (length > GSM_PHONEBOOK_ENTRIES)
    length = GSM_PHONEBOOK_ENTRIES;
  /* TODO:?? Alloc only length GSM_SubMemoryEntry. */
  mem_entry.Entries = malloc(GSM_PHONEBOOK_ENTRIES * sizeof(GSM_SubMemoryEntry));
  for (i=0; i < length; i++)
    entries[i] = SubMemoryEntry_val(Field(ventries, i));
  mem_entry.EntriesNum = length;
  mem_entry.Entries = entries;
  return mem_entry;
}

static value Val_MemoryEntry(GSM_MemoryEntry mem_entry)
{
  CAMLlocal1(res);
  const int length = mem_entry.EntriesNum;
  const entries = mem_entry.entries;
  int i;
  res = caml_alloc(length, 0);
  for (i=0; i < length; i++)
    Store_field(res, i, Val_SubMemoryEntry(entries[i]));
  CAMLreturn(res);
}

static GSM_SubMemoryEntry SubMemoryEntry_val(value vsub_mem_entry)
{
  CAMLparam1(sub_mem_entry);
  CAMLlocal1(vsms_list);
  GSM_SubMemoryEntry res;
  int sms_list[20];
  int i;
  res.EntryType = EntryType_val(Field(vsub_mem_entry, 0));
  res.Date = DateTime_val(Field(vsub_mem_entry, 1));
  res.Number = Int_val(Field(vsub_mem_entry, 2));
  res.VoiceTag = Int_val(Field(vsub_mem_entry, 3));
  vsms_list = Field(vsub_mem_entry, 4);
  if (wosize_val(sms_list) != 20)
    return NULL; /* TODO: Raise error ! */
  for (i=0; i < 20; i++)
    sms_list[i] = Field(vsms_list, i);
  res.SMSList = sms_list;
  res.CallLength = Int_val(Field(vsub_mem_entry, 5));
  res.AddError = Error_val(Field(vsub_mem_entry, 6));
  res.Text = String_val(Field(vsub_mem_entry, 7));
  return res;
}

static value Val_SubMemoryEntry(GSM_SubMemoryEntry sub_mem_entry)
{
  CAMLlocal2(res, vsms_list);
  const int *sms_list;
  int i;
  StoreField(res, 0, Val_EntryType(sub_mem_entry.EntryType));
  StoreField(res, 1, Val_DateTime(sub_mem_entry.Date));
  StoreField(res, 2, Val_int(sub_mem_entry.Number));
  StoreField(res, 3, Val_int(sub_mem_entry.VoiceTag));
  sms_list = sub_mem_entry.SMSList;
  vsms_list = caml_alloc(20, 0);
  for (i=0; i < 20; i++)
    StoreField(vsms_list, i, sms_list[i]);
  StoreField(res, 4, vsms_list);
  StoreField(res, 5, Val_int(sub_mem_entry.CallLength));
  StoreField(res, 6, Val_Error(sub_mem_entry.AddError));
  StoreField(res, 7, caml_copy_string(sub_mem_entry.Text));
  CAMLreturn(res);
}

#define EntryType_val(v) (Int_val(v) + 1)
#define Val_EntryType(v) Val_int(v - 1)

/************************************************************************/
/* Messages */

#define SMSFormat_val(v) (Int_val(v) + 1)
#define Val_SMSFormat(v) (Val_int(v) - 1)
#define ValidyPeriod_val(v) (Int_val(v) + 1)
#define Val_ValidyPeriod(v) (Val_int(v) - 1)
#define SMS_State_val(v) (Int_val(v) + 1)
#define Val_SMS_State(v) (Val_int(v) - 1)
#define UDH_val(v) (Int_val(v) + 1)
#define Val_UDH(v) (Val_int(v) - 1)

static GSM_UDHHeader UDHHeader_val(value vudh_header)
{
  GSM_UDHHeader udh_header;
  udh_header.udh = UDH_val(Field(vudh_header, 0));
  udh_header.text = String_val(Field(vudh_header, 1));
  udh_header.id8bit = Int_val(Field(vudh_header, 2));
  udh_header.id16bit = Int_val(Field(vudh_header, 3));
  udh_header.part_number = Int_val(Field(vudh_header, 4));
  udh_header.all_parts = Int_val(Field(vudh_header, 5));
  return udh_header;
}

static value Val_UDHHeader(GSM_UDHHeader udh_header)
{
  CAMLlocal1(res);
  res = caml_alloc(6, 0);
  Store_field(res, 0, Val_UDH(udh_header.udh));
  Store_field(res, 1, caml_copy_string(udh_header.text));
  Store_field(res, 2, Val_int(udh_header.id8bit));
  Store_field(res, 3, Val_int(udh_header.id16bit));
  Store_field(res, 4, Val_int(udh_header.part_number));
  Store_field(res, 5, Val_int(udh_header.all_parts));
  return res;
}

#define SMSMessageType_val(v) (Int_val(v) + 1)
#define Val_SMSMessageType(v) (Val_int(v) - 1)
#define Coding_Type_val(v) (Int_val(v) + 1)
#define Val_Coding_Type(v) (Val_int(v) - 1)

#define Char_val(v) \
  ((char) Int_val(caml_callback(*caml_named_value("Char.code"), v)))
#define Val_char(v) \
  caml_callback(*caml_named_value("Char.chr"), Val_int((int) v))

static GSM_SMSMessage SMSMessage_val(value vsms)
{
  GSM_SMSMessage sms;
  sms.replace_message = (unsigned char) Char_val(Field(vsms, 0));
  sms.reject_duplicates = Bool_val(Field(vsms, 1));
  sms.udh = UDHHeader_val(Field(vsms, 2));
  sms.number = String_val(Field(vsms, 3));
  sms.other_numbers = ???_val(Field(vsms, 4));
  sms.smsc = SMSC_val(Field(vsms, 5));
  sms.memory = MemoryType_val(Field(vsms, 6));
  sms.location = Int_val(Field(vsms, 7));
  sms.folder = Int_val(Field(vsms, 8));
  sms.inbox_folder = Bool_val(Field(vsms, 9));
  sms.state = SMS_State_val(Field(vsms, 10));
  sms.name = (unsigned char) Char_val(Field(vudh_header, 11));
  sms.text = (unsigned char) Char_val(Field(vsms, 12));
  sms.pdu = SMSMessageType_val(Field(vsms, 13));
  sms.coding = Coding_Type_val(Field(vsms, 14));
  sms.date_time = DateTime_val(Field(vsms, 15));
  sms.smsc_time = DateTime_val(Field(vsms, 16));
  sms.delivery_status = (unsigned char) Char_val(Field(vsms, 17));
  sms.reply_via_same_smsc = Bool_val(Field(vsms, 18));
  sms.class = (signed char) Char_val(Field(vudh_header, 19));
  sms.message_reference = (unsigned char) Char_val(Field(vsms, 20));
  return sms;
}

static value Val_SMSMessage(GSM_SMSMessage sms)
{
  StoreField(res, 0, Val_Char(sms.replace_message));
  StoreField(res, 1, Val_bool(sms.reject_duplicates));
  StoreField(res, 2, Val_UDHHeader(sms.udh));
  StoreField(res, 3, caml_copy_string(sms.number));
  StoreField(res, 4, ???(sms.other_numbers));
  StoreField(res, 5, Val_SMSC(sms.smsc));
  StoreField(res, 6, Val_MemoryType(sms.memory));
  StoreField(res, 7, caml_copy_string(sub_mem_entry.Text));
  CAMLreturn(res);
}

/* message array
   GetSMS
   GetNextSMS... */


static GSM_OneSMSFolder OneSMSFolder_val(value vfolder)
{
  GSM_OneSMSFolder folder;
  folder.inbox_folder = Bool_val(Field(vudh_header, 0));
  folder.outbox_folder = Bool_val(Field(vudh_header, 1));
  folder.memory = MemoryType_val(Field(vudh_header, 2));
  folder.name = String_val(Field(vudh_header, 3));
  return folder;
}

static value Val_OneSMSFolder(GSM_OneSMSFolder folder)
{
  CAMLlocal1(res);
  res = caml_alloc(4, 0);
  Store_field(res, 0, Val_bool(folder.inbox_folder));
  Store_field(res, 1, VAl_bool(folder.outbox_folder));
  Store_field(res, 2, Val_MemoryType(folder.memory));
  Store_field(res, 3, caml_copy_string(folder.name));
  return res;
}

/* folders */


static GSM_SMSMemoryStatus SMSMemoryStatus_val(value vsms_mem)
{
  GSM_SMSMemoryStatus sms_mem;
  sms_mem.phone_size = Int_val(Field(vsms_mem, 0));
  sms_mem.phone_unread = Int_val(Field(vsms_mem, 1));
  sms_mem.phone_used = Int_val(Field(vsms_mem, 2));
  sms_mem.sim_size = Int_val(Field(vsms_mem, 3));
  sms_mem.sim_unread = Int_val(Field(vsms_mem, 4));
  sms_mem.sim_used = Int_val(Field(vsms_mem, 5));
  sms_mem.templates_used = Int_val(Field(vsms_mem, 6));
  return sms_mem;
}

static value Val_SMSMemoryStatus(GSM_SMSMemoryStatus sms_mem)
{
  CAMLlocal1(res);
  res = caml_alloc(7, 0);
  Store_field(res, 0, Val_int(sms_mem.phone_size));
  Store_field(res, 1, VAl_int(sms_mem.phone_unread));
  Store_field(res, 2, Val_int(sms_mem.phone_used));
  Store_field(res, 3, Val_int(sms_mem.sim_size));
  Store_field(res, 4, Val_int(sms_mem.sim_unread));
  Store_field(res, 5, VAl_int(sms_mem.sim_used));
  Store_field(res, 6, Val_int(sms_mem.templates_used));
  return res;
}

CAMLexport
value gammu_caml_GetSMSStatus(value s)
{
  CAMLparam1(s);
  GSM_SMSMemoryStatus *status;
  CAMLreturn(Val_SMSMemoryStatus(GSM_GetSMSStatus(StateMachine_val(s),
                                                  &status)));
}

CAMLexport
void gammu_caml_SetIncommingSMS(value s, value enable)
{
  CAMLparam2(s, enable);
  GSM_SetIncomingSMS(StateMachine_val(s), Bool_val(enable));
  CAMLretrun0;
}

CAMLexport
void gammu_caml_DeleteSMS(value s, value sms)
{
  CAMLparam2(s, sms);
  GSM_DeleteSMS(StateMachine(s), SMSMessage_val(sms));
  CAMLreturn0;
}

static GSM_MultipartSMSInfo MultipartSMSInfo_val(value vmult_part_sms)
{
  GSM_MultipartSMSInfo mult_part_sms;
  mult_part_sms.unicode_coding = Bool_val(Field(vmult_part_sms, 0));
  mult_part_sms.info_class = Int_val(Field(vmult_part_sms, 1));
  mult_part_sms.replace_message =
    (unsigned char) Char_val(Field(vmult_part_sms, 2));
  mult_part_sms.unknown = Bool_val(Field(vmult_part_sms, 3));
  mult_part_sms.entries = /* ????(Field(vmult_part_sms, 4));*/;
  return mult_part_sms;
}

static value Val_MultipartSMSInfo(GSM_MultipartSMSInfo mult_part_sms)
{
  CAMLlocal1(res);
  res = caml_alloc(5, 0);
  Store_field(res, 0, Val_bool(mult_part_sms.unicode_coding));
  Store_field(res, 1, VAl_int(mult_part_sms.info_class));
  Store_field(res, 2, Val_char(mult_part_sms.replace_message));
  Store_field(res, 3, Val_bool(mult_part_sms.unknown));
  Store_field(res, 4, /* ???(mult_part_sms.entries));*/);
  return res;
}


static GSM_MultipartSMSEntry MultipartSMSEntry_val(value vmult_part_sms)
{
  GSM_MultipartSMSEntry mult_part_sms;
  mult_part_sms.id = EncodeMultiPartSMSID_val(Field(vmult_part_sms, 0));
  mult_part_sms.number = Int_val(Field(vmult_part_sms, 1));
  mult_part_sms.phonebook = MemoryEntry_val(Field(vmult_part_sms, 2));
  mult_part_sms.protecter = Bool_val(Field(vmult_part_sms, 3));
  mult_part_sms.buffer = /* ???_val(Field(vmult_part_sms, 4)*/;
  mult_part_sms.left = Bool_val(Field(vmult_part_sms, 5));
  mult_part_sms.right = Bool_val(Field(vmult_part_sms, 6));
  mult_part_sms.center = Bool_val(Field(vmult_part_sms, 7));
  mult_part_sms.large = Bool_val(Field(vmult_part_sms, 8));
  mult_part_sms.small = Bool_val(Field(vmult_part_sms, 9));
  mult_part_sms.bold = Bool_val(Field(vmult_part_sms, 10));
  mult_part_sms.italic = Bool_val(Field(vmult_part_sms, 11));
  mult_part_sms.underlined = Bool_val(Field(vmult_part_sms, 12));
  mult_part_sms.strikethrough = Bool_val(Field(vmult_part_sms, 13));
  mult_part_sms.ringstone_notes = Int_val(Field(vmult_part_sms, 14));
  return mult_part_sms;
}

static value Val_MultipartSMSEntry(GSM_MultipartSMSEntry mult_part_sms)
{
  CAMLlocal1(res);
  res = caml_alloc(15, 0);
  Store_field(res, 0, Val_EncodeMultiPartSMSID(mult_part_sms.id));
  Store_field(res, 1, VAl_int(mult_part_sms.number));
  Store_field(res, 2, Val_MemoryEntry(mult_part_sms.phonebook));
  Store_field(res, 3, Val_bool(mult_part_sms.unknown));
  Store_field(res, 4, /* ???(mult_part_sms.entries));*/);
  Store_field(res, 5, Val_bool(mult_part_sms.left));
  Store_field(res, 6, VAl_bool(mult_part_sms.right));
  Store_field(res, 7, Val_bool(mult_part_sms.center));
  Store_field(res, 8, Val_bool(mult_part_sms.large));
  Store_field(res, 9, Val_bool(mult_part_sms.small));
  Store_field(res, 10, VAl_bool(mult_part_sms.bold));
  Store_field(res, 11, Val_bool(mult_part_sms.italic));
  Store_field(res, 12, Val_bool(mult_part_sms.underlined));
  Store_field(res, 13, Val_bool(mult_part_sms.strikethrough));
  Store_field(res, 9, Val_int(mult_part_sms.ringstone_notes));
  return res;
}

#define EncodeMultiPartSMSID_val(v) (Int_val(v) + 1)
#define Val_EncodeMultiPartSMSID(v) (Val_int(v) - 1)

CAMLexport
value gammu_caml_DecodeMultiPartSMS(value vdi, value vsms, value vems)
{
  CAMLparam4(vdi, vinfo, vsms, vems);
  GSM_DecodeMultiPartSMS(Debug_Info_val(vdi),
                         &MultiPartSMSInfo_val(vinfo),
                         &MultiSMSMessage_val(vsms),
                         Bool_val(vems));
  CAMLreturn0;
}

/************************************************************************/
/* Events */

void incoming_sms_callback(GSM_StateMachine *sm, GSM_SMSMessage sms,
                           void *user_data)
{
  CAMLlocal1(f);
  f = *((value) user_data);
  caml_callback2(f, Val_StateMachine(sm), Val_SMSMessage(sms));
}

CAMLexport
void gammu_caml_SetIncomingSMS(value s, value vf)
{
  CAMLparam2(s, vf);
  GSM_StateMachine *sm = StateMachine_val(s);
  GSM_SetIncomingSMSCallback(sm, incoming_sms_callback, (void *) &vf);
  CAMLreturn0;
}
