import commands
import gleam/io
import gleam/option.{None, Some}
import gleam/result
import gleam/string
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
    commands.Cwd -> "Cwd"
    commands.Cat -> "Cat"
    commands.Idk -> "Unknown command"
  }
}

pub fn main() -> Nil {
  let _ =
    sh.Shell("~", None)
    |> run
  Nil
}

fn run(shell: sh.Shell) -> Result(Nil, commands.Error) {
  let res = gell(shell)
  case res {
    Ok(#(s, args)) -> {
      case sh.last(s) {
        Some(p) -> {
          cmd_to_str(p) |> io.println
          case p {
            commands.Exit -> {
              "Goodbye" |> io.println
              Ok(Nil)
            }
            commands.Cd -> {
              case commands.cd(sh.cwd(s), args) {
                Ok(path) -> run(sh.Shell(cwd: path, last: Some(commands.Cd)))
                Error(code) -> Error(code)
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
  io.println("> " <> sh.cwd(shell))
  let maybe_shell =
    in.read_line()
    |> result.map_error(fn(_err) { "Problem getting line from input" })
    |> result.try(fn(line) {
      parse_cmd(line)
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

fn parse_cmd(line: String) -> Result(#(commands.Command, String), Nil) {
  let cmd = string.split(line, " ")
  let cmd = case cmd {
    [] -> #("", "")
    [program, ..args] -> #(string.trim(program), string.join(args, " "))
  }
  case cmd {
    #(program, args) -> {
      case program {
        "exit" -> Ok(#(commands.Exit, args))
        "cd" -> Ok(#(commands.Cd, args))
        "ls" -> Ok(#(commands.Ls, args))
        "cwd" -> Ok(#(commands.Cwd, args))
        "cat" -> Ok(#(commands.Cat, args))
        _ -> Ok(#(commands.Idk, args))
      }
    }
  }
}
