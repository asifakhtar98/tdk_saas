import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/demo/demo_data_constants.dart';

/// Service for managing demo mode data seeding.
///
/// Provides functionality to check if demo data should be seeded,
/// seed demo data on first launch, and check if demo data exists.
abstract class DemoDataService {
  /// Returns true if demo data should be seeded (first launch, no data).
  Future<bool> shouldSeedDemoData();

  /// Seeds all demo data:
  /// user, organization, tournament, division, participants.
  Future<void> seedDemoData();

  /// Returns true if demo data exists in the database.
  Future<bool> hasDemoData();
}

/// Implementation of [DemoDataService] using the Drift database.
@LazySingleton(as: DemoDataService)
class DemoDataServiceImpl implements DemoDataService {
  DemoDataServiceImpl(this._db);

  final AppDatabase _db;

  @override
  Future<bool> shouldSeedDemoData() async {
    // Check if any organizations exist - if empty, this is first launch
    final orgs = await _db.getActiveOrganizations();
    return orgs.isEmpty;
  }

  @override
  Future<bool> hasDemoData() => _db.hasDemoData();

  @override
  Future<void> seedDemoData() async {
    // Use transaction to ensure all-or-nothing seeding
    await _db.transaction(() async {
      final now = DateTime.now();

      // 1. Create demo organization first (FK target for users and tournaments)
      await _db.insertOrganization(OrganizationsCompanion(
        id: const Value(DemoDataConstants.demoOrganizationId),
        name: const Value(DemoDataConstants.demoOrganizationName),
        slug: const Value(DemoDataConstants.demoOrganizationSlug),
        subscriptionTier: const Value(DemoDataConstants.demoOrganizationTier),
        isDemoData: const Value(true),
        createdAtTimestamp: Value(now),
        updatedAtTimestamp: Value(now),
      ));

      // 2. Create demo user (owner)
      await _db.insertUser(UsersCompanion(
        id: const Value(DemoDataConstants.demoUserId),
        organizationId: const Value(DemoDataConstants.demoOrganizationId),
        email: const Value(DemoDataConstants.demoUserEmail),
        displayName: const Value(DemoDataConstants.demoUserDisplayName),
        role: const Value(DemoDataConstants.demoUserRole),
        isDemoData: const Value(true),
        createdAtTimestamp: Value(now),
        updatedAtTimestamp: Value(now),
      ));

      // 3. Create demo tournament
      final tournamentDate = now.add(
        const Duration(days: DemoDataConstants.demoTournamentDaysFromNow),
      );
      await _db.insertTournament(TournamentsCompanion(
        id: const Value(DemoDataConstants.demoTournamentId),
        organizationId: const Value(DemoDataConstants.demoOrganizationId),
        createdByUserId: const Value(DemoDataConstants.demoUserId),
        name: const Value(DemoDataConstants.demoTournamentName),
        federationType:
            const Value(DemoDataConstants.demoTournamentFederation),
        status: const Value(DemoDataConstants.demoTournamentStatus),
        scheduledDate: Value(tournamentDate),
        isDemoData: const Value(true),
        createdAtTimestamp: Value(now),
        updatedAtTimestamp: Value(now),
      ));

      // 4. Create demo division
      await _db.insertDivision(DivisionsCompanion(
        id: const Value(DemoDataConstants.demoDivisionId),
        tournamentId: const Value(DemoDataConstants.demoTournamentId),
        name: const Value(DemoDataConstants.demoDivisionName),
        category: const Value(DemoDataConstants.demoDivisionCategory),
        gender: const Value(DemoDataConstants.demoDivisionGender),
        ageMin: const Value(DemoDataConstants.demoDivisionAgeMin),
        ageMax: const Value(DemoDataConstants.demoDivisionAgeMax),
        weightMinKg: const Value(DemoDataConstants.demoDivisionWeightMin),
        weightMaxKg: const Value(DemoDataConstants.demoDivisionWeightMax),
        bracketFormat:
            const Value(DemoDataConstants.demoDivisionBracketFormat),
        status: const Value(DemoDataConstants.demoDivisionStatus),
        isDemoData: const Value(true),
        createdAtTimestamp: Value(now),
        updatedAtTimestamp: Value(now),
      ));

      // 5. Create 8 demo participants (2 from each of 4 dojangs)
      await _seedDemoParticipants(now);
    });
  }

  /// Seeds the 8 demo participants with varied ages and dojangs.
  Future<void> _seedDemoParticipants(DateTime now) async {
    // Participant data: [first, last, dojangIndex, birthYearOffset, weight]
    final participantData = [
      ['Min-jun', 'Kim', 0, -13, 42.0],
      ['Seo-yeon', 'Park', 0, -14, 44.0],
      ['Ji-hoon', 'Lee', 1, -12, 38.0],
      ['Ha-eun', 'Choi', 1, -13, 41.0],
      ['Ethan', 'Johnson', 2, -14, 43.0],
      ['Sophia', 'Williams', 2, -12, 39.0],
      ['Jacob', 'Martinez', 3, -13, 44.0],
      ['Emma', 'Davis', 3, -14, 45.0],
    ];

    for (var i = 0; i < participantData.length; i++) {
      final data = participantData[i];
      final firstName = data[0] as String;
      final lastName = data[1] as String;
      final dojangIndex = data[2] as int;
      final birthYearOffset = data[3] as int;
      final weight = data[4] as double;

      // Calculate date of birth based on year offset from today
      final dateOfBirth = DateTime(
        now.year + birthYearOffset,
        now.month,
        now.day,
      );

      await _db.insertParticipant(ParticipantsCompanion(
        id: Value(DemoDataConstants.demoParticipantIds[i]),
        divisionId: const Value(DemoDataConstants.demoDivisionId),
        firstName: Value(firstName),
        lastName: Value(lastName),
        dateOfBirth: Value(dateOfBirth),
        gender: const Value(DemoDataConstants.demoParticipantGender),
        weightKg: Value(weight),
        schoolOrDojangName:
            Value(DemoDataConstants.sampleDojangs[dojangIndex]),
        checkInStatus: const Value('pending'),
        isDemoData: const Value(true),
        createdAtTimestamp: Value(now),
        updatedAtTimestamp: Value(now),
      ));
    }
  }
}
