import '../models/team_model.dart';
import '../models/athlete_model.dart';
import '../models/chrono_model.dart';

abstract class DatabaseRepository {
  // --- Teams ---
  Stream<List<Team>> getTeamsStream();
  Future<String> addTeam(Team team);
  Future<void> updateTeam(Team team);
  Future<void> deleteTeam(String teamId); // Cascading delete (cancella anche atleti e tempi)

  // --- Athletes ---
  Stream<List<Athlete>> getAthletesStream(String teamId);
  Future<String> addAthlete(String teamId, Athlete athlete);
  Future<void> updateAthlete(String teamId, Athlete athlete);
  Future<void> deleteAthlete(String athleteId); // Cascading delete (cancella anche tempi)
  
  // --- Chronos ---
  Stream<List<Chrono>> getChronosStream(String athleteId);
  Future<String> addChrono(String teamId, String athleteId, Chrono chrono);
  Future<void> updateChrono(String teamId, String athleteId, Chrono chrono);
  Future<void> deleteChrono(String athleteId, String chronoId);

  // --- Batch / Complex Operations (per Settings e Move) ---
  Future<void> moveAthlete(String athleteId, String sourceTeamId, String destTeamId);
  Future<int> deactivateInactiveAthletes(int monthsInactive);
  Future<int> deleteInactiveAthletes(int yearsInactive);
}