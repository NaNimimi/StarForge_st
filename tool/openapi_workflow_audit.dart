import 'dart:convert';
import 'dart:io';

typedef Operation = ({String method, String path});

const _httpMethods = {'GET', 'POST', 'PUT', 'PATCH', 'DELETE'};

const _requiredFamilyOperations = <Operation>{
  (method: 'POST', path: '/api/v1/auth/role-login/'),
  (method: 'POST', path: '/api/v1/auth/logout/'),
  (method: 'GET', path: '/api/v1/users/me/'),
  (method: 'PATCH', path: '/api/v1/users/me/'),
  (method: 'GET', path: '/api/v1/students/me/dashboard/'),
  (method: 'GET', path: '/api/v1/students/me/report/'),
  (method: 'GET', path: '/api/v1/students/'),
  (method: 'GET', path: '/api/v1/students/{}/'),
  (method: 'GET', path: '/api/v1/students/{}/events/'),
  (method: 'GET', path: '/api/v1/parents/me/children/'),
  (method: 'GET', path: '/api/v1/parents/me/children/{}/report/'),
  (method: 'GET', path: '/api/v1/parents/'),
  (method: 'GET', path: '/api/v1/parents/guardians/'),
  (method: 'GET', path: '/api/v1/parents/pickups/'),
};

void main(List<String> arguments) {
  if (arguments.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/openapi_workflow_audit.dart '
      '<schema.json> <extensions.json> <source-directory>',
    );
    exitCode = 64;
    return;
  }

  final schemaFile = File(arguments[0]);
  final extensionsFile = File(arguments[1]);
  final sourceDirectory = Directory(arguments[2]);
  final errors = <String>[];

  if (!schemaFile.existsSync()) {
    errors.add('Schema not found: ${schemaFile.path}');
  }
  if (!extensionsFile.existsSync()) {
    errors.add('Extensions file not found: ${extensionsFile.path}');
  }
  if (!sourceDirectory.existsSync()) {
    errors.add('Source directory not found: ${sourceDirectory.path}');
  }
  if (errors.isNotEmpty) _fail(errors);

  final schema = _object(jsonDecode(schemaFile.readAsStringSync()), 'schema');
  final openApiVersion = '${schema['openapi'] ?? ''}';
  if (!openApiVersion.startsWith('3.')) {
    errors.add('Expected OpenAPI 3.x, found "$openApiVersion".');
  }

  final paths = _object(schema['paths'], 'schema.paths');
  final schemaOperations = <Operation>{};
  for (final entry in paths.entries) {
    final item = _object(entry.value, 'path ${entry.key}');
    for (final method in _httpMethods) {
      if (item[method.toLowerCase()] is Map) {
        schemaOperations.add((method: method, path: _canonicalPath(entry.key)));
      }
    }
  }

  final extensions = _object(
    jsonDecode(extensionsFile.readAsStringSync()),
    'extensions',
  );
  final rawExtensions = extensions['operations'];
  if (rawExtensions is! List) {
    errors.add('extensions.operations must be a list.');
    _fail(errors);
  }
  final extensionOperations = <Operation>{};
  for (final (index, raw) in rawExtensions.indexed) {
    final item = _object(raw, 'extensions.operations[$index]');
    final method = '${item['method'] ?? ''}'.toUpperCase();
    final path = _canonicalPath('${item['path'] ?? ''}');
    final reason = '${item['reason'] ?? ''}'.trim();
    if (!_httpMethods.contains(method) || !path.startsWith('/api/v1/')) {
      errors.add('Invalid extension operation at index $index: $method $path');
      continue;
    }
    if (reason.isEmpty) {
      errors.add('Extension $method $path must explain why it is required.');
    }
    final operation = (method: method, path: path);
    if (schemaOperations.contains(operation)) {
      errors.add(
        'Extension $method $path is now present in OpenAPI; remove the override.',
      );
    }
    if (!extensionOperations.add(operation)) {
      errors.add('Duplicate extension operation: $method $path');
    }
  }

  final sourceOperations = _sourceOperations(sourceDirectory);
  final availableOperations = {...schemaOperations, ...extensionOperations};
  for (final operation in sourceOperations.difference(availableOperations)) {
    errors.add(
      'Frontend call is absent from the API contract: '
      '${operation.method} ${operation.path}',
    );
  }
  for (final operation in extensionOperations.difference(sourceOperations)) {
    errors.add(
      'Unused OpenAPI extension override: ${operation.method} ${operation.path}',
    );
  }
  for (final operation in _requiredFamilyOperations.difference(
    schemaOperations,
  )) {
    errors.add(
      'Required student/parent operation is absent from OpenAPI: '
      '${operation.method} ${operation.path}',
    );
  }

  final components = _object(schema['components'], 'schema.components');
  final securitySchemes = _object(
    components['securitySchemes'],
    'schema.components.securitySchemes',
  );
  final sessionAuth = _object(
    securitySchemes['sessionAuth'],
    'schema.components.securitySchemes.sessionAuth',
  );
  if ('${sessionAuth['type']}' != 'http' ||
      '${sessionAuth['scheme']}'.toLowerCase() != 'bearer') {
    errors.add('sessionAuth must remain an HTTP bearer security scheme.');
  }

  final schemas = _object(components['schemas'], 'schema.components.schemas');
  final success = _object(
    schemas['Success'],
    'schema.components.schemas.Success',
  );
  final required = success['required'];
  if (required is! List || !required.contains('success')) {
    errors.add('The Success envelope must require the success field.');
  }

  if (errors.isNotEmpty) _fail(errors);
  stdout.writeln(
    'OpenAPI audit passed: ${schemaOperations.length} schema operations, '
    '${extensionOperations.length} reviewed extensions, '
    '${sourceOperations.length} frontend calls.',
  );
}

Set<Operation> _sourceOperations(Directory sourceDirectory) {
  final operations = <Operation>{};
  final callPattern = RegExp(
    r"_api\s*\.\s*(get|post|put|patch|delete)\s*\(\s*'([^']+)'",
    multiLine: true,
  );
  final optionalGetPattern = RegExp(
    r"_optionalGet\s*\(\s*'([^']+)'",
    multiLine: true,
  );
  final files = sourceDirectory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
  for (final file in files) {
    final source = file.readAsStringSync();
    for (final match in callPattern.allMatches(source)) {
      final path = match.group(2)!;
      if (!path.startsWith('/api/v1/')) continue;
      operations.add((
        method: match.group(1)!.toUpperCase(),
        path: _canonicalPath(path),
      ));
    }
    for (final match in optionalGetPattern.allMatches(source)) {
      final path = match.group(1)!;
      if (!path.startsWith('/api/v1/')) continue;
      operations.add((method: 'GET', path: _canonicalPath(path)));
    }
  }
  return operations;
}

String _canonicalPath(String raw) => raw
    .replaceAll(RegExp(r'\$\{[^}]+\}'), '{}')
    .replaceAll(RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*'), '{}')
    .replaceAll(RegExp(r'\{[^}/]+\}'), '{}');

Map<String, Object?> _object(Object? value, String label) {
  if (value is! Map) throw FormatException('$label must be a JSON object.');
  return Map<String, Object?>.from(value);
}

Never _fail(List<String> errors) {
  for (final error in errors) {
    stderr.writeln('ERROR: $error');
  }
  exit(1);
}
