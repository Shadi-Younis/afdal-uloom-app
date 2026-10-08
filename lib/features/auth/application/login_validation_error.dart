/// A login form problem found before calling the server.
enum LoginValidationError implements Exception {
  usernameRequired,
  passwordRequired,
}
