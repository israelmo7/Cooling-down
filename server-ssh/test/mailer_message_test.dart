import 'package:cooling_down_server/mailer.dart';
import 'package:test/test.dart';

void main() {
  test('a report with a table is sent as one html part', () {
    final message = reportMessage(
      from: 'from@shop.test',
      to: 'owner@shop.test',
      subject: 'דוח',
      body: 'plain',
      html: '<table><tr><td>חלב</td></tr></table>',
    );

    expect(message.html, contains('<table'));
    expect(message.text, isNull);
  });

  test('a report without a table stays plain text', () {
    final message = reportMessage(
      from: 'from@shop.test',
      to: 'owner@shop.test',
      subject: 'דוח',
      body: 'plain',
    );

    expect(message.text, 'plain');
    expect(message.html, isNull);
  });
}
