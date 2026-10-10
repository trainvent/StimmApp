import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/participation_filter.dart';

void main() {
  test('three participation modes include exactly the intended records', () {
    expect(ParticipationFilter.notParticipated.matches(false), isTrue);
    expect(ParticipationFilter.notParticipated.matches(true), isFalse);
    expect(ParticipationFilter.all.matches(false), isTrue);
    expect(ParticipationFilter.all.matches(true), isTrue);
    expect(ParticipationFilter.participated.matches(false), isFalse);
    expect(ParticipationFilter.participated.matches(true), isTrue);
  });
}
