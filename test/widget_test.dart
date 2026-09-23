import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sudoku_game/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SudokuApp());
    await tester.pumpAndSettle();

    expect(find.text('Gridline'), findsOneWidget);
    expect(find.text('New Game'), findsOneWidget);
    expect(find.text('DIFFICULTY'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Expert'), findsOneWidget);
    expect(find.text('Played'), findsOneWidget);
    expect(find.text('Won'), findsOneWidget);
  });

  testWidgets('Starting a game navigates to the game screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SudokuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Game'));
    await tester.pumpAndSettle();

    expect(find.text('Erase'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });
}