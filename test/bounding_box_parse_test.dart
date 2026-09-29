import 'package:flutter_test/flutter_test.dart';
import 'package:shravani_thermal/models/inspection_models.dart';

void main() {
  group('BoundingBox.tryParse', () {
    test('accepts valid percentage box', () {
      final box = BoundingBox.tryParse({
        'x1': 12.5,
        'y1': 20,
        'x2': 40,
        'y2': 55.5,
      });
      expect(box, isNotNull);
      expect(box!.x1, 12.5);
      expect(box.y1, 20);
      expect(box.x2, 40);
      expect(box.y2, 55.5);
    });

    test('rejects missing box', () {
      expect(BoundingBox.tryParse(null), isNull);
    });

    test('rejects inverted or equal edges', () {
      expect(
        BoundingBox.tryParse({'x1': 50, 'y1': 10, 'x2': 20, 'y2': 40}),
        isNull,
      );
      expect(
        BoundingBox.tryParse({'x1': 10, 'y1': 10, 'x2': 10, 'y2': 50}),
        isNull,
      );
    });

    test('does not invent 10-50 fallback when boundingBox missing', () {
      final issue = DistressIssue.fromJson({
        'type': 'hollow_section',
        'confidence': 90,
        'description': 'void',
      });
      expect(issue.boundingBox, isNull);
      expect(issue.type, 'hollow_section');
      expect(issue.confidence, closeTo(0.9, 0.001));
    });

    test(
      'rejects clearly out-of-range coordinates instead of hard-clamping',
      () {
        expect(
          BoundingBox.tryParse({'x1': -5, 'y1': 10, 'x2': 40, 'y2': 50}),
          isNull,
        );
        expect(
          BoundingBox.tryParse({'x1': 10, 'y1': 10, 'x2': 150, 'y2': 50}),
          isNull,
        );
      },
    );

    test('clamps only tiny boundary drift', () {
      final box = BoundingBox.tryParse({
        'x1': -0.1,
        'y1': 10,
        'x2': 100.1,
        'y2': 50,
      });
      expect(box, isNotNull);
      expect(box!.x1, 0);
      expect(box.x2, 100);
    });
  });
}
