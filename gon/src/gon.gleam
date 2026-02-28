import gleam/int
import gleam/io
import gleam/string
import in

// the game  of nim
pub fn main() -> Nil {
  io.println("Hello from gon!")
  let pile_size = 68
  case game(pile_size, True) {
    True -> io.println("computer wins")
    False -> io.println("human wins")
  }
}

fn game(pile_size: Int, is_cpu: Bool) -> Bool {
  let new_size = turn(pile_size, is_cpu)
  case new_size {
    #(pile, is_cpu) if pile <= 1 -> !is_cpu
    #(pile, is_cpu) -> game(pile, is_cpu)
  }
}

fn turn(pile: Int, is_cpu: Bool) -> #(Int, Bool) {
  case is_cpu {
    True -> {
      io.println(
        "The current pile size is: "
        <> int.to_string(pile)
        <> ", computer's turn",
      )
      case pile {
        n if n > 2 -> #(pile - pile / 2 + 1, !is_cpu)
        _ -> #(1, !is_cpu)
      }
    }
    False -> {
      io.println(
        "The current pile size is: "
        <> int.to_string(pile)
        <> ", please guess a number",
      )
      let input = in.read_line()
      case input {
        Ok(val) -> {
          case int.parse(string.trim(val)) {
            Ok(num) if num > 0 && pile - num >= 2 -> #(pile - num, !is_cpu)
            Ok(_) -> turn(pile, is_cpu)
            Error(_) -> turn(pile, is_cpu)
          }
        }
        Error(_) -> turn(pile, is_cpu)
      }
    }
  }
}
