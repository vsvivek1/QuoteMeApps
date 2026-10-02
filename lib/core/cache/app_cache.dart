import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_cache.g.dart';

/// Server rows kept on device for stale-while-revalidate reads.
///
/// One generic table for every entity keeps the schema shared and stable:
/// `kind` is the entity (request, quote, lead, chat, message), `scope` groups
/// rows for a list query (e.g. the request id for its quotes), and `json` is
/// the server row exactly as the Supabase repository received it.
class CachedRows extends Table {
  TextColumn get kind => text()();
  TextColumn get id => text()();
  TextColumn get scope => text().withDefault(const Constant(''))();
  TextColumn get json => text()();
  IntColumn get sortKey => integer().withDefault(const Constant(0))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {kind, id};
}

/// Writes made while offline (drafts, chat messages), replayed in order.
class OutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  TextColumn get payload => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [CachedRows, OutboxEntries])
class AppCache extends _$AppCache {
  AppCache(super.e);

  /// Opens the database file for one flavor, e.g. `iwant_india_prod`.
  /// Same schema for every flavor; only the file differs (brief Section 23).
  factory AppCache.forFlavor(String country, String env) => AppCache(driftDatabase(name: 'iwant_${country}_$env'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('CREATE INDEX IF NOT EXISTS cached_rows_scope ON cached_rows (kind, scope, sort_key)');
    },
  );

  Future<void> putRows(String kind, Map<String, String> jsonById, {String scope = '', bool replaceScope = false}) =>
      transaction(() async {
        if (replaceScope) {
          await (delete(cachedRows)..where((t) => t.kind.equals(kind) & t.scope.equals(scope))).go();
        }
        final now = DateTime.now();
        var i = 0;
        await batch((b) {
          for (final e in jsonById.entries) {
            b.insert(
              cachedRows,
              CachedRowsCompanion.insert(
                kind: kind,
                id: e.key,
                scope: Value(scope),
                json: e.value,
                sortKey: Value(i++),
                cachedAt: now,
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
      });

  Future<List<String>> rowsInScope(String kind, String scope) async {
    final q = select(cachedRows)
      ..where((t) => t.kind.equals(kind) & t.scope.equals(scope))
      ..orderBy([(t) => OrderingTerm.asc(t.sortKey)]);
    return (await q.get()).map((r) => r.json).toList();
  }

  Future<String?> row(String kind, String id) async {
    final q = select(cachedRows)..where((t) => t.kind.equals(kind) & t.id.equals(id));
    return (await q.getSingleOrNull())?.json;
  }

  Future<void> removeRow(String kind, String id) =>
      (delete(cachedRows)..where((t) => t.kind.equals(kind) & t.id.equals(id))).go();

  /// Drops everything (sign-out, account deletion).
  Future<void> clearAll() => transaction(() async {
    await delete(cachedRows).go();
    await delete(outboxEntries).go();
  });

  Future<int> enqueue(String kind, String payload, {DateTime? at}) {
    final now = at ?? DateTime.now();
    return into(outboxEntries)
        .insert(OutboxEntriesCompanion.insert(kind: kind, payload: payload, nextAttemptAt: now, createdAt: now));
  }

  Future<List<OutboxEntry>> pendingEntries() => (select(outboxEntries)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Stream<int> watchPendingCount() => (selectOnly(
    outboxEntries,
  )..addColumns([outboxEntries.id.count()])).map((r) => r.read(outboxEntries.id.count()) ?? 0).watchSingle();

  Future<void> completeEntry(int id) => (delete(outboxEntries)..where((t) => t.id.equals(id))).go();

  Future<void> failEntry(OutboxEntry e, String error, DateTime retryAt) =>
      (update(outboxEntries)..where((t) => t.id.equals(e.id))).write(
        OutboxEntriesCompanion(attempts: Value(e.attempts + 1), lastError: Value(error), nextAttemptAt: Value(retryAt)),
      );
}
