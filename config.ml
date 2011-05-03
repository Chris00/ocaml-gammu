(* Post configure script to select the locations of the Gammu C library. *)

(* Unix/Cygwin include and library flags.  Empty means to use the
   output of pkg-config. *)
let unix_cflags = "" (* e.g. "-I/usr/include/gammu" *)
let unix_cclib = ""  (* e.g. "-lGammu -lm" *)

let windows_cflags = "/I\"C:\\Program Files (x86)\\Gammu 1.29.0\\lib\""
let windows_cclib = "Gammu.lib"

;;

(* pkg-config configuration.
 ***********************************************************************)

#load "unix.cma";;
open Printf

let output_of cmd =
  let fh = Unix.open_process_in cmd in
  let s = input_line fh in
  ignore(Unix.close_process_in fh);
  s

let cflags, cclib =
  match Sys.os_type with
  | "Unix" ->
    (if unix_cflags = "" then output_of "pkg-config --cflags gammu"
     else unix_cflags),
    (if unix_cclib = "" then output_of "pkg-config --libs gammu"
     else unix_cclib)
  | "Win32" ->
    (* TODO *)
    windows_cflags, windows_cclib
  | os ->
    printf "Operating system %S not known" os;
    exit 1

let () =
  let fh = open_out_gen [Open_append] 0o666 "setup.data" in
  fprintf fh "gammu_cflags = %S\n" cflags;
  fprintf fh "gammu_libs = %S\n" cclib;
  close_out fh
