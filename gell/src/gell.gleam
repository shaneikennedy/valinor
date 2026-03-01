import commands
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import in
import sh

// gell just needs to return state and we need to decide how to shut down (exit, crtl+d, ctrl+c)
// how to decide if we exit State objects with cwd and last command? parse last command in the main function and exit on
// exit commands?

fn cmd_to_str(c: commands.Command) -> String {
  case c {
    commands.Exit -> "Exit"
    commands.Cd -> "Cd"
    commands.Ls -> "Ls"
    commands.Pwd -> "Cwd"
    commands.Cat -> "Cat"
    commands.Idk(program) -> "Non-native command: " <> program
  }
}

pub fn main() -> Nil {
  let res =
    sh.Shell("/Users/shanekennedy/dev/shane/valinor/gell", None)
    |> run
  case res {
    Ok(_) -> "Goodbye" |> io.println
    Error(code) -> code.msg |> io.println
  }
  Nil
}

fn run(shell: sh.Shell) -> Result(Nil, commands.ErrorCode) {
  let res = gell(shell)
  case res {
    Ok(#(s, args)) -> {
      case sh.last(s) {
        Some(p) -> {
          cmd_to_str(p) |> io.println
          case p {
            commands.Exit -> {
              Ok(Nil)
            }
            commands.Cd -> {
              case commands.cd(sh.cwd(s), args) {
                Ok(path) -> run(sh.Shell(cwd: path, last: Some(commands.Cd)))
                Error(code) -> {
                  code.msg |> io.println
                  run(sh.Shell(cwd: sh.cwd(shell), last: Some(commands.Cd)))
                }
              }
            }
            commands.Ls -> {
              case commands.ls(sh.cwd(s), args) {
                Ok(contents) -> {
                  contents |> list.map(fn(s) { s |> io.println })
                  run(sh.Shell(cwd: sh.cwd(shell), last: Some(commands.Ls)))
                }
                Error(code) -> {
                  code.msg |> io.println
                  run(sh.Shell(cwd: sh.cwd(shell), last: Some(commands.Ls)))
                }
              }
            }
            commands.Idk(program) -> {
              case commands.idk(sh.cwd(s), program, args) {
                Ok(o) -> {
                  o |> io.println
                  run(sh.Shell(
                    cwd: sh.cwd(shell),
                    last: Some(commands.Idk(program)),
                  ))
                }
                Error(code) -> {
                  code.msg |> io.println
                  run(sh.Shell(
                    cwd: sh.cwd(shell),
                    last: Some(commands.Idk(program)),
                  ))
                }
              }
            }
            commands.Pwd -> {
              case commands.pwd(sh.cwd(s)) {
                Ok(pwd) -> {
				  pwd |> io.println
                  run(sh.Shell(cwd: sh.cwd(shell), last: Some(commands.Pwd)))
				}
                Error(code) -> {
				  code.msg |> io.println
                  run(sh.Shell(cwd: sh.cwd(shell), last: Some(commands.Pwd)))
				}
              }
            }
            _ -> run(s)
          }
        }
        None -> run(s)
      }
    }
    Error(e) -> {
      e |> io.println
      Ok(Nil)
    }
  }
}

// Get the current line, do something, return updated state
// every command is "program ...args"
fn gell(shell: sh.Shell) -> Result(#(sh.Shell, String), String) {
  sh.cwd(shell) |> io.println
  "> " |> io.print
  let maybe_shell =
    in.read_line()
    |> result.map_error(fn(_err) { "Problem getting line from input" })
    |> result.try(fn(line) {
      commands.parse_cmd(line)
      |> result.map_error(fn(_err) { "problem getting cmd" })
    })
  case maybe_shell {
    Ok(#(program, args)) ->
      Ok(#(sh.Shell(sh.cwd(shell), last: Some(program)), args))
    Error(_) -> {
      Error("Unable to get a result from gell")
    }
  }
}
