import gleam/bytes_tree
import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/otp/actor
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import mist

pub fn main() {
  let assert Ok(started) = rate_limiter_start()
  let rate_limiter_subject = started.data

  let assert Ok(_) =
    fn(req) {
      let user_id =
        req
        |> request.get_header("x-user-id")
        |> fn(r) {
          case r {
            Ok(id) -> id
            Error(_) -> "unknown"
          }
        }

      let is_allowed =
        actor.call(rate_limiter_subject, 1000, CheckRateLimit(user_id, _))

      case is_allowed {
        True ->
          response.new(200)
          |> response.set_body(mist.Bytes(bytes_tree.from_string("OK")))
        False ->
          response.new(429)
          |> response.set_body(
            mist.Bytes(bytes_tree.from_string("Rate limited")),
          )
      }
    }
    |> mist.new
    |> mist.port(3000)
    |> mist.start

  process.sleep_forever()
}

pub type Message {
  CheckRateLimit(user_id: String, reply_with: Subject(Bool))
}

pub const name_prefix = "rate_limiter"

// 3 RPM
pub const rate_limit = 3

fn handle_message(
  state: dict.Dict(String, #(List(Timestamp), Timestamp)),
  message: Message,
) -> actor.Next(dict.Dict(String, #(List(Timestamp), Timestamp)), Message) {
  case message {
    CheckRateLimit(user_id, client) -> {
      let res = is_rate_limited(state, user_id)
      process.send(client, !res.1)
      actor.continue(res.0)
    }
  }
}

fn is_rate_limited(
  limits: dict.Dict(String, #(List(Timestamp), Timestamp)),
  user_id: String,
) -> #(dict.Dict(String, #(List(Timestamp), Timestamp)), Bool) {
  let maybe_user = dict.get(limits, user_id)
  let now = timestamp.system_time()
  let user_limits = case maybe_user {
    Ok(#(events, last)) ->
      case
        duration.to_seconds(timestamp.difference(timestamp.system_time(), last))
        >=. 60.0
      {
        // the last time stamp is older than a minute, clear the user-bucket and return false
        True -> #([now], now, False)

        // the last time stamp is less than a minute old, filter for values for the last minute, update bucket, and return true/false depending on cound
        False -> {
          let new_events =
            events
            |> list.filter(fn(t: Timestamp) { less_than_minute_ago(t, now) })
            |> list.append([now])
          case list.length(new_events) > rate_limit {
            True -> #(new_events, now, True)
            False -> #(new_events, now, False)
          }
        }
      }
    // user doesn't exist yet, new entry
    Error(_) -> #([now], now, False)
  }

  #(
    dict.insert(limits, user_id, #(user_limits.0, user_limits.1)),
    user_limits.2,
  )
}

fn less_than_minute_ago(t: Timestamp, now: Timestamp) {
  duration.to_seconds(timestamp.difference(now, t)) <=. 60.0
}

pub fn rate_limiter_start() -> actor.StartResult(Subject(Message)) {
  actor.new(dict.new())
  |> actor.on_message(handle_message)
  |> actor.named(process.new_name(prefix: name_prefix))
  |> actor.start
}
