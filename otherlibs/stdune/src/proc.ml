(* [execve] doesn't exist on Windows, so instead we do a
   [Unix.create_process_env] followed by [Unix.waitpid] and finally [sys_exit].
   We use [sys_exit] rather than [exit] so that [at_exit] functions are not
   invoked. We don't want [at_exit] functions to be invoked to match the
   behaviour of [Unix.execve] on Unix. *)
external sys_exit : int -> 'a = "caml_sys_exit"

let restore_cwd_and_execve prog argv ~env =
  let env = Env.to_unix env |> Array.of_list in
  let argv = Array.of_list (prog :: argv) in
  (* run at_exit before changing the working directory *)
  Stdlib.do_at_exit ();
  Sys.chdir (Path.External.to_string Path.External.initial_cwd);
  if Sys.win32 || Platform.OS.value = Platform.OS.Haiku
  then (
    let pid = Unix.create_process_env prog argv env Unix.stdin Unix.stdout Unix.stderr in
    match snd (Unix.waitpid [] pid) with
    | WEXITED n -> sys_exit n
    | WSIGNALED _ -> sys_exit 255
    | WSTOPPED _ -> assert false)
  else (
    ignore (Unix.sigprocmask SIG_SETMASK [] : int list);
    Unix.execve prog argv env)
;;

let get_win32_prog_and_args ~env ~dir prog args =
  let get_cmd_and_args prog args =
    let cmd, extra_args =
      try
        (* Check if first 2 chars are shebang *)
        Io.with_file_in ~binary:true prog ~f:(fun ic ->
          if really_input_string ic 2 <> "#!"
          then None, []
          else (
            let line = input_line ic |> String.trim in
            let parts = String.split_on_char ~sep:' ' line in
            match parts with
            | [] -> None, [] (* Empty shebang line *)
            | executable_path :: exe_args ->
              let exe_name = Filename.basename executable_path in
              let exe, extra_args =
                if exe_name <> "env"
                then Some exe_name, exe_args
                else (
                  match exe_args with
                  | [] -> None, [] (* env command with no args *)
                  | name :: cmd_args -> Some name, cmd_args)
              in
              exe, extra_args))
      with
      | Not_found -> None, args
    in
    match cmd with
    | None -> prog, args
    | Some cmd ->
      (* FIXME: Env.initial?  *)
      let path = Option.value env ~default:Env.initial |> Env_path.path in
      (match Bin.which ~path cmd with
       | None -> prog, args
       | Some cmd ->
         let prog_str = Path.reach_for_running ?from:dir prog in
         let args = List.concat [ extra_args; prog_str :: args ] in
         cmd, args)
  in
  (* Check if we are on Windows and change the prog being used if required *)
  if not Sys.win32 then prog, args else get_cmd_and_args prog args
;;

module Resource_usage = struct
  type t =
    { user_cpu_time : float
    ; system_cpu_time : float
    }
end

module Times = struct
  type t =
    { elapsed_time : Time.Span.t
    ; resource_usage : Resource_usage.t option
    }
end

module Process_info = struct
  type t =
    { pid : Pid.t
    ; status : Unix.process_status
    ; end_time : Time.t
    ; resource_usage : Resource_usage.t option
    }
end

external stub_wait4
  :  int
  -> Unix.wait_flag list
  -> int * Unix.process_status * float * Resource_usage.t
  = "dune_wait4"

type wait =
  | Any
  | Pid of Pid.t

let wait wait flags =
  if Sys.win32
  then Code_error.raise "wait4 not available on windows" []
  else (
    let pid =
      match wait with
      | Any -> -1
      | Pid pid -> Pid.to_int pid
    in
    let pid, status, end_time, resource_usage = stub_wait4 pid flags in
    let end_time = Time.of_epoch_secs end_time in
    { Process_info.pid = Pid.of_int pid
    ; status
    ; end_time
    ; resource_usage = Some resource_usage
    })
;;
