String formatMetersClimbed(int meters) {
  final safeMeters = meters < 0 ? 0 : meters;
  if (safeMeters < 1000) {
    return safeMeters.toString();
  }

  final thousands = safeMeters / 1000;
  if (safeMeters >= 10000 || safeMeters % 1000 == 0) {
    return '${thousands.toStringAsFixed(0)}k';
  }

  return '${thousands.toStringAsFixed(1)}k';
}