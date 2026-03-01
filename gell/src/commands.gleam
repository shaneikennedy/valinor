import gleam/option.{type Option}

pub type Command {
  Exit
  Cd
  Ls
  Cwd
  Cat
  Idk
}

pub type Error {
  Error(code: Option(String))
}

pub fn cd(cwd: String, path: String) -> Result(String, Error) {
  Ok(cwd <> "/" <> path)
}
