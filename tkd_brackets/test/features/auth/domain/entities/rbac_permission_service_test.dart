import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/permission.dart';
import 'package:tkd_brackets/features/auth/domain/entities/rbac_permission_service.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

void main() {
  late RbacPermissionService service;

  setUp(() {
    service = RbacPermissionService();
  });

  group('RbacPermissionService', () {
    group('Owner permissions', () {
      test('has all permissions', () {
        for (final permission in Permission.values) {
          expect(
            service.canPerform(UserRole.owner, permission),
            isTrue,
            reason: 'Owner should have ${permission.value}',
          );
        }
      });
    });

    group('Admin permissions', () {
      test('has all permissions except billing and delete org', () {
        // Admin SHOULD have
        const adminHas = [
          Permission.manageOrganization,
          Permission.manageTeamMembers,
          Permission.changeUserRoles,
          Permission.sendInvitations,
          Permission.createTournament,
          Permission.editTournament,
          Permission.deleteTournament,
          Permission.archiveTournament,
          Permission.manageDivisions,
          Permission.manageParticipants,
          Permission.manageBrackets,
          Permission.enterScores,
          Permission.editScores,
          Permission.viewData,
        ];

        for (final permission in adminHas) {
          expect(
            service.canPerform(UserRole.admin, permission),
            isTrue,
            reason: 'Admin should have ${permission.value}',
          );
        }

        // Robust negative testing: Admin should NOT have anything else
        for (final permission in Permission.values) {
          if (adminHas.contains(permission)) continue;
          expect(
            service.canPerform(UserRole.admin, permission),
            isFalse,
            reason: 'Admin should NOT have ${permission.value}',
          );
        }
      });
    });

    group('Scorer permissions', () {
      test('has only score and read permissions', () {
        const scorerHas = [
          Permission.enterScores,
          Permission.editScores,
          Permission.viewData,
        ];

        for (final permission in scorerHas) {
          expect(
            service.canPerform(UserRole.scorer, permission),
            isTrue,
            reason: 'Scorer should have ${permission.value}',
          );
        }

        // Robust negative testing: Scorer should NOT have anything else
        for (final permission in Permission.values) {
          if (scorerHas.contains(permission)) continue;
          expect(
            service.canPerform(UserRole.scorer, permission),
            isFalse,
            reason: 'Scorer should NOT have ${permission.value}',
          );
        }
      });
    });

    group('Viewer permissions', () {
      test('has only read permission', () {
        expect(
          service.canPerform(UserRole.viewer, Permission.viewData),
          isTrue,
        );

        // Viewer should NOT have anything else
        for (final permission in Permission.values) {
          if (permission == Permission.viewData) continue;
          expect(
            service.canPerform(UserRole.viewer, permission),
            isFalse,
            reason:
                'Viewer should NOT have '
                '${permission.value}',
          );
        }
      });
    });

    group('assertPermission', () {
      test('returns Right(unit) when permission is granted', () {
        final result = service.assertPermission(
          UserRole.owner,
          Permission.manageBilling,
        );
        expect(result, const Right<Failure, Unit>(unit));
      });

      test('returns Left(AuthorizationPermissionDeniedFailure) '
          'when permission is denied', () {
        final result = service.assertPermission(
          UserRole.viewer,
          Permission.manageBilling,
        );
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) =>
              expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });
  });
}
