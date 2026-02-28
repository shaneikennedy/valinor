import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import in

// gell just needs to return state and we need to decide how to shut down (exit, crtl+d, ctrl+c)
// how to decide if we exit State objects with cwd and last command? parse last command in the main function and exit on
// exit commands?

type Command {
  Exit
  Cd
  Ls
  Cwd
  Cat
  Idk
}

fn cmd_to_str(c: Command) -> String {
  case c {
    Exit -> "Exit"
    Cd -> "Cd"
    Ls -> "Ls"
    Cwd -> "Cwd"
    Cat -> "Cat"
    Idk -> "Unknown command"
  }
}

type Shell {
  Shell(cwd: String, last: Option(Command))
}

pub fn main() -> Nil {
  let _ =
    Shell("~", None)
    |> run()
}

fn run(shell: Shell) -> Nil {
  let res = gell(shell)
  case res {
    Ok(s) -> {
      case s.last {
        Some(p) -> {
          cmd_to_str(p) |> io.println
          case p {
            Exit -> {
              "Goodbye" |> io.println
              Nil
            }
            _ -> run(s)
          }
        }
        None -> run(s)
      }
    }
    Error(e) -> {
      e |> io.println
      Nil
    }
  }
}

// Get the current line, do something, return updated state
// every command is "program ...args"
fn gell(shell: Shell) -> Result(Shell, String) {
  "> " |> io.print
  let maybe_shell =
    in.read_line()
    |> result.map_error(fn(_err) { "Problem getting line from input" })
    |> result.try(fn(line) {
      parse_cmd(line)
      |> result.map_error(fn(_err) { "problem getting cmd" })
    })
  case maybe_shell {
    Ok(#(program, _)) -> Ok(Shell(shell.cwd, last: Some(program)))
    Error(_) -> {
      Error("Unable to get a result from gell")
    }
  }
}

fn parse_cmd(line: String) -> Result(#(Command, String), Nil) {
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
        "cwd" -> Ok(#(Cwd, args))
        "cat" -> Ok(#(Cat, args))
        _ -> Ok(#(Idk, args))
      }
    }
  }
}
