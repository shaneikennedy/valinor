import gleam.{Error}
import gleam/io
import gleam/list
import gleam/option.{type Option, Some}
import gleam/result
import gleam/string
import shellout
import simplifile

pub type Command {
  Exit
  Cd
  Ls
  Cwd
  Cat
  Idk(String)
}

pub fn parse_cmd(line: String) -> Result(#(Command, String), Nil) {
  let cmd = string.split(line, " ")
  let cmd = case cmd {
    [] -> #("", "")
    [program, ..args] -> #(string.trim(program), string.join(args, " "))
  }
  case cmd {
    #(program, args) -> {
      case program {
        "exit" -> Ok(#(Exit, args))
        "cd" -> Ok(#(Cd, args))
        "ls" -> Ok(#(Ls, args))
        "pwd" -> Ok(#(Cwd, args))
        "cat" -> Ok(#(Cat, args))
        // Return the whole thing for unknown commands
        // we'll eventually make on os call as a fallback
        _ -> Ok(#(Idk(program), args))
      }
    }
  }
}

pub type ErrorCode {
  ErrorCode(code: Option(Int), msg: String)
}

pub fn cd(cwd: String, path: String) -> Result(String, ErrorCode) {
  let dir = cwd <> "/" <> string.trim(path)
  case simplifile.is_directory(dir) {
    Ok(is_dir) ->
      case is_dir {
        True -> Ok(dir)
        False -> Error(ErrorCode(code: option.None, msg: "not a directory"))
      }
    Error(_) ->
      Error(ErrorCode(code: option.None, msg: "unable to check if dir"))
  }
}

pub fn ls(cwd: String, path: String) -> Result(List(String), ErrorCode) {
  let dir = case string.trim(path) {
    "" -> cwd
    _ -> cwd <> "/" <> string.trim(path)
  }
  dir |> io.println
  case simplifile.read_directory(dir) {
    Ok(files) -> Ok(files)
    Error(_) -> Error(ErrorCode(code: option.None, msg: "Unable to list files"))
  }
}

pub fn idk(cwd: String, cmd: String, args: String) -> Result(String, ErrorCode) {
  let clean_args =
    string.split(args, " ")
    |> list.filter(fn(a) { !string.is_empty(a) })
    |> list.map(fn(a) { string.trim(a) })
  shellout.command(run: cmd, with: clean_args, in: cwd, opt: [])
  |> result.map_error(fn(err) { ErrorCode(code: Some(err.0), msg: err.1) })
}
