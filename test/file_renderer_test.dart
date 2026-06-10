import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klangk_plugin_api/klangk_plugin_api.dart';

/// A fake renderer that matches files by extension, for registry tests.
class FakeRenderer extends FileRenderer {
  FakeRenderer({
    required this.id,
    required this.priority,
    required this.matchExtensions,
    this.modeLabel = 'View',
  });

  @override
  final String id;

  @override
  final int priority;

  @override
  final String modeLabel;

  final Set<String> matchExtensions;

  @override
  IconData get icon => Icons.description;

  @override
  bool canRender(RenderableFile file) =>
      matchExtensions.contains(file.extension);

  @override
  Widget build(BuildContext context, RenderableFile file) =>
      Text('rendered ${file.name}');
}

/// A fake plugin contributing two renderers.
class FakeRendererPlugin extends FileRendererPlugin {
  @override
  List<FileRenderer> get fileRenderers => [
        FakeRenderer(id: 'a', priority: 10, matchExtensions: {'md'}),
        FakeRenderer(id: 'b', priority: 5, matchExtensions: {'txt'}),
      ];
}

RenderableFile makeFile({
  String path = 'docs/readme.md',
  String name = 'readme.md',
  String extension = 'md',
  String? mimeType,
}) {
  return RenderableFile(
    path: path,
    name: name,
    extension: extension,
    mimeType: mimeType,
    readText: () async => 'text:$name',
    readBytes: () async => Uint8List.fromList([1, 2, 3]),
    downloadUrl: 'https://example.test/$path',
  );
}

void main() {
  group('RenderableFile', () {
    test('exposes its fields and lazy loaders', () async {
      final file = makeFile(mimeType: 'text/markdown');
      expect(file.path, 'docs/readme.md');
      expect(file.name, 'readme.md');
      expect(file.extension, 'md');
      expect(file.mimeType, 'text/markdown');
      expect(file.downloadUrl, 'https://example.test/docs/readme.md');
      expect(await file.readText(), 'text:readme.md');
      expect(await file.readBytes(), Uint8List.fromList([1, 2, 3]));
    });

    test('mimeType defaults to null', () {
      expect(makeFile().mimeType, isNull);
    });

    test('saveText defaults to null (read-only)', () {
      expect(makeFile().saveText, isNull);
    });

    test('saveText, when provided, persists content', () async {
      String? saved;
      final file = RenderableFile(
        path: 'a.txt',
        name: 'a.txt',
        extension: 'txt',
        readText: () async => 'old',
        readBytes: () async => Uint8List.fromList([0]),
        downloadUrl: 'u',
        saveText: (content) async => saved = content,
      );
      await file.saveText!('new content');
      expect(saved, 'new content');
    });
  });

  group('FileRenderer', () {
    testWidgets('exposes metadata and builds a widget', (tester) async {
      final renderer = FakeRenderer(
        id: 'fake',
        priority: 3,
        matchExtensions: {'md'},
        modeLabel: 'Raw',
      );
      expect(renderer.id, 'fake');
      expect(renderer.priority, 3);
      expect(renderer.modeLabel, 'Raw');
      expect(renderer.icon, Icons.description);
      expect(renderer.canRender(makeFile()), isTrue);
      expect(renderer.canRender(makeFile(extension: 'png')), isFalse);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) => renderer.build(context, makeFile()),
          ),
        ),
      );
      expect(find.text('rendered readme.md'), findsOneWidget);
    });
  });

  group('FileRendererRegistry', () {
    late FileRendererRegistry registry;

    setUp(() {
      registry = FileRendererRegistry();
    });

    test('register adds a renderer', () {
      final r = FakeRenderer(id: 'a', priority: 1, matchExtensions: {'md'});
      registry.register(r);
      expect(registry.renderers, [r]);
    });

    test('registerAll adds renderers in order', () {
      final a = FakeRenderer(id: 'a', priority: 1, matchExtensions: {'md'});
      final b = FakeRenderer(id: 'b', priority: 2, matchExtensions: {'md'});
      registry.registerAll([a, b]);
      expect(registry.renderers, [a, b]);
    });

    test('renderers getter is unmodifiable', () {
      registry.register(
        FakeRenderer(id: 'a', priority: 1, matchExtensions: {'md'}),
      );
      expect(
        () => registry.renderers.add(
          FakeRenderer(id: 'x', priority: 0, matchExtensions: {'md'}),
        ),
        throwsUnsupportedError,
      );
    });

    test('renderersFor filters by canRender', () {
      final md = FakeRenderer(id: 'md', priority: 1, matchExtensions: {'md'});
      final png =
          FakeRenderer(id: 'png', priority: 1, matchExtensions: {'png'});
      registry.registerAll([md, png]);
      expect(registry.renderersFor(makeFile(extension: 'md')), [md]);
      expect(registry.renderersFor(makeFile(extension: 'png')), [png]);
    });

    test('renderersFor sorts by priority descending', () {
      final low = FakeRenderer(id: 'low', priority: 1, matchExtensions: {'md'});
      final high = FakeRenderer(
        id: 'high',
        priority: 10,
        matchExtensions: {'md'},
      );
      final mid = FakeRenderer(id: 'mid', priority: 5, matchExtensions: {'md'});
      registry.registerAll([low, high, mid]);
      expect(registry.renderersFor(makeFile()), [high, mid, low]);
    });

    test('renderersFor keeps registration order on priority ties', () {
      final first = FakeRenderer(
        id: 'first',
        priority: 5,
        matchExtensions: {'md'},
      );
      final second = FakeRenderer(
        id: 'second',
        priority: 5,
        matchExtensions: {'md'},
      );
      final third = FakeRenderer(
        id: 'third',
        priority: 5,
        matchExtensions: {'md'},
      );
      registry.registerAll([first, second, third]);
      expect(registry.renderersFor(makeFile()), [first, second, third]);
    });

    test('renderersFor returns empty when nothing matches', () {
      registry.register(
        FakeRenderer(id: 'md', priority: 1, matchExtensions: {'md'}),
      );
      expect(registry.renderersFor(makeFile(extension: 'pdf')), isEmpty);
    });
  });

  group('FileRendererPlugin', () {
    test('exposes its contributed renderers', () {
      final plugin = FakeRendererPlugin();
      expect(plugin.fileRenderers, hasLength(2));
      expect(plugin.fileRenderers.map((r) => r.id), ['a', 'b']);
    });

    test('contributed renderers can be registered', () {
      final registry = FileRendererRegistry();
      registry.registerAll(FakeRendererPlugin().fileRenderers);
      expect(registry.renderersFor(makeFile(extension: 'md')).single.id, 'a');
      expect(
        registry.renderersFor(makeFile(extension: 'txt')).single.id,
        'b',
      );
    });
  });
}
