(* Simple demo/test file that prints some informations and the first sms. *)
open Printf
open Gammu
open Args_demo
open Utils_tests

let print_sms s folder message_number =
  let multi_sms = SMS.get s ~folder ~message_number in
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
  print_newline ()

let () =
  let s = Gammu.make () in
  prepare_phone s;
  while true do
    print_string "Enter folder: ";
    let folder = int_of_string (read_line ()) in
    print_string "Enter message number: ";
    let message_number = int_of_string (read_line ()) in
    print_sms s folder message_number;
  done
(* TODO: add trap to disconnect *)

