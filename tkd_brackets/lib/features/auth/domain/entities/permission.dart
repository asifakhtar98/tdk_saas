import 'package:tkd_brackets/features/auth/auth.dart'
    show RbacPermissionService, UserRole;

/// Granular permissions for RBAC enforcement.
///
/// Each value represents a specific action that can be checked
/// against a [UserRole] via [RbacPermissionService].
enum Permission {
  // Organization management
  manageOrganization('manage_organization'),
  deleteOrganization('delete_organization'),

  // Team management
  manageTeamMembers('manage_team_members'),
  changeUserRoles('change_user_roles'),
  sendInvitations('send_invitations'),

  // Tournament management
  createTournament('create_tournament'),
  editTournament('edit_tournament'),
  deleteTournament('delete_tournament'),
  archiveTournament('archive_tournament'),

  // Division management
  manageDivisions('manage_divisions'),

  // Participant management
  manageParticipants('manage_participants'),

  // Bracket management
  manageBrackets('manage_brackets'),

  // Scoring
  enterScores('enter_scores'),
  editScores('edit_scores'),

  // Billing
  manageBilling('manage_billing'),

  // Read-only
  viewData('view_data');

  const Permission(this.value);

  final String value;
}
