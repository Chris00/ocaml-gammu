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
  printf "Date and time: %s\n"
    (DateTime.os_date_time sms.SMS.date_time);
  printf "Status : %s\n" (string_of_sms_status sms.SMS.state);
  if (sms.SMS.udh_header.SMS.udh = SMS.No_udh) then
    (* There's no udh so text is raw in the sms message. *)
    print_string sms.SMS.text
  else begin
    (* There's an udh so we have to decode the sms. *)
    let multi_info = SMS.decode_multipart multi_sms in
    Array.iter (fun info -> print_string info.SMS.buffer) multi_info.SMS.entries
  end;
  print_newline ();
  flush stdout

let rec read_all s ~folder ?message_number () =
  try
    match message_number with
    | None ->
      let multi_sms = SMS.get_next s ~folder () in
      print_multi_sms multi_sms;
      read_all s ~folder:0 ~message_number:(multi_sms.(0).SMS.location) ()
    | Some message_number ->
      let multi_sms = SMS.get_next s ~folder ~message_number () in
      print_multi_sms multi_sms;
      read_all s ~folder:0 ~message_number:(multi_sms.(0).SMS.location) ()
  with
    Error EMPTY -> ()
  | Error NOTSUPPORTED | Error NOTIMPLEMENTED ->
    print_string "Sorry but your phone doesn't support GetNext \
                  or it is not implemented.\n"

let () =
  parse_args ();
  let s = make () in
  configure s;
  prepare_phone s;
  print_string "From folder: ";
  let folder = int_of_string (read_line ()) in
  read_all s ~folder ();
(* TODO: add trap to disconnect *)

