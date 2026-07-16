import '../l10n/app_localizations.dart';
import '../models/team_model.dart';
import '../models/athlete_model.dart';
import '../models/chrono_model.dart';
import '../repositories/database_repository.dart';

/// Generates generic, fully localized sample data:
/// 4 teams with 2-3 placeholder athletes each (no invented real names).
class DummyDataGenerator {
  static Future<void> populateDatabase(
    DatabaseRepository db,
    AppLocalizations l10n,
  ) async {
    // Birth years are computed from the current year so the sample data
    // always matches the age ranges of each category.
    final currentYear = DateTime.now().year;
    // --- TEAM A - NOVICE (e.g. "Squadra A - Esordienti A") ---
    final noviceTeamId = await db.addTeam(
      Team(id: '', name: l10n.dummyTeamNoviceA, poolLength: 25),
    );

    final noviceSuffix = l10n.dummyCodeNovice;

    // Athlete A1<Novice>
    final a1Id = await db.addAthlete(
      noviceTeamId,
      Athlete(
        id: '',
        name: l10n.dummyAthleteName('A1$noviceSuffix'),
        birthYear: currentYear - 10, // Novice / Esordienti
        gender: 'Female',
        preferredStyles: ['Freestyle'],
        isActive: true,
        notes: l10n.dummyAthleteNote,
      ),
    );
    await db.addChrono(noviceTeamId, a1Id, Chrono(
      id: '',
      date: DateTime.now().subtract(const Duration(days: 3)),
      poolLength: 25,
      distance: 50,
      style: 'Freestyle',
      finalTime: '00:41.30',
      finalTimeMs: 41300,
      type: 'Training',
      notes: l10n.dummyNoteTraining,
      splits: [
        ChronoSplit(distance: 25, time: 19800, splitTime: 19800),
        ChronoSplit(distance: 50, time: 41300, splitTime: 21500),
      ],
    ));

    // Athlete A2<Novice>
    final a2Id = await db.addAthlete(
      noviceTeamId,
      Athlete(
        id: '',
        name: l10n.dummyAthleteName('A2$noviceSuffix'),
        birthYear: currentYear - 11, // Novice / Esordienti
        gender: 'Male',
        preferredStyles: ['Backstroke'],
        isActive: true,
        notes: '',
      ),
    );
    await db.addChrono(noviceTeamId, a2Id, Chrono(
      id: '',
      date: DateTime.now().subtract(const Duration(days: 6)),
      poolLength: 25,
      distance: 25,
      style: 'Backstroke',
      finalTime: '00:22.90',
      finalTimeMs: 22900,
      type: 'Race',
      notes: l10n.dummyNoteRace,
      splits: [ChronoSplit(distance: 25, time: 22900, splitTime: 22900)],
    ));

    // --- TEAM A - MASTERS (e.g. "Squadra A - Master") ---
    final mastersTeamId = await db.addTeam(
      Team(id: '', name: l10n.dummyTeamMasters, poolLength: 25),
    );

    final mastersSuffix = l10n.dummyCodeMasters;

    // Athlete A1<Masters>
    final m1Id = await db.addAthlete(
      mastersTeamId,
      Athlete(
        id: '',
        name: l10n.dummyAthleteName('A1$mastersSuffix'),
        birthYear: currentYear - 38, // Masters
        gender: 'Male',
        preferredStyles: ['Freestyle', 'Butterfly'],
        isActive: true,
        notes: '',
      ),
    );
    await db.addChrono(mastersTeamId, m1Id, Chrono(
      id: '',
      date: DateTime.now().subtract(const Duration(days: 2)),
      poolLength: 25,
      distance: 100,
      style: 'Freestyle',
      finalTime: '01:05.80',
      finalTimeMs: 65800,
      type: 'Race',
      notes: l10n.dummyNotePersonalBest,
      splits: [
        ChronoSplit(distance: 25, time: 15200, splitTime: 15200),
        ChronoSplit(distance: 50, time: 31800, splitTime: 16600),
        ChronoSplit(distance: 75, time: 48600, splitTime: 16800),
        ChronoSplit(distance: 100, time: 65800, splitTime: 17200),
      ],
    ));

    // Athlete A2<Masters>
    final m2Id = await db.addAthlete(
      mastersTeamId,
      Athlete(
        id: '',
        name: l10n.dummyAthleteName('A2$mastersSuffix'),
        birthYear: currentYear - 34, // Masters
        gender: 'Female',
        preferredStyles: ['Breaststroke'],
        isActive: true,
        notes: '',
      ),
    );
    await db.addChrono(mastersTeamId, m2Id, Chrono(
      id: '',
      date: DateTime.now().subtract(const Duration(days: 9)),
      poolLength: 25,
      distance: 50,
      style: 'Breaststroke',
      finalTime: '00:39.60',
      finalTimeMs: 39600,
      type: 'Training',
      notes: l10n.dummyNoteTraining,
      splits: [
        ChronoSplit(distance: 25, time: 18900, splitTime: 18900),
        ChronoSplit(distance: 50, time: 39600, splitTime: 20700),
      ],
    ));

    // --- TEAM B (no category) ---
    final teamBId = await db.addTeam(
      Team(id: '', name: l10n.dummyTeamB, poolLength: 25),
    );

    // Athlete B1
    final b1Id = await db.addAthlete(
      teamBId,
      Athlete(
        id: '',
        name: l10n.dummyAthleteName('B1'),
        birthYear: currentYear - 24, // No category: wide age range
        gender: 'Male',
        preferredStyles: ['IM', 'Breaststroke'],
        isActive: true,
        notes: '',
      ),
    );
    await db.addChrono(teamBId, b1Id, Chrono(
      id: '',
      date: DateTime.now().subtract(const Duration(days: 1)),
      poolLength: 25,
      distance: 100,
      style: 'IM',
      finalTime: '01:12.40',
      finalTimeMs: 72400,
      type: 'Training',
      notes: l10n.dummyNoteTraining,
      splits: [
        ChronoSplit(distance: 25, time: 16300, splitTime: 16300),
        ChronoSplit(distance: 50, time: 35100, splitTime: 18800),
        ChronoSplit(distance: 75, time: 55600, splitTime: 20500),
        ChronoSplit(distance: 100, time: 72400, splitTime: 16800),
      ],
    ));

    // Athlete B2
    final b2Id = await db.addAthlete(
      teamBId,
      Athlete(
        id: '',
        name: l10n.dummyAthleteName('B2'),
        birthYear: currentYear - 16, // No category: wide age range
        gender: 'Female',
        preferredStyles: ['Butterfly'],
        isActive: true,
        notes: '',
      ),
    );
    await db.addChrono(teamBId, b2Id, Chrono(
      id: '',
      date: DateTime.now().subtract(const Duration(days: 4)),
      poolLength: 25,
      distance: 50,
      style: 'Butterfly',
      finalTime: '00:33.10',
      finalTimeMs: 33100,
      type: 'Race',
      notes: l10n.dummyNoteRace,
      splits: [
        ChronoSplit(distance: 25, time: 15600, splitTime: 15600),
        ChronoSplit(distance: 50, time: 33100, splitTime: 17500),
      ],
    ));

    // Athlete B3
    final b3Id = await db.addAthlete(
      teamBId,
      Athlete(
        id: '',
        name: l10n.dummyAthleteName('B3'),
        birthYear: currentYear - 9, // No category: wide age range
        gender: 'Male',
        preferredStyles: ['Freestyle'],
        isActive: true,
        notes: '',
      ),
    );
    await db.addChrono(teamBId, b3Id, Chrono(
      id: '',
      date: DateTime.now().subtract(const Duration(days: 7)),
      poolLength: 25,
      distance: 100,
      style: 'Freestyle',
      finalTime: '01:01.20',
      finalTimeMs: 61200,
      type: 'Training',
      notes: '',
      splits: [
        ChronoSplit(distance: 50, time: 29400, splitTime: 29400),
        ChronoSplit(distance: 100, time: 61200, splitTime: 31800),
      ],
    ));

    // --- TEAM C - JUNIORS (e.g. "Squadra C - Juniores") ---
    final juniorsTeamId = await db.addTeam(
      Team(id: '', name: l10n.dummyTeamJuniors, poolLength: 50),
    );

    final juniorsSuffix = l10n.dummyCodeJuniors;

    // Athlete C1<Juniors>
    final c1Id = await db.addAthlete(
      juniorsTeamId,
      Athlete(
        id: '',
        name: l10n.dummyAthleteName('C1$juniorsSuffix'),
        birthYear: currentYear - 18, // Juniors / Juniores
        gender: 'Male',
        preferredStyles: ['Freestyle', 'Butterfly'],
        isActive: true,
        notes: '',
      ),
    );
    await db.addChrono(juniorsTeamId, c1Id, Chrono(
      id: '',
      date: DateTime.now().subtract(const Duration(days: 2)),
      poolLength: 50,
      distance: 100,
      style: 'Freestyle',
      finalTime: '00:56.70',
      finalTimeMs: 56700,
      type: 'Race',
      notes: l10n.dummyNotePersonalBest,
      splits: [
        ChronoSplit(distance: 50, time: 27100, splitTime: 27100),
        ChronoSplit(distance: 100, time: 56700, splitTime: 29600),
      ],
    ));
    await db.addChrono(juniorsTeamId, c1Id, Chrono(
      id: '',
      date: DateTime.now().subtract(const Duration(days: 12)),
      poolLength: 50,
      distance: 100,
      style: 'Freestyle',
      finalTime: '00:57.90',
      finalTimeMs: 57900,
      type: 'Training',
      notes: l10n.dummyNoteTraining,
      splits: [
        ChronoSplit(distance: 50, time: 27800, splitTime: 27800),
        ChronoSplit(distance: 100, time: 57900, splitTime: 30100),
      ],
    ));

    // Athlete C2<Juniors>
    final c2Id = await db.addAthlete(
      juniorsTeamId,
      Athlete(
        id: '',
        name: l10n.dummyAthleteName('C2$juniorsSuffix'),
        birthYear: currentYear - 17, // Juniors / Juniores
        gender: 'Female',
        preferredStyles: ['Backstroke'],
        isActive: true,
        notes: '',
      ),
    );
    await db.addChrono(juniorsTeamId, c2Id, Chrono(
      id: '',
      date: DateTime.now().subtract(const Duration(days: 5)),
      poolLength: 50,
      distance: 100,
      style: 'Backstroke',
      finalTime: '01:07.50',
      finalTimeMs: 67500,
      type: 'Race',
      notes: l10n.dummyNoteRace,
      splits: [
        ChronoSplit(distance: 50, time: 32600, splitTime: 32600),
        ChronoSplit(distance: 100, time: 67500, splitTime: 34900),
      ],
    ));
  }
}
