/* File: gammu_stubs.c

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     Pierre Hauweele <Pierre.Hauweele@student.umons.ac.be>
     Noémie Meunier <Noemie.Meunier@student.umons.ac.be>
     WWW: http://math.umons.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License version 3 or
   later as published by the Free Software Foundation.  See the file
   LICENCE for more details.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. */

#include <gammu.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/custom.h>
#include <caml/intext.h>

#define Error_val(v) (Int_val(v) + 1)

CAMLprim
value gammu_caml_ErrorString(value verr)
{
  CAMLparam1(verr);
  const char *msg = GSM_ErrorString(Error_val(verr));
  CAMLreturn(caml_copy_string(msg));
}

/************************************************************************/
/* Debuging handling */

CAMLprim
value gammu_caml_GetGlobalDebug()
{
  CAMLparam0;
  CAMLreturn((value) GSM_GetGlobalDebug());
}

CAMLexport
void gammu_caml_SetDebugGlobal(value vinfo, value vdi)
{
  CAMLparam2(vinfo, vdi);
  GSM_SetDebugGlobal(Bool_val(vinfo), (GSM_Debug_Info *) vdi);
  CAMLreturn0;
}

CAMLexport
void gammu_caml_SetDebugFileDescriptor(value vfd, value vclosable, value vdi)
{
  CAMLparam3(vfd, vclosable, vdi);
  GSM_SetDebugFileDescriptor(Int_val(vfd),
                             Bool_val(vclosable),
                             (GSM_Debug_Info *) vdi);
  CAMLreturn0;
}

CAMLexport
void gammu_caml_SetDebugLevel(value vlevel, value vdi)
{
  CAMLparam2(vlevel, vdi);
  GSM_SetDebugLevel(String_val(vlevel), (GSM_Debug_Info *) vdi);
  CAMLreturn0;
}

/************************************************************************/
/* INI files */

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
                      1, 1000);
}

#define INI_Section_val(v) (*(INI_Section **) (Data_Custom_val(v))

static value Val_INI_Section(INI_Section *ini_section)
{
  CAMLlocal1(res);
  res = alloc_INI_Section();
  INI_Section_val(res) = ini_section;
  return res;
}

CAMLprim
value gammu_caml_ReadFile(value file_name, value unicode)
{
  CAMLparam2(filename, unicode);
  INI_Section *cfg;
  INI_ReadFile(String_val(filename), Bool_val unicode, &cfg);
  CAMLreturn(Val_INI_Section(cfg));
}

/************************************************************************/
/* State machine */

static void gammu_caml_sm_finalize(value state_machine)
{
  GSM_FreeStateMachine(STATE_MACHINE_VAL(state_machine));
}

