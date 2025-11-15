// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_attempt_isar_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLoginAttemptIsarModelCollection on Isar {
  IsarCollection<LoginAttemptIsarModel> get loginAttemptIsarModels =>
      this.collection();
}

const LoginAttemptIsarModelSchema = CollectionSchema(
  name: r'LoginAttemptIsarModel',
  id: -7853212251789754980,
  properties: {
    r'attemptedAt': PropertySchema(
      id: 0,
      name: r'attemptedAt',
      type: IsarType.dateTime,
    ),
    r'authMethod': PropertySchema(
      id: 1,
      name: r'authMethod',
      type: IsarType.string,
    ),
    r'deviceInfo': PropertySchema(
      id: 2,
      name: r'deviceInfo',
      type: IsarType.string,
    ),
    r'email': PropertySchema(
      id: 3,
      name: r'email',
      type: IsarType.string,
    ),
    r'errorMessage': PropertySchema(
      id: 4,
      name: r'errorMessage',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 5,
      name: r'id',
      type: IsarType.string,
    ),
    r'ipAddress': PropertySchema(
      id: 6,
      name: r'ipAddress',
      type: IsarType.string,
    ),
    r'success': PropertySchema(
      id: 7,
      name: r'success',
      type: IsarType.bool,
    )
  },
  estimateSize: _loginAttemptIsarModelEstimateSize,
  serialize: _loginAttemptIsarModelSerialize,
  deserialize: _loginAttemptIsarModelDeserialize,
  deserializeProp: _loginAttemptIsarModelDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'email': IndexSchema(
      id: -26095440403582047,
      name: r'email',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'email',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'attemptedAt': IndexSchema(
      id: -9035213857872564991,
      name: r'attemptedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'attemptedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _loginAttemptIsarModelGetId,
  getLinks: _loginAttemptIsarModelGetLinks,
  attach: _loginAttemptIsarModelAttach,
  version: '3.1.0+1',
);

int _loginAttemptIsarModelEstimateSize(
  LoginAttemptIsarModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.authMethod.length * 3;
  {
    final value = object.deviceInfo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.email.length * 3;
  {
    final value = object.errorMessage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.ipAddress;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _loginAttemptIsarModelSerialize(
  LoginAttemptIsarModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.attemptedAt);
  writer.writeString(offsets[1], object.authMethod);
  writer.writeString(offsets[2], object.deviceInfo);
  writer.writeString(offsets[3], object.email);
  writer.writeString(offsets[4], object.errorMessage);
  writer.writeString(offsets[5], object.id);
  writer.writeString(offsets[6], object.ipAddress);
  writer.writeBool(offsets[7], object.success);
}

LoginAttemptIsarModel _loginAttemptIsarModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LoginAttemptIsarModel();
  object.attemptedAt = reader.readDateTime(offsets[0]);
  object.authMethod = reader.readString(offsets[1]);
  object.deviceInfo = reader.readStringOrNull(offsets[2]);
  object.email = reader.readString(offsets[3]);
  object.errorMessage = reader.readStringOrNull(offsets[4]);
  object.id = reader.readString(offsets[5]);
  object.ipAddress = reader.readStringOrNull(offsets[6]);
  object.isarId = id;
  object.success = reader.readBool(offsets[7]);
  return object;
}

P _loginAttemptIsarModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _loginAttemptIsarModelGetId(LoginAttemptIsarModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _loginAttemptIsarModelGetLinks(
    LoginAttemptIsarModel object) {
  return [];
}

void _loginAttemptIsarModelAttach(
    IsarCollection<dynamic> col, Id id, LoginAttemptIsarModel object) {
  object.isarId = id;
}

extension LoginAttemptIsarModelByIndex
    on IsarCollection<LoginAttemptIsarModel> {
  Future<LoginAttemptIsarModel?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  LoginAttemptIsarModel? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<LoginAttemptIsarModel?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<LoginAttemptIsarModel?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(LoginAttemptIsarModel object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(LoginAttemptIsarModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<LoginAttemptIsarModel> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<LoginAttemptIsarModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension LoginAttemptIsarModelQueryWhereSort
    on QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QWhere> {
  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhere>
      anyAttemptedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'attemptedAt'),
      );
    });
  }
}

extension LoginAttemptIsarModelQueryWhere on QueryBuilder<LoginAttemptIsarModel,
    LoginAttemptIsarModel, QWhereClause> {
  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      emailEqualTo(String email) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'email',
        value: [email],
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      emailNotEqualTo(String email) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'email',
              lower: [],
              upper: [email],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'email',
              lower: [email],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'email',
              lower: [email],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'email',
              lower: [],
              upper: [email],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      attemptedAtEqualTo(DateTime attemptedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'attemptedAt',
        value: [attemptedAt],
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      attemptedAtNotEqualTo(DateTime attemptedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'attemptedAt',
              lower: [],
              upper: [attemptedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'attemptedAt',
              lower: [attemptedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'attemptedAt',
              lower: [attemptedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'attemptedAt',
              lower: [],
              upper: [attemptedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      attemptedAtGreaterThan(
    DateTime attemptedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'attemptedAt',
        lower: [attemptedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      attemptedAtLessThan(
    DateTime attemptedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'attemptedAt',
        lower: [],
        upper: [attemptedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterWhereClause>
      attemptedAtBetween(
    DateTime lowerAttemptedAt,
    DateTime upperAttemptedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'attemptedAt',
        lower: [lowerAttemptedAt],
        includeLower: includeLower,
        upper: [upperAttemptedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LoginAttemptIsarModelQueryFilter on QueryBuilder<
    LoginAttemptIsarModel, LoginAttemptIsarModel, QFilterCondition> {
  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> attemptedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attemptedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> attemptedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attemptedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> attemptedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attemptedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> attemptedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attemptedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> authMethodEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'authMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> authMethodGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'authMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> authMethodLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'authMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> authMethodBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'authMethod',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> authMethodStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'authMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> authMethodEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'authMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
          QAfterFilterCondition>
      authMethodContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'authMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
          QAfterFilterCondition>
      authMethodMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'authMethod',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> authMethodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'authMethod',
        value: '',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> authMethodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'authMethod',
        value: '',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> deviceInfoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deviceInfo',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> deviceInfoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deviceInfo',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> deviceInfoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> deviceInfoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deviceInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> deviceInfoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deviceInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> deviceInfoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deviceInfo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> deviceInfoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deviceInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> deviceInfoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deviceInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
          QAfterFilterCondition>
      deviceInfoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deviceInfo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
          QAfterFilterCondition>
      deviceInfoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deviceInfo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> deviceInfoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceInfo',
        value: '',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> deviceInfoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deviceInfo',
        value: '',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> emailEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> emailGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> emailLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> emailBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'email',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> emailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> emailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
          QAfterFilterCondition>
      emailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
          QAfterFilterCondition>
      emailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'email',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> errorMessageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> errorMessageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> errorMessageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> errorMessageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> errorMessageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorMessage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> errorMessageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> errorMessageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
          QAfterFilterCondition>
      errorMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
          QAfterFilterCondition>
      errorMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'errorMessage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
          QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
          QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> ipAddressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ipAddress',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> ipAddressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ipAddress',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> ipAddressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ipAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> ipAddressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ipAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> ipAddressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ipAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> ipAddressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ipAddress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> ipAddressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ipAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> ipAddressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ipAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
          QAfterFilterCondition>
      ipAddressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ipAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
          QAfterFilterCondition>
      ipAddressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ipAddress',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> ipAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ipAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> ipAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ipAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel,
      QAfterFilterCondition> successEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'success',
        value: value,
      ));
    });
  }
}

extension LoginAttemptIsarModelQueryObject on QueryBuilder<
    LoginAttemptIsarModel, LoginAttemptIsarModel, QFilterCondition> {}

extension LoginAttemptIsarModelQueryLinks on QueryBuilder<LoginAttemptIsarModel,
    LoginAttemptIsarModel, QFilterCondition> {}

extension LoginAttemptIsarModelQuerySortBy
    on QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QSortBy> {
  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByAttemptedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptedAt', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByAttemptedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptedAt', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByAuthMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authMethod', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByAuthMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authMethod', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByDeviceInfo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceInfo', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByDeviceInfoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceInfo', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByIpAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ipAddress', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortByIpAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ipAddress', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortBySuccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'success', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      sortBySuccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'success', Sort.desc);
    });
  }
}

extension LoginAttemptIsarModelQuerySortThenBy
    on QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QSortThenBy> {
  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByAttemptedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptedAt', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByAttemptedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptedAt', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByAuthMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authMethod', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByAuthMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authMethod', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByDeviceInfo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceInfo', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByDeviceInfoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceInfo', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByIpAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ipAddress', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByIpAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ipAddress', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenBySuccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'success', Sort.asc);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QAfterSortBy>
      thenBySuccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'success', Sort.desc);
    });
  }
}

extension LoginAttemptIsarModelQueryWhereDistinct
    on QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QDistinct> {
  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QDistinct>
      distinctByAttemptedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attemptedAt');
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QDistinct>
      distinctByAuthMethod({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'authMethod', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QDistinct>
      distinctByDeviceInfo({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceInfo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QDistinct>
      distinctByEmail({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QDistinct>
      distinctByErrorMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorMessage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QDistinct>
      distinctById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QDistinct>
      distinctByIpAddress({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ipAddress', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LoginAttemptIsarModel, LoginAttemptIsarModel, QDistinct>
      distinctBySuccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'success');
    });
  }
}

extension LoginAttemptIsarModelQueryProperty on QueryBuilder<
    LoginAttemptIsarModel, LoginAttemptIsarModel, QQueryProperty> {
  QueryBuilder<LoginAttemptIsarModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<LoginAttemptIsarModel, DateTime, QQueryOperations>
      attemptedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attemptedAt');
    });
  }

  QueryBuilder<LoginAttemptIsarModel, String, QQueryOperations>
      authMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'authMethod');
    });
  }

  QueryBuilder<LoginAttemptIsarModel, String?, QQueryOperations>
      deviceInfoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceInfo');
    });
  }

  QueryBuilder<LoginAttemptIsarModel, String, QQueryOperations>
      emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<LoginAttemptIsarModel, String?, QQueryOperations>
      errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorMessage');
    });
  }

  QueryBuilder<LoginAttemptIsarModel, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LoginAttemptIsarModel, String?, QQueryOperations>
      ipAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ipAddress');
    });
  }

  QueryBuilder<LoginAttemptIsarModel, bool, QQueryOperations>
      successProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'success');
    });
  }
}
