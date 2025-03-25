mixin ValidatorMixin {
  String? validateIsEmpty(String? value, {String? title}) {
    if (value == null || value.isEmpty) {
      return '${(title ?? 'This')} is required';
    }
    return null;
  }
}
