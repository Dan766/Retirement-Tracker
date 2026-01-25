class Validators {
  /// Validate that a value is a positive number
  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number < 0) {
      return 'Please enter a positive number';
    }
    return null;
  }

  /// Validate that a value is a positive number or zero
  static String? positiveNumberOrZero(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number < 0) {
      return 'Please enter a positive number or zero';
    }
    return null;
  }

  /// Validate that a value is a valid percentage (0-100)
  static String? percentage(String? value) {
    final error = positiveNumberOrZero(value);
    if (error != null) return error;

    final number = double.parse(value!);
    if (number > 100) {
      return 'Percentage must be 100 or less';
    }
    return null;
  }

  /// Validate that a value is a valid percentage with a more reasonable range for returns
  static String? returnPercentage(String? value) {
    final error = positiveNumberOrZero(value);
    if (error != null) return error;

    final number = double.parse(value!);
    if (number > 50) {
      return 'Expected return seems unrealistic. Please enter a value below 50%';
    }
    return null;
  }

  /// Validate that required text is not empty
  static String? requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  /// Validate inflation rate (typically 0-20%)
  static String? inflationRate(String? value) {
    final error = positiveNumberOrZero(value);
    if (error != null) return error;

    final number = double.parse(value!);
    if (number > 20) {
      return 'Inflation rate seems too high. Please enter a value below 20%';
    }
    return null;
  }
}
