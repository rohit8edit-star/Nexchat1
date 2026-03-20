import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexchat/main.dart';

void main() {
  testWidgets('NexChat smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NexChatApp());
  });
}
