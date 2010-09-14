(* Simple demo/test file that prints some informations and the first sms. *)
open Args_demo
open Utils_tests
open Printf

let read_all s folder =
  let begin_time = Unix.gettimeofday () in
  let c =
    try
      Gammu.SMS.fold s ~folder
        ~on_err:(fun loc e ->
          printf "Failed to get SMS next to location %i: %s\n%!"
            loc (Gammu.string_of_error e);
          Unix.sleep 1)
        (fun c m -> print_multi_sms m; c + 1) 0;
    with
    | Gammu.Error Gammu.NOTSUPPORTED ->
      failwith "Sorry but your phone doesn't support GetNext"
    | Gammu.Error Gammu.NOTIMPLEMENTED ->
      failwith "Sorry but GetNext is not implemented."
  in
  let elapsed_time = Unix.gettimeofday () -. begin_time in
  printf "\n%i message(s) read in %fsecs\n" c elapsed_time

let () =
  try
    let s = Gammu.make () in
    prepare_phone s;
    print_string "Start reading from folder: ";
    let folder = int_of_string (read_line ()) in
    read_all s folder
  with Gammu.Error e -> printf "Error: %s\n" (Gammu.string_of_error e)

