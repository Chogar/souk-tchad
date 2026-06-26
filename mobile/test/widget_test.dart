import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('affiche le nom Souk Tchad au démarrage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SoukTchadApp()),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Souk Tchad'), findsOneWidget);
  });
}
