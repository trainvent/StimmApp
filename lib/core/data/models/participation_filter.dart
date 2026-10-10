/// Which forms to show based on the current user's participation records.
enum ParticipationFilter {
  notParticipated,
  all,
  participated;

  bool matches(bool hasParticipated) => switch (this) {
    notParticipated => !hasParticipated,
    all => true,
    participated => hasParticipated,
  };
}
