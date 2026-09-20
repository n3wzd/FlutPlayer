import 'dart:io';

class FileRecencyResolver {
  FileRecencyResolver._();

  static final List<RegExp> _datePatterns = [
    RegExp(
      r'(?:^|[^0-9])((?:19|20)[0-9]{2})[-_. ](0?[1-9]|1[0-2])[-_. ](0?[1-9]|[12][0-9]|3[01])(?=[^0-9]|$)',
    ),
    RegExp(
      r'(?:^|[^0-9])((?:19|20)[0-9]{2})(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])(?=[^0-9]|$)',
    ),
    RegExp(
      r'(?:^|[^0-9])((?:19|20)[0-9]{2})년\s*(0?[1-9]|1[0-2])월\s*(0?[1-9]|[12][0-9]|3[01])일',
    ),
  ];

  static DateTime resolve(File file) {
    final fileNameDate = fromFileName(file.path);
    if (fileNameDate != null) {
      return fileNameDate;
    }
    final modified = file.statSync().modified;
    return DateTime(modified.year, modified.month, modified.day);
  }

  static DateTime? fromFileName(String path) {
    final fileName = path.split(RegExp(r'[/\\]')).last;
    final dates = <DateTime>[];
    for (final pattern in _datePatterns) {
      for (final match in pattern.allMatches(fileName)) {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        final date = DateTime(year, month, day);
        if (date.year == year && date.month == month && date.day == day) {
          dates.add(date);
        }
      }
    }
    if (dates.isEmpty) {
      return null;
    }
    dates.sort();
    return dates.last;
  }
}
