// Code index generator for Dart/Flutter projects.
//
// Walks a source directory and emits a markdown outline per sub-directory
// under <out>/, optimized for LLM (Claude Code) consumption. Output captures
// classes, mixins, extensions, enums, top-level functions/vars, with line
// numbers for targeted Read offset/limit reads.
//
// Usage:
//   dart run tool/code_index.dart                                  # full regen
//   dart run tool/code_index.dart --files lib/foo.dart ...         # incremental
//   dart run tool/code_index.dart --source src --out docs/.code-map
//   dart run tool/code_index.dart --exclude-suffix .gen.dart
//   dart run tool/code_index.dart --quiet
//
// Defaults:
//   source dir         lib
//   output dir         docs/.code-map
//   excluded suffixes  .g.dart, .freezed.dart
//   excluded prefixes  app_localizations
//
// Part of: claude-conf / code-index (https://github.com/Bidiche49/claude-conf)

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

const _outDirDefault = 'docs/.code-map';
const _sourceDirDefault = 'lib';
const _defaultExcludeSuffixes = <String>{'.g.dart', '.freezed.dart'};
const _defaultExcludeNamePrefixes = <String>{'app_localizations'};

void main(List<String> args) async {
  final stopwatch = Stopwatch()..start();
  final config = _parseArgs(args);

  final files = config.specificFiles ?? await _discoverFiles(config.root, config.sourceDir);
  final dartFiles = files.where((f) => _isIndexable(f, config)).toList()..sort();

  if (!config.quiet) {
    stderr.writeln('[code_index] ${dartFiles.length} files to index');
  }

  final outlinesByDir = <String, List<_FileOutline>>{};
  var parsed = 0;
  var failed = 0;

  for (final filePath in dartFiles) {
    try {
      final outline = await _parseFileOutline(filePath, config.root, config.sourceDir);
      final dirKey = _dirKey(filePath, config.root, config.sourceDir);
      outlinesByDir.putIfAbsent(dirKey, () => []).add(outline);
      parsed++;
    } catch (e) {
      failed++;
      if (!config.quiet) {
        stderr.writeln('[code_index] FAIL ${p.relative(filePath, from: config.root)}: $e');
      }
    }
  }

  // Write per-directory markdown files.
  final outDir = Directory(p.join(config.root, config.outDir));
  if (config.specificFiles == null) {
    if (outDir.existsSync()) outDir.deleteSync(recursive: true);
  }
  outDir.createSync(recursive: true);

  for (final entry in outlinesByDir.entries) {
    entry.value.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    final outFile = File(p.join(outDir.path, '${_safeName(entry.key)}.md'));
    outFile.writeAsStringSync(_renderDirMd(entry.key, entry.value, config.sourceDir));
  }

  // Emit global INDEX.md (light: dirs only) + SYMBOLS.md (exhaustive dump).
  if (config.specificFiles == null) {
    File(p.join(outDir.path, 'INDEX.md')).writeAsStringSync(
      _renderIndexMd(outlinesByDir, parsed, failed, stopwatch.elapsed, config.sourceDir),
    );
    File(p.join(outDir.path, 'SYMBOLS.md')).writeAsStringSync(
      _renderSymbolsMd(outlinesByDir),
    );
  }

  stopwatch.stop();
  if (!config.quiet) {
    stderr.writeln(
      '[code_index] done — $parsed parsed, $failed failed, '
      '${outlinesByDir.length} dirs, ${stopwatch.elapsedMilliseconds}ms',
    );
  }
}

// -----------------------------------------------------------------------------
// CLI args
// -----------------------------------------------------------------------------

class _Config {
  _Config({
    required this.root,
    required this.sourceDir,
    required this.outDir,
    required this.excludeSuffixes,
    required this.excludeNamePrefixes,
    required this.quiet,
    required this.specificFiles,
  });

  final String root;
  final String sourceDir;
  final String outDir;
  final Set<String> excludeSuffixes;
  final Set<String> excludeNamePrefixes;
  final bool quiet;
  final List<String>? specificFiles;
}

