(* Simple demo/test file that prints some informations and the first sms. *)
open Gammu
open Args_demo
open Utils_tests
open Printf

let print_multi_sms multi_sms =
  let sms = multi_sms.(0) in
  print_string "==SMS==\n";
  printf "Folder: %d\n" sms.SMS.folder;
  (* TODO: rename location to message_number *)
  printf "Message_number: %d\n" sms.SMS.location;
  printf "Is in inbox: %B\n" sms.SMS.inbox_folder;
  printf "Number: %s\n" sms.SMS.number;
  printf "Date and time: %s\n" (DateTime.os_date_time sms.SMS.date_time);
  printf "Status : %s\n" (string_of_sms_status sms.SMS.state);
  if sms.SMS.udh_header.SMS.udh = SMS.No_udh then
    (* There's no udh so text is raw in the sms message. *)
    printf "%s" sms.SMS.text
  else begin
    (* There's an udh so we have to decode the sms. *)
    let multi_info = SMS.decode_multipart multi_sms in
    Array.iter (fun info -> print_string info.SMS.buffer) multi_info.SMS.entries
  end;
  printf "\n%!"

let () =
  parse_args ();
  let s = make () in
  configure s;
  prepare_phone s;
  print_string "Start reading from folder: ";
  let folder = int_of_string (read_line ()) in
  let begin_time = Unix.gettimeofday () in
  let c =
    try
      SMS.fold s ~folder
        ~on_err:(fun loc e ->
          printf "Failed to get SMS next to location %i: %s\n%!"
            loc (string_of_error e);
          Unix.sleep 1)
        (fun c m -> print_multi_sms m; c + 1) 0;
    with
    | Error NOTSUPPORTED ->
      failwith "Sorry but your phone doesn't support GetNext"
    | Error NOTIMPLEMENTED ->
      failwith "Sorry but GetNext is not implemented."
  in
  let elapsed_time = Unix.gettimeofday () -. begin_time in
  printf "\n%i message(s) read in %fsecs\n" c elapsed_time
(* TODO: add trap to disconnect *)

