import 'package:test/test.dart';
import 'package:serverpod_boost/skills/skill.dart';
import 'package:serverpod_boost/skills/skill_conflict_resolver.dart';
import 'package:serverpod_boost/skills/skill_metadata.dart';

void main() {
  group('SkillConflictResolver', () {
    group('resolve()', () {
      test('returns all skills when no conflicts', () async {
        final skills = [
          Skill(
            name: 'skill1',
            description: 'First skill',
            template: 'template1',
            metadata: SkillMetadata.defaults,
          ),
          Skill(
            name: 'skill2',
            description: 'Second skill',
            template: 'template2',
            metadata: SkillMetadata.defaults,
          ),
          Skill(
            name: 'skill3',
            description: 'Third skill',
            template: 'template3',
            metadata: SkillMetadata.defaults,
          ),
        ];

        final resolver = SkillConflictResolver();
        final resolved = await resolver.resolve(skills);

        expect(resolved, hasLength(3));
        expect(resolved, containsAll(skills));
      });

      test('handles conflicts by taking first skill', () async {
        final skills = [
          Skill(
            name: 'conflict-skill',
            description: 'First version',
            template: 'template1',
            metadata: SkillMetadata.defaults,
          ),
          Skill(
            name: 'conflict-skill',
            description: 'Second version',
            template: 'template2',
            metadata: SkillMetadata.defaults,
          ),
          Skill(
            name: 'unique-skill',
            description: 'Unique skill',
            template: 'template3',
            metadata: SkillMetadata.defaults,
          ),
        ];

        final resolver = SkillConflictResolver();
        final resolved = await resolver.resolve(skills);

        expect(resolved, hasLength(2));

        // The first skill with the conflicting name should be kept
        final conflictSkill = resolved.firstWhere((s) => s.name == 'conflict-skill');
        expect(conflictSkill.description, 'First version');

        // The unique skill should be preserved
        expect(resolved.any((s) => s.name == 'unique-skill'), isTrue);
      });

      test('preserves order of non-conflicting skills', () async {
        final skills = [
          Skill(name: 'a', description: 'A', template: 'template1', metadata: SkillMetadata.defaults),
          Skill(name: 'b', description: 'B', template: 'template2', metadata: SkillMetadata.defaults),
          Skill(name: 'a', description: 'A duplicate', template: 'template3', metadata: SkillMetadata.defaults),
          Skill(name: 'c', description: 'C', template: 'template4', metadata: SkillMetadata.defaults),
        ];

        final resolver = SkillConflictResolver();
        final resolved = await resolver.resolve(skills);

        expect(resolved, hasLength(3));

        // Check order of non-conflicting skills
        expect(resolved[0].name, 'a'); // First 'a' is kept
        expect(resolved[1].name, 'b'); // 'b' should follow
        expect(resolved[2].name, 'c'); // 'c' should be last
      });
    });

    group('hasConflicts()', () {
      test('returns false for unique names', () {
        final skills = [
          Skill(name: 'unique1', description: '1', template: 't1', metadata: SkillMetadata.defaults),
          Skill(name: 'unique2', description: '2', template: 't2', metadata: SkillMetadata.defaults),
          Skill(name: 'unique3', description: '3', template: 't3', metadata: SkillMetadata.defaults),
        ];

        final hasConflicts = SkillConflictResolver.hasConflicts(skills);
        expect(hasConflicts, isFalse);
      });

      test('detects duplicate skill names', () {
        final skills = [
          Skill(name: 'duplicate', description: '1', template: 't1', metadata: SkillMetadata.defaults),
          Skill(name: 'unique', description: '2', template: 't2', metadata: SkillMetadata.defaults),
          Skill(name: 'duplicate', description: '3', template: 't3', metadata: SkillMetadata.defaults),
        ];

        final hasConflicts = SkillConflictResolver.hasConflicts(skills);
        expect(hasConflicts, isTrue);
      });

      test('returns false for empty list', () {
        final skills = <Skill>[];

        final hasConflicts = SkillConflictResolver.hasConflicts(skills);
        expect(hasConflicts, isFalse);
      });

      test('handles single skill', () {
        final skills = [
          Skill(name: 'single', description: '1', template: 't1', metadata: SkillMetadata.defaults),
        ];

        final hasConflicts = SkillConflictResolver.hasConflicts(skills);
        expect(hasConflicts, isFalse);
      });
    });

    group('getConflicts()', () {
      test('returns empty list when no conflicts', () {
        final skills = [
          Skill(name: 'unique1', description: '1', template: 't1', metadata: SkillMetadata.defaults),
          Skill(name: 'unique2', description: '2', template: 't2', metadata: SkillMetadata.defaults),
        ];

        final conflicts = SkillConflictResolver.getConflicts(skills);
        expect(conflicts, isEmpty);
      });

      test('returns list of conflicting names', () {
        final skills = [
          Skill(name: 'conflict1', description: '1', template: 't1', metadata: SkillMetadata.defaults),
          Skill(name: 'unique', description: '2', template: 't2', metadata: SkillMetadata.defaults),
          Skill(name: 'conflict1', description: '3', template: 't3', metadata: SkillMetadata.defaults),
          Skill(name: 'conflict2', description: '4', template: 't4', metadata: SkillMetadata.defaults),
          Skill(name: 'conflict2', description: '5', template: 't5', metadata: SkillMetadata.defaults),
        ];

        final conflicts = SkillConflictResolver.getConflicts(skills);
        expect(conflicts, hasLength(2));
        expect(conflicts, contains('conflict1'));
        expect(conflicts, contains('conflict2'));
      });

      test('returns each conflict only once', () {
        final skills = [
          Skill(name: 'duplicate', description: '1', template: 't1', metadata: SkillMetadata.defaults),
          Skill(name: 'duplicate', description: '2', template: 't2', metadata: SkillMetadata.defaults),
          Skill(name: 'duplicate', description: '3', template: 't3', metadata: SkillMetadata.defaults),
          Skill(name: 'unique', description: '4', template: 't4', metadata: SkillMetadata.defaults),
        ];

        final conflicts = SkillConflictResolver.getConflicts(skills);
        expect(conflicts, hasLength(1));
        expect(conflicts, contains('duplicate'));
      });

      test('handles empty list', () {
        final skills = <Skill>[];

        final conflicts = SkillConflictResolver.getConflicts(skills);
        expect(conflicts, isEmpty);
      });

      test('handles multiple conflicts with different frequencies', () {
        final skills = [
          Skill(name: 'triple', description: '1', template: 't1', metadata: SkillMetadata.defaults),
          Skill(name: 'double', description: '2', template: 't2', metadata: SkillMetadata.defaults),
          Skill(name: 'unique', description: '3', template: 't3', metadata: SkillMetadata.defaults),
          Skill(name: 'triple', description: '4', template: 't4', metadata: SkillMetadata.defaults),
          Skill(name: 'double', description: '5', template: 't5', metadata: SkillMetadata.defaults),
        ];

        final conflicts = SkillConflictResolver.getConflicts(skills);
        expect(conflicts, hasLength(2));
        expect(conflicts, contains('triple'));
        expect(conflicts, contains('double'));
      });
    });

    group('Edge cases', () {
      test('Skills with same name but different templates should be considered conflicts', () {
        final skills = [
          Skill(
            name: 'same-name',
            description: 'First',
            template: 'template 1',
            metadata: SkillMetadata.defaults,
          ),
          Skill(
            name: 'same-name',
            description: 'Second',
            template: 'template 2',
            metadata: SkillMetadata.defaults,
          ),
        ];
        expect(SkillConflictResolver.hasConflicts(skills), isTrue);
        expect(SkillConflictResolver.getConflicts(skills), equals(['same-name']));
      });

      test('Skills with same name and same template should be considered the same', () {
        final template = 'same template';
        final skills = [
          Skill(
            name: 'same-name',
            description: 'Skill',
            template: template,
            metadata: SkillMetadata.defaults,
          ),
          Skill(
            name: 'same-name',
            description: 'Skill',
            template: template,
            metadata: SkillMetadata.defaults,
          ),
        ];
        // This is an edge case - same name and same template might be considered duplicates
        // but the Skill class equals method checks for both name and template
        expect(skills[0] == skills[1], isTrue);
      });
    });
  });
}