import 'package:cooling_down_server/report_time.dart';
import 'package:test/test.dart';

void main() {
  test(
    '18:30 waits until that minute and the next alarm is tomorrow after it',
    () {
      const time = ReportTime(18, 30);

      expect(time.reached(DateTime(2026, 10, 12, 18, 29)), isFalse);
      expect(time.reached(DateTime(2026, 10, 12, 18, 30)), isTrue);
      expect(
        time.nextAfter(DateTime(2026, 10, 12, 10)),
        DateTime(2026, 10, 12, 18, 30),
      );
      expect(
        time.nextAfter(DateTime(2026, 10, 12, 18, 30)),
        DateTime(2026, 10, 13, 18, 30),
      );
      expect(normalizeReportTime('18:30').text, '18:30');
      expect(normalizeReportTime('18:30:00').text, '18:30');
      expect(normalizeReportTime('6').text, '06:00');
      expect(normalizeReportTime('').text, '00:00');
      expect(normalizeReportTime('25:00').text, '00:00');
      expect(normalizeReportFormat('custom'), 'custom');
      expect(normalizeReportFormat(''), 'builtin');
    },
  );
}
