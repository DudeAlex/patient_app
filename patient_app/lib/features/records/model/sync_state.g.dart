// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_state.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncStateCollection on Isar {
  IsarCollection<SyncState> get syncStates => this.collection();
}

const SyncStateSchema = CollectionSchema(
  name: r'SyncState',
  id: 8359124993045979625,
  properties: {
    r'autoSyncCadenceId': PropertySchema(
      id: 0,
      name: r'autoSyncCadenceId',
      type: IsarType.string,
    ),
    r'autoSyncEnabled': PropertySchema(
      id: 1,
      name: r'autoSyncEnabled',
      type: IsarType.bool,
    ),
    r'deviceId': PropertySchema(
      id: 2,
      name: r'deviceId',
      type: IsarType.string,
    ),
    r'lastRemoteModified': PropertySchema(
      id: 3,
      name: r'lastRemoteModified',
      type: IsarType.dateTime,
    ),
    r'lastSyncedAt': PropertySchema(
      id: 4,
      name: r'lastSyncedAt',
      type: IsarType.dateTime,
    ),
    r'localChangeCounter': PropertySchema(
      id: 5,
      name: r'localChangeCounter',
      type: IsarType.long,
    ),
    r'pendingCriticalChanges': PropertySchema(
      id: 6,
      name: r'pendingCriticalChanges',
      type: IsarType.long,
    ),
    r'pendingRoutineChanges': PropertySchema(
      id: 7,
      name: r'pendingRoutineChanges',
      type: IsarType.long,
    )
  },
  estimateSize: _syncStateEstimateSize,
  serialize: _syncStateSerialize,
  deserialize: _syncStateDeserialize,
  deserializeProp: _syncStateDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _syncStateGetId,
  getLinks: _syncStateGetLinks,
  attach: _syncStateAttach,
  version: '3.1.0+1',
);

int _syncStateEstimateSize(
  SyncState object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.autoSyncCadenceId.length * 3;
  bytesCount += 3 + object.deviceId.length * 3;
  return bytesCount;
}

void _syncStateSerialize(
  SyncState object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.autoSyncCadenceId);
  writer.writeBool(offsets[1], object.autoSyncEnabled);
  writer.writeString(offsets[2], object.deviceId);
  writer.writeDateTime(offsets[3], object.lastRemoteModified);
  writer.writeDateTime(offsets[4], object.lastSyncedAt);
  writer.writeLong(offsets[5], object.localChangeCounter);
  writer.writeLong(offsets[6], object.pendingCriticalChanges);
  writer.writeLong(offsets[7], object.pendingRoutineChanges);
}

SyncState _syncStateDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncState();
  object.autoSyncCadenceId = reader.readString(offsets[0]);
  object.autoSyncEnabled = reader.readBool(offsets[1]);
  object.deviceId = reader.readString(offsets[2]);
  object.id = id;
  object.lastRemoteModified = reader.readDateTimeOrNull(offsets[3]);
  object.lastSyncedAt = reader.readDateTimeOrNull(offsets[4]);
  object.localChangeCounter = reader.readLong(offsets[5]);
  object.pendingCriticalChanges = reader.readLong(offsets[6]);
  object.pendingRoutineChanges = reader.readLong(offsets[7]);
  return object;
}

