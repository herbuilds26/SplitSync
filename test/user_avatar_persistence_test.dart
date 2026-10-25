import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/models/activity_log_model.dart';
import 'package:splitsync/models/user_model.dart';
import 'package:splitsync/widgets/profile_avatar.dart';

void main() {
  group('User Avatar & Persistence Tests', () {
    test('resolveAvatarId canonicalizes all avatar identifiers correctly', () {
      expect(resolveAvatarId(''), 'initial');
      expect(resolveAvatarId('   '), 'initial');
      expect(resolveAvatarId('initial'), 'initial');
      expect(resolveAvatarId('INITIAL'), 'initial');
      expect(resolveAvatarId('girl'), 'girl');
      expect(resolveAvatarId('berry_face'), 'girl');
      expect(resolveAvatarId('boy'), 'boy');
      expect(resolveAvatarId('mint_smile'), 'boy');
      expect(resolveAvatarId('mint_sun'), 'boy');
      expect(resolveAvatarId('leaves'), 'leaves');
      expect(resolveAvatarId('mint_leaf'), 'leaves');
      expect(resolveAvatarId('flower'), 'flower');
      expect(resolveAvatarId('rose_flower'), 'flower');
      expect(resolveAvatarId('berry_rose'), 'flower');
      expect(resolveAvatarId('dog'), 'dog');
      expect(resolveAvatarId('berry_dog'), 'dog');
      expect(resolveAvatarId('sage_pet'), 'dog');
      expect(resolveAvatarId('cat'), 'cat');
      expect(resolveAvatarId('kitty'), 'cat');
      expect(resolveAvatarId('berry_cat'), 'cat');
      expect(resolveAvatarId('bunny'), 'bunny');
      expect(resolveAvatarId('rabbit'), 'bunny');
      expect(resolveAvatarId('panda'), 'panda');
      expect(resolveAvatarId('fox'), 'fox');
      expect(resolveAvatarId('bear'), 'bear');
      expect(resolveAvatarId('koala'), 'koala');
      expect(resolveAvatarId('lion'), 'lion');
      expect(resolveAvatarId('penguin'), 'penguin');
      expect(resolveAvatarId('whale'), 'whale');
      expect(resolveAvatarId('dolphin'), 'whale');
      expect(resolveAvatarId('frog'), 'frog');
      expect(resolveAvatarId('mushroom'), 'mushroom');
      expect(resolveAvatarId('plum_star'), 'mushroom');
      expect(resolveAvatarId('deep_crown'), 'mushroom');
    });

    test('profileAvatarOptions does not include leaves and includes cute animals', () {
      final ids = profileAvatarOptions.map((opt) => opt.id).toList();
      expect(ids.contains('leaves'), isFalse);
      expect(ids, containsAll([
        'initial', 'girl', 'boy', 'flower', 'dog',
        'cat', 'bunny', 'panda', 'fox', 'bear',
        'koala', 'lion', 'penguin', 'whale', 'frog', 'mushroom',
      ]));
    });

    test('New user defaults to empty avatarUrl which maps to initial', () {
      final newUser = UserModel(
        uid: 'new_uid',
        name: 'Rathu',
        email: 'rathu@example.com',
        createdAt: DateTime.now(),
      );
      expect(newUser.avatarUrl, '');
      expect(resolveAvatarId(newUser.avatarUrl), 'initial');
    });

    test('UserModel preserves avatarUrl across serialization and deserialization', () {
      final user = UserModel(
        uid: 'user_123',
        name: 'Alex',
        email: 'alex@example.com',
        avatarUrl: 'flower',
        createdAt: DateTime(2026, 1, 1),
      );

      final map = user.toMap();
      expect(map['avatarUrl'], 'flower');

      final deserialized = UserModel.fromMap(map, 'user_123');
      expect(deserialized.avatarUrl, 'flower');
      expect(deserialized.name, 'Alex');
    });

    test('UserModel copyWith correctly updates avatarUrl', () {
      final user = UserModel(
        uid: 'user_123',
        name: 'Alex',
        email: 'alex@example.com',
        avatarUrl: 'dog',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = user.copyWith(avatarUrl: 'mushroom');
      expect(updated.avatarUrl, 'mushroom');
      expect(updated.name, 'Alex');
    });

    testWidgets('ProfileAvatar widget renders without error for any chosen animal or avatar option', (tester) async {
      for (final option in profileAvatarOptions) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ProfileAvatar(
              avatarId: option.id,
              name: 'Test User',
              radius: 20,
            ),
          ),
        );
        expect(find.byType(ProfileAvatar), findsOneWidget);
      }
    });

    test('ActivityLogModel preserves userAvatarUrl across serialization and deserialization', () {
      final log = ActivityLogModel(
        id: 'log_1',
        groupId: 'grp_1',
        userId: 'user_1',
        userName: 'Priya',
        userAvatarUrl: 'cat',
        action: 'added_expense',
        details: 'Added Dinner',
        timestamp: DateTime(2026, 1, 1),
      );

      final map = log.toMap();
      expect(map['userAvatarUrl'], 'cat');

      final deserialized = ActivityLogModel.fromMap(map, 'log_1');
      expect(deserialized.userAvatarUrl, 'cat');
      expect(deserialized.userName, 'Priya');
    });

    test('ActivityLogModel defaults userAvatarUrl to empty string for legacy maps without field', () {
      final legacyMap = {
        'groupId': 'grp_1',
        'userId': 'user_1',
        'userName': 'Priya',
        'action': 'added_expense',
        'details': 'Added Dinner',
      };

      final deserialized = ActivityLogModel.fromMap(legacyMap, 'log_legacy');
      expect(deserialized.userAvatarUrl, '');
      expect(deserialized.userName, 'Priya');
    });
  });
}

