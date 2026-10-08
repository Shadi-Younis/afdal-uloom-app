/// Why an input was refused, before or by the server.
enum InputError {
  /// Empty, or nothing chosen.
  required,
  tooShort,
  tooLong,

  /// A username with characters other than `a-z 0-9 . _ -`.
  invalidCharacters,

  /// A student code that is not `S` + 3..5 digits.
  invalidFormat,

  /// The server says the username or student code already exists.
  taken,
}
