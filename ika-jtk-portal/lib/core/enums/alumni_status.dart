enum AlumniStatus {
  unverified('UNVERIFIED'),
  pending('PENDING'),
  approved('APPROVED'),
  active('ACTIVE'),
  inactive('INACTIVE'),
  rejected('REJECTED');

  final String value;
  const AlumniStatus(this.value);

  factory AlumniStatus.fromString(String val) {
    return values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => AlumniStatus.pending,
    );
  }
}
