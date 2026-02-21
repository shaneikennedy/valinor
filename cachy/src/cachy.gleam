import gleam/dict

pub opaque type Cache(key, value) {
  Cache(dict: dict.Dict(key, value))
}

pub fn new() -> Cache(key, value) {
  Cache(dict.new())
}

pub fn insert(c: Cache(key, value), k: key, v: value) -> Cache(key, value) {
  let Cache(inner) = c
  Cache(dict.insert(inner, k, v))
}

pub fn remove(c: Cache(key, value), k: key) -> Cache(key, value) {
  let Cache(inner) = c
  Cache(dict.delete(inner, k))
}

pub fn get(c: Cache(key, value), k: key) -> Result(value, Nil) {
  let Cache(inner) = c
  dict.get(inner, k)
}

pub fn size(c: Cache(key, value)) -> Int {
  let Cache(inner) = c
  dict.size(inner)
}