_Config _parseArgs(List<String> args) {
  var root = Directory.current.path;
  var sourceDir = _sourceDirDefault;
  var outDir = _outDirDefault;
  var quiet = false;
  List<String>? specific;
  final excludeSuffixes = <String>{..._defaultExcludeSuffixes};
  final excludePrefixes = <String>{..._defaultExcludeNamePrefixes};
  var suffixesReset = false;
  var prefixesReset = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    switch (a) {
      case '--root':
        root = args[++i];
      case '--source':
        sourceDir = args[++i];
      case '--out':
        outDir = args[++i];
      case '--quiet':
        quiet = true;
      case '--files':
        specific = [];
        while (i + 1 < args.length && !args[i + 1].startsWith('--')) {
          specific.add(p.absolute(args[++i]));
        }
      case '--exclude-suffix':
        if (!suffixesReset) {
          excludeSuffixes.clear();
          suffixesReset = true;
        }
        excludeSuffixes.add(args[++i]);
      case '--exclude-prefix':
        if (!prefixesReset) {
          excludePrefixes.clear();
          prefixesReset = true;
        }
        excludePrefixes.add(args[++i]);
      case '--no-default-excludes':
        excludeSuffixes.clear();
        excludePrefixes.clear();
        suffixesReset = true;
        prefixesReset = true;
      case '-h':
      case '--help':
        _printHelp();
        exit(0);
      default:
        stderr.writeln('Unknown arg: $a');
        _printHelp();
        exit(2);
    }
  }

  return _Config(
    root: p.absolute(root),
    sourceDir: sourceDir,
    outDir: outDir,
    excludeSuffixes: excludeSuffixes,
    excludeNamePrefixes: excludePrefixes,
    quiet: quiet,
    specificFiles: specific,
  );
}

void _printHelp() {
  stdout.writeln('''
code_index — generate per-directory markdown outlines for Claude Code.

Usage:
  dart run tool/code_index.dart [options]

Options:
  --root <dir>             Project root (default: cwd)
  --source <dir>           Source directory to walk, relative to root
                           (default: $_sourceDirDefault)
  --out <dir>              Output directory, relative to root
                           (default: $_outDirDefault)
  --files <f1> <f2>...     Only re-index these files (incremental mode)
  --exclude-suffix <s>     Exclude files ending in <s>; repeatable.
                           First use replaces defaults (${_defaultExcludeSuffixes.join(', ')}).
  --exclude-prefix <s>     Exclude files starting with <s>; repeatable.
                           First use replaces defaults (${_defaultExcludeNamePrefixes.join(', ')}).
  --no-default-excludes    Clear all default exclusions before adding any custom ones.
  --quiet                  Suppress non-error output.
  -h, --help               Show this help.

Defaults are tuned for Flutter projects with Freezed/build_runner. For other
Dart projects, you may want --no-default-excludes plus your own filters.
''');
}

// -----------------------------------------------------------------------------
// Discovery
// -----------------------------------------------------------------------------

bool _isIndexable(String path, _Config config) {
  final name = p.basename(path);
  if (!name.endsWith('.dart')) return false;
  for (final s in config.excludeSuffixes) {
    if (name.endsWith(s)) return false;
  }
  for (final pfx in config.excludeNamePrefixes) {
    if (name.startsWith(pfx)) return false;
  }
  return true;
}

Future<List<String>> _discoverFiles(String root, String sourceDir) async {
  final dir = Directory(p.join(root, sourceDir));
  if (!dir.existsSync()) return const [];

  final results = <String>[];
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File) results.add(entity.path);
  }
  return results;
}

String _dirKey(String filePath, String root, String sourceDir) {
  final rel = p.relative(filePath, from: p.join(root, sourceDir));
  final dir = p.dirname(rel);
  return dir == '.' ? '_root' : dir;
}

String _safeName(String dirKey) =>
    dirKey.replaceAll(p.separator, '_').replaceAll('/', '_');

String _displayDir(String dirKey, String sourceDir) {
  final src = sourceDir.endsWith('/') ? sourceDir : '$sourceDir/';
  return dirKey == '_root' ? src : '$src$dirKey/';
}

// -----------------------------------------------------------------------------
// Parsing
// -----------------------------------------------------------------------------

class _FileOutline {
  _FileOutline({
    required this.relativePath,
    required this.lineCount,
    required this.imports,
    required this.declarations,
  });

  final String relativePath;
  final int lineCount;
  final List<String> imports;
  final List<_Declaration> declarations;
}

class _Declaration {
  _Declaration({
    required this.kind, // class, mixin, extension, enum, fn, var, typedef
    required this.name,
    required this.signature,
    required this.lineStart,
    required this.lineEnd,
    this.extendsClause,
    this.withClause,
    this.implementsClause,
    this.fields = const [],
    this.constructors = const [],
    this.publicMethods = const [],
    this.privateMethods = const [],
    this.publicAccessors = const [],
    this.privateAccessors = const [],
  });

