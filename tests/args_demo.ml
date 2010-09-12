open Printf

let debug_level = ref "nothing"
let connection = ref "at"
let device = ref "/dev/ttyUSB0"
let folder = ref 1

let parse_args () =
  let args = [
    ("--debug", Arg.Set_string debug_level,
     sprintf "<debug_level> Set debug level \
      (e.g \"textall\", defaults to %S)." !debug_level);
    ("--connection", Arg.Set_string connection,
     sprintf "<connection_type> Set connection/protocol type \
	(defaults to %S)." !connection);
    ("--device", Arg.Set_string device,
     sprintf "<device> Set device file (defaults to %S)." !device);
    ("--folder", Arg.Set_int folder,
     sprintf "<connection_type> Set folder location (default = %i)." !folder);
  ] in
  let anon _ = raise (Arg.Bad "No anonymous arguments.") in
  Arg.parse (Arg.align args) anon "Usage:"

let configure s =
  parse_args ();
  (* TODO: debug things seem to be ignored... *)
  let config = {
    Gammu.model = "";
    debug_level = !debug_level;
    device = !device;
    connection = !connection;
    sync_time = false; (* On some phones, year "10" is interpreted as 1910... *)
    lock_device = false;
    debug_file = "";
    start_info = true;
    use_global_debug_file = true;
    text_reminder = "";
    text_meeting = "";
    text_call = "";
    text_birthday = "";
    text_memo = "";
  } in
  let di = Gammu.get_debug s in
  Gammu.Debug.set_global di true;
  Gammu.Debug.set_output Gammu.Debug.global stderr;
  Gammu.Debug.set_level Gammu.Debug.global !debug_level;
  Gammu.push_config s config

(* Connect and unlock phone. *)
let prepare_phone s =
  configure s;
  (* Unlock the phone asking user for codes. *)
  let rec ask_user_code s code_type code_type_name =
    printf "Enter %s code: %!" code_type_name;
    let code = read_line () in
    try
      Gammu.enter_security_code s ~code_type ~code;
      (* Check if there's another security code to enter. *)
      unlock_phone s;
    with Gammu.Error Gammu.SECURITYERROR ->
      printf "Wrong code, retry.\n%!";
      ask_user_code s code_type code_type_name;
  and unlock_phone s =
    let sec_status =
      try Gammu.get_security_status s
      with Gammu.Error Gammu.UNKNOWNRESPONSE -> Gammu.SEC_None
    in
    match sec_status with
    | Gammu.SEC_None -> print_string "SIM/Phone unlocked.\n"
    | Gammu.SEC_SecurityCode as c -> ask_user_code s c "Security"
    | Gammu.SEC_Pin as c -> ask_user_code s c "PIN"
    | Gammu.SEC_Pin2 as c -> ask_user_code s c "PIN2"
    | Gammu.SEC_Puk as c -> ask_user_code s c "PUK"
    | Gammu.SEC_Puk2 as c -> ask_user_code s c "PUK2"
    | Gammu.SEC_Phone as c -> ask_user_code s c "Phone"
    | Gammu.SEC_Network as c -> ask_user_code s c "Network"
  in
  printf "Trying to connect.\n%!";
  Gammu.connect s;
  printf "Phone model : \"%s\"\n" (Gammu.Info.model s);
  printf "Unlock SIM/Phone:\n%!";
  unlock_phone s
