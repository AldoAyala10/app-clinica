bool validarCorreo(String email) {
  final normalizedEmail = email.trim();

  if (normalizedEmail.isEmpty) {
    return false;
  }

  final emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$",
  );

  return emailRegex.hasMatch(normalizedEmail);
}
