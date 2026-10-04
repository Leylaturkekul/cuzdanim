import 'package:cuzdanim/main.dart';
import 'package:cuzdanim/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Login ve giriş butonu görünür', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController();
    await controller.initialize();
    await tester.pumpWidget(MyApp(controller: controller));

    expect(find.text('Cüzdanım'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('Demo ile hemen başla'), findsOneWidget);
  });

  testWidgets('Demo girişi genel bakışı açar', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController();
    await controller.initialize();
    await tester.pumpWidget(MyApp(controller: controller));

    await tester.ensureVisible(find.text('Demo ile hemen başla'));
    await tester.tap(find.text('Demo ile hemen başla'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('Genel Bakış'), findsOneWidget);
    expect(find.text('İşlem ekle'), findsOneWidget);
    expect(find.text('Bu ay kalan'), findsOneWidget);
  });
}
