import gleam/int
import gleam/list
import gleam/order
import gleam/regex
import gleam/string_builder
import birl/duration

pub opaque type DateTime {
  DateTime(Int)
}

pub type Date {
  Date(year: Int, month: Int, day: Int)
}

pub type Time {
  Time(hour: Int, minute: Int, second: Int)
}

const pattern = "\\d{4}-\\d{1,2}-\\d{1,2}T\\d{1,2}:\\d{1,2}:\\d{1,2}.\\d{3}Z"

pub fn now() {
  ffi_now()
  |> DateTime
}

pub fn to_parts(value: DateTime) -> #(Date, Time) {
  case value {
    DateTime(t) ->
      case ffi_to_parts(t) {
        #(#(year, month, day), #(hour, minute, second)) -> #(
          Date(year, month, day),
          Time(hour, minute, second),
        )
      }
  }
}

pub fn from_parts(date: Date, time: Time) -> DateTime {
  let string_date = case date {
    Date(year, month, day) ->
      [int.to_string(year), int.to_string(month), int.to_string(day)]
      |> list.map(string_builder.from_string)
      |> string_builder.join("-")
  }

  let string_time = case time {
    Time(hour, minute, second) ->
      [int.to_string(hour), int.to_string(minute), int.to_string(second)]
      |> list.map(string_builder.from_string)
      |> string_builder.join(":")
      |> string_builder.append(".000Z")
  }

  case
    string_builder.join([string_date, string_time], "T")
    |> string_builder.to_string
    |> from_iso
  {
    Ok(value) -> value
    Error(Nil) -> DateTime(0)
  }
}

pub fn to_iso(value: DateTime) -> String {
  case value {
    DateTime(t) -> ffi_to_iso(t)
  }
}

pub fn from_iso(value: String) -> Result(DateTime, Nil) {
  case regex.from_string(pattern) {
    Ok(pattern) ->
      case regex.check(pattern, value) {
        True ->
          value
          |> ffi_from_iso
          |> DateTime
          |> Ok
        False -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

pub fn compare(a: DateTime, b: DateTime) {
  let DateTime(dta) = a
  let DateTime(dtb) = b
  case dta == dtb {
    True -> order.Eq
    False ->
      case dta < dtb {
        True -> order.Lt
        False -> order.Gt
      }
  }
}

pub fn difference(a: DateTime, b: DateTime) -> duration.Duration {
  let DateTime(dta) = a
  let DateTime(dtb) = b
  duration.Duration(dtb - dta)
}

pub fn add(value: DateTime, duration: duration.Duration) -> DateTime {
  let DateTime(timestamp) = value
  let duration.Duration(duration) = duration
  DateTime(timestamp + duration)
}

pub fn subtract(value: DateTime, duration: duration.Duration) -> DateTime {
  let DateTime(timestamp) = value
  let duration.Duration(duration) = duration
  DateTime(timestamp - duration)
}

if erlang {
  external fn ffi_now() -> Int =
    "birl_ffi" "now"

  external fn ffi_to_parts(Int) -> #(#(Int, Int, Int), #(Int, Int, Int)) =
    "birl_ffi" "to_parts"

  external fn ffi_to_iso(Int) -> String =
    "birl_ffi" "to_iso"

  external fn ffi_from_iso(String) -> Int =
    "birl_ffi" "from_iso"
}

if javascript {
  external fn ffi_now() -> Int =
    "../birl_ffi.mjs" "now"

  external fn ffi_to_parts(Int) -> #(#(Int, Int, Int), #(Int, Int, Int)) =
    "../birl_ffi.mjs" "to_parts"

  external fn ffi_to_iso(Int) -> String =
    "../birl_ffi.mjs" "to_iso"

  external fn ffi_from_iso(String) -> Int =
    "../birl_ffi.mjs" "from_iso"
}