P _syncStateDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncStateGetId(SyncState object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncStateGetLinks(SyncState object) {
  return [];
}

void _syncStateAttach(IsarCollection<dynamic> col, Id id, SyncState object) {
  object.id = id;
}

extension SyncStateQueryWhereSort
    on QueryBuilder<SyncState, SyncState, QWhere> {
  QueryBuilder<SyncState, SyncState, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncStateQueryWhere
    on QueryBuilder<SyncState, SyncState, QWhereClause> {
  QueryBuilder<SyncState, SyncState, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SyncStateQueryFilter
    on QueryBuilder<SyncState, SyncState, QFilterCondition> {
  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      autoSyncCadenceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoSyncCadenceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      autoSyncCadenceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'autoSyncCadenceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      autoSyncCadenceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'autoSyncCadenceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      autoSyncCadenceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'autoSyncCadenceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      autoSyncCadenceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'autoSyncCadenceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      autoSyncCadenceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'autoSyncCadenceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      autoSyncCadenceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'autoSyncCadenceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      autoSyncCadenceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'autoSyncCadenceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      autoSyncCadenceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoSyncCadenceId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      autoSyncCadenceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'autoSyncCadenceId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      autoSyncEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoSyncEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> deviceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> deviceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> deviceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> deviceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deviceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> deviceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> deviceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> deviceIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> deviceIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deviceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      lastRemoteModifiedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastRemoteModified',
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      lastRemoteModifiedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastRemoteModified',
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      lastRemoteModifiedEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastRemoteModified',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      lastRemoteModifiedGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastRemoteModified',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      lastRemoteModifiedLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastRemoteModified',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      lastRemoteModifiedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastRemoteModified',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      lastSyncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      lastSyncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> lastSyncedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      lastSyncedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      lastSyncedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition> lastSyncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      localChangeCounterEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localChangeCounter',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      localChangeCounterGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localChangeCounter',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      localChangeCounterLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localChangeCounter',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      localChangeCounterBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localChangeCounter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      pendingCriticalChangesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingCriticalChanges',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      pendingCriticalChangesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pendingCriticalChanges',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      pendingCriticalChangesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pendingCriticalChanges',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      pendingCriticalChangesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pendingCriticalChanges',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      pendingRoutineChangesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingRoutineChanges',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      pendingRoutineChangesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pendingRoutineChanges',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      pendingRoutineChangesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pendingRoutineChanges',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterFilterCondition>
      pendingRoutineChangesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pendingRoutineChanges',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SyncStateQueryObject
    on QueryBuilder<SyncState, SyncState, QFilterCondition> {}

extension SyncStateQueryLinks
    on QueryBuilder<SyncState, SyncState, QFilterCondition> {}

extension SyncStateQuerySortBy on QueryBuilder<SyncState, SyncState, QSortBy> {
  QueryBuilder<SyncState, SyncState, QAfterSortBy> sortByAutoSyncCadenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSyncCadenceId', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      sortByAutoSyncCadenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSyncCadenceId', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> sortByAutoSyncEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSyncEnabled', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> sortByAutoSyncEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSyncEnabled', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> sortByLastRemoteModified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRemoteModified', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      sortByLastRemoteModifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRemoteModified', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> sortByLocalChangeCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localChangeCounter', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      sortByLocalChangeCounterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localChangeCounter', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      sortByPendingCriticalChanges() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingCriticalChanges', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      sortByPendingCriticalChangesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingCriticalChanges', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      sortByPendingRoutineChanges() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingRoutineChanges', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      sortByPendingRoutineChangesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingRoutineChanges', Sort.desc);
    });
  }
}

extension SyncStateQuerySortThenBy
    on QueryBuilder<SyncState, SyncState, QSortThenBy> {
  QueryBuilder<SyncState, SyncState, QAfterSortBy> thenByAutoSyncCadenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSyncCadenceId', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      thenByAutoSyncCadenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSyncCadenceId', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> thenByAutoSyncEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSyncEnabled', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> thenByAutoSyncEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSyncEnabled', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> thenByLastRemoteModified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRemoteModified', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      thenByLastRemoteModifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRemoteModified', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy> thenByLocalChangeCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localChangeCounter', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      thenByLocalChangeCounterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localChangeCounter', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      thenByPendingCriticalChanges() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingCriticalChanges', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      thenByPendingCriticalChangesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingCriticalChanges', Sort.desc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      thenByPendingRoutineChanges() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingRoutineChanges', Sort.asc);
    });
  }

  QueryBuilder<SyncState, SyncState, QAfterSortBy>
      thenByPendingRoutineChangesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingRoutineChanges', Sort.desc);
    });
  }
}

extension SyncStateQueryWhereDistinct
    on QueryBuilder<SyncState, SyncState, QDistinct> {
  QueryBuilder<SyncState, SyncState, QDistinct> distinctByAutoSyncCadenceId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoSyncCadenceId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncState, SyncState, QDistinct> distinctByAutoSyncEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoSyncEnabled');
    });
  }

  QueryBuilder<SyncState, SyncState, QDistinct> distinctByDeviceId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncState, SyncState, QDistinct> distinctByLastRemoteModified() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastRemoteModified');
    });
  }

  QueryBuilder<SyncState, SyncState, QDistinct> distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<SyncState, SyncState, QDistinct> distinctByLocalChangeCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localChangeCounter');
    });
  }

  QueryBuilder<SyncState, SyncState, QDistinct>
      distinctByPendingCriticalChanges() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingCriticalChanges');
    });
  }

  QueryBuilder<SyncState, SyncState, QDistinct>
      distinctByPendingRoutineChanges() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingRoutineChanges');
    });
  }
}

extension SyncStateQueryProperty
    on QueryBuilder<SyncState, SyncState, QQueryProperty> {
  QueryBuilder<SyncState, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncState, String, QQueryOperations>
      autoSyncCadenceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoSyncCadenceId');
    });
  }

  QueryBuilder<SyncState, bool, QQueryOperations> autoSyncEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoSyncEnabled');
    });
  }

  QueryBuilder<SyncState, String, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<SyncState, DateTime?, QQueryOperations>
      lastRemoteModifiedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastRemoteModified');
    });
  }

  QueryBuilder<SyncState, DateTime?, QQueryOperations> lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<SyncState, int, QQueryOperations> localChangeCounterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localChangeCounter');
    });
  }

  QueryBuilder<SyncState, int, QQueryOperations>
      pendingCriticalChangesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingCriticalChanges');
    });
  }

  QueryBuilder<SyncState, int, QQueryOperations>
      pendingRoutineChangesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingRoutineChanges');
    });
  }
}
