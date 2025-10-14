import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

// Character sets
const lowercase = "abcdefghijklmnopqrstuvwxyz"

const uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

const digits = "0123456789"

const symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?"

pub type PasswordConfig {
  PasswordConfig(
    length: Int,
    use_lowercase: Bool,
    use_uppercase: Bool,
    use_digits: Bool,
    use_symbols: Bool,
    custom_symbols: Option(String),
  )
}

pub type PasswordStrength {
  Weak
  Medium
  Strong
  VeryStrong
}

pub fn main() {
  io.println("🔐 Secure Password Generator (Gleam)")
  io.println("═════════════════════════════════════")
  io.println("")

  // Example 1: Default strong password
  io.println("Example 1: Default Strong Password (16 chars)")
  let config1 =
    PasswordConfig(
      length: 16,
      use_lowercase: True,
      use_uppercase: True,
      use_digits: True,
      use_symbols: True,
      custom_symbols: None,
    )
  generate_and_display(config1, 3)

  io.println("")

  // Example 2: Long password with custom symbols
  io.println("Example 2: Extra Strong (24 chars, custom symbols)")
  let config2 =
    PasswordConfig(
      length: 24,
      use_lowercase: True,
      use_uppercase: True,
      use_digits: True,
      use_symbols: True,
      custom_symbols: Some("!@#$%&*"),
    )
  generate_and_display(config2, 2)

  io.println("")

  // Example 3: Alphanumeric only
  io.println("Example 3: Alphanumeric Only (12 chars)")
  let config3 =
    PasswordConfig(
      length: 12,
      use_lowercase: True,
      use_uppercase: True,
      use_digits: True,
      use_symbols: False,
      custom_symbols: None,
    )
  generate_and_display(config3, 3)

  io.println("")

  // Example 4: PIN-like (digits only)
  io.println("Example 4: Numeric PIN (8 digits)")
  let config4 =
    PasswordConfig(
      length: 8,
      use_lowercase: False,
      use_uppercase: False,
      use_digits: True,
      use_symbols: False,
      custom_symbols: None,
    )
  generate_and_display(config4, 5)
}

fn generate_and_display(config: PasswordConfig, count: Int) {
  let charset = build_charset(config)

  case string.length(charset) {
    0 -> io.println("❌ Error: No character types selected!")
    _ -> {
      list.range(1, count)
      |> list.each(fn(i) {
        let password = generate_password(config.length, charset)
        let strength = analyze_strength(password, config)
        let emoji = strength_emoji(strength)

        io.println(
          int.to_string(i)
          <> ". "
          <> password
          <> " "
          <> emoji
          <> " ["
          <> strength_to_string(strength)
          <> "]",
        )
      })

      io.println("")
      io.println(
        "📊 Charset: " <> int.to_string(string.length(charset)) <> " characters",
      )

      let combinations =
        calculate_combinations(config.length, string.length(charset))
      io.println("🔢 Possible combinations: " <> float.to_string(combinations))
    }
  }
}

fn build_charset(config: PasswordConfig) -> String {
  let base = case config.use_lowercase {
    True -> lowercase
    False -> ""
  }

  let with_upper = case config.use_uppercase {
    True -> base <> uppercase
    False -> base
  }

  let with_digits = case config.use_digits {
    True -> with_upper <> digits
    False -> with_upper
  }

  case config.use_symbols {
    True -> {
      case config.custom_symbols {
        Some(custom) -> with_digits <> custom
        None -> with_digits <> symbols
      }
    }
    False -> with_digits
  }
}

fn generate_password(length: Int, charset: String) -> String {
  let chars = string.to_graphemes(charset)
  let charset_length = list.length(chars)

  list.range(1, length)
  |> list.map(fn(_) {
    let random_index = get_random_int(charset_length)
    case list.at(chars, random_index) {
      Ok(char) -> char
      Error(_) -> "?"
    }
  })
  |> string.join("")
}

// Secure random number generator using Erlang's crypto module
@external(erlang, "crypto", "strong_rand_bytes")
fn crypto_random_bytes(n: Int) -> BitArray

fn get_random_int(max: Int) -> Int {
  // Get 4 random bytes and convert to integer
  let random_bytes = crypto_random_bytes(4)
  let assert <<random_int:unsigned-big-32>> = random_bytes
  random_int % max
}

fn analyze_strength(
  password: String,
  config: PasswordConfig,
) -> PasswordStrength {
  let length_score = case string.length(password) {
    l if l >= 16 -> 3
    l if l >= 12 -> 2
    l if l >= 8 -> 1
    _ -> 0
  }

  let variety_score =
    bool_to_int(config.use_lowercase)
    + bool_to_int(config.use_uppercase)
    + bool_to_int(config.use_digits)
    + bool_to_int(config.use_symbols)

  let total_score = length_score + variety_score

  case total_score {
    s if s >= 7 -> VeryStrong
    s if s >= 5 -> Strong
    s if s >= 3 -> Medium
    _ -> Weak
  }
}

fn bool_to_int(value: Bool) -> Int {
  case value {
    True -> 1
    False -> 0
  }
}

fn strength_to_string(strength: PasswordStrength) -> String {
  case strength {
    VeryStrong -> "Very Strong"
    Strong -> "Strong"
    Medium -> "Medium"
    Weak -> "Weak"
  }
}

fn strength_emoji(strength: PasswordStrength) -> String {
  case strength {
    VeryStrong -> "🟢"
    Strong -> "🔵"
    Medium -> "🟡"
    Weak -> "🔴"
  }
}

fn calculate_combinations(length: Int, charset_size: Int) -> Float {
  // Calculate charset_size^length
  int.to_float(charset_size)
  |> float_power(int.to_float(length))
}

fn float_power(base: Float, exponent: Float) -> Float {
  case exponent {
    0.0 -> 1.0
    _ -> {
      let exp_int = float.truncate(exponent)
      list.range(1, exp_int)
      |> list.fold(1.0, fn(acc, _) { acc *. base })
    }
  }
}
