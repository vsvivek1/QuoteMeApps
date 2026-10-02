import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/async_view.dart';
import '../../audit/application/audit_providers.dart';
import '../application/trends_providers.dart';
import '../domain/trends_models.dart';
import 'trends_widgets.dart';

/// Live trend board by place (hottest first) and the polled feeds. Refreshes
/// every minute (polling runs every 5 minutes); failing feeds are shown on top.
class BoardTab extends ConsumerStatefulWidget {
  const BoardTab({super.key});

  @override
  ConsumerState<BoardTab> createState() => _BoardTabState();
}

class _BoardTabState extends ConsumerState<BoardTab> {
  static const hourOptions = [6, 24, 72];
  int _hours = 24;
  String _place = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) ref.invalidate(trendBoardProvider(_hours));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final board = ref.watch(trendBoardProvider(_hours));
    return AsyncView(
      value: board,
      onRetry: () => ref.invalidate(trendBoardProvider(_hours)),
      builder: (b) {
        final places = b.placesMatching(_place);
        final failing = b.failingSources;
        return ListView(padding: const EdgeInsets.all(16), children: [
          Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [for (final h in hourOptions) ButtonSegment(value: h, label: Text(l.trendsLastHours(h)))],
              selected: {_hours},
              onSelectionChanged: (v) => setState(() => _hours = v.first),
            ),
            SizedBox(
              width: 240,
              child: TextField(
                key: const ValueKey('trends-place-filter'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.place_outlined),
                  hintText: l.trendsPlaceFilter,
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _place = v),
              ),
            ),
            Text(l.trendsGeneratedAt(fmtDateTime(b.generatedAt)), style: Theme.of(context).textTheme.bodySmall),
          ]),
          if (failing.isNotEmpty) ...[
            const SizedBox(height: 12),
            _FailingSources(failing),
          ],
          const SizedBox(height: 12),
          if (places.isEmpty)
            Padding(padding: const EdgeInsets.all(24), child: EmptyState(l.trendsNoTopics))
          else
            for (final p in places) _PlaceCard(p),
          const SizedBox(height: 16),
          _SourcesCard(b.sources),
        ]);
      },
    );
  }
}

