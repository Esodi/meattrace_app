// Increments the build number (the `+N` suffix) in pubspec.yaml's `version:` line.
// Usage: dart run tool/bump_build_number.dart
import 'dart:io';

void main() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('pubspec.yaml not found. Run this from the meattrace_app directory.');
    exit(1);
  }

  final versionRegex = RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$');
  final lines = pubspecFile.readAsLinesSync();

  var found = false;
  final newLines = lines.map((line) {
    final match = versionRegex.firstMatch(line);
    if (match == null) return line;
    found = true;

    final major = match.group(1);
    final minor = match.group(2);
    final patch = match.group(3);
    final oldBuild = int.parse(match.group(4)!);
    final newBuild = oldBuild + 1;

    stdout.writeln(
      'Bumped build number: $major.$minor.$patch+$oldBuild -> $major.$minor.$patch+$newBuild',
    );
    return 'version: $major.$minor.$patch+$newBuild';
  }).toList();

  if (!found) {
    stderr.writeln('Could not find a "version: X.Y.Z+N" line in pubspec.yaml');
    exit(1);
  }

  pubspecFile.writeAsStringSync('${newLines.join('\n')}\n');
}
