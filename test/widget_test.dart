import 'package:flutter_test/flutter_test.dart';

import 'package:sudoku_game/main.dart';

void main() {
  testWidgets('Home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SudokuApp());
    await tester.pumpAndSettle();

    expect(find.text('Gridline'), findsOneWidget);
    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('New Game'), findsOneWidget);
    expect(find.text('DIFFICULTY'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Expert'), findsOneWidget);
  });
}
