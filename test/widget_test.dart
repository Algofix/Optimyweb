import 'package:flutter_test/flutter_test.dart';
import 'package:optimyweb/models/project.dart';

void main() {
  test('ProjectStatus parses known values', () {
    expect(ProjectStatusX.fromString('active'), ProjectStatus.active);
    expect(ProjectStatusX.fromString(null), ProjectStatus.draft);
  });
}
