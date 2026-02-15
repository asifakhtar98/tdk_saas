import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/auth/data/models/invitation_model.dart';

/// Remote datasource for invitation operations via Supabase.
abstract class InvitationRemoteDatasource {
  /// Send invitation email via Supabase Edge Function.
  Future<void> sendInvitationEmail(InvitationModel invitation);

  /// Upsert invitation to Supabase for sync.
  Future<void> upsertInvitation(InvitationModel invitation);

  /// Get invitation by token from Supabase.
  Future<InvitationModel?> getInvitationByToken(String token);
}

@LazySingleton(as: InvitationRemoteDatasource)
class InvitationRemoteDatasourceImplementation
    implements InvitationRemoteDatasource {
  InvitationRemoteDatasourceImplementation(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  @override
  Future<void> sendInvitationEmail(InvitationModel invitation) async {
    final response = await _supabaseClient.functions.invoke(
      'send-invitation',
      body: {
        'email': invitation.email,
        'organization_id': invitation.organizationId,
        'role': invitation.role,
        'token': invitation.token,
        'invited_by': invitation.invitedBy,
      },
    );

    // Check for Edge Function errors
    if (response.status >= 400) {
      throw Exception(
        'Email Edge Function failed with status ${response.status}: ${response.data}',
      );
    }
  }

  @override
  Future<void> upsertInvitation(InvitationModel invitation) async {
    await _supabaseClient.from('invitations').upsert(invitation.toJson());
  }

  @override
  Future<InvitationModel?> getInvitationByToken(String token) async {
    final response = await _supabaseClient
        .from('invitations')
        .select()
        .eq('token', token)
        .maybeSingle();
    if (response == null) return null;
    return InvitationModel.fromJson(response);
  }
}
