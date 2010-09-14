open Printf

let parse_args () =
  let gammurc = ref None
  and section = ref 0 in
  let args = [
    ("--gammurc", Arg.String (fun s -> gammurc := Some s),
     "<file> Force gammurc file path (no autodetection).");
    ("--section", Arg.Set_int section,
     "<integer> Section number from gammurc to load.");
  ] in
  let anon _ = raise (Arg.Bad "No anonymous arguments.") in
  Arg.parse (Arg.align args) anon (sprintf "Usage: %s [options]" Sys.argv.(0));
  (!gammurc, !section)

let configure s =
  let path, section = parse_args () in
  (* Not ideal but quick workaround to effectively use debug configuration
     from gammurc. *)
  let ini = Gammu.INI.ini_of_gammurc ?path () in
  let cfg = Gammu.INI.config_of_ini ini section in
  Gammu.push_config s { cfg with Gammu.use_global_debug_file = false }

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
