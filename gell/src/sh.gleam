import commands.{type Command}
import gleam/option.{type Option}

pub type Shell {
  Shell(cwd: String, last: Option(Command))
}

pub fn cwd(s: Shell) -> String {
  s.cwd
}

pub fn last(s: Shell) -> Option(Command) {
  s.last
}