  final String kind;
  final String name;
  final String signature;
  final int lineStart;
  final int lineEnd;
  final String? extendsClause;
  final String? withClause;
  final String? implementsClause;
  final List<_Member> fields;
  final List<_Member> constructors;
  final List<_Member> publicMethods;
  final List<_Member> privateMethods;
  final List<_Member> publicAccessors; // getters/setters public
  final List<_Member> privateAccessors;
}

class _Member {
  _Member({required this.signature, required this.line});

  final String signature;
  final int line;
}

Future<_FileOutline> _parseFileOutline(
    String filePath, String root, String sourceDir) async {
  final content = await File(filePath).readAsString();
  final result = parseString(content: content, path: filePath, throwIfDiagnostics: false);
  final unit = result.unit;
  final lineInfo = result.lineInfo;
  final lineCount = lineInfo.lineCount;

  final imports = <String>[];
  for (final dir in unit.directives) {
    if (dir is ImportDirective) {
      final uri = dir.uri.stringValue;
      if (uri != null && !uri.startsWith('dart:') && uri != 'package:flutter/material.dart') {
        // Trim package: prefix for compactness; keep relative paths intact
        imports.add(uri.replaceFirst('package:', ''));
      }
    }
  }

  final decls = <_Declaration>[];
  for (final member in unit.declarations) {
    final d = _declarationFor(member, lineInfo);
    if (d != null) decls.add(d);
  }

  return _FileOutline(
    relativePath: p.relative(filePath, from: p.join(root, sourceDir)),
    lineCount: lineCount,
    imports: imports,
    declarations: decls,
  );
}

_Declaration? _declarationFor(CompilationUnitMember member, LineInfo lineInfo) {
  final start = lineInfo.getLocation(member.offset).lineNumber;
  final end = lineInfo.getLocation(member.offset + member.length).lineNumber;

  if (member is ClassDeclaration) {
    return _classDeclaration(member, lineInfo, start, end);
  }
  if (member is MixinDeclaration) {
    return _mixinDeclaration(member, lineInfo, start, end);
  }
  if (member is ExtensionDeclaration) {
    return _extensionDeclaration(member, lineInfo, start, end);
  }
  if (member is EnumDeclaration) {
    final values = member.constants.map((c) => c.name.lexeme).join(', ');
    return _Declaration(
      kind: 'enum',
      name: member.name.lexeme,
      signature: 'enum ${member.name.lexeme} { $values }',
      lineStart: start,
      lineEnd: end,
    );
  }
  if (member is FunctionDeclaration) {
    final isPrivate = member.name.lexeme.startsWith('_');
    final sig = _functionSignature(member);
    return _Declaration(
      kind: isPrivate ? 'fn(private)' : 'fn',
      name: member.name.lexeme,
      signature: sig,
      lineStart: start,
      lineEnd: end,
    );
  }
  if (member is TopLevelVariableDeclaration) {
    final names = member.variables.variables.map((v) => v.name.lexeme).join(', ');
    final type = member.variables.type?.toSource() ?? '';
    final keyword = member.variables.keyword?.lexeme ?? '';
    final parts = [
      if (keyword.isNotEmpty) keyword,
      if (type.isNotEmpty) type,
      names,
    ];
    return _Declaration(
      kind: 'var',
      name: names,
      signature: parts.join(' ').trim(),
      lineStart: start,
      lineEnd: end,
    );
  }
  if (member is FunctionTypeAlias || member is GenericTypeAlias) {
    final name = (member as dynamic).name?.lexeme ?? '?';
    return _Declaration(
      kind: 'typedef',
      name: name,
      signature: 'typedef $name = ${(member).toSource().split('=').skip(1).join('=').trim()}',
      lineStart: start,
      lineEnd: end,
    );
  }
  return null;
}

