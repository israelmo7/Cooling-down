import 'package:cooling_down_server/report_layout.dart';
import 'package:test/test.dart';

void main() {
  test('the chosen columns become the report file', () {
    const columns = ReportColumns(
      quantity: true,
      checkIn: true,
      checkInTime: true,
      checkOut: false,
      checkOutTime: false,
    );

    final text = columns.toTemplate();

    expect(text, contains('{{product}}'));
    expect(text, contains('{{quantity}}'));
    expect(text, contains('{{check_in}}'));
    expect(text, contains('{{check_in_time}}'));
    expect(text, isNot(contains('{{check_out}}')));
    expect(text, isNot(contains('{{notes}}')));
    expect(text, isNot(contains('{{conclusion}}')));
    expect(ReportColumns.fromTemplate(text).checkOut, isFalse);
    expect(ReportColumns.fromTemplate(text).quantity, isTrue);
  });

  test('an empty file means the full table', () {
    final columns = ReportColumns.fromTemplate('');
    expect(columns.quantity, isTrue);
    expect(columns.checkIn, isTrue);
    expect(columns.checkOutTime, isTrue);
  });
}
