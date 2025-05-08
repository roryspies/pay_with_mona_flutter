/// Configuration for biometric prompts
class BiometricPromptConfig {
  final String title;
  final String subtitle;
  final String cancelButtonText;

  const BiometricPromptConfig({
    this.title = 'Biometric Authentication',
    this.subtitle = 'Authenticate to continue',
    this.cancelButtonText = 'Cancel',
  });
}
