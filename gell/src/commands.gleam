import gleam.{Error}
import gleam/io
import gleam/option.{type Option}
import gleam/string
import simplifile

pub type Command {
  Exit
  Cd
  Ls
  Cwd
  Cat
  Idk
}

pub type ErrorCode {
  ErrorCode(code: Option(String), msg: String)
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
