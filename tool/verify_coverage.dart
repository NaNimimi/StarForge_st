import 'dart:io';

const _defaultMinimumPercent = 20.0;

void main(List<String> arguments) {
  final coveragePath = arguments.isEmpty
      ? 'coverage/lcov.info'
      : arguments.first;
  final minimumPercent = arguments.length < 2
      ? _defaultMinimumPercent
      : double.tryParse(arguments[1]);

  if (minimumPercent == null ||
      minimumPercent.isNaN ||
      minimumPercent < 0 ||
      minimumPercent > 100) {
    stderr.writeln('Coverage threshold must be a number from 0 through 100.');
    exitCode = 64;
    return;
  }

  final coverageFile = File(coveragePath);
  if (!coverageFile.existsSync()) {
    stderr.writeln('Coverage file does not exist: $coveragePath');
    exitCode = 66;
    return;
  }

  var linesFound = 0;
  var linesHit = 0;
  for (final line in coverageFile.readAsLinesSync()) {
    if (line.startsWith('LF:')) {
      linesFound += int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LH:')) {
      linesHit += int.tryParse(line.substring(3).trim()) ?? 0;
    }
  }

  if (linesFound <= 0 || linesHit < 0 || linesHit > linesFound) {
    stderr.writeln(
      'Coverage data is missing or inconsistent '
      '(lines=$linesFound, hit=$linesHit).',
    );
    exitCode = 65;
    return;
  }

  final actualPercent = linesHit * 100 / linesFound;
  stdout.writeln(
    'Line coverage: ${actualPercent.toStringAsFixed(2)}% '
    '($linesHit/$linesFound); required: '
    '${minimumPercent.toStringAsFixed(2)}%.',
  );
  if (actualPercent + 0.0000001 < minimumPercent) {
    stderr.writeln('Coverage is below the required threshold.');
    exitCode = 1;
  }
}
