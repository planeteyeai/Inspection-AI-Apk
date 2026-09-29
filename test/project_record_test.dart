import 'package:flutter_test/flutter_test.dart';
import 'package:shravani_thermal/models/inspection_models.dart';

void main() {
  group('ProjectRecord tests', () {
    test('excludes demo "Aasam" project', () {
      final rawProjects = [
        'Aasam',
        'aasam',
        'Tolling ,Operation,Maintenance and Transfer of Agra By- Pass Section form KM 0.00 to KM 32.80 In the State Of Uttar Pradesh of NH-44',
      ];

      final records = ProjectRecord.fromDatabaseProjects(rawProjects);

      expect(records.length, equals(1));
      expect(records.first.displayName, equals('Agra-Bypass Section'));
      expect(
        records.first.databaseName,
        equals(
          'Tolling ,Operation,Maintenance and Transfer of Agra By- Pass Section form KM 0.00 to KM 32.80 In the State Of Uttar Pradesh of NH-44',
        ),
      );
    });

    test('correctly maps known database project names to short display labels', () {
      final rawProjects = [
        'Tolling ,Operation,Maintenance and Transfer of Agra By- Pass Section form KM 0.00 to KM 32.80 In the State Of Uttar Pradesh of NH-44',
        'Tolling, Operation, Maintenance & Transfer of Abu Road-Swaroopganj section from km 646+000 to 677+000 of NH-27 in the state of Rajasthan',
        'Tolling, Operation, Maintenance & Transfer of Chittorgarh Bypass to Kota section from km 891+929 to 1052+429 of NH-27 in the state of Rajasthan',
        'Tolling, Operation, Maintenance & Transfer of Kochugaon – Khaljhar section from km 30+000 to 92+671 / 961+500 to 1013+000 of NH-27 in the state of Assam',
        'Bhopkhedi-Wadner section',
        'Four Lane Chichra to Kharagpur Section',
        'Palanpur/Khemana – Abu Road section',
        'Shivpuri-Jhansi section',
      ];

      final records = ProjectRecord.fromDatabaseProjects(rawProjects);

      expect(records.length, equals(8));
      final displayNames = records.map((r) => r.displayName).toList();

      expect(displayNames, contains('Agra-Bypass Section'));
      expect(displayNames, contains('Abu Road-Swaroopganj Section'));
      expect(displayNames, contains('Chittorgarh Bypass to Kota Section'));
      expect(displayNames, contains('Kochugaon – Khaljhar Section'));
      expect(displayNames, contains('Bhopkhedi-Wadner Section'));
      expect(displayNames, contains('Four Lane Chichra to Kharagpur Section'));
      expect(displayNames, contains('Palanpur/Khemana – Abu Road Section'));
      expect(displayNames, contains('Shivpuri-Jhansi Section'));
    });

    test('preserves original full databaseName for SQL queries', () {
      const rawName =
          'Tolling, Operation, Maintenance & Transfer of Kochugaon – Khaljhar section from km 30+000 to 92+671 / 961+500 to 1013+000 of NH-27 in the state of Assam';
      final records = ProjectRecord.fromDatabaseProjects([rawName]);

      expect(records.first.displayName, equals('Kochugaon – Khaljhar Section'));
      expect(records.first.databaseName, equals(rawName));
    });

    test('disambiguates duplicate display names to avoid collision', () {
      final rawProjects = [
        'Tolling, Operation, Maintenance & Transfer of Agra Bypass section from km 0 to 30 of NH-44 in the state of Uttar Pradesh',
        'Tolling, Operation, Maintenance & Transfer of Agra Bypass section from km 30 to 60 of NH-19 in the state of Uttar Pradesh',
      ];

      final records = ProjectRecord.fromDatabaseProjects(rawProjects);

      expect(records.length, equals(2));
      expect(records[0].displayName, contains('NH-44'));
      expect(records[1].displayName, contains('NH-19'));
      expect(records[0].databaseName, equals(rawProjects[0]));
      expect(records[1].databaseName, equals(rawProjects[1]));
    });
  });
}
