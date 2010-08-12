(* Simple demo/test file that listen for incoming events. *)
open Gammu
open Utils_demo

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
  (* Check for (maybe) non supported operation. Unfortunately, libGammu
     doesn't recognize the CMS error for those function right now. CMS Error
     303 "operation not supported" is translated to Error UNKNOWN. *)
  let warn_not_supported t =
    Printf.printf "Sorry, incoming_%s notifications \
                   aren't supported by your phone." t;
    flush stdout
  in
  begin
    try
      incoming_sms s incoming_sms_callback;
    with
      Error UNKNOWN -> warn_not_supported "sms";
    | Error NOTSUPPORTED -> warn_not_supported "sms";
  end;
  begin
    try
      incoming_call s incoming_call_callback;
    with
      Error UNKNOWN -> warn_not_supported "call";
    | Error NOTSUPPORTED -> warn_not_supported "call";
  end;
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
