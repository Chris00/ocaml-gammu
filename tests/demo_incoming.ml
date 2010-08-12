(* Simple demo/test file that listen for incoming events. *)
(*#use "topfind";;
  #require "gammu";;*)
open Gammu;;

let debug_level = ref "nothing";;
let connection = ref "at";;
let device = ref "/dev/ttyUSB0";;

let parse_args () =
  let args = [
    ("--debug", Arg.Set_string debug_level,
     "<debug_level>  Set debug level \
      (e.g \"textall\", defaults to \"nothing\").");
    ("--connection", Arg.Set_string connection,
     "<connection_type> Set connection/protocol type (defaults to \"at\").");
    ("--device", Arg.Set_string device,
     "<device> Set device file (defaults to \"/dev/ttyUSB0\").");
  ] in
  let anon _ = raise (Arg.Bad "No anonymous arguments.") in
  Arg.parse args anon "Usage:";;

let configure s =
  (* TODO: debug things seem to be ignored... *)
  let config = {
    model = "";
    debug_level = !debug_level;
    device = !device;
    connection = !connection;
    sync_time = true;
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
  let di = get_debug s in
  Debug.set_global di true;
  Debug.set_output Debug.global stderr;
  Debug.set_level Debug.global !debug_level;
  push_config s config;
  assert (length_config s = 1);;

(* Connect and unlock phone. *)
let prepare_phone s =
  (* Unlock the phone asking user for codes. *)
  let rec ask_user_code s code_type code_type_name =
    print_string ("Enter " ^ code_type_name ^ " code : ");
    flush stdout;
    let code = read_line () in
    try
      enter_security_code s ~code_type ~code;
      (* Check if there's another security code to enter. *)
      unlock_phone s;
    with Error SECURITYERROR ->
      print_string "Wrong code, retry.\n";
      flush stdout;
      ask_user_code s code_type code_type_name;
  and unlock_phone s =
    let sec_status = get_security_status s in
    (match sec_status with
      SEC_None -> print_string "SIM/Phone unlocked.\n"
    | SEC_SecurityCode as c -> ask_user_code s c "Security"
    | SEC_Pin as c -> ask_user_code s c "PIN"
    | SEC_Pin2 as c -> ask_user_code s c "PIN2"
    | SEC_Puk as c -> ask_user_code s c "PUK"
    | SEC_Puk2 as c -> ask_user_code s c "PUK2"
    | SEC_Phone as c -> ask_user_code s c "Phone"
    | SEC_Network as c -> ask_user_code s c "Network")
  in
  print_string "Trying to connect.\n";
  flush stdout;
  connect s;
  print_string ("Phone model : " ^ Info.model s ^ "\n");
  print_string "Unlock SIM/Phone:\n";
  flush stdout;
  unlock_phone s;;

let () =
  parse_args ();
  let s = make () in
  configure s;
  prepare_phone s;
  let incoming_sms_callback sms =
    print_string "\nIncoming SMS !\n";
    Printf.printf "From number: %s\n" sms.SMS.number;
  and incoming_call_callback call =
    print_string "\nIncoming Call !\n";
    Printf.printf "From number: %s\n" call.Call.number;
  in
  incoming_sms s incoming_sms_callback;
  incoming_call s incoming_call_callback;
  print_newline ();
 (* Busy waiting to keep communication with phone *)
  while true do
    let signal = Info.signal_quality s in
    Printf.printf "\rSignal Strength = %i, %i%%"
      signal.Info.signal_strength signal.Info.signal_percent;
    flush(stdout);
    Unix.sleep 1;
  done;;
  (* TODO: Add a trap to disconnect... *)