_Declaration _classDeclaration(
    ClassDeclaration cls, LineInfo lineInfo, int start, int end) {
  final fields = <_Member>[];
  final ctors = <_Member>[];
  final pubMethods = <_Member>[];
  final privMethods = <_Member>[];
  final pubAcc = <_Member>[];
  final privAcc = <_Member>[];

  for (final m in cls.members) {
    final mLine = lineInfo.getLocation(m.offset).lineNumber;
    if (m is FieldDeclaration) {
      for (final v in m.fields.variables) {
        final name = v.name.lexeme;
        final type = m.fields.type?.toSource();
        final modifiers = <String>[
          if (m.isStatic) 'static',
          ...m.fields.keyword == null ? const [] : [m.fields.keyword!.lexeme],
        ];
        final mod = modifiers.isEmpty ? '' : '${modifiers.join(' ')} ';
        final typeStr = type == null ? '' : '$type ';
        fields.add(_Member(signature: '$mod$typeStr$name', line: mLine));
      }
    } else if (m is ConstructorDeclaration) {
      final ctorName = m.name?.lexeme;
      final params = _paramListShort(m.parameters);
      final base = ctorName == null
          ? '${cls.name.lexeme}($params)'
          : '${cls.name.lexeme}.$ctorName($params)';
      final modifiers = [
        if (m.factoryKeyword != null) 'factory',
        if (m.constKeyword != null) 'const',
      ].join(' ');
      final sig = modifiers.isEmpty ? base : '$modifiers $base';
      ctors.add(_Member(signature: sig, line: mLine));
    } else if (m is MethodDeclaration) {
      final name = m.name.lexeme;
      final isPrivate = name.startsWith('_');
      final retType = m.returnType?.toSource() ?? '';
      if (m.isGetter) {
        final sig = '${retType.isEmpty ? '' : '$retType '}get $name';
        (isPrivate ? privAcc : pubAcc).add(_Member(signature: sig, line: mLine));
      } else if (m.isSetter) {
        final params = _paramListShort(m.parameters);
        final sig = 'set $name($params)';
        (isPrivate ? privAcc : pubAcc).add(_Member(signature: sig, line: mLine));
      } else {
        final params = _paramListShort(m.parameters);
        final modifiers = <String>[
          if (m.isStatic) 'static',
          if (m.isAbstract) 'abstract',
        ];
        final mod = modifiers.isEmpty ? '' : '${modifiers.join(' ')} ';
        final sig = '$mod$name($params)${retType.isEmpty ? '' : ' → $retType'}';
        (isPrivate ? privMethods : pubMethods).add(_Member(signature: sig, line: mLine));
      }
    }
  }

  final extendsName = cls.extendsClause?.superclass.toSource();
  final withNames = cls.withClause?.mixinTypes.map((t) => t.toSource()).join(', ');
  final implName = cls.implementsClause?.interfaces.map((t) => t.toSource()).join(', ');

  final modifiers = <String>[
    if (cls.abstractKeyword != null) 'abstract',
    if (cls.sealedKeyword != null) 'sealed',
    if (cls.finalKeyword != null) 'final',
    if (cls.baseKeyword != null) 'base',
    if (cls.interfaceKeyword != null) 'interface',
    if (cls.mixinKeyword != null) 'mixin class',
  ];
  final modPrefix = modifiers.isEmpty ? '' : '${modifiers.join(' ')} ';

  final sig = StringBuffer('${modPrefix}class ${cls.name.lexeme}');
  if (cls.typeParameters != null) sig.write(cls.typeParameters!.toSource());
  if (extendsName != null) sig.write(' extends $extendsName');
  if (withNames != null && withNames.isNotEmpty) sig.write(' with $withNames');
  if (implName != null && implName.isNotEmpty) sig.write(' implements $implName');

  return _Declaration(
    kind: 'class',
    name: cls.name.lexeme,
    signature: sig.toString(),
    lineStart: start,
    lineEnd: end,
    extendsClause: extendsName,
    withClause: withNames,
    implementsClause: implName,
    fields: fields,
    constructors: ctors,
    publicMethods: pubMethods,
    privateMethods: privMethods,
    publicAccessors: pubAcc,
    privateAccessors: privAcc,
  );
}

