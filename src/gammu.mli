(** Interface to the gammu library (libGammu) to manage data in your
    cell phone such as contacts, calendar or messages.  *)

type error =
  | DEVICEOPENERROR     (** Error during opening device *)
  | DEVICELOCKED        (** Device locked *)
  | DEVICENOTEXIST      (** Device does not exits *)
  | DEVICEBUSY          (** Device is busy *)
  | DEVICENOPERMISSION  (** No permissions to open device *)
  | DEVICENODRIVER      (** No driver installed for a device *)
  | DEVICENOTWORK       (** Device doesn't seem to be working *)
  | DEVICEDTRRTSERROR   (** Error during setting DTR/RTS in device *)
  | DEVICECHANGESPEEDERROR      (** 10 Error during changing speed in device *)
  | DEVICEWRITEERROR    (** Error during writing device *)
  | DEVICEREADERROR     (** Error during reading device *)
  | DEVICEPARITYERROR   (** Can't set parity on device *)
  | TIMEOUT             (** Command timed out *)
  | FRAMENOTREQUESTED   (** Frame handled, but not requested in this moment *)
  | UNKNOWNRESPONSE     (** Response not handled by gammu *)
  | UNKNOWNFRAME        (** Frame not handled by gammu *)
  | UNKNOWNCONNECTIONTYPESTRING (** Unknown connection type given by user *)
  | UNKNOWNMODELSTRING  (** Unknown model given by user *)
  | SOURCENOTAVAILABLE  (** 20 Some functions not compiled in your OS *)
  | NOTSUPPORTED        (** Not supported by phone *)
  | EMPTY               (** Empty entry or transfer end. *)
  | SECURITYERROR       (** Not allowed *)
  | INVALIDLOCATION     (** Too high or too low location... *)
  | NOTIMPLEMENTED      (** Function not implemented *)
  | FULL                (** Memory is full *)
  | UNKNOWN             (** Unknown response from phone *)
  | CANTOPENFILE        (** Error during opening file *)
  | MOREMEMORY          (** More memory required *)
  | PERMISSION          (** 30 No permission *)
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
  | OTHERCONNECTIONREQUIRED (** 40 You need other connectin for
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
  | GNAPPLETWRONG       (** 50 Invalid gnapplet version *)
  | FOLDERPART          (** Only part of folders listed *)
  | FOLDERNOTEMPTY      (** Folder is not empty *)
  | DATACONVERTED       (** Data were converted *)
  | UNCONFIGURED        (** Gammu is not configured. *)
  | WRONGFOLDER         (** Wrong folder selected (eg. for SMS). *)
  | PHONE_INTERNAL      (** Internal phone error (phone got crazy). *)
  | WRITING_FILE        (** Could not write to a file (on local filesystem). *)
  | NONE_SECTION        (** No such section exists. *)
  | USING_DEFAULTS      (** Using default values. *)
  | CORRUPTED           (** 60 Corrupted data returned by phone. *)
  | BADFEATURE          (** Bad feature string. *)
  | DISABLED            (** Some functions not compiled in your OS *)
  | SPECIFYCHANNEL      (** Bluetooth configuration requires channel option. *)
  | NOTRUNNING          (** Service is not runnig. *)
  | NOSERVICE           (** Service setup is missing. *)
  | BUSY                (** Command failed. Try again. *)
  | COULDNT_CONNECT     (** Can not connect to server. *)
  | COULDNT_RESOLVE     (** Can not resolve host name. *)

val string_of_error : error -> string

exception Error of error
  (** May be raised by any of the functions of this module to indicate
      an error. *)

(************************************************************************)
(** {2 INI files} *)

(* These functions parse ini file and make them available in easily
   accessable manner. *)
module INI : sig
  type entry
  type section

  val get_value : section -> section:string -> key:string -> string
    (** Returns a value of the INI file entry. *)

  val read : ?unicode:bool -> string -> section
    (** [read fname] reads INI data from the file [fname].
        @param unicode Whether file shoul be treated as unicode encoded.

        FIXME: unicode must be stored in section *)
end

(************************************************************************)
(** {2 State machine} *)

type t
  (** Value holding information about phone connection (called a
      "state machine"). *)

(** Configuration of state machine.  *)
type config = {
  model : string;              (* Model from config file  *)
  debug_level : string;        (* Debug level  *)
  device : string;             (* Device name from config file  *)
  connection : string;         (* Connection type as string  *)
  sync_time : bool;            (* Synchronize time on startup?  *)
  lock_device : bool;          (* Lock device ? (Unix)  *)
  debug_file : string;         (* Name of debug file  *)
  start_info : bool;           (* Display something during start ?  *)
  use_global_debug_file : bool; (* Should we use global debug file?  *)
  text_reminder : string;      (* Text for reminder calendar entry category
                                  in local language  *)
  text_meeting : string;       (* Text for meeting calendar entry category
                                  in local language  *)
  text_call : string;          (* Text for call calendar entry category
                                  in local language  *)
  text_birthday : string;      (* Text for birthday calendar entry category
                                  in local language  *)
  text_memo : string;          (* Text for memo calendar entry
                                  category in local language *)
}

val find_gammurc : ?path:string -> unit -> INI.section
  (** Finds and reads gammu configuration file.  The search order
      depends on platform.  On POSIX systems it looks for ~/.gammurc
      and then for /etc/gammurc, on Windows for gammurc in Application
      data folder, then in home and last fallback is in current
      directory.

      @param path force the use of a custom path instead of the
      autodetected one (default: autodetection is performed). *)

val read_config : INI.section -> int -> config

val get_config : t -> int -> config
  (** [get_config s num] gets gammu configuration from state machine
      [s], where [num] is the number of the section to read, [-1] for
      the currently used one. *)


(* maybe a type t should be created by reading a config file, then one
   connects.  config files seem to play the same role as files for
   [open_*] *)
val connect : ?log:(string -> unit) -> reply_num:int -> t

val disconnect : t -> unit

val is_connected : t -> bool

(************************************************************************)
(** {2 Informations on the phone} *)

type battery_charge = {
  percent : int;             (* Signal strength in percent, -1 = unknown  *)
  state : charge_state;      (* Charge state. *)
  battery_voltage : int;     (* Current battery voltage (in mV).  *)
  charge_voltage : int;      (* Voltage from charger (in mV). *)
  charge_current : int;      (* Current from charger (in mA). *)
  phone_current : int;       (* Phone current consumption (in mA). *)
  battery_temperature : int; (* Battery temperature (in degrees Celsius) *)
  phone_temperature : int;   (* Phone temperature (in degrees Celsius)  *)
  battery_capacity : int;    (* Remaining battery capacity (in mAh)  *)
  battery_type : battery_type; (* Battery type  *)
}
and charge_state =
  | BatteryPowered 	(* Powered from battery *)
  | BatteryConnected 	(* Powered from AC, battery connected *)
  | BatteryCharging 	(* Powered from AC, battery is charging *)
  | BatteryNotConnected (* Powered from AC, no battery *)
  | BatteryFull 	(* Powered from AC, battery is fully charged *)
  | PowerFault 		(* Power failure  *)
and battery_type =
  | Unknown 	(* Unknown battery *)
  | NiMH 	(* NiMH battery *)
  | LiIon 	(* Lithium Ion battery *)
  | LiPol 	(* Lithium Polymer battery  *)

val battery_charge : t -> battery_charge
  (** @return information about batery charge and phone charging state. *)

val manufacturer : t -> string

val model : t -> string

val product_code : t -> string

(** Information about signal quality, all these should be -1 when unknown. *)
type signal_quality = {
  signal_strength : int;
  signal_percent : int;  (* Signal strength in percent. *)
  bit_error_rate : int;  (* Bit error rate in percent.  *)
}

val signal_quality : t -> signal_quality

(************************************************************************)
(** {2 Date and time} *)

type date_time = {
  timezone : int; (* The difference between local time and GMT in seconds *)
  second : int;
  minute : int;
  hour : int;
  day : int;
  month : int;    (* January = 1, February = 2, etc. *)
  year : int;     (* Complete year number. Not 03, but 2003. *)
}

val check_date : date_time -> bool
  (** Checks whether date is valid. This does not check time, see
      [check_time] for this. *)

val check_time : date_time -> bool
  (** Checks whether time is valid. This does not check date, see
      [check_date] for this. *)

val os_date : date_time -> string
  (** Converts date from timestamp to string according to OS settings. *)

val os_date_time : ?timezone:bool -> date_time -> string
  (** Converts timestamp to string according to OS settings.
      @param timezone Whether to include time zone. *)

(************************************************************************)
(** {2 Messages} *)

(** SMS messages manipulations.  *)
module SMS : sig

  type format = Pager | Fax | Email | Text
  type validity_period = Hour_1 | Hour_6 | Day_1 | Day_3 | Week | Max_time

  type state = Sent | Unsent | Read | Unread

  type udh =
    | No_udh
    | ConcatenatedMessages 	(** Linked SMS. *)
    | ConcatenatedMessages16bit (** Linked SMS with 16 bit reference. *)
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
    udh : udh;          (** UDH type. *)
    text : string;      (** UDH text. *)
    id8bit : int;       (** 8-bit ID, when required (-1 otherwise). *)
    id16bit : int;      (** 16-bit ID, when required (-1 otherwise). *)
    part_number : int;  (** Number of current part. *)
    all_parts : int;    (** Total number of parts. *)
  }

  type message_type =
    | Deliver           (** SMS in Inbox. *)
    | Status_Report     (** Delivery Report *)
    | Submit            (** SMS for sending or in Outbox  *)

  type coding =
    | Unicode_No_Compression     (** Unicode *)
    | Unicode_Compression
    | Default_No_Compression     (** Default GSM alphabet. *)
    | Default_Compression
    | height_bit                 (** 8-bit.  *)

  (** Defines ID for various phone and SIM memories.  Phone modules
      can translate them to values specific for concrete models.  Two
      letter codes (excluding VM and SL) are from GSM 07.07. *)
  type memory =
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
    | QD (** Quick dialing choices.  *)

  type message = {
    replace_message : char;
    RejectDuplicates : bool;
    udh : udh_header;
    number : string;
    other_numbers : string array;
    smsc : smsc;     (** SMS Center *)
    memory : memory; (** For saved SMS: where exactly it's saved (SIM/phone). *)
    location : int;  (** For saved SMS: location of SMS in memory. *)
    folder : int;    (** For saved SMS: number of folder, where SMS is saved. *)
    inbox_folder : bool; (** For saved SMS: whether SMS is really in Inbox. *)
    state : state;   (** Status (read/unread/...) of SMS message. *)
    name : string;   (** Name in Nokia with SMS memory (6210/7110, etc.)
                         Ignored in other. *)
    text : string;   (** Text for SMS. *)
    pdu : message_type; (** Type of message. *)
    coding : coding; (** Type of coding. *)
    date_time : date_time;
    smsc_time : date_time;
    delivery_status : char; (** In delivery reports: status. *)
    reply_via_same_smsc : bool; (** Indicates whether "Reply via same
                                    center" is set. *)
    sms_class : char; (** SMS class (0 is flash SMS, 1 is normal one). *)
    message_reference : char; (** Message reference. *)
  }

  type multipart_message = message array
    (** Multiple SMS messages, used for Smart Messaging 3.0/EMS. *)

  val get : t -> location:int -> folder:int -> multipart_message
    (** Reads SMS message. *)

  val get_next : ?message:message -> t -> multipart_message
    (** Reads next (or first if [message] is not set) SMS message.
        This might be faster for some phones than using
        {!Gammu.SMS.get} for each message.

        Please note that this command does not mark the message as
        read in phone.  To do so, you have to call {!Gammu.SMS.get}.

        @param message if not provided, start reading from beginning. *)

  type folder = {
    inbox_folder : bool;  (** Whether it is inbox. *)
    outbox_folder : bool; (** Whether it is outbox. *)
    memory : memory;      (** Where exactly it's saved. *)
    name : string;        (** Name of the folder. *)
  }

  val folders : t -> folder array
    (** Returns SMS folders information. *)

  val set_incoming_sms : t -> bool -> unit
    (** Enable/disable notification on incoming SMS. *)

  val delete : t -> message -> unit
    (** Deletes SMS (SMS location and folder must be set). *)



  type multipart_info = {
    unicode_coding : bool;
    info_class : int;
    replace_message : char;
    unknown : bool;
    entries : entry array;
  }
  and entry = {

  }

  val decode_multipart : ?ems:bool -> multipart_message -> multipart_info
    (** Decodes multi part SMS to "readable" format. *)

end
