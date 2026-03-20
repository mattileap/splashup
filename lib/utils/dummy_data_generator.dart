import '../models/team_model.dart';
import '../models/athlete_model.dart';
import '../models/chrono_model.dart';
import '../repositories/database_repository.dart';

class DummyDataGenerator {
  static Future<void> populateDatabase(DatabaseRepository db) async {
    // --- SQUADRA 1 ---
    final team1 = Team(id: '', name: 'Dolphins Elite Pro', poolLength: 50);
    final t1Id = await db.addTeam(team1);

    // Atleta 1A
    final a1A = Athlete(id: '', name: 'Marco Rossi', birthYear: 2002, gender: 'Male', preferredStyles: ['Freestyle', 'Butterfly'], isActive: true, notes: 'Ottima partenza dal blocco.');
    final a1AId = await db.addAthlete(t1Id, a1A);
    
    // Tempi Atleta 1A
    await db.addChrono(t1Id, a1AId, Chrono(
      id: '', date: DateTime.now().subtract(const Duration(days: 2)), poolLength: 50, distance: 100, style: 'Freestyle', finalTime: '00:52.40', finalTimeMs: 52400, type: 'Race', notes: 'Gara regionale',
      splits: [
        ChronoSplit(distance: 50, time: 25100, splitTime: 25100),
        ChronoSplit(distance: 100, time: 52400, splitTime: 27300),
      ],
    ));
    await db.addChrono(t1Id, a1AId, Chrono(
      id: '', date: DateTime.now().subtract(const Duration(days: 10)), poolLength: 50, distance: 100, style: 'Freestyle', finalTime: '00:53.10', finalTimeMs: 53100, type: 'Training', notes: 'Carico pesante',
      splits: [
        ChronoSplit(distance: 50, time: 25800, splitTime: 25800),
        ChronoSplit(distance: 100, time: 53100, splitTime: 27300),
      ],
    ));

    // Atleta 1B
    final a1B = Athlete(id: '', name: 'Giulia Bianchi', birthYear: 2004, gender: 'Female', preferredStyles: ['Backstroke', 'Freestyle'], isActive: true, notes: '');
    final a1BId = await db.addAthlete(t1Id, a1B);
    
    // Tempi Atleta 1B
    await db.addChrono(t1Id, a1BId, Chrono(
      id: '', date: DateTime.now().subtract(const Duration(days: 5)), poolLength: 50, distance: 50, style: 'Backstroke', finalTime: '00:29.80', finalTimeMs: 29800, type: 'Race', notes: 'Personal Best!',
      splits: [ChronoSplit(distance: 50, time: 29800, splitTime: 29800)],
    ));


    // --- SQUADRA 2 ---
    final team2 = Team(id: '', name: 'Sharks Junior', poolLength: 25);
    final t2Id = await db.addTeam(team2);

    // Atleta 2A
    final a2A = Athlete(id: '', name: 'Luca Verdi', birthYear: 2010, gender: 'Male', preferredStyles: ['Breaststroke', 'IM'], isActive: true, notes: 'Migliorare la virata a rana.');
    final a2AId = await db.addAthlete(t2Id, a2A);
    
    // Tempi Atleta 2A
    await db.addChrono(t2Id, a2AId, Chrono(
      id: '', date: DateTime.now().subtract(const Duration(days: 1)), poolLength: 25, distance: 100, style: 'Breaststroke', finalTime: '01:12.50', finalTimeMs: 72500, type: 'Training', notes: 'Test in allenamento',
      splits: [
        ChronoSplit(distance: 25, time: 16000, splitTime: 16000),
        ChronoSplit(distance: 50, time: 34500, splitTime: 18500),
        ChronoSplit(distance: 75, time: 53500, splitTime: 19000),
        ChronoSplit(distance: 100, time: 72500, splitTime: 19000),
      ],
    ));

    // Atleta 2B
    final a2B = Athlete(id: '', name: 'Elena Neri', birthYear: 2011, gender: 'Female', preferredStyles: ['Butterfly'], isActive: true, notes: 'Molto resistente.');
    final a2BId = await db.addAthlete(t2Id, a2B);
    
    // Tempi Atleta 2B
    await db.addChrono(t2Id, a2BId, Chrono(
      id: '', date: DateTime.now().subtract(const Duration(days: 3)), poolLength: 25, distance: 100, style: 'Butterfly', finalTime: '01:08.20', finalTimeMs: 68200, type: 'Training', notes: '',
      splits: [
        ChronoSplit(distance: 25, time: 14500, splitTime: 14500),
        ChronoSplit(distance: 50, time: 31000, splitTime: 16500),
        ChronoSplit(distance: 75, time: 49000, splitTime: 18000),
        ChronoSplit(distance: 100, time: 68200, splitTime: 19200),
      ],
    ));
  }
}