import cachy

pub fn main() -> Nil {
  let c: cachy.Cache(String, String) =
    cachy.new()
    |> cachy.insert("hello", "world")
    |> cachy.insert("world", "hello")
    |> cachy.insert("wow", "things")
  let maybe_v = cachy.get(c, "nej")
  case maybe_v {
    Ok(v) -> echo v
    Error(_) -> echo "not found"
  }
  Nil
}
