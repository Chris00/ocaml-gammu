(* File: gammu.ml

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     Noémie Meunier <Noemie.Meunier@student.umons.ac.be>
     Pierre Hauweele <Pierre.Hauweele@student.umons.ac.be>

     WWW: http://math.umons.ac.be/an/software/

   This library is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details. *)

(* Initialize the C library *)
external c_init : unit -> unit = "caml_gammu_init"
let () = c_init ()


(************************************************************************)
(* Error handling *)

(* WARNING: Keep the order in sync with gammu-error.h *)
type error =
  | DEVICEOPENERROR     (** Error during opening device *)
  | DEVICELOCKED        (** Device locked *)
  | DEVICENOTEXIST      (** Device does not exits *)
  | DEVICEBUSY          (** Device is busy *)
  | DEVICENOPERMISSION  (** No permissions to open device *)
  | DEVICENODRIVER      (** No driver installed for a device *)
  | DEVICENOTWORK       (** Device doesn't seem to be working *)
  | DEVICEDTRRTSERROR   (** Error during setting DTR/RTS in device *)
  | DEVICECHANGESPEEDERROR (** Error during changing speed in device *)
  | DEVICEWRITEERROR    (** Error during writing device *)
  | DEVICEREADERROR     (** Error during reading device *)
  | DEVICEPARITYERROR   (** Can't set parity on device *)
  | TIMEOUT             (** Command timed out *)
  | FRAMENOTREQUESTED   (** Frame handled, but not requested in this moment *)
  | UNKNOWNRESPONSE     (** Response not handled by gammu *)
  | UNKNOWNFRAME        (** Frame not handled by gammu *)
  | UNKNOWNCONNECTIONTYPESTRING (** Unknown connection type given by user *)
  | UNKNOWNMODELSTRING  (** Unknown model given by user *)
  | SOURCENOTAVAILABLE  (** Some functions not compiled in your OS *)
  | NOTSUPPORTED        (** Not supported by phone *)
  | EMPTY               (** Empty entry or transfer end. *)
  | SECURITYERROR       (** Not allowed *)
  | INVALIDLOCATION     (** Too high or too low location... *)
  | NOTIMPLEMENTED      (** Function not implemented *)
  | FULL                (** Memory is full *)
  | UNKNOWN             (** Unknown response from phone *)
  | CANTOPENFILE        (** Error during opening file *)
  | MOREMEMORY          (** More memory required *)
  | PERMISSION          (** No permission *)
  | EMPTYSMSC           (** SMSC number is empty *)
  | INSIDEPHONEMENU     (** Inside phone menu - can't make something *)
  | NOTCONNECTED        (** Phone NOT connected - can't make something *)
  | WORKINPROGRESS      (** Work in progress *)
  | PHONEOFF            (** Phone is disabled and connected to charger *)
  | FILENOTSUPPORTED    (** File format not supported by Gammu *)
  | BUG                 (** Found bug in implementation or phone *)
  | CANCELED            (** Action was canceled by user *)
  | NEEDANOTHERANSWER   (** Inside Gammu: phone module need to send
                            another answer frame *)
  | OTHERCONNECTIONREQUIRED (** You need other connection for
                                this operation. *)
  | WRONGCRC            (** Wrong CRC *)
  | INVALIDDATETIME     (** Invalid date/time *)
  | MEMORY              (** Phone memory error, maybe it is read only *)
  | INVALIDDATA         (** Invalid data given to phone *)
  | FILEALREADYEXIST    (** File with specified name already exist *)
  | FILENOTEXIST        (** File with specified name doesn't exist *)
  | SHOULDBEFOLDER      (** You have to give folder (not file) name *)
  | SHOULDBEFILE        (** You have to give file (not folder) name *)
  | NOSIM               (** Can not access SIM card *)
  | GNAPPLETWRONG       (** Invalid gnapplet version *)
  | FOLDERPART          (** Only part of folders listed *)
  | FOLDERNOTEMPTY      (** Folder is not empty *)
  | DATACONVERTED       (** Data were converted *)
  | UNCONFIGURED        (** Gammu is not configured. *)
  | WRONGFOLDER         (** Wrong folder selected (eg. for SMS). *)
  | PHONE_INTERNAL      (** Internal phone error (phone got crazy). *)
  | WRITING_FILE        (** Could not write to a file (on local filesystem). *)
  | NONE_SECTION        (** No such section exists. *)
  | USING_DEFAULTS      (** Using default values. *)
  | CORRUPTED           (** Corrupted data returned by phone. *)
  | BADFEATURE          (** Bad feature string. *)
  | DISABLED            (** Some functions not compiled in your OS *)
  | SPECIFYCHANNEL      (** Bluetooth configuration requires channel option. *)
  | NOTRUNNING          (** Service is not runnig. *)
  | NOSERVICE           (** Service setup is missing. *)
  | BUSY                (** Command failed. Try again. *)
  | COULDNT_CONNECT     (** Can not connect to server. *)
  | COULDNT_RESOLVE     (** Can not resolve host name. *)
  | GETTING_SMSC        (** Failed to get SMSC number from phone. *)
  (* Errors specific to the Caml bindings (not present in Gammu): *)
  | INI_KEY_NOT_FOUND   (** Pair section/value not found in INI file. *)
  | COULD_NOT_DECODE    (** Decoding SMS Message failed. *)
  | INVALID_CONFIG_NUM  (** Invalid config number. *)

external string_of_error : error -> string = "caml_gammu_GSM_ErrorString"

exception Error of error

let () = Callback.register_exception "Gammu.GSM_Error" (Error DEVICEOPENERROR)


(************************************************************************)
(* Debugging handling *)

module Debug =
struct

  type info

  external get_global : unit -> info = "caml_gammu_GSM_GetGlobalDebug"

  let global = get_global ()

  external set_global : info -> bool -> unit
    = "caml_gammu_GSM_SetDebugGlobal"

  external set_output : info -> out_channel -> unit
    = "caml_gammu_GSM_SetDebugFileDescriptor"

  external set_level : info -> string -> unit
    = "caml_gammu_GSM_SetDebugLevel"

end


(************************************************************************)
(* State machine types *)

type t

type config = {
  model : string;
  debug_level : string;
  device : string;
  connection : string;
  sync_time : bool;
  lock_device : bool;
  debug_file : string;
  start_info : bool;
  use_global_debug_file : bool;
  text_reminder : string;
  text_meeting : string;
  text_call : string;
  text_birthday : string;
  text_memo : string;
}

type connection_type =
  | BUS2
  | FBUS2
  | FBUS2DLR3
  | DKU2AT
  | DKU2PHONET
  | DKU5FBUS2
  | ARK3116FBUS2
  | FBUS2PL2303
  | FBUS2BLUE
  | FBUS2IRDA
  | PHONETBLUE
  | AT
  | BLUEGNAPBUS
  | IRDAOBEX
  | IRDAGNAPBUS
  | IRDAAT
  | IRDAPHONET
  | BLUEFBUS2
  | BLUEAT
  | BLUEPHONET
  | BLUEOBEX
  | FBUS2USB
  | NONE


(************************************************************************)
(* INI files *)

module INI =
struct
  type entry
  type section_node
  type sections = {
    head : section_node;
    unicode : bool;
  }

  external _read : string -> bool -> section_node = "caml_gammu_INI_ReadFile"
  let read ?(unicode=false) file_name =
    { head = _read file_name unicode;
      unicode = unicode; }

  external _find_gammurc_force : string -> section_node
    = "caml_gammu_GSM_FindGammuRC_force"
  external _find_gammurc : unit -> section_node = "caml_gammu_GSM_FindGammuRC"
  let ini_of_gammurc ?path () =
    let s_node = match path with
      | None -> _find_gammurc ()
      | Some path -> _find_gammurc_force path
    in
    (* TODO: Check if can set a better unicode flag. *)
    { head = s_node; unicode=false; }

  external _config_of_ini : section_node -> int -> config
    = "caml_gammu_GSM_ReadConfig"

  let config_of_ini cfg_info num =
    _config_of_ini cfg_info.head num

  external _get_value : section_node -> string -> string -> bool -> string
    = "caml_gammu_INI_GetValue"
  let get_value file_info ~section ~key =
    _get_value file_info.head section key file_info.unicode

end


(************************************************************************)
(* State machine *)

external get_debug : t -> Debug.info = "caml_gammu_GSM_GetDebug"

external _init_locales : string -> unit = "caml_gammu_GSM_InitLocales"
external _init_default_locales : unit -> unit
  = "caml_gammu_GSM_InitDefaultLocales"
let init_locales ?path () = match path with
  | None -> _init_default_locales ()
  | Some path -> _init_locales path

external make : unit -> t = "caml_gammu_GSM_AllocStateMachine"

external get_config : t -> int -> config = "caml_gammu_GSM_GetConfig"

external push_config : t -> config -> unit = "caml_gammu_push_config"

external remove_config : t -> config = "caml_gammu_remove_config"

external length_config : t -> int = "caml_gammu_GSM_GetConfigNum"

let load_gammurc ?path ?(section=0) s =
  let ini = INI.ini_of_gammurc ?path () in
  let cfg = INI.config_of_ini ini section in
  push_config s cfg

external _connect : t -> int -> unit= "caml_gammu_GSM_InitConnection"
external _connect_log : t -> int -> (string -> unit) -> unit
  = "caml_gammu_GSM_InitConnection_Log"

let connect ?log ?(replies=3) s = match log with
  | None -> _connect s replies
  | Some log_func -> _connect_log s replies log_func

external disconnect : t -> unit = "caml_gammu_GSM_TerminateConnection"

external is_connected : t -> bool = "caml_gammu_GSM_IsConnected"

external get_used_connection : t -> connection_type =
  "caml_gammu_GSM_GetUsedConnection"

external _read_device : t -> bool -> int = "caml_gammu_GSM_ReadDevice"
let read_device ?(wait_for_reply=true) s =
  _read_device s wait_for_reply


(************************************************************************)
(* Security related operations with phone *)

type security_code_type =
  | SEC_SecurityCode
  | SEC_Pin
  | SEC_Pin2
  | SEC_Puk
  | SEC_Puk2
  | SEC_None
  | SEC_Phone
  | SEC_Network

external _enter_security_code : t -> security_code_type -> string -> unit =
  "caml_gammu_GSM_EnterSecurityCode"

let enter_security_code s ~code_type ~code =
  _enter_security_code s code_type code

external get_security_status : t -> security_code_type =
  "caml_gammu_GSM_GetSecurityStatus"


(************************************************************************)
(* Informations on the phone *)
module Info =
struct
  type battery_charge = {
    battery_type : battery_type;
    battery_capacity : int;
    battery_percent : int;
    charge_state : charge_state;
    battery_voltage : int;
    charge_voltage : int;
    charge_current : int;
    phone_current : int;
    battery_temperature : int;
    phone_temperature : int;
  }
  and charge_state =
    | BatteryPowered
    | BatteryConnected
    | BatteryCharging
    | BatteryNotConnected
    | BatteryFull
    | PowerFault
  and battery_type =
    | Unknown_battery
    | NiMH
    | LiIon
    | LiPol

  type firmware = {
    version : string;
    ver_date : string;
    ver_num : float;
  }

  type phone_model = {
    model : string;
    number : string;
    irda : string;
  (* features : feature list; *)
  }

  type network = {
    cid : string;
    code : string;
    state : network_state;
    lac : string;
    name : string;
    gprs : gprs_state;
    packet_cid : string;
    packet_state : network_state;
    packet_lac : string;
  }
  and gprs_state =
    | Detached
    | Attached
    | Unknown_gprs
  and network_state =
    | HomeNetwork
    | NoNetwork
    | RoamingNetwork
    | RegistrationDenied
    | Unknown_network
    | RequestingNetwork

  type signal_quality = {
    signal_strength : int;
    signal_percent : int;
    bit_error_rate : int;
  }

  external network_code_name : string -> string
    = "caml_gammu_GSM_GetNetworkName"

  external country_code_name : string -> string
    = "caml_gammu_GSM_GetCountryName"

  external battery_charge : t -> battery_charge
    = "caml_gammu_GSM_GetBatteryCharge"

  external firmware : t -> firmware = "caml_gammu_GSM_GetFirmWare"

  external hardware : t -> string = "caml_gammu_GSM_GetHardware"

  external imei : t -> string = "caml_gammu_GSM_GetIMEI"

  external manufacture_month : t -> string
    = "caml_gammu_GSM_GetManufactureMonth"

  external manufacturer : t -> string = "caml_gammu_GSM_GetManufacturer"

  external model : t -> string = "caml_gammu_GSM_GetModel"

  external model_info : t -> phone_model = "caml_gammu_GSM_GetModelInfo"

  external network_info : t -> network = "caml_gammu_GSM_GetNetworkInfo"

  external product_code : t -> string = "caml_gammu_GSM_GetProductCode"

  external signal_quality : t -> signal_quality
    = "caml_gammu_GSM_GetSignalQuality"

end


(************************************************************************)
(* Date and time *)

module DateTime =
struct

  type t = {
    timezone : int;
    second : int;
    minute : int;
    hour : int;
    day : int;
    month : int;
    year : int;
  }

  let compare d1 d2 =
    (* Rough integer representation of the GMT date and time. *)
    let int_of_date d =
      d.year * 32140800 + d.month * 2678400 + d.day * 86400
      + d.hour * 3600 + d.minute * 60 + d.second
      - d.timezone
    in
    compare (int_of_date d1) (int_of_date d2)

  external check_date : t -> bool = "caml_gammu_GSM_CheckDate"

  external check_time : t -> bool = "caml_gammu_GSM_CheckTime"

  external os_date : t -> string = "caml_gammu_GSM_OSDate"

  external _os_date_time : t -> bool -> string = "caml_gammu_GSM_OSDateTime"

  let os_date_time ?(timezone=false) dt = _os_date_time dt timezone

end


(************************************************************************)
(* Memory *)

type memory_type =
  | ME (** Internal memory of the mobile equipment *)
  | SM (** SIM card memory *)
  | ON (** Own numbers *)
  | DC (** Dialled calls *)
  | RC (** Received calls *)
  | MC (** Missed calls *)
  | MT (** Combined ME and SIM phonebook *)
  | FD (** Fixed dial *)
  | VM (** Voice mailbox *)
  | SL (** Sent SMS logs *)
  | QD (** Quick dialing choices *)

type memory_entry = {
  memory_type : memory_type; (** Used memory for phonebook entry. *)
  location : int; (** Used location for phonebook entry. *)
  entries : sub_memory_entry array; (** Values of SubEntries. *)
}
and sub_memory_entry = {
  entry_type : entry_type; (** Type of entry. *)
  date : DateTime.t;
  number : int; (** Number of entry (if applicable, see {!entry_type}). *)
  voice_tag : int; (** Voice dialling tag. *)
  sms_list : int array;
  call_length : int;
  add_error : error; (** During adding SubEntry Gammu can return here info,
                         if it was done OK. *)
  text : string; (** Text of entry
                     (if applicable, see {!entry_type}). *)
  (* picture : binary_picture (* NYI Picture data. *) *)
}
and entry_type =
  | Number_General (** General number. (Text) *)
  | Number_Mobile (** Mobile number. (Text) *)
  | Number_Work (** Work number. (Text) *)
  | Number_Fax (** Fax number. (Text) *)
  | Number_Home (** Home number. (Text) *)
  | Number_Pager (** Pager number. (Text) *)
  | Number_Other (** Other number. (Text) *)
  | Text_Note (** Note. (Text) *)
  | Text_Postal (** Complete postal address. (Text) *)
  | Text_Email (** Email. (Text) *)
  | Text_Email2
  | Text_URL (** URL (Text) *)
  | Date (** Date and time of last call. (Date) *)
  | Caller_Group (** Caller group. (Number) *)
  | Text_Name (** Name (Text) *)
  | Text_LastName (** Last name. (Text) *)
  | Text_FirstName (** First name. (Text) *)
  | Text_Company (** Company. (Text) *)
  | Text_JobTitle (** Job title. (Text) *)
  | Category (** Category. (Number, if -1 then text) *)
  | Private (** Whether entry is private. (Number) *)
  | Text_StreetAddress (** Street address. (Text) *)
  | Text_City (** City. (Text) *)
  | Text_State (** State. (Text) *)
  | Text_Zip (** Zip code. (Text) *)
  | Text_Country (** Country. (Text) *)
  | Text_Custom1 (** Custom information 1. (Text) *)
  | Text_Custom2 (** Custom information 2. (Text) *)
  | Text_Custom3 (** Custom information 3. (Text) *)
  | Text_Custom4 (** Custom information 4. (Text) *)
  | RingtoneID (** Ringtone ID. (Number) *)
  | PictureID (** Picture ID. (Number) *)
  | Text_UserID (** User ID. (Text) *)
  | CallLength (** Length of call (Number) *)
  | Text_LUID (** LUID - Unique Identifier used for synchronisation (Text) *)
  | LastModified (** Date of last modification (Date) *)
  | Text_NickName (** Nick name (Text) *)
  | Text_FormalName (** Formal name (Text) *)
  | Text_WorkStreetAddress (** Work street address. (Text) *)
  | Text_WorkCity (** Work city. (Text) *)
  | Text_WorkState (** Work state. (Text) *)
  | Text_WorkZip (** Work zip code. (Text) *)
  | Text_WorkCountry (** Work country. (Text) *)
  | Text_WorkPostal (** Complete work postal address. (Text) *)
  | Text_PictureName (** Picture name (on phone filesystem). (Text) *)
  | PushToTalkID (** Push-to-talk ID (Text) *)
  | Number_Messaging (** Favorite messaging number. (Text) *)
  | Photo (** Photo (Picture). *)
  | Number_Mobile_Home (** Home mobile number. (Text) *)
  | Number_Mobile_Work (** Work mobile number. (Text) *)


(************************************************************************)
(* Messages *)

module SMS =
struct

  type format = Pager | Fax | Email | Text

  type validity_period = Hour_1 | Hour_6 | Day_1 | Day_3 | Week | Max_time

  type state = Sent | Unsent | Read | Unread

  type udh =
    | No_udh
    | ConcatenatedMessages
    | ConcatenatedMessages16bit
    | DisableVoice
    | DisableFax
    | DisableEmail
    | EnableVoice
    | EnableFax
    | EnableEmail
    | VoidSMS
    | NokiaRingtone
    | NokiaRingtoneLong
    | NokiaOperatorLogo
    | NokiaOperatorLogoLong
    | NokiaCallerLogo
    | NokiaWAP
    | NokiaWAPLong
    | NokiaCalendarLong
    | NokiaProfileLong
    | NokiaPhonebookLong
    | UserUDH
    | MMSIndicatorLong
  and udh_header = {
    udh : udh;
    udh_text : string;
    id8bit : int;
    id16bit : int;
    part_number : int;
    all_parts : int;
  }

  type message_type =
    | Deliver
    | Status_Report
    | Submit

  type coding =
    | Unicode_No_Compression
    | Unicode_Compression
    | Default_No_Compression
    | Default_Compression
    | Eight_bit

  type message = {
    replace : char;
    reject_duplicates : bool;
    udh_header : udh_header;
    number : string;
    other_numbers : string array;
    (* smsc : smsc; (* NYI *) *)
    memory : memory_type;
    location : int;
    folder : int;
    inbox_folder : bool;
    state : state;
    nokia_name : string;
    text : string;
    pdu : message_type;
    coding : coding;
    date_time : DateTime.t;
    smsc_time : DateTime.t;
    delivery_status : char;
    reply_via_same_smsc : bool;
    sms_class : char;
    message_reference : char;
  }

  type multi_sms = message array

  external _get : t -> int -> int -> multi_sms =
    "caml_gammu_GSM_GetSMS"
  let get s ~folder ~message_number =
    _get s message_number folder

  external _get_next : t -> int -> int -> bool ->
    multi_sms = "caml_gammu_GSM_GetNextSMS"
  let fold s ?(folder=0) ?(for_n=(-1))
      ?(retries=2) ?(on_err=(fun _ _ -> ())) f a =
    let rec aux retries_num location acc = function
      | 0 -> acc
      | for_n ->
        try
          let multi_sms =
            match location with
            | -1 -> (* Start from the beginning of the folder. *)
              _get_next s 0 folder true
            | loc -> (* Get next location, folder need to be 0 because the
                        location carries the folder in its representation. *)
              _get_next s loc 0 false
          in
          aux 0 multi_sms.(0).location (f acc multi_sms) (for_n - 1)
        with Error EMPTY -> acc (* There's no next SMS message *)
        | Error e when e = UNKNOWN || e = CORRUPTED ->
          on_err location e;
          if retries_num = retries then
            (* Continue with next message. *)
            aux 0 (location + 1) acc for_n
          else
            (* Retry retrieval. *)
            aux (retries_num + 1) location acc for_n;
    in
    aux 0 (-1) a for_n

  external set : t -> message -> int * int = "caml_gammu_GSM_SetSMS"

  external add : t -> message -> int * int = "caml_gammu_GSM_AddSMS"

  type folder = {
    box : folder_box;
    folder_memory : memory_type;
    name : string;
  }
  and folder_box = Inbox | Outbox

  external folders : t -> folder array = "caml_gammu_GSM_GetSMSFolders"

  type memory_status = {
    sim_unread : int;
    sim_used : int;
    sim_size : int;
    templates_used : int;
    phone_unread : int;
    phone_used : int;
    phone_size : int;
  }

  external get_status : t -> memory_status = "caml_gammu_GSM_GetSMSStatus"

  external set_incoming_sms : t -> bool -> unit = "caml_gammu_GSM_SetIncomingSMS"

  external _delete : t -> int -> int -> unit = "caml_gammu_GSM_DeleteSMS"
  let delete s ~folder ~message_number =
    _delete s message_number folder

  type multipart_info = {
    unicode_coding : bool;
    info_class : int;
    replace_message : char;
    unknown : bool;
    entries : info array;
  }
  and info = {
    id : encode_part_type_id;
    nbr : int;
    (* TODO: use <encode_part_type_id> of ... as [id] and handle the following
       fields used by the [id] type. *)
    (* ringtone : ringtone; (* NYI *)
       bitmap : multi_bitmap; (* NYI *)
       bookmark : wap_bookmark; (* NYI *)
       settings : wap_settings; (* NYI *)
       mms_indicator : mms_indicator; (* NYI *)
       phonebook : memory_entry; *)
    (* calendar : calendar_entry; (* NYI *)
       todo : todo_entry; (* NYI *)
       file : file; (* NYI *) *)
    protected : bool;
    buffer : string;
    (* TODO:?? use a variant type for alignment ? *)
    left : bool;
    right : bool;
    center : bool;
    large : bool;
    small : bool;
    bold : bool;
    italic : bool;
    underlined : bool;
    strikethrough : bool;
    ringtone_notes : int;
  }
  and encode_part_type_id =
    | Text (* of Nothing *)
    | ConcatenatedTextLong (* of Nothing *)
    | ConcatenatedAutoTextLong (* of Nothing *)
    | ConcatenatedTextLong16bit (* of Nothing *)
    | ConcatenatedAutoTextLong16bit (* of Nothing *)
    | NokiaProfileLong (* of multi_bitmap *)
    | NokiaPictureImageLong
    | NokiaScreenSaverLong
    | NokiaRingtone
    | NokiaRingtoneLong
    | NokiaOperatorLogo
    | NokiaOperatorLogoLong
    | NokiaCallerLogo
    | NokiaWAPBookmarkLong
    | NokiaWAPSettingsLong
    | NokiaMMSSettingsLong
    | NokiaVCARD10Long (* of mem_entry (* Phonebook *) *)
    | NokiaVCARD21Long
    | NokiaVCALENDAR10Long
    | NokiaVTODOLong
    | VCARD10Long
    | VCARD21Long
    | DisableVoice
    | DisableFax
    | DisableEmail
    | EnableVoice
    | EnableFax
    | EnableEmail
    | VoidSMS
    | EMSSound10
    | EMSSound12
    | EMSSonyEricssonSound
    | EMSSound10Long
    | EMSSound12Long
    | EMSSonyEricssonSoundLong
    | EMSPredefinedSound
    | EMSPredefinedAnimation
    | EMSAnimation
    | EMSFixedBitmap
    | EMSVariableBitmap
    | EMSVariableBitmapLong
    | MMSIndicatorLong
    | WAPIndicatorLong
    | AlcatelMonoBitmapLong
    | AlcatelMonoAnimationLong
    | AlcatelSMSTemplateName
    | SiemensFile

  external _decode_multipart :
    Debug.info -> multi_sms -> bool -> multipart_info
      = "caml_gammu_GSM_DecodeMultiPartSMS"

  let decode_multipart ?debug ?(ems=true) multp_mess =
    let di = match debug with
      | None -> Debug.global
      | Some s_di -> s_di
    in
    _decode_multipart di multp_mess ems

end


(************************************************************************)
(* Calls *)

module Call =
struct

  type call = {
    status : status;
    call_id : int option;
    number : string;
  }
  and status =
    | Incoming
    | Outgoing
    | Started
    | Ended
    | RemoteEnded of int
    | LocalEnded
    | Established
    | Held
    | Resumed
    | Switched

end


(************************************************************************)
(* Events *)

external enable_incoming_sms : t -> bool -> unit
  = "caml_gammu_GSM_SetIncomingSMS"

external _incoming_sms : t -> (SMS.message -> unit) -> unit
  = "caml_gammu_GSM_SetIncomingSMSCallback"

let incoming_sms ?(enable=true) s f =
  _incoming_sms s f;
  enable_incoming_sms s enable

external enable_incoming_call : t -> bool -> unit
  = "caml_gammu_GSM_SetIncomingCall"

external _incoming_call : t -> (Call.call -> unit) -> unit
  = "caml_gammu_GSM_SetIncomingCallCallback"

let incoming_call ?(enable=true) s f =
  _incoming_call s f;
  enable_incoming_call s enable

