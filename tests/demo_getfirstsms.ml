(* Simple demo/test file that prints some informations and the first sms. *)
open Gammu
open Utils_demo

let () =
  parse_args ();
  let s = make () in
  configure s;
  prepare_phone s;
  let multi_sms = SMS.get s ~folder:0 ~message_number:0 in
  let sms = multi_sms.(0) in
  print_string "==SMS==\n";
  Printf.printf "Number: %s\n" sms.SMS.number;
  Printf.printf "Date and time: %s\n"
    (DateTime.os_date_time sms.SMS.date_time);
  Printf.printf "Status : %s\n"
    (match sms.SMS.state with
      SMS.Sent -> "sent";
    | SMS.Unsent -> "unsent";
    | SMS.Read -> "read";
    | SMS.Unread -> "unread");
  print_string "Text : ";
  if (sms.SMS.udh_header.SMS.udh = SMS.No_udh) then
    (* There's no udh so text is raw in the sms message. *)
    print_string sms.SMS.text
  else begin
    (* There's an udh so we have to decode the sms. *)
    let multi_info = SMS.decode_multipart multi_sms in
    Array.iter (fun info -> print_string info.SMS.buffer) multi_info.SMS.entries
  end;
  print_newline ();
  disconnect s;;