_Declaration _mixinDeclaration(
    MixinDeclaration m, LineInfo lineInfo, int start, int end) {
  final pubMethods = <_Member>[];
  final privMethods = <_Member>[];
  final pubAcc = <_Member>[];
  final privAcc = <_Member>[];
  final fields = <_Member>[];

  for (final mem in m.members) {
    final mLine = lineInfo.getLocation(mem.offset).lineNumber;
    if (mem is MethodDeclaration) {
      final name = mem.name.lexeme;
      final isPrivate = name.startsWith('_');
      final retType = mem.returnType?.toSource() ?? '';
      if (mem.isGetter) {
        final sig = '${retType.isEmpty ? '' : '$retType '}get $name';
        (isPrivate ? privAcc : pubAcc).add(_Member(signature: sig, line: mLine));
      } else if (mem.isSetter) {
        final sig = 'set $name(${_paramListShort(mem.parameters)})';
        (isPrivate ? privAcc : pubAcc).add(_Member(signature: sig, line: mLine));
      } else {
        final params = _paramListShort(mem.parameters);
        final sig = '$name($params)${retType.isEmpty ? '' : ' → $retType'}';
        (isPrivate ? privMethods : pubMethods).add(_Member(signature: sig, line: mLine));
      }
    } else if (mem is FieldDeclaration) {
      for (final v in mem.fields.variables) {
        final type = mem.fields.type?.toSource();
        fields.add(_Member(
          signature: '${type == null ? '' : '$type '}${v.name.lexeme}',
          line: mLine,
        ));
      }
    }
  }

  final on = m.onClause?.superclassConstraints.map((t) => t.toSource()).join(', ');
  final sig = StringBuffer('mixin ${m.name.lexeme}');
  if (m.typeParameters != null) sig.write(m.typeParameters!.toSource());
  if (on != null && on.isNotEmpty) sig.write(' on $on');

  return _Declaration(
    kind: 'mixin',
    name: m.name.lexeme,
    signature: sig.toString(),
    lineStart: start,
    lineEnd: end,
    fields: fields,
    publicMethods: pubMethods,
    privateMethods: privMethods,
    publicAccessors: pubAcc,
    privateAccessors: privAcc,
  );
}

_Declaration _extensionDeclaration(
    ExtensionDeclaration ext, LineInfo lineInfo, int start, int end) {
  final pubMethods = <_Member>[];
  final privMethods = <_Member>[];
  final pubAcc = <_Member>[];
  final privAcc = <_Member>[];

  for (final mem in ext.members) {
    final mLine = lineInfo.getLocation(mem.offset).lineNumber;
    if (mem is MethodDeclaration) {
      final name = mem.name.lexeme;
      final isPrivate = name.startsWith('_');
      final retType = mem.returnType?.toSource() ?? '';
      if (mem.isGetter) {
        final sig = '${retType.isEmpty ? '' : '$retType '}get $name';
        (isPrivate ? privAcc : pubAcc).add(_Member(signature: sig, line: mLine));
      } else if (mem.isSetter) {
        final sig = 'set $name(${_paramListShort(mem.parameters)})';
        (isPrivate ? privAcc : pubAcc).add(_Member(signature: sig, line: mLine));
      } else {
        final params = _paramListShort(mem.parameters);
        final sig = '$name($params)${retType.isEmpty ? '' : ' → $retType'}';
        (isPrivate ? privMethods : pubMethods).add(_Member(signature: sig, line: mLine));
      }
    }
  }

  final extName = ext.name?.lexeme ?? '<unnamed>';
  final extOn = ext.onClause?.extendedType.toSource() ?? '?';
  final sig = 'extension $extName on $extOn';

  return _Declaration(
    kind: 'extension',
    name: extName,
    signature: sig,
    lineStart: start,
    lineEnd: end,
    publicMethods: pubMethods,
    privateMethods: privMethods,
    publicAccessors: pubAcc,
    privateAccessors: privAcc,
  );
}

String _functionSignature(FunctionDeclaration fn) {
  final ret = fn.returnType?.toSource() ?? '';
  final name = fn.name.lexeme;
  if (fn.isGetter) return '${ret.isEmpty ? '' : '$ret '}get $name';
  if (fn.isSetter) return 'set $name(${_paramListShort(fn.functionExpression.parameters)})';
  final params = _paramListShort(fn.functionExpression.parameters);
  return '$name($params)${ret.isEmpty ? '' : ' → $ret'}';
}

/// Compact param list — keeps types but drops default values & annotations.
String _paramListShort(FormalParameterList? params) {
  if (params == null) return '';
  final parts = <String>[];
  for (final p in params.parameters) {
    parts.add(_paramShort(p));
  }
  return parts.join(', ');
}

String _paramShort(FormalParameter param) {
  // Strip annotations, default values; keep "required", type, name.
  if (param is DefaultFormalParameter) {
    return _paramShort(param.parameter);
  }
  if (param is SimpleFormalParameter) {
    final type = param.type?.toSource();
    final name = param.name?.lexeme ?? '';
    return type == null ? name : '$type $name'.trim();
  }
  if (param is FieldFormalParameter) {
    final type = param.type?.toSource();
    return type == null ? 'this.${param.name.lexeme}' : '$type this.${param.name.lexeme}';
  }
  if (param is FunctionTypedFormalParameter) {
    return param.toSource();
  }
  if (param is SuperFormalParameter) {
    return 'super.${param.name.lexeme}';
  }
  return param.toSource();
}