static struct custom_operations gammu_caml_sm_ops = {
  "be.umons.ml-gammu.state_machine",
  gammu_caml_sm_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static value alloc_StateMachine()
{
  return alloc_custom(&gammu_caml_sm_ops, sizeof(StateMachine *), 1, 1000);
}

#define StateMachine_val(v) (*(GSM_StateMachine **) Data_Custom_val(v))

static value Val_StateMachine(StateMachine *state_machine)
{
  CAMLlocal1(res);
  res = alloc_StateMachine();
  StateMachine_val(res) = state_machine;
  return res;
}

static value Val_Config(GSM_Config config)
{
  CAMLlocal1(res);
  res = caml_alloc(14, 0);
  Store_field(res, 0, caml_copy_string(config.model));
  Store_field(res, 1, caml_copy_string(config.debug_level));
  Store_field(res, 2, caml_copy_string(config.device));
  Store_field(res, 3, caml_copy_string(config.connection));
  Store_field(res, 4, Val_bool(config.sync_time));
  Store_field(res, 5, Val_bool(config.lock_device));
  Store_field(res, 6, caml_copy_string(config.debug_file));
  Store_field(res, 7, Val_bool(config.start_info));
  Store_field(res, 8, Val_bool(config.use_global_debug_file));
  Store_field(res, 9, caml_copy_string(config.text_reminder));
  Store_field(res, 10, caml_copy_string(config.text_reminder));
  Store_field(res, 11, caml_copy_string(config.text_meeting));
  Store_field(res, 12, caml_copy_string(config.text_birthday));
  Store_field(res, 13, caml_copy_string(config.text_memo));
  return res;
}

static GSM_Config Config_val(value vconfig)
{
  GSM_Config config;
  config.model = String_val(Field(vconfig, 0));
  config.debug_level = String_val(Field(vconfig, 1));
  config.device = String_val(Field(vconfig, 2));
  config.connection = String_val(Field(vconfig, 3));
  config.sync_time = Bool_val(Field(vconfig, 4));
  config.lock_device = Bool_val(Field(vconfig, 5));
  config.debug_file = String_val(Field(vconfig, 6));
  config.start_info = Bool_val(Field(vconfig, 7));
  config.use_global_debug_file = Bool_val(Field(vconfig, 8));
  config.text_reminder = String_val(Field(vconfig, 9));
  config.text_meeting = String_val(Field(vconfig, 10));
  config.text_call = String_val(Field(vconfig, 11));
  config.text_birthday = String_val(Field(vconfig, 12));
  config.text_memo = String_val(Field(vconfig, 13));
  return config;
}

#define ConnectionType_val(v) (Int_val(v) + 1)
#define Val_ConnectionType(v) Val_int(v - 1)

CAMLprim
value gammu_caml_GetDebug(value s)
{
  CAMLparam1(s);
  /* How to declare dependence of DebugInfo on StateMachine ? 
     StateMachine* s -> DebugInfo* di
     say
       let s = Gammu.make () in
       let di = get_debug s in
       some_func di;;
     and say s got garbage collected, it will free di... */
  CAMLreturn((value) GSM_GetDebug(s));
}

CAMLprim
void gammu_caml_InitLocales(value vpath)
{
  CAMLparam1(path);
  GSM_InitLocales(String_val(vpath));
  CAMLreturn0;
}

CAMLprim
void gammu_caml_InitDefaultLocales()
{
  CAMLparam0;
  GSM_InitLocales(NULL);
  CAMLreturn0;
}

CAMLprim
value gammu_caml_CreateStateMachine()
{
  CAMLparam0;
  CAMLreturn(Val_StateMachine(GSM_AllocStateMachine()));
}

CAMLprim
INI_Section* gammu_caml_FindGammuRC_force(value vpath)
{
  CAMLparam1(path);
  const INI_Section *file_info = GSM_FindGammuRC(String_val(vpath));
  CAMLreturn(Val_INI_Section(file_info));
}

CAMLprim
INI_Section* gammu_caml_FindGammuRC()
{
  CAMLparam0;
  CAMLreturn(Val_INI_Section(GSM_FindGammuRC(NULL)));
}

CAMLprim
value gammu_caml_ReadConfig(value vcfg_info, value vnum)
{
  CAMLparam2(vcfg_info, vnum);
  const INI_Section *cfg_info = INI_Section_val(vcfg_info);
  const GSM_Config *cfg = GSM_ReadConfig(cfg_info, Int_val(vnum));
  CAMLreturn(Val_Config(*cfg));
}

CAMLprim
value gammu_caml_GetConfig(value s, value vnum)
{
  CAMLparam2(s, num);
  GSM_Config *cfg = GSM_GetConfig(StateMachine_val(s), Int_val(vnum));
  CAMLreturn(Val_Config(*cfg));
}

CAMLexport
void gammu_caml_PushConfig(value s, value vcfg)
{
  CAMLparam2(s, vcfg);
  GSM_StateMachin *sm = StateMachine_val(s);
  int cfg_num = GSM_GetConfigNum(sm);
  GSM_Config *dest_cfg = GSM_GetConfig(sm, cfg_num);
  if (cfg != NULL)
    dest_cfg = Config_val(*cfg);
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
  int cfg_num = GSM_GetConfigNum(sm);
  /* TODO: explicitly free old config or use GC (-> pop)*/
  if (cfg_num > 0)
    GSM_SetConfigNum(sm, cfg_num - 1);
  /* else
     Empty stack, can't remove
  */
  CAMLreturn0;
}
  
CAMLprim
value gammu_caml_GetConfigNum(value s)
{
  CAMLparam1(s);
  CAMLreturn(Val_int( GSM_SetConfigNum(StateMachine_val(s)) ));
}

CAMLexport
void gammu_caml_InitConnection(value s, value vreply_num)
{
  CAMLparam2(s, vreply_num);
  GSM_InitConnection(StateMachine_val(s), Int_val(vreply_num));
}

#define Log_Function_val(v) 

void log_function_callback(char *text, void *data)
{
  CAMLlocal1(f);
  value f = *(value) data;
  caml_callback(f, caml_copy_string(text));
}

CAMLexport
void gammu_caml_InitConnectionLog(value s, value vreply_num, value vlog_func)
{
  CAMLparam3(s, vreply_num, vlog_func);
  /* TODO:?? vlog_func should not be freed until TerminateConnection. But
     the GC could forget about her through the side effect and free it. */
  GSM_InitConnectionLog(StateMachine_val(s),
                        Int_val(reply_num),
                        log_function_callback, (void *) &vlog_func);
  CAMLreturn0;
}

CAMLprim
void gammu_caml_TerminateConnection(value s)
{
  CAMLparam1(s);
  GSM_TerminateConnection(StateMachine_val(s));
  CAMLreturn0;
}

CAMLprim
value gammu_caml_IsConnected(value s)
{
  CAMLparam1(s);
  CAMLreturn(Val_bool(GSM_IsConnected(StateMachine_val(s))));
}

CAMLprim
value gammu_caml_GetUsedConnection(value s)
{
  CAMLparam1(s);
  CAMLreturn(Val_ConnectionType(GSM_GetUsedConnection(StateMachine_val(s))));
}

/************************************************************************/
/* Security related operations with phone */

static GSM_SecurityCode SecurityCode_val(value vsecurity_code)
{
  GSM_SecurityCode security_code;
  security_code.code_type = SecurityCodeType_val(Field(vsecurity_code, 0));
  config.debug_level = String_val(Field(vsecurity_code, 1));
  return security_code;
}

#define SecurityCodeType_val(v) (Int_val(v) + 1)
#define Val_SecurityCodeType(v) (Val_int(v - 1))

CAMLprim
void SecurityCode(value s, value code)
{
  CAMLparam1(s, code);
  GSM_EnterSecurityCode(StateMachine_val(s), SecurityCode_val(code));
  CAMLreturn0;
}

CAMLprim
value GetSecurityCode(value s)
{
  CAMLparam1(s);
  GSM_SecurityCodeType *status;
  GSM_GetSecurityStatus(StateMachine_val(s), status);
  CAMLreturn(Val_SecurityCodeType status);
}

/************************************************************************/
/* Informations on the phone */

static GSM_BatteryCharge BatteryCharge_val(value vbattery_charge)
{
  GSM_BatteryCharge battery_charge;
  battery_charge.battery_type = BatteryType_val(Field(vbattery_charge, 0));
  battery_charge.battery_capacity = Int_val(Field(vbattery_charge, 1));
  battery_charge.battery_percent = Int_val(Field(vbattery_charge, 2));
  battery_charge.charge_state = ChargeState_val(Field(vbattery_charge, 3));
  battery_charge.battery_voltage = Int_val(Field(vbattery_charge, 4));
  battery_charge.charge_voltage = Int_val(Field(vbattery_charge, 5));
  battery_charge.charge_current = Int_val(Field(vbattery_charge, 6));
  battery_charge.phone_current = Int_val(Field(vbattery_charge, 7));
  battery_charge.battery_temperature = Int_val(Field(vbattery_charge, 8));
  battery_charge.phone_temperature = Int_val(Field(vbattery_charge, 9));
  return battery_charge;
}

static value Val_BatteryCharge(GSM_BatteryCharge battery_charge)
{
  CAMLlocal1(res);
  res = caml_alloc(10, 0);
  Store_field(res, 0, Val_BatteryType(battery_charge.battery_type));
  Store_field(res, 1, Val_int(battery_charge.battery_capacity));
  Store_field(res, 2, Val_int(battery_charge.battery_percent));
  Store_field(res, 3, Val_ChargeState(battery_charge.charge_state));
  Store_field(res, 4, Val_int(battery_charge.battery_voltage));
  Store_field(res, 5, Val_int(battery_charge.charge_voltage));
  Store_field(res, 6, Val_int(battery_charge.charge_current));
  Store_field(res, 7, Val_int(battery_charge.phone_current));
  Store_field(res, 8, Val_int(battery_charge.battery_temperature));
  Store_field(res, 9, Val_int(battery_charge.phone_temperature));
  return res;
}

#define ChargeState_val(v) (Int_val(v) + 1)
#define Val_ChargeState(v) (Val_int(v - 1))
#define BatteryType_val(v) (Int_val(v) + 1)
#define Val_BatteryType(v) (Val_int(v - 1))

static GSM_PhoneModel PhoneModel_val(value vphone_model)
{
  GSM_PhoneModel phone_model;
  /* phone_model.features = ?  0!!!! ;*/
  phone_model.irda = String_val(Field(vphone_model, 1));
  phone_model.model = String_val(Field(vphone_model, 2));
  phone_model.number = String_val(Field(vphone_model, 3));
  return phone_model;
}

static value Val_PhoneModel(GSM_PhoneModel phone_model)
{
  CAMLlocal1(res);
  res = caml_alloc(3, 0);
  Store_field(res, 0, caml_copy_string(phone_model.irda));
  Store_field(res, 1, caml_copy_string(phone_model.model));
  Store_field(res, 2, caml_copy_string(phone_model.number));
  return res;
}

static GSM_NetworkInfo NetworkInfo_val(value vnetwork_info)
{
  GSM_NetworkInfo network_info;
  network_info.cid = String_val(Field(vnetwork_info, 0));
  network_info.gprs = GPRS_State_val(Field(vnetwork_info, 1)); /*nom?*/
  network_info.lac = String_val(Field(vnetwork_info, 2));
  network_info.code = String_val(Field(vnetwork_info, 3));
  network_info.name = String_val(Field(vnetwork_info, 4));
  network_info.packet_cid = String_val(Field(vnetwork_info, 5));
  network_info.packet_lac = String_val(Field(vnetwork_info, 6));
  network_info.packet_state = NetworkState_val(Field(vnetwork_info, 7));
  network_info.state = NetworkState_val(Field(vnetwork_info, 8));
  return network_info;
}

static value Val_NetworkInfo(GSM_NetworkInfo network_info)
{
  CAMLlocal1(res);
  res = caml_alloc(9, 0);
  Store_field(res, 0, caml_copy_string(network_info.cid));
  Store_field(res, 1, Val_GPRS_State(network_info.gprs));
  Store_field(res, 2, caml_copy_string(network_info.lac));
  Store_field(res, 3, caml_copy_string(network_info.code));
  Store_field(res, 4, caml_copy_string(network_info.name));
  Store_field(res, 5, caml_copy_string(network_info.packet_cid));
  Store_field(res, 6, caml_copy_string(network_info.packet_lac));
  Store_field(res, 7, Val_NetworkState(network_info.packet_state));
  Store_field(res, 8, Val_NetworkState(network_info.state));
  return res;
}

#define GPRS_Sate_val(v) (Int_val(v) + 1)
#define Val_GPRS_State(v) (Val_int(v) - 1)
#define NetworkState_val(v) (Int_val(v) + 1)
#define Val_NetworkState(v) (Val_int(v) - 1)

static GSM_SignalQuality SignalQuality_val(value vsignal_quality)
{
  GSM_SignalQuality signal_quality;
  signal_quality.signal_strength = Int_val(Field(vsignal_quality, 0));
  signal_quality.signal_percent = Int_val(Field(vsignal_quality, 1));
  signal_quality.bit_error_rate = Int_val(Field(vsignal_quality, 2));
  return signal_quality;
}

static value Val_SignalQuality(GSM_SignalQuality signal_quality)
{
  CAMLlocal1(res);
  res = caml_alloc(3, 0);
  Store_field(res, 0, Val_int(signal_quality.signal_strength));
  Store_field(res, 1, Val_int(signal_quality.signal_percent));
  Store_field(res, 2, Val_int(signal_quality.bit_error_rate));
  return res;
}

CAMLprim
value gammu_caml_GetBatteryCharge(value s)
{
  CAMLparam1(s);
  GSM_BatteryCharge *bat;
  GSM_GetBatteryCharge(StateMachine_val(s), bat);
  CAMLreturn(Val_BatteryCharge(bat));
}

CAMLprim
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

CAMLprim
value gammu_caml_GetHardware(value s)
{
  CAMLparam1(s);
  char *val;
  GSM_GetHardware(StateMachine_val(s), val);
  CAMLreturn(caml_copy_string(val));
}

CAMLprim
value gammu_caml_GetIMEI(value s)
{
  CAMLparam1(s);
  char *val;
  GSM_GetIMEI(StateMachine_val(s), val);
  CAMLreturn(caml_copy_string(val));
}

CAMLprim
value gammu_caml_GetManufactureMonth(value s)
{
  CAMLparam1(s);
  char *val;
  GSM_GetManufactureMonth(StateMachine_val(s), val);
  CAMLreturn(caml_copy_string(val));
}

CAMLprim
value gammu_caml_GetManufacturer(value s)
{
  CAMLparam1(s);
  char *val;
  GSM_GetManufacturer(StateMachine_val(s), val);
  CAMLreturn(caml_copy_string(val));
}

CAMLprim
value gammu_caml_GetModel(value s)
{
  CAMLparam1(s);
  char *val;
  GSM_GetModel(StateMachine_val(s), val);
  CAMLreturn(caml_copy_string(val));
}

CAMLprim
value gammu_caml_GetModelInfo(value s)
{
  CAMLparam1(s);
  GSM_PhoneModel *phone_model = GSM_GetModelInfo(StateMachine_val(s));
  CAMLreturn(Val_PhoneModel(*phone_model));
}

CAMLprim
value gammu_caml_GetNetworkInfo(value s)
{
  CAMLparam1(s);
  GSM_NetworkInfo *netinfo;
  GSM_GetNetworkInfo(StateMachine_val(s), netinfo);
  CAMLreturn(Val_NetworkInfo(*netinfo));
}

CAMLprim
value gammu_caml_GetProductCode(value s)
{
  CAMLparam1(s);
  char *val;
  GSM_GetProductCode(StateMachine_val(s), val);
  CAMLreturn(caml_copy_string(val));
}

CAMLprim
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

CAMLprim
value gammu_caml_CheckDate(value date)
{
  CAMLparam1(date);
  bool date_ok = CheckDate(&DateTime_val(date));
  CAMLreturn(Val_bool(date_ok));
}

CAMLprim
value gammu_caml_CheckTime(value date)
{
  CAMLparam1(date);
  const bool time_ok = CheckTime(&DateTime_val(date));
  CAMLreturn(Val_bool(time_ok));
}

CAMLprim
value gammu_caml_OSDate(value dt)
{
  CAMLparam1(dt);
  const char *os_date = OSDate(DateTime_val(dt));
  CAMLreturn(caml_copy_string(os_date));
}

CAMLprim
value gammu_caml_OSDateTime(value dt, value timezone)
{
  CAMLparam2(dt, timezone);
  const char *os_date_time = OSDateTime(DateTime_val(dt), Bool_val(timezone));
  CAMLreturn(caml_copy_string(os_date_time));
}





