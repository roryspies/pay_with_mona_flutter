sealed class AuthState {
  const AuthState();
}

/// The user is authenticated and logged in
class AuthStateLoggedIn extends AuthState {
  const AuthStateLoggedIn();
}

/// The user is not authenticated and logged out
class AuthStateLoggedOut extends AuthState {
  const AuthStateLoggedOut();
}

/// An error occurred during authentication
class AuthStateError extends AuthState {
  final String message;
  const AuthStateError(this.message);
}

/// The user is not a Mona user
class AuthStateNotAMonaUser extends AuthState {
  const AuthStateNotAMonaUser();
}

/// Currently doing login with strong auth token
class AuthStatePerformingLogin extends AuthState {
  const AuthStatePerformingLogin();
}

/// Currently generating a public key
class AuthStateGeneratingPublicKey extends AuthState {
  const AuthStateGeneratingPublicKey();
}

/// Currently generating a signature
class AuthStateGeneratingSignature extends AuthState {
  final String rawData;
  const AuthStateGeneratingSignature({
    required this.rawData,
  });
}
