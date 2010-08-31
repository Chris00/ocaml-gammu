(* Simple demo/test file that prints some informations and the first sms. *)
open Gammu
open Args_demo
open Utils_tests

let () =
  parse_args ();
  let s = make () in
  configure s;
  prepare_phone s;
  while true do
    print_string "Enter folder: ";
    let folder = int_of_string (read_line ()) in
    print_string "Enter message number: ";
    let message_number = int_of_string (read_line ()) in
    let multi_sms = SMS.get s ~folder ~message_number in
    print_multi_sms multi_sms;
  done
(* TODO: add trap to disconnect *)

