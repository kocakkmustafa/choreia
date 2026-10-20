import 'package:choreia/app/shell/profile_view.dart';
import 'package:choreia/app/theme.dart';
import 'package:choreia/app/theme/theme_preference.dart';
import 'package:choreia/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const probe=Key('theme.probe');
  Widget app(ChoreiaThemeController themes, {Widget? home}) => ChoreiaApp(
    themeController: themes,
    shellBuilder: (_, __) => home ?? const Scaffold(body: SizedBox(key:probe)),
  );
  Brightness brightness(WidgetTester tester) => Theme.of(tester.element(find.byKey(probe))).brightness;
  testWidgets('system responds to OS brightness; explicit choice stays stable', (tester) async {
    final themes=ChoreiaThemeController.memory(); addTearDown(themes.dispose);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue=Brightness.light;
    await tester.pumpWidget(app(themes)); await tester.pump(); expect(brightness(tester),Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue=Brightness.dark;
    await tester.pump(); expect(brightness(tester),Brightness.dark);
    await themes.select(ThemeMode.light); await tester.pump(); expect(brightness(tester),Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue=Brightness.light; await tester.pump();
    tester.platformDispatcher.platformBrightnessTestValue=Brightness.dark; await tester.pump();
    expect(brightness(tester),Brightness.light); expect(tester.takeException(),isNull);
  });
  testWidgets('saved explicit mode is present on the startup first frame too', (tester) async {
    final themes=ChoreiaThemeController.memory(ThemeMode.light); addTearDown(themes.dispose);
    await tester.pumpWidget(ChoreiaAccountStartupFailure(themeController:themes,waiting:true));
    expect(Theme.of(tester.element(find.byKey(const Key('choreia.accountStartupWaiting')))).brightness,Brightness.light);
    await themes.select(ThemeMode.dark); await tester.pump();
    expect(Theme.of(tester.element(find.byKey(const Key('choreia.accountStartupWaiting')))).brightness,Brightness.dark);
    expect(tester.takeException(),isNull);
  });
  testWidgets('theme changes preserve an open route, draft and focus', (tester) async {
    final themes=ChoreiaThemeController.memory(ThemeMode.dark); addTearDown(themes.dispose);
    await tester.pumpWidget(app(themes, home: Builder(builder:(context)=>Scaffold(body:TextButton(
      onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const Scaffold(body:TextField(key:probe)))),child:const Text('Open'))))));
    await tester.tap(find.text('Open')); await tester.pumpAndSettle();
    await tester.enterText(find.byKey(probe),'draft survives');
    final before=tester.state<EditableTextState>(find.byType(EditableText));
    expect(before.widget.focusNode.hasFocus,true);
    await themes.select(ThemeMode.light); await tester.pump();
    final after=tester.state<EditableTextState>(find.byType(EditableText));
    expect(identical(before,after),true); expect(after.widget.controller.text,'draft survives');
    expect(after.widget.focusNode.hasFocus,true); expect(brightness(tester),Brightness.light);
    Navigator.of(tester.element(find.byKey(probe))).pop(); await tester.pumpAndSettle();
    expect(find.text('Open'),findsOneWidget); expect(tester.takeException(),isNull);
  });
  testWidgets('two app trees resolve independent custom palettes', (tester) async {
    final a=ChoreiaThemeController.memory(ThemeMode.light),b=ChoreiaThemeController.memory(ThemeMode.dark);
    addTearDown(a.dispose);addTearDown(b.dispose);
    await tester.pumpWidget(Directionality(textDirection:TextDirection.ltr,child:Row(children:[
      Expanded(child:app(a,home:const Scaffold(body:SizedBox(key:Key('a'))))),
      Expanded(child:app(b,home:const Scaffold(body:SizedBox(key:Key('b'))))),
    ])));
    expect(ChoreiaPalette.of(tester.element(find.byKey(const Key('a')))).stage,ChoreiaPalette.light.stage);
    expect(ChoreiaPalette.of(tester.element(find.byKey(const Key('b')))).stage,ChoreiaPalette.dark.stage);
    await a.select(ThemeMode.dark);await tester.pump();
    expect(ChoreiaPalette.of(tester.element(find.byKey(const Key('b')))).stage,ChoreiaPalette.dark.stage);
    expect(tester.takeException(),isNull);
  });
  testWidgets('profile exposes three selected theme choices with keyboard targets', (tester) async {
    final themes=ChoreiaThemeController.memory(); addTearDown(themes.dispose);
    await tester.pumpWidget(app(themes,home:Scaffold(body:ProfileView(accountPageBuilder:(_)=>const Scaffold()))));
    await tester.pump();
    final dark=find.byKey(const Key('theme.choice.dark'));
    await tester.ensureVisible(dark);
    final label=find.descendant(of:dark,matching:find.byType(Text)).first;
    Focus.of(tester.element(label)).requestFocus();await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);await tester.pump();
    expect(themes.value,ThemeMode.dark);expect(tester.widget<ChoiceChip>(dark).selected,true);
    expect(tester.getSize(dark).height,greaterThanOrEqualTo(48));
    expect(tester.takeException(),isNull);await tester.pumpWidget(const SizedBox.shrink());
  });
}