class _FailingSources extends StatelessWidget {
  const _FailingSources(this.sources);
  final List<TrendSource> sources;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final l = context.l10n;
    return Card(
      color: s.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, color: s.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l.trendsFailingSources(sources.length),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: s.onErrorContainer)),
            ),
          ]),
          const SizedBox(height: 6),
          for (final f in sources)
            Text('${f.kind.wire} ${f.geo} ${f.placeName}${f.query == null ? '' : ' (${f.query})'}: ${f.lastError ?? '-'} '
                '(${fmtDateTime(f.lastPolledAt)})',
                style: TextStyle(color: s.onErrorContainer)),
        ]),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard(this.p);
  final TrendPlace p;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('${p.placeName}  ·  ${countryLabel(context, p.country)}${p.level == null ? '' : '  ·  ${p.level}'}',
                  style: t.titleMedium),
            ),
            VelocityBar(p.maxVelocity),
          ]),
          const Divider(),
          for (final topic in p.topics)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(spacing: 12, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 220, maxWidth: 360),
                  child: Text(topic.title, style: t.bodyLarge),
                ),
                TopicStatusChip(topic.status),
                VelocityBar(topic.velocity, width: 70),
                Text(context.l10n.trendsSignalsDomains(topic.signalCount, topic.domainCount), style: t.bodySmall),
                if (topic.domains.isNotEmpty)
                  Tooltip(
                    message: topic.domains.join('\n'),
                    child: const Icon(Icons.public, size: 16),
                  ),
                if (topic.firedAt != null)
                  Text(context.l10n.trendsFiredAt(fmtDateTime(topic.firedAt)), style: t.bodySmall),
                if (topic.statusReason != null) Text(topic.statusReason!, style: t.bodySmall),
                if (topic.articleSlug != null) SelectableText('/${topic.articleSlug}', style: t.bodySmall),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _SourcesCard extends ConsumerWidget {
  const _SourcesCard(this.sources);
  final List<TrendSource> sources;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(l.trendsSources, style: Theme.of(context).textTheme.titleMedium)),
            OutlinedButton.icon(
              onPressed: () async {
                final draft = await showDialog<TrendSourceDraft>(context: context, builder: (_) => const AddSourceDialog());
                if (draft == null || !context.mounted) return;
                try {
                  await ref.read(trendsRepositoryProvider).addSource(draft);
                  invalidateTrends(ref);
                  ref.invalidate(auditLogProvider);
                  if (context.mounted) context.toast(l.saved);
                } catch (e) {
                  if (context.mounted) showTrendsError(context, e);
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l.trendsAddSource),
            ),
          ]),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(l.trendsColKind)),
                DataColumn(label: Text(l.trendsColCountry)),
                DataColumn(label: Text(l.trendsColGeo)),
                DataColumn(label: Text(l.trendsColPlace)),
                DataColumn(label: Text(l.trendsColQuery)),
                DataColumn(label: Text(l.trendsColStatus)),
                DataColumn(label: Text(l.trendsColItems), numeric: true),
                DataColumn(label: Text(l.trendsColPolled)),
                DataColumn(label: Text(l.trendsColEnabled)),
              ],
              rows: [
                for (final src in sources)
                  DataRow(
                    color: WidgetStatePropertyAll(src.failing ? s.errorContainer.withValues(alpha: 0.5) : null),
                    cells: [
                      DataCell(Text(src.kind.wire)),
                      DataCell(Text(countryLabel(context, src.country))),
                      DataCell(Text(src.geo)),
                      DataCell(Text('${src.placeName} (${src.level})')),
                      DataCell(Text(src.query ?? '-')),
                      DataCell(Tooltip(
                        message: src.lastError ?? '',
                        child: Text(src.enabled ? (src.lastStatus ?? '-') : l.trendsDisabled),
                      )),
                      DataCell(Text(fmtInt(src.lastItems))),
                      DataCell(Text(fmtDateTime(src.lastPolledAt))),
                      DataCell(Switch(
                        value: src.enabled,
                        onChanged: (v) async {
                          try {
                            await ref.read(trendsRepositoryProvider).setSourceEnabled(src.id, v);
                            invalidateTrends(ref);
                            ref.invalidate(auditLogProvider);
                          } catch (e) {
                            if (context.mounted) showTrendsError(context, e);
                          }
                        },
                      )),
                    ],
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// New Google Trends geo, Google News query or subreddit.
class AddSourceDialog extends StatefulWidget {
  const AddSourceDialog({super.key});

  @override
  State<AddSourceDialog> createState() => _AddSourceDialogState();
}

class _AddSourceDialogState extends State<AddSourceDialog> {
  var _kind = SourceKind.googleNews;
  var _country = TrendsCountry.india;
  var _level = 'metro';
  final _geo = TextEditingController();
  final _slug = TextEditingController();
  final _name = TextEditingController();
  final _state = TextEditingController();
  final _query = TextEditingController();

  @override
  void dispose() {
    for (final c in [_geo, _slug, _name, _state, _query]) {
      c.dispose();
    }
    super.dispose();
  }

  TrendSourceDraft get _draft => TrendSourceDraft(
        kind: _kind,
        country: _country,
        geo: _geo.text,
        placeSlug: _slug.text,
        placeName: _name.text,
        level: _level,
        state: _state.text,
        query: _query.text,
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final err = _draft.validate();
    Widget field(TextEditingController c, String label, {String? helper}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: c,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: label, helperText: helper),
          ),
        );
    return AlertDialog(
      title: Text(l.trendsAddSource),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<SourceKind>(
              initialValue: _kind,
              decoration: InputDecoration(labelText: l.trendsColKind),
              items: [for (final k in SourceKind.values) DropdownMenuItem(value: k, child: Text(k.wire))],
              onChanged: (v) => setState(() => _kind = v ?? _kind),
            ),
            DropdownButtonFormField<TrendsCountry>(
              initialValue: _country,
              decoration: InputDecoration(labelText: l.trendsColCountry),
              items: [for (final c in TrendsCountry.values) DropdownMenuItem(value: c, child: Text(countryLabel(context, c)))],
              onChanged: (v) => setState(() => _country = v ?? _country),
            ),
            DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: InputDecoration(labelText: l.trendsLevel),
              items: [for (final x in placeLevels) DropdownMenuItem(value: x, child: Text(x))],
              onChanged: (v) => setState(() => _level = v ?? _level),
            ),
            field(_geo, l.trendsColGeo, helper: 'IN, IN-MH, US, US-CA'),
            field(_slug, l.trendsPlaceSlug, helper: 'pune'),
            field(_name, l.trendsPlaceName),
            field(_state, l.trendsState),
            field(_query, l.trendsColQuery, helper: l.trendsQueryHelp),
            if (err != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(err, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: err == null ? () => Navigator.pop(context, _draft) : null, child: Text(l.save)),
      ],
    );
  }
}