// -----------------------------------------------------------------------------
// Markdown rendering
// -----------------------------------------------------------------------------

String _renderDirMd(String dirKey, List<_FileOutline> outlines, String sourceDir) {
  final buf = StringBuffer();
  buf.writeln('# ${_displayDir(dirKey, sourceDir)}');
  buf.writeln();
  buf.writeln('${outlines.length} files · ${outlines.fold<int>(0, (s, o) => s + o.lineCount)} lines total');
  buf.writeln();

  for (final o in outlines) {
    buf.writeln('## ${o.relativePath} · ${o.lineCount} lines');
    if (o.imports.isNotEmpty) {
      final shown = o.imports.take(8).join('`, `');
      final more = o.imports.length > 8 ? ' +${o.imports.length - 8}' : '';
      buf.writeln('imports: `$shown`$more');
    }
    buf.writeln();

    for (final d in o.declarations) {
      _renderDecl(buf, d);
      buf.writeln();
    }
  }

  return buf.toString();
}

void _renderDecl(StringBuffer buf, _Declaration d) {
  buf.writeln('### ${d.signature}  ·  L${d.lineStart}-${d.lineEnd}');

  void section(String label, List<_Member> items) {
    if (items.isEmpty) return;
    final lines = items.map((m) => '`${m.signature}` L${m.line}').join(' · ');
    buf.writeln('- *$label:* $lines');
  }

  section('fields', d.fields);
  section('ctor', d.constructors);
  section('public', d.publicMethods);
  section('getters/setters', d.publicAccessors);
  section('private', d.privateMethods);
  section('private getters/setters', d.privateAccessors);
}

String _renderIndexMd(
  Map<String, List<_FileOutline>> byDir,
  int parsed,
  int failed,
  Duration elapsed,
  String sourceDir,
) {
  final src = sourceDir.endsWith('/') ? sourceDir : '$sourceDir/';
  final buf = StringBuffer();
  buf.writeln('# Code Index');
  buf.writeln();
  buf.writeln('Generated: ${DateTime.now().toIso8601String()}');
  buf.writeln('Source: `$src` — $parsed files parsed, $failed failed, ${elapsed.inMilliseconds}ms');
  buf.writeln();
  buf.writeln('## How to use this index (for Claude Code agents)');
  buf.writeln();
  buf.writeln('1. **First reflex** entering an unfamiliar zone: read the relevant `<dir>.md` (file outlines with line numbers).');
  buf.writeln('2. **Then** use `Read offset=X limit=Y` targeted on specific symbols rather than reading the full file.');
  buf.writeln('3. **To find a symbol globally**: `grep -n "ClassName\\|methodName" <out>/SYMBOLS.md`.');
  buf.writeln('4. **To find call sites in source**: `grep -rn "methodName" $src` (the index does not track references — Grep does).');
  buf.writeln();
  buf.writeln('## Directories');
  buf.writeln();
  buf.writeln('| Directory | Files | Lines | Outline file |');
  buf.writeln('|---|---:|---:|---|');
  final entries = byDir.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  for (final e in entries) {
    final lines = e.value.fold<int>(0, (s, o) => s + o.lineCount);
    final niceDir = _displayDir(e.key, sourceDir);
    buf.writeln('| `$niceDir` | ${e.value.length} | $lines | [`${_safeName(e.key)}.md`](${_safeName(e.key)}.md) |');
  }
  buf.writeln();
  buf.writeln('See [`SYMBOLS.md`](SYMBOLS.md) for the flat grep-friendly dump of every top-level symbol.');

  return buf.toString();
}

String _renderSymbolsMd(Map<String, List<_FileOutline>> byDir) {
  final buf = StringBuffer();
  buf.writeln('# Symbols (flat dump for grep)');
  buf.writeln();
  buf.writeln('Format: `<kind>  <name>  <path>:<line>`. One line per top-level declaration.');
  buf.writeln('Use `grep -n "ClassName" <out>/SYMBOLS.md` to locate any symbol.');
  buf.writeln();
  buf.writeln('```');
  final entries = byDir.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  for (final e in entries) {
    for (final o in e.value) {
      for (final d in o.declarations) {
        buf.writeln('${d.kind.padRight(12)} ${d.name.padRight(40)} ${o.relativePath}:${d.lineStart}');
      }
    }
  }
  buf.writeln('```');
  return buf.toString();
}
