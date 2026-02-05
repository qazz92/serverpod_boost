import 'package:test/test.dart';
import 'package:serverpod_boost/skills/skill_loader.dart';

void main() {
  test('minimal test', () async {
    // This should work
    final skills = await SkillLoader(skillsPath: '/tmp').loadAll();
    expect(skills, isNotNull);
  });
}