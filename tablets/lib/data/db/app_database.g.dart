// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _listedMeta = const VerificationMeta('listed');
  @override
  late final GeneratedColumn<bool> listed = GeneratedColumn<bool>(
    'listed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("listed" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sku, listed, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('listed')) {
      context.handle(
        _listedMeta,
        listed.isAcceptableOrUnknown(data['listed']!, _listedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      listed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}listed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final String id;
  final String name;
  final String? sku;
  final bool listed;
  final DateTime createdAt;
  const ProductRow({
    required this.id,
    required this.name,
    this.sku,
    required this.listed,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    map['listed'] = Variable<bool>(listed);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      listed: Value(listed),
      createdAt: Value(createdAt),
    );
  }

  factory ProductRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sku: serializer.fromJson<String?>(json['sku']),
      listed: serializer.fromJson<bool>(json['listed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sku': serializer.toJson<String?>(sku),
      'listed': serializer.toJson<bool>(listed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProductRow copyWith({
    String? id,
    String? name,
    Value<String?> sku = const Value.absent(),
    bool? listed,
    DateTime? createdAt,
  }) => ProductRow(
    id: id ?? this.id,
    name: name ?? this.name,
    sku: sku.present ? sku.value : this.sku,
    listed: listed ?? this.listed,
    createdAt: createdAt ?? this.createdAt,
  );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sku: data.sku.present ? data.sku.value : this.sku,
      listed: data.listed.present ? data.listed.value : this.listed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('listed: $listed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sku, listed, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sku == this.sku &&
          other.listed == this.listed &&
          other.createdAt == this.createdAt);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> sku;
  final Value<bool> listed;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sku = const Value.absent(),
    this.listed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    this.sku = const Value.absent(),
    this.listed = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<ProductRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? sku,
    Expression<bool>? listed,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (listed != null) 'listed': listed,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? sku,
    Value<bool>? listed,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      listed: listed ?? this.listed,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (listed.present) {
      map['listed'] = Variable<bool>(listed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('listed: $listed, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FridgesTable extends Fridges with TableInfo<$FridgesTable, FridgeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FridgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minCelsiusMeta = const VerificationMeta(
    'minCelsius',
  );
  @override
  late final GeneratedColumn<double> minCelsius = GeneratedColumn<double>(
    'min_celsius',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxCelsiusMeta = const VerificationMeta(
    'maxCelsius',
  );
  @override
  late final GeneratedColumn<double> maxCelsius = GeneratedColumn<double>(
    'max_celsius',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, minCelsius, maxCelsius];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fridges';
  @override
  VerificationContext validateIntegrity(
    Insertable<FridgeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('min_celsius')) {
      context.handle(
        _minCelsiusMeta,
        minCelsius.isAcceptableOrUnknown(data['min_celsius']!, _minCelsiusMeta),
      );
    } else if (isInserting) {
      context.missing(_minCelsiusMeta);
    }
    if (data.containsKey('max_celsius')) {
      context.handle(
        _maxCelsiusMeta,
        maxCelsius.isAcceptableOrUnknown(data['max_celsius']!, _maxCelsiusMeta),
      );
    } else if (isInserting) {
      context.missing(_maxCelsiusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FridgeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FridgeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      minCelsius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_celsius'],
      )!,
      maxCelsius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_celsius'],
      )!,
    );
  }

  @override
  $FridgesTable createAlias(String alias) {
    return $FridgesTable(attachedDatabase, alias);
  }
}

class FridgeRow extends DataClass implements Insertable<FridgeRow> {
  final String id;
  final String name;
  final double minCelsius;
  final double maxCelsius;
  const FridgeRow({
    required this.id,
    required this.name,
    required this.minCelsius,
    required this.maxCelsius,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['min_celsius'] = Variable<double>(minCelsius);
    map['max_celsius'] = Variable<double>(maxCelsius);
    return map;
  }

  FridgesCompanion toCompanion(bool nullToAbsent) {
    return FridgesCompanion(
      id: Value(id),
      name: Value(name),
      minCelsius: Value(minCelsius),
      maxCelsius: Value(maxCelsius),
    );
  }

  factory FridgeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FridgeRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      minCelsius: serializer.fromJson<double>(json['minCelsius']),
      maxCelsius: serializer.fromJson<double>(json['maxCelsius']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'minCelsius': serializer.toJson<double>(minCelsius),
      'maxCelsius': serializer.toJson<double>(maxCelsius),
    };
  }

  FridgeRow copyWith({
    String? id,
    String? name,
    double? minCelsius,
    double? maxCelsius,
  }) => FridgeRow(
    id: id ?? this.id,
    name: name ?? this.name,
    minCelsius: minCelsius ?? this.minCelsius,
    maxCelsius: maxCelsius ?? this.maxCelsius,
  );
  FridgeRow copyWithCompanion(FridgesCompanion data) {
    return FridgeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      minCelsius: data.minCelsius.present
          ? data.minCelsius.value
          : this.minCelsius,
      maxCelsius: data.maxCelsius.present
          ? data.maxCelsius.value
          : this.maxCelsius,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FridgeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('minCelsius: $minCelsius, ')
          ..write('maxCelsius: $maxCelsius')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, minCelsius, maxCelsius);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FridgeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.minCelsius == this.minCelsius &&
          other.maxCelsius == this.maxCelsius);
}

class FridgesCompanion extends UpdateCompanion<FridgeRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> minCelsius;
  final Value<double> maxCelsius;
  final Value<int> rowid;
  const FridgesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.minCelsius = const Value.absent(),
    this.maxCelsius = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FridgesCompanion.insert({
    required String id,
    required String name,
    required double minCelsius,
    required double maxCelsius,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       minCelsius = Value(minCelsius),
       maxCelsius = Value(maxCelsius);
  static Insertable<FridgeRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? minCelsius,
    Expression<double>? maxCelsius,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (minCelsius != null) 'min_celsius': minCelsius,
      if (maxCelsius != null) 'max_celsius': maxCelsius,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FridgesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? minCelsius,
    Value<double>? maxCelsius,
    Value<int>? rowid,
  }) {
    return FridgesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      minCelsius: minCelsius ?? this.minCelsius,
      maxCelsius: maxCelsius ?? this.maxCelsius,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (minCelsius.present) {
      map['min_celsius'] = Variable<double>(minCelsius.value);
    }
    if (maxCelsius.present) {
      map['max_celsius'] = Variable<double>(maxCelsius.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FridgesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('minCelsius: $minCelsius, ')
          ..write('maxCelsius: $maxCelsius, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkersTable extends Workers with TableInfo<$WorkersTable, WorkerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workers';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WorkersTable createAlias(String alias) {
    return $WorkersTable(attachedDatabase, alias);
  }
}

class WorkerRow extends DataClass implements Insertable<WorkerRow> {
  final String id;
  final String name;
  final DateTime createdAt;
  const WorkerRow({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WorkersCompanion toCompanion(bool nullToAbsent) {
    return WorkersCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory WorkerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkerRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WorkerRow copyWith({String? id, String? name, DateTime? createdAt}) =>
      WorkerRow(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  WorkerRow copyWithCompanion(WorkersCompanion data) {
    return WorkerRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkerRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkerRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class WorkersCompanion extends UpdateCompanion<WorkerRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WorkersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkersCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<WorkerRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return WorkersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RefrigerationLogsTable extends RefrigerationLogs
    with TableInfo<$RefrigerationLogsTable, RefrigerationLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefrigerationLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movementIdMeta = const VerificationMeta(
    'movementId',
  );
  @override
  late final GeneratedColumn<String> movementId = GeneratedColumn<String>(
    'movement_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _productNameSnapshotMeta =
      const VerificationMeta('productNameSnapshot');
  @override
  late final GeneratedColumn<String> productNameSnapshot =
      GeneratedColumn<String>(
        'product_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fridgeIdMeta = const VerificationMeta(
    'fridgeId',
  );
  @override
  late final GeneratedColumn<String> fridgeId = GeneratedColumn<String>(
    'fridge_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES fridges (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LogEventType, String> eventType =
      GeneratedColumn<String>(
        'event_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LogEventType>(
        $RefrigerationLogsTable.$convertereventType,
      );
  static const VerificationMeta _temperatureCelsiusMeta =
      const VerificationMeta('temperatureCelsius');
  @override
  late final GeneratedColumn<double> temperatureCelsius =
      GeneratedColumn<double>(
        'temperature_celsius',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _workerNameSnapshotMeta =
      const VerificationMeta('workerNameSnapshot');
  @override
  late final GeneratedColumn<String> workerNameSnapshot =
      GeneratedColumn<String>(
        'worker_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    movementId,
    productId,
    productNameSnapshot,
    fridgeId,
    eventType,
    temperatureCelsius,
    occurredAt,
    createdAt,
    originDeviceId,
    workerNameSnapshot,
    dueAt,
    quantity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'refrigeration_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RefrigerationLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('movement_id')) {
      context.handle(
        _movementIdMeta,
        movementId.isAcceptableOrUnknown(data['movement_id']!, _movementIdMeta),
      );
    } else if (isInserting) {
      context.missing(_movementIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name_snapshot')) {
      context.handle(
        _productNameSnapshotMeta,
        productNameSnapshot.isAcceptableOrUnknown(
          data['product_name_snapshot']!,
          _productNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameSnapshotMeta);
    }
    if (data.containsKey('fridge_id')) {
      context.handle(
        _fridgeIdMeta,
        fridgeId.isAcceptableOrUnknown(data['fridge_id']!, _fridgeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fridgeIdMeta);
    }
    if (data.containsKey('temperature_celsius')) {
      context.handle(
        _temperatureCelsiusMeta,
        temperatureCelsius.isAcceptableOrUnknown(
          data['temperature_celsius']!,
          _temperatureCelsiusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_temperatureCelsiusMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('worker_name_snapshot')) {
      context.handle(
        _workerNameSnapshotMeta,
        workerNameSnapshot.isAcceptableOrUnknown(
          data['worker_name_snapshot']!,
          _workerNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RefrigerationLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RefrigerationLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      movementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name_snapshot'],
      )!,
      fridgeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fridge_id'],
      )!,
      eventType: $RefrigerationLogsTable.$convertereventType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}event_type'],
        )!,
      ),
      temperatureCelsius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_celsius'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      workerNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_name_snapshot'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
    );
  }

  @override
  $RefrigerationLogsTable createAlias(String alias) {
    return $RefrigerationLogsTable(attachedDatabase, alias);
  }

  static TypeConverter<LogEventType, String> $convertereventType =
      const LogEventTypeConverter();
}

class RefrigerationLogRow extends DataClass
    implements Insertable<RefrigerationLogRow> {
  final String id;
  final String movementId;
  final String productId;
  final String productNameSnapshot;
  final String fridgeId;
  final LogEventType eventType;
  final double temperatureCelsius;
  final DateTime occurredAt;
  final DateTime createdAt;
  final String originDeviceId;
  final String workerNameSnapshot;
  final DateTime? dueAt;
  final int quantity;
  const RefrigerationLogRow({
    required this.id,
    required this.movementId,
    required this.productId,
    required this.productNameSnapshot,
    required this.fridgeId,
    required this.eventType,
    required this.temperatureCelsius,
    required this.occurredAt,
    required this.createdAt,
    required this.originDeviceId,
    required this.workerNameSnapshot,
    this.dueAt,
    required this.quantity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['movement_id'] = Variable<String>(movementId);
    map['product_id'] = Variable<String>(productId);
    map['product_name_snapshot'] = Variable<String>(productNameSnapshot);
    map['fridge_id'] = Variable<String>(fridgeId);
    {
      map['event_type'] = Variable<String>(
        $RefrigerationLogsTable.$convertereventType.toSql(eventType),
      );
    }
    map['temperature_celsius'] = Variable<double>(temperatureCelsius);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['worker_name_snapshot'] = Variable<String>(workerNameSnapshot);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    map['quantity'] = Variable<int>(quantity);
    return map;
  }

  RefrigerationLogsCompanion toCompanion(bool nullToAbsent) {
    return RefrigerationLogsCompanion(
      id: Value(id),
      movementId: Value(movementId),
      productId: Value(productId),
      productNameSnapshot: Value(productNameSnapshot),
      fridgeId: Value(fridgeId),
      eventType: Value(eventType),
      temperatureCelsius: Value(temperatureCelsius),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
      originDeviceId: Value(originDeviceId),
      workerNameSnapshot: Value(workerNameSnapshot),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      quantity: Value(quantity),
    );
  }

  factory RefrigerationLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RefrigerationLogRow(
      id: serializer.fromJson<String>(json['id']),
      movementId: serializer.fromJson<String>(json['movementId']),
      productId: serializer.fromJson<String>(json['productId']),
      productNameSnapshot: serializer.fromJson<String>(
        json['productNameSnapshot'],
      ),
      fridgeId: serializer.fromJson<String>(json['fridgeId']),
      eventType: serializer.fromJson<LogEventType>(json['eventType']),
      temperatureCelsius: serializer.fromJson<double>(
        json['temperatureCelsius'],
      ),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      workerNameSnapshot: serializer.fromJson<String>(
        json['workerNameSnapshot'],
      ),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      quantity: serializer.fromJson<int>(json['quantity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'movementId': serializer.toJson<String>(movementId),
      'productId': serializer.toJson<String>(productId),
      'productNameSnapshot': serializer.toJson<String>(productNameSnapshot),
      'fridgeId': serializer.toJson<String>(fridgeId),
      'eventType': serializer.toJson<LogEventType>(eventType),
      'temperatureCelsius': serializer.toJson<double>(temperatureCelsius),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'workerNameSnapshot': serializer.toJson<String>(workerNameSnapshot),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'quantity': serializer.toJson<int>(quantity),
    };
  }

  RefrigerationLogRow copyWith({
    String? id,
    String? movementId,
    String? productId,
    String? productNameSnapshot,
    String? fridgeId,
    LogEventType? eventType,
    double? temperatureCelsius,
    DateTime? occurredAt,
    DateTime? createdAt,
    String? originDeviceId,
    String? workerNameSnapshot,
    Value<DateTime?> dueAt = const Value.absent(),
    int? quantity,
  }) => RefrigerationLogRow(
    id: id ?? this.id,
    movementId: movementId ?? this.movementId,
    productId: productId ?? this.productId,
    productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
    fridgeId: fridgeId ?? this.fridgeId,
    eventType: eventType ?? this.eventType,
    temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt ?? this.createdAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
    workerNameSnapshot: workerNameSnapshot ?? this.workerNameSnapshot,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    quantity: quantity ?? this.quantity,
  );
  RefrigerationLogRow copyWithCompanion(RefrigerationLogsCompanion data) {
    return RefrigerationLogRow(
      id: data.id.present ? data.id.value : this.id,
      movementId: data.movementId.present
          ? data.movementId.value
          : this.movementId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productNameSnapshot: data.productNameSnapshot.present
          ? data.productNameSnapshot.value
          : this.productNameSnapshot,
      fridgeId: data.fridgeId.present ? data.fridgeId.value : this.fridgeId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      temperatureCelsius: data.temperatureCelsius.present
          ? data.temperatureCelsius.value
          : this.temperatureCelsius,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      workerNameSnapshot: data.workerNameSnapshot.present
          ? data.workerNameSnapshot.value
          : this.workerNameSnapshot,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RefrigerationLogRow(')
          ..write('id: $id, ')
          ..write('movementId: $movementId, ')
          ..write('productId: $productId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('fridgeId: $fridgeId, ')
          ..write('eventType: $eventType, ')
          ..write('temperatureCelsius: $temperatureCelsius, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('workerNameSnapshot: $workerNameSnapshot, ')
          ..write('dueAt: $dueAt, ')
          ..write('quantity: $quantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    movementId,
    productId,
    productNameSnapshot,
    fridgeId,
    eventType,
    temperatureCelsius,
    occurredAt,
    createdAt,
    originDeviceId,
    workerNameSnapshot,
    dueAt,
    quantity,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RefrigerationLogRow &&
          other.id == this.id &&
          other.movementId == this.movementId &&
          other.productId == this.productId &&
          other.productNameSnapshot == this.productNameSnapshot &&
          other.fridgeId == this.fridgeId &&
          other.eventType == this.eventType &&
          other.temperatureCelsius == this.temperatureCelsius &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt &&
          other.originDeviceId == this.originDeviceId &&
          other.workerNameSnapshot == this.workerNameSnapshot &&
          other.dueAt == this.dueAt &&
          other.quantity == this.quantity);
}

class RefrigerationLogsCompanion extends UpdateCompanion<RefrigerationLogRow> {
  final Value<String> id;
  final Value<String> movementId;
  final Value<String> productId;
  final Value<String> productNameSnapshot;
  final Value<String> fridgeId;
  final Value<LogEventType> eventType;
  final Value<double> temperatureCelsius;
  final Value<DateTime> occurredAt;
  final Value<DateTime> createdAt;
  final Value<String> originDeviceId;
  final Value<String> workerNameSnapshot;
  final Value<DateTime?> dueAt;
  final Value<int> quantity;
  final Value<int> rowid;
  const RefrigerationLogsCompanion({
    this.id = const Value.absent(),
    this.movementId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productNameSnapshot = const Value.absent(),
    this.fridgeId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.temperatureCelsius = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.workerNameSnapshot = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.quantity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RefrigerationLogsCompanion.insert({
    required String id,
    required String movementId,
    required String productId,
    required String productNameSnapshot,
    required String fridgeId,
    required LogEventType eventType,
    required double temperatureCelsius,
    required DateTime occurredAt,
    required DateTime createdAt,
    this.originDeviceId = const Value.absent(),
    this.workerNameSnapshot = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.quantity = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       movementId = Value(movementId),
       productId = Value(productId),
       productNameSnapshot = Value(productNameSnapshot),
       fridgeId = Value(fridgeId),
       eventType = Value(eventType),
       temperatureCelsius = Value(temperatureCelsius),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt);
  static Insertable<RefrigerationLogRow> custom({
    Expression<String>? id,
    Expression<String>? movementId,
    Expression<String>? productId,
    Expression<String>? productNameSnapshot,
    Expression<String>? fridgeId,
    Expression<String>? eventType,
    Expression<double>? temperatureCelsius,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? createdAt,
    Expression<String>? originDeviceId,
    Expression<String>? workerNameSnapshot,
    Expression<DateTime>? dueAt,
    Expression<int>? quantity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (movementId != null) 'movement_id': movementId,
      if (productId != null) 'product_id': productId,
      if (productNameSnapshot != null)
        'product_name_snapshot': productNameSnapshot,
      if (fridgeId != null) 'fridge_id': fridgeId,
      if (eventType != null) 'event_type': eventType,
      if (temperatureCelsius != null) 'temperature_celsius': temperatureCelsius,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (workerNameSnapshot != null)
        'worker_name_snapshot': workerNameSnapshot,
      if (dueAt != null) 'due_at': dueAt,
      if (quantity != null) 'quantity': quantity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RefrigerationLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? movementId,
    Value<String>? productId,
    Value<String>? productNameSnapshot,
    Value<String>? fridgeId,
    Value<LogEventType>? eventType,
    Value<double>? temperatureCelsius,
    Value<DateTime>? occurredAt,
    Value<DateTime>? createdAt,
    Value<String>? originDeviceId,
    Value<String>? workerNameSnapshot,
    Value<DateTime?>? dueAt,
    Value<int>? quantity,
    Value<int>? rowid,
  }) {
    return RefrigerationLogsCompanion(
      id: id ?? this.id,
      movementId: movementId ?? this.movementId,
      productId: productId ?? this.productId,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      fridgeId: fridgeId ?? this.fridgeId,
      eventType: eventType ?? this.eventType,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      workerNameSnapshot: workerNameSnapshot ?? this.workerNameSnapshot,
      dueAt: dueAt ?? this.dueAt,
      quantity: quantity ?? this.quantity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (movementId.present) {
      map['movement_id'] = Variable<String>(movementId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productNameSnapshot.present) {
      map['product_name_snapshot'] = Variable<String>(
        productNameSnapshot.value,
      );
    }
    if (fridgeId.present) {
      map['fridge_id'] = Variable<String>(fridgeId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(
        $RefrigerationLogsTable.$convertereventType.toSql(eventType.value),
      );
    }
    if (temperatureCelsius.present) {
      map['temperature_celsius'] = Variable<double>(temperatureCelsius.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (workerNameSnapshot.present) {
      map['worker_name_snapshot'] = Variable<String>(workerNameSnapshot.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefrigerationLogsCompanion(')
          ..write('id: $id, ')
          ..write('movementId: $movementId, ')
          ..write('productId: $productId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('fridgeId: $fridgeId, ')
          ..write('eventType: $eventType, ')
          ..write('temperatureCelsius: $temperatureCelsius, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('workerNameSnapshot: $workerNameSnapshot, ')
          ..write('dueAt: $dueAt, ')
          ..write('quantity: $quantity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlertsTable extends Alerts with TableInfo<$AlertsTable, AlertRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AlertSeverity, String> severity =
      GeneratedColumn<String>(
        'severity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AlertSeverity>($AlertsTable.$converterseverity);
  @override
  late final GeneratedColumnWithTypeConverter<AlertKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AlertKind>($AlertsTable.$converterkind);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _logIdMeta = const VerificationMeta('logId');
  @override
  late final GeneratedColumn<String> logId = GeneratedColumn<String>(
    'log_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES refrigeration_logs (id)',
    ),
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acknowledgedAtMeta = const VerificationMeta(
    'acknowledgedAt',
  );
  @override
  late final GeneratedColumn<DateTime> acknowledgedAt =
      GeneratedColumn<DateTime>(
        'acknowledged_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    severity,
    kind,
    productId,
    logId,
    message,
    createdAt,
    acknowledgedAt,
    originDeviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlertRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('log_id')) {
      context.handle(
        _logIdMeta,
        logId.isAcceptableOrUnknown(data['log_id']!, _logIdMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('acknowledged_at')) {
      context.handle(
        _acknowledgedAtMeta,
        acknowledgedAt.isAcceptableOrUnknown(
          data['acknowledged_at']!,
          _acknowledgedAtMeta,
        ),
      );
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlertRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlertRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      severity: $AlertsTable.$converterseverity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}severity'],
        )!,
      ),
      kind: $AlertsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      logId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_id'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      acknowledgedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}acknowledged_at'],
      ),
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
    );
  }

  @override
  $AlertsTable createAlias(String alias) {
    return $AlertsTable(attachedDatabase, alias);
  }

  static TypeConverter<AlertSeverity, String> $converterseverity =
      const AlertSeverityConverter();
  static TypeConverter<AlertKind, String> $converterkind =
      const AlertKindConverter();
}

class AlertRow extends DataClass implements Insertable<AlertRow> {
  final String id;
  final AlertSeverity severity;
  final AlertKind kind;
  final String? productId;
  final String? logId;
  final String message;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final String originDeviceId;
  const AlertRow({
    required this.id,
    required this.severity,
    required this.kind,
    this.productId,
    this.logId,
    required this.message,
    required this.createdAt,
    this.acknowledgedAt,
    required this.originDeviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['severity'] = Variable<String>(
        $AlertsTable.$converterseverity.toSql(severity),
      );
    }
    {
      map['kind'] = Variable<String>($AlertsTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || logId != null) {
      map['log_id'] = Variable<String>(logId);
    }
    map['message'] = Variable<String>(message);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || acknowledgedAt != null) {
      map['acknowledged_at'] = Variable<DateTime>(acknowledgedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    return map;
  }

  AlertsCompanion toCompanion(bool nullToAbsent) {
    return AlertsCompanion(
      id: Value(id),
      severity: Value(severity),
      kind: Value(kind),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      logId: logId == null && nullToAbsent
          ? const Value.absent()
          : Value(logId),
      message: Value(message),
      createdAt: Value(createdAt),
      acknowledgedAt: acknowledgedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgedAt),
      originDeviceId: Value(originDeviceId),
    );
  }

  factory AlertRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlertRow(
      id: serializer.fromJson<String>(json['id']),
      severity: serializer.fromJson<AlertSeverity>(json['severity']),
      kind: serializer.fromJson<AlertKind>(json['kind']),
      productId: serializer.fromJson<String?>(json['productId']),
      logId: serializer.fromJson<String?>(json['logId']),
      message: serializer.fromJson<String>(json['message']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      acknowledgedAt: serializer.fromJson<DateTime?>(json['acknowledgedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'severity': serializer.toJson<AlertSeverity>(severity),
      'kind': serializer.toJson<AlertKind>(kind),
      'productId': serializer.toJson<String?>(productId),
      'logId': serializer.toJson<String?>(logId),
      'message': serializer.toJson<String>(message),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'acknowledgedAt': serializer.toJson<DateTime?>(acknowledgedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
    };
  }

  AlertRow copyWith({
    String? id,
    AlertSeverity? severity,
    AlertKind? kind,
    Value<String?> productId = const Value.absent(),
    Value<String?> logId = const Value.absent(),
    String? message,
    DateTime? createdAt,
    Value<DateTime?> acknowledgedAt = const Value.absent(),
    String? originDeviceId,
  }) => AlertRow(
    id: id ?? this.id,
    severity: severity ?? this.severity,
    kind: kind ?? this.kind,
    productId: productId.present ? productId.value : this.productId,
    logId: logId.present ? logId.value : this.logId,
    message: message ?? this.message,
    createdAt: createdAt ?? this.createdAt,
    acknowledgedAt: acknowledgedAt.present
        ? acknowledgedAt.value
        : this.acknowledgedAt,
    originDeviceId: originDeviceId ?? this.originDeviceId,
  );
  AlertRow copyWithCompanion(AlertsCompanion data) {
    return AlertRow(
      id: data.id.present ? data.id.value : this.id,
      severity: data.severity.present ? data.severity.value : this.severity,
      kind: data.kind.present ? data.kind.value : this.kind,
      productId: data.productId.present ? data.productId.value : this.productId,
      logId: data.logId.present ? data.logId.value : this.logId,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      acknowledgedAt: data.acknowledgedAt.present
          ? data.acknowledgedAt.value
          : this.acknowledgedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlertRow(')
          ..write('id: $id, ')
          ..write('severity: $severity, ')
          ..write('kind: $kind, ')
          ..write('productId: $productId, ')
          ..write('logId: $logId, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('acknowledgedAt: $acknowledgedAt, ')
          ..write('originDeviceId: $originDeviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    severity,
    kind,
    productId,
    logId,
    message,
    createdAt,
    acknowledgedAt,
    originDeviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlertRow &&
          other.id == this.id &&
          other.severity == this.severity &&
          other.kind == this.kind &&
          other.productId == this.productId &&
          other.logId == this.logId &&
          other.message == this.message &&
          other.createdAt == this.createdAt &&
          other.acknowledgedAt == this.acknowledgedAt &&
          other.originDeviceId == this.originDeviceId);
}

class AlertsCompanion extends UpdateCompanion<AlertRow> {
  final Value<String> id;
  final Value<AlertSeverity> severity;
  final Value<AlertKind> kind;
  final Value<String?> productId;
  final Value<String?> logId;
  final Value<String> message;
  final Value<DateTime> createdAt;
  final Value<DateTime?> acknowledgedAt;
  final Value<String> originDeviceId;
  final Value<int> rowid;
  const AlertsCompanion({
    this.id = const Value.absent(),
    this.severity = const Value.absent(),
    this.kind = const Value.absent(),
    this.productId = const Value.absent(),
    this.logId = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.acknowledgedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertsCompanion.insert({
    required String id,
    required AlertSeverity severity,
    required AlertKind kind,
    this.productId = const Value.absent(),
    this.logId = const Value.absent(),
    required String message,
    required DateTime createdAt,
    this.acknowledgedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       severity = Value(severity),
       kind = Value(kind),
       message = Value(message),
       createdAt = Value(createdAt);
  static Insertable<AlertRow> custom({
    Expression<String>? id,
    Expression<String>? severity,
    Expression<String>? kind,
    Expression<String>? productId,
    Expression<String>? logId,
    Expression<String>? message,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? acknowledgedAt,
    Expression<String>? originDeviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (severity != null) 'severity': severity,
      if (kind != null) 'kind': kind,
      if (productId != null) 'product_id': productId,
      if (logId != null) 'log_id': logId,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
      if (acknowledgedAt != null) 'acknowledged_at': acknowledgedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertsCompanion copyWith({
    Value<String>? id,
    Value<AlertSeverity>? severity,
    Value<AlertKind>? kind,
    Value<String?>? productId,
    Value<String?>? logId,
    Value<String>? message,
    Value<DateTime>? createdAt,
    Value<DateTime?>? acknowledgedAt,
    Value<String>? originDeviceId,
    Value<int>? rowid,
  }) {
    return AlertsCompanion(
      id: id ?? this.id,
      severity: severity ?? this.severity,
      kind: kind ?? this.kind,
      productId: productId ?? this.productId,
      logId: logId ?? this.logId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(
        $AlertsTable.$converterseverity.toSql(severity.value),
      );
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $AlertsTable.$converterkind.toSql(kind.value),
      );
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (logId.present) {
      map['log_id'] = Variable<String>(logId.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (acknowledgedAt.present) {
      map['acknowledged_at'] = Variable<DateTime>(acknowledgedAt.value);
    }
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertsCompanion(')
          ..write('id: $id, ')
          ..write('severity: $severity, ')
          ..write('kind: $kind, ')
          ..write('productId: $productId, ')
          ..write('logId: $logId, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('acknowledgedAt: $acknowledgedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($SyncOutboxTable.$converterstatus);
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operation,
    payloadJson,
    status,
    attemptCount,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: $SyncOutboxTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }

  static TypeConverter<SyncStatus, String> $converterstatus =
      const SyncStatusConverter();
}

class SyncOutboxRow extends DataClass implements Insertable<SyncOutboxRow> {
  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final SyncStatus status;
  final int attemptCount;
  final String? lastError;
  final DateTime createdAt;
  const SyncOutboxRow({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.status,
    required this.attemptCount,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    {
      map['status'] = Variable<String>(
        $SyncOutboxTable.$converterstatus.toSql(status),
      );
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      status: Value(status),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory SyncOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxRow(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<SyncStatus>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<SyncStatus>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncOutboxRow copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? operation,
    String? payloadJson,
    SyncStatus? status,
    int? attemptCount,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => SyncOutboxRow(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncOutboxRow copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxRow(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxRow(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    payloadJson,
    status,
    attemptCount,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxRow &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxRow> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<SyncStatus> status;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SyncOutboxCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    required SyncStatus status,
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payloadJson = Value(payloadJson),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<SyncOutboxRow> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<SyncStatus>? status,
    Value<int>? attemptCount,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SyncOutboxCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $SyncOutboxTable.$converterstatus.toSql(status.value),
      );
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _environmentNameMeta = const VerificationMeta(
    'environmentName',
  );
  @override
  late final GeneratedColumn<String> environmentName = GeneratedColumn<String>(
    'environment_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUrlMeta = const VerificationMeta(
    'serverUrl',
  );
  @override
  late final GeneratedColumn<String> serverUrl = GeneratedColumn<String>(
    'server_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _serverTokenMeta = const VerificationMeta(
    'serverToken',
  );
  @override
  late final GeneratedColumn<String> serverToken = GeneratedColumn<String>(
    'server_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ownerEmailMeta = const VerificationMeta(
    'ownerEmail',
  );
  @override
  late final GeneratedColumn<String> ownerEmail = GeneratedColumn<String>(
    'owner_email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dailyReportEnabledMeta =
      const VerificationMeta('dailyReportEnabled');
  @override
  late final GeneratedColumn<bool> dailyReportEnabled = GeneratedColumn<bool>(
    'daily_report_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("daily_report_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _reportHourMeta = const VerificationMeta(
    'reportHour',
  );
  @override
  late final GeneratedColumn<int> reportHour = GeneratedColumn<int>(
    'report_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reportMinuteMeta = const VerificationMeta(
    'reportMinute',
  );
  @override
  late final GeneratedColumn<int> reportMinute = GeneratedColumn<int>(
    'report_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncCursorMeta = const VerificationMeta(
    'syncCursor',
  );
  @override
  late final GeneratedColumn<int> syncCursor = GeneratedColumn<int>(
    'sync_cursor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmActionMeta = const VerificationMeta(
    'confirmAction',
  );
  @override
  late final GeneratedColumn<bool> confirmAction = GeneratedColumn<bool>(
    'confirm_action',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("confirm_action" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _workerIdleSecondsMeta = const VerificationMeta(
    'workerIdleSeconds',
  );
  @override
  late final GeneratedColumn<int> workerIdleSeconds = GeneratedColumn<int>(
    'worker_idle_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(600),
  );
  static const VerificationMeta _workerRefreshModeMeta = const VerificationMeta(
    'workerRefreshMode',
  );
  @override
  late final GeneratedColumn<String> workerRefreshMode =
      GeneratedColumn<String>(
        'worker_refresh_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('idle'),
      );
  static const VerificationMeta _workerPromptStyleMeta = const VerificationMeta(
    'workerPromptStyle',
  );
  @override
  late final GeneratedColumn<String> workerPromptStyle =
      GeneratedColumn<String>(
        'worker_prompt_style',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('wait'),
      );
  static const VerificationMeta _workerRefreshStartMinuteMeta =
      const VerificationMeta('workerRefreshStartMinute');
  @override
  late final GeneratedColumn<int> workerRefreshStartMinute =
      GeneratedColumn<int>(
        'worker_refresh_start_minute',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(480),
      );
  static const VerificationMeta _workerRefreshIntervalHoursMeta =
      const VerificationMeta('workerRefreshIntervalHours');
  @override
  late final GeneratedColumn<int> workerRefreshIntervalHours =
      GeneratedColumn<int>(
        'worker_refresh_interval_hours',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(8),
      );
  static const VerificationMeta _workerRefreshEndMinuteMeta =
      const VerificationMeta('workerRefreshEndMinute');
  @override
  late final GeneratedColumn<int> workerRefreshEndMinute = GeneratedColumn<int>(
    'worker_refresh_end_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1200),
  );
  static const VerificationMeta _settingsPasswordMeta = const VerificationMeta(
    'settingsPassword',
  );
  @override
  late final GeneratedColumn<String> settingsPassword = GeneratedColumn<String>(
    'settings_password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _currentWorkerIdMeta = const VerificationMeta(
    'currentWorkerId',
  );
  @override
  late final GeneratedColumn<String> currentWorkerId = GeneratedColumn<String>(
    'current_worker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workerActiveAtMeta = const VerificationMeta(
    'workerActiveAt',
  );
  @override
  late final GeneratedColumn<DateTime> workerActiveAt =
      GeneratedColumn<DateTime>(
        'worker_active_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceId,
    deviceName,
    environmentName,
    serverUrl,
    serverToken,
    ownerEmail,
    dailyReportEnabled,
    reportHour,
    reportMinute,
    syncCursor,
    lastSyncAt,
    lastSyncError,
    confirmAction,
    workerIdleSeconds,
    workerRefreshMode,
    workerPromptStyle,
    workerRefreshStartMinute,
    workerRefreshIntervalHours,
    workerRefreshEndMinute,
    settingsPassword,
    currentWorkerId,
    workerActiveAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('environment_name')) {
      context.handle(
        _environmentNameMeta,
        environmentName.isAcceptableOrUnknown(
          data['environment_name']!,
          _environmentNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentNameMeta);
    }
    if (data.containsKey('server_url')) {
      context.handle(
        _serverUrlMeta,
        serverUrl.isAcceptableOrUnknown(data['server_url']!, _serverUrlMeta),
      );
    }
    if (data.containsKey('server_token')) {
      context.handle(
        _serverTokenMeta,
        serverToken.isAcceptableOrUnknown(
          data['server_token']!,
          _serverTokenMeta,
        ),
      );
    }
    if (data.containsKey('owner_email')) {
      context.handle(
        _ownerEmailMeta,
        ownerEmail.isAcceptableOrUnknown(data['owner_email']!, _ownerEmailMeta),
      );
    }
    if (data.containsKey('daily_report_enabled')) {
      context.handle(
        _dailyReportEnabledMeta,
        dailyReportEnabled.isAcceptableOrUnknown(
          data['daily_report_enabled']!,
          _dailyReportEnabledMeta,
        ),
      );
    }
    if (data.containsKey('report_hour')) {
      context.handle(
        _reportHourMeta,
        reportHour.isAcceptableOrUnknown(data['report_hour']!, _reportHourMeta),
      );
    }
    if (data.containsKey('report_minute')) {
      context.handle(
        _reportMinuteMeta,
        reportMinute.isAcceptableOrUnknown(
          data['report_minute']!,
          _reportMinuteMeta,
        ),
      );
    }
    if (data.containsKey('sync_cursor')) {
      context.handle(
        _syncCursorMeta,
        syncCursor.isAcceptableOrUnknown(data['sync_cursor']!, _syncCursorMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    if (data.containsKey('confirm_action')) {
      context.handle(
        _confirmActionMeta,
        confirmAction.isAcceptableOrUnknown(
          data['confirm_action']!,
          _confirmActionMeta,
        ),
      );
    }
    if (data.containsKey('worker_idle_seconds')) {
      context.handle(
        _workerIdleSecondsMeta,
        workerIdleSeconds.isAcceptableOrUnknown(
          data['worker_idle_seconds']!,
          _workerIdleSecondsMeta,
        ),
      );
    }
    if (data.containsKey('worker_refresh_mode')) {
      context.handle(
        _workerRefreshModeMeta,
        workerRefreshMode.isAcceptableOrUnknown(
          data['worker_refresh_mode']!,
          _workerRefreshModeMeta,
        ),
      );
    }
    if (data.containsKey('worker_prompt_style')) {
      context.handle(
        _workerPromptStyleMeta,
        workerPromptStyle.isAcceptableOrUnknown(
          data['worker_prompt_style']!,
          _workerPromptStyleMeta,
        ),
      );
    }
    if (data.containsKey('worker_refresh_start_minute')) {
      context.handle(
        _workerRefreshStartMinuteMeta,
        workerRefreshStartMinute.isAcceptableOrUnknown(
          data['worker_refresh_start_minute']!,
          _workerRefreshStartMinuteMeta,
        ),
      );
    }
    if (data.containsKey('worker_refresh_interval_hours')) {
      context.handle(
        _workerRefreshIntervalHoursMeta,
        workerRefreshIntervalHours.isAcceptableOrUnknown(
          data['worker_refresh_interval_hours']!,
          _workerRefreshIntervalHoursMeta,
        ),
      );
    }
    if (data.containsKey('worker_refresh_end_minute')) {
      context.handle(
        _workerRefreshEndMinuteMeta,
        workerRefreshEndMinute.isAcceptableOrUnknown(
          data['worker_refresh_end_minute']!,
          _workerRefreshEndMinuteMeta,
        ),
      );
    }
    if (data.containsKey('settings_password')) {
      context.handle(
        _settingsPasswordMeta,
        settingsPassword.isAcceptableOrUnknown(
          data['settings_password']!,
          _settingsPasswordMeta,
        ),
      );
    }
    if (data.containsKey('current_worker_id')) {
      context.handle(
        _currentWorkerIdMeta,
        currentWorkerId.isAcceptableOrUnknown(
          data['current_worker_id']!,
          _currentWorkerIdMeta,
        ),
      );
    }
    if (data.containsKey('worker_active_at')) {
      context.handle(
        _workerActiveAtMeta,
        workerActiveAt.isAcceptableOrUnknown(
          data['worker_active_at']!,
          _workerActiveAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      environmentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_name'],
      )!,
      serverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_url'],
      )!,
      serverToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_token'],
      )!,
      ownerEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_email'],
      )!,
      dailyReportEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}daily_report_enabled'],
      )!,
      reportHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}report_hour'],
      )!,
      reportMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}report_minute'],
      )!,
      syncCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_cursor'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
      confirmAction: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}confirm_action'],
      )!,
      workerIdleSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}worker_idle_seconds'],
      )!,
      workerRefreshMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_refresh_mode'],
      )!,
      workerPromptStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_prompt_style'],
      )!,
      workerRefreshStartMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}worker_refresh_start_minute'],
      )!,
      workerRefreshIntervalHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}worker_refresh_interval_hours'],
      )!,
      workerRefreshEndMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}worker_refresh_end_minute'],
      )!,
      settingsPassword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings_password'],
      )!,
      currentWorkerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_worker_id'],
      ),
      workerActiveAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}worker_active_at'],
      ),
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSettingsRow extends DataClass
    implements Insertable<LocalSettingsRow> {
  final String id;
  final String deviceId;
  final String deviceName;
  final String environmentName;
  final String serverUrl;
  final String serverToken;
  final String ownerEmail;
  final bool dailyReportEnabled;
  final int reportHour;
  final int reportMinute;
  final int syncCursor;
  final DateTime? lastSyncAt;
  final String? lastSyncError;
  final bool confirmAction;
  final int workerIdleSeconds;
  final String workerRefreshMode;
  final String workerPromptStyle;
  final int workerRefreshStartMinute;
  final int workerRefreshIntervalHours;
  final int workerRefreshEndMinute;
  final String settingsPassword;
  final String? currentWorkerId;
  final DateTime? workerActiveAt;
  const LocalSettingsRow({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.environmentName,
    required this.serverUrl,
    required this.serverToken,
    required this.ownerEmail,
    required this.dailyReportEnabled,
    required this.reportHour,
    required this.reportMinute,
    required this.syncCursor,
    this.lastSyncAt,
    this.lastSyncError,
    required this.confirmAction,
    required this.workerIdleSeconds,
    required this.workerRefreshMode,
    required this.workerPromptStyle,
    required this.workerRefreshStartMinute,
    required this.workerRefreshIntervalHours,
    required this.workerRefreshEndMinute,
    required this.settingsPassword,
    this.currentWorkerId,
    this.workerActiveAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['device_name'] = Variable<String>(deviceName);
    map['environment_name'] = Variable<String>(environmentName);
    map['server_url'] = Variable<String>(serverUrl);
    map['server_token'] = Variable<String>(serverToken);
    map['owner_email'] = Variable<String>(ownerEmail);
    map['daily_report_enabled'] = Variable<bool>(dailyReportEnabled);
    map['report_hour'] = Variable<int>(reportHour);
    map['report_minute'] = Variable<int>(reportMinute);
    map['sync_cursor'] = Variable<int>(syncCursor);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    map['confirm_action'] = Variable<bool>(confirmAction);
    map['worker_idle_seconds'] = Variable<int>(workerIdleSeconds);
    map['worker_refresh_mode'] = Variable<String>(workerRefreshMode);
    map['worker_prompt_style'] = Variable<String>(workerPromptStyle);
    map['worker_refresh_start_minute'] = Variable<int>(
      workerRefreshStartMinute,
    );
    map['worker_refresh_interval_hours'] = Variable<int>(
      workerRefreshIntervalHours,
    );
    map['worker_refresh_end_minute'] = Variable<int>(workerRefreshEndMinute);
    map['settings_password'] = Variable<String>(settingsPassword);
    if (!nullToAbsent || currentWorkerId != null) {
      map['current_worker_id'] = Variable<String>(currentWorkerId);
    }
    if (!nullToAbsent || workerActiveAt != null) {
      map['worker_active_at'] = Variable<DateTime>(workerActiveAt);
    }
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      deviceName: Value(deviceName),
      environmentName: Value(environmentName),
      serverUrl: Value(serverUrl),
      serverToken: Value(serverToken),
      ownerEmail: Value(ownerEmail),
      dailyReportEnabled: Value(dailyReportEnabled),
      reportHour: Value(reportHour),
      reportMinute: Value(reportMinute),
      syncCursor: Value(syncCursor),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
      confirmAction: Value(confirmAction),
      workerIdleSeconds: Value(workerIdleSeconds),
      workerRefreshMode: Value(workerRefreshMode),
      workerPromptStyle: Value(workerPromptStyle),
      workerRefreshStartMinute: Value(workerRefreshStartMinute),
      workerRefreshIntervalHours: Value(workerRefreshIntervalHours),
      workerRefreshEndMinute: Value(workerRefreshEndMinute),
      settingsPassword: Value(settingsPassword),
      currentWorkerId: currentWorkerId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentWorkerId),
      workerActiveAt: workerActiveAt == null && nullToAbsent
          ? const Value.absent()
          : Value(workerActiveAt),
    );
  }

  factory LocalSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSettingsRow(
      id: serializer.fromJson<String>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      environmentName: serializer.fromJson<String>(json['environmentName']),
      serverUrl: serializer.fromJson<String>(json['serverUrl']),
      serverToken: serializer.fromJson<String>(json['serverToken']),
      ownerEmail: serializer.fromJson<String>(json['ownerEmail']),
      dailyReportEnabled: serializer.fromJson<bool>(json['dailyReportEnabled']),
      reportHour: serializer.fromJson<int>(json['reportHour']),
      reportMinute: serializer.fromJson<int>(json['reportMinute']),
      syncCursor: serializer.fromJson<int>(json['syncCursor']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
      confirmAction: serializer.fromJson<bool>(json['confirmAction']),
      workerIdleSeconds: serializer.fromJson<int>(json['workerIdleSeconds']),
      workerRefreshMode: serializer.fromJson<String>(json['workerRefreshMode']),
      workerPromptStyle: serializer.fromJson<String>(json['workerPromptStyle']),
      workerRefreshStartMinute: serializer.fromJson<int>(
        json['workerRefreshStartMinute'],
      ),
      workerRefreshIntervalHours: serializer.fromJson<int>(
        json['workerRefreshIntervalHours'],
      ),
      workerRefreshEndMinute: serializer.fromJson<int>(
        json['workerRefreshEndMinute'],
      ),
      settingsPassword: serializer.fromJson<String>(json['settingsPassword']),
      currentWorkerId: serializer.fromJson<String?>(json['currentWorkerId']),
      workerActiveAt: serializer.fromJson<DateTime?>(json['workerActiveAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceName': serializer.toJson<String>(deviceName),
      'environmentName': serializer.toJson<String>(environmentName),
      'serverUrl': serializer.toJson<String>(serverUrl),
      'serverToken': serializer.toJson<String>(serverToken),
      'ownerEmail': serializer.toJson<String>(ownerEmail),
      'dailyReportEnabled': serializer.toJson<bool>(dailyReportEnabled),
      'reportHour': serializer.toJson<int>(reportHour),
      'reportMinute': serializer.toJson<int>(reportMinute),
      'syncCursor': serializer.toJson<int>(syncCursor),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'confirmAction': serializer.toJson<bool>(confirmAction),
      'workerIdleSeconds': serializer.toJson<int>(workerIdleSeconds),
      'workerRefreshMode': serializer.toJson<String>(workerRefreshMode),
      'workerPromptStyle': serializer.toJson<String>(workerPromptStyle),
      'workerRefreshStartMinute': serializer.toJson<int>(
        workerRefreshStartMinute,
      ),
      'workerRefreshIntervalHours': serializer.toJson<int>(
        workerRefreshIntervalHours,
      ),
      'workerRefreshEndMinute': serializer.toJson<int>(workerRefreshEndMinute),
      'settingsPassword': serializer.toJson<String>(settingsPassword),
      'currentWorkerId': serializer.toJson<String?>(currentWorkerId),
      'workerActiveAt': serializer.toJson<DateTime?>(workerActiveAt),
    };
  }

  LocalSettingsRow copyWith({
    String? id,
    String? deviceId,
    String? deviceName,
    String? environmentName,
    String? serverUrl,
    String? serverToken,
    String? ownerEmail,
    bool? dailyReportEnabled,
    int? reportHour,
    int? reportMinute,
    int? syncCursor,
    Value<DateTime?> lastSyncAt = const Value.absent(),
    Value<String?> lastSyncError = const Value.absent(),
    bool? confirmAction,
    int? workerIdleSeconds,
    String? workerRefreshMode,
    String? workerPromptStyle,
    int? workerRefreshStartMinute,
    int? workerRefreshIntervalHours,
    int? workerRefreshEndMinute,
    String? settingsPassword,
    Value<String?> currentWorkerId = const Value.absent(),
    Value<DateTime?> workerActiveAt = const Value.absent(),
  }) => LocalSettingsRow(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    deviceName: deviceName ?? this.deviceName,
    environmentName: environmentName ?? this.environmentName,
    serverUrl: serverUrl ?? this.serverUrl,
    serverToken: serverToken ?? this.serverToken,
    ownerEmail: ownerEmail ?? this.ownerEmail,
    dailyReportEnabled: dailyReportEnabled ?? this.dailyReportEnabled,
    reportHour: reportHour ?? this.reportHour,
    reportMinute: reportMinute ?? this.reportMinute,
    syncCursor: syncCursor ?? this.syncCursor,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
    confirmAction: confirmAction ?? this.confirmAction,
    workerIdleSeconds: workerIdleSeconds ?? this.workerIdleSeconds,
    workerRefreshMode: workerRefreshMode ?? this.workerRefreshMode,
    workerPromptStyle: workerPromptStyle ?? this.workerPromptStyle,
    workerRefreshStartMinute:
        workerRefreshStartMinute ?? this.workerRefreshStartMinute,
    workerRefreshIntervalHours:
        workerRefreshIntervalHours ?? this.workerRefreshIntervalHours,
    workerRefreshEndMinute:
        workerRefreshEndMinute ?? this.workerRefreshEndMinute,
    settingsPassword: settingsPassword ?? this.settingsPassword,
    currentWorkerId: currentWorkerId.present
        ? currentWorkerId.value
        : this.currentWorkerId,
    workerActiveAt: workerActiveAt.present
        ? workerActiveAt.value
        : this.workerActiveAt,
  );
  LocalSettingsRow copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      environmentName: data.environmentName.present
          ? data.environmentName.value
          : this.environmentName,
      serverUrl: data.serverUrl.present ? data.serverUrl.value : this.serverUrl,
      serverToken: data.serverToken.present
          ? data.serverToken.value
          : this.serverToken,
      ownerEmail: data.ownerEmail.present
          ? data.ownerEmail.value
          : this.ownerEmail,
      dailyReportEnabled: data.dailyReportEnabled.present
          ? data.dailyReportEnabled.value
          : this.dailyReportEnabled,
      reportHour: data.reportHour.present
          ? data.reportHour.value
          : this.reportHour,
      reportMinute: data.reportMinute.present
          ? data.reportMinute.value
          : this.reportMinute,
      syncCursor: data.syncCursor.present
          ? data.syncCursor.value
          : this.syncCursor,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
      confirmAction: data.confirmAction.present
          ? data.confirmAction.value
          : this.confirmAction,
      workerIdleSeconds: data.workerIdleSeconds.present
          ? data.workerIdleSeconds.value
          : this.workerIdleSeconds,
      workerRefreshMode: data.workerRefreshMode.present
          ? data.workerRefreshMode.value
          : this.workerRefreshMode,
      workerPromptStyle: data.workerPromptStyle.present
          ? data.workerPromptStyle.value
          : this.workerPromptStyle,
      workerRefreshStartMinute: data.workerRefreshStartMinute.present
          ? data.workerRefreshStartMinute.value
          : this.workerRefreshStartMinute,
      workerRefreshIntervalHours: data.workerRefreshIntervalHours.present
          ? data.workerRefreshIntervalHours.value
          : this.workerRefreshIntervalHours,
      workerRefreshEndMinute: data.workerRefreshEndMinute.present
          ? data.workerRefreshEndMinute.value
          : this.workerRefreshEndMinute,
      settingsPassword: data.settingsPassword.present
          ? data.settingsPassword.value
          : this.settingsPassword,
      currentWorkerId: data.currentWorkerId.present
          ? data.currentWorkerId.value
          : this.currentWorkerId,
      workerActiveAt: data.workerActiveAt.present
          ? data.workerActiveAt.value
          : this.workerActiveAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsRow(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('environmentName: $environmentName, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('serverToken: $serverToken, ')
          ..write('ownerEmail: $ownerEmail, ')
          ..write('dailyReportEnabled: $dailyReportEnabled, ')
          ..write('reportHour: $reportHour, ')
          ..write('reportMinute: $reportMinute, ')
          ..write('syncCursor: $syncCursor, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('confirmAction: $confirmAction, ')
          ..write('workerIdleSeconds: $workerIdleSeconds, ')
          ..write('workerRefreshMode: $workerRefreshMode, ')
          ..write('workerPromptStyle: $workerPromptStyle, ')
          ..write('workerRefreshStartMinute: $workerRefreshStartMinute, ')
          ..write('workerRefreshIntervalHours: $workerRefreshIntervalHours, ')
          ..write('workerRefreshEndMinute: $workerRefreshEndMinute, ')
          ..write('settingsPassword: $settingsPassword, ')
          ..write('currentWorkerId: $currentWorkerId, ')
          ..write('workerActiveAt: $workerActiveAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    deviceId,
    deviceName,
    environmentName,
    serverUrl,
    serverToken,
    ownerEmail,
    dailyReportEnabled,
    reportHour,
    reportMinute,
    syncCursor,
    lastSyncAt,
    lastSyncError,
    confirmAction,
    workerIdleSeconds,
    workerRefreshMode,
    workerPromptStyle,
    workerRefreshStartMinute,
    workerRefreshIntervalHours,
    workerRefreshEndMinute,
    settingsPassword,
    currentWorkerId,
    workerActiveAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSettingsRow &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.deviceName == this.deviceName &&
          other.environmentName == this.environmentName &&
          other.serverUrl == this.serverUrl &&
          other.serverToken == this.serverToken &&
          other.ownerEmail == this.ownerEmail &&
          other.dailyReportEnabled == this.dailyReportEnabled &&
          other.reportHour == this.reportHour &&
          other.reportMinute == this.reportMinute &&
          other.syncCursor == this.syncCursor &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastSyncError == this.lastSyncError &&
          other.confirmAction == this.confirmAction &&
          other.workerIdleSeconds == this.workerIdleSeconds &&
          other.workerRefreshMode == this.workerRefreshMode &&
          other.workerPromptStyle == this.workerPromptStyle &&
          other.workerRefreshStartMinute == this.workerRefreshStartMinute &&
          other.workerRefreshIntervalHours == this.workerRefreshIntervalHours &&
          other.workerRefreshEndMinute == this.workerRefreshEndMinute &&
          other.settingsPassword == this.settingsPassword &&
          other.currentWorkerId == this.currentWorkerId &&
          other.workerActiveAt == this.workerActiveAt);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSettingsRow> {
  final Value<String> id;
  final Value<String> deviceId;
  final Value<String> deviceName;
  final Value<String> environmentName;
  final Value<String> serverUrl;
  final Value<String> serverToken;
  final Value<String> ownerEmail;
  final Value<bool> dailyReportEnabled;
  final Value<int> reportHour;
  final Value<int> reportMinute;
  final Value<int> syncCursor;
  final Value<DateTime?> lastSyncAt;
  final Value<String?> lastSyncError;
  final Value<bool> confirmAction;
  final Value<int> workerIdleSeconds;
  final Value<String> workerRefreshMode;
  final Value<String> workerPromptStyle;
  final Value<int> workerRefreshStartMinute;
  final Value<int> workerRefreshIntervalHours;
  final Value<int> workerRefreshEndMinute;
  final Value<String> settingsPassword;
  final Value<String?> currentWorkerId;
  final Value<DateTime?> workerActiveAt;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.environmentName = const Value.absent(),
    this.serverUrl = const Value.absent(),
    this.serverToken = const Value.absent(),
    this.ownerEmail = const Value.absent(),
    this.dailyReportEnabled = const Value.absent(),
    this.reportHour = const Value.absent(),
    this.reportMinute = const Value.absent(),
    this.syncCursor = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.confirmAction = const Value.absent(),
    this.workerIdleSeconds = const Value.absent(),
    this.workerRefreshMode = const Value.absent(),
    this.workerPromptStyle = const Value.absent(),
    this.workerRefreshStartMinute = const Value.absent(),
    this.workerRefreshIntervalHours = const Value.absent(),
    this.workerRefreshEndMinute = const Value.absent(),
    this.settingsPassword = const Value.absent(),
    this.currentWorkerId = const Value.absent(),
    this.workerActiveAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String id,
    required String deviceId,
    required String deviceName,
    required String environmentName,
    this.serverUrl = const Value.absent(),
    this.serverToken = const Value.absent(),
    this.ownerEmail = const Value.absent(),
    this.dailyReportEnabled = const Value.absent(),
    this.reportHour = const Value.absent(),
    this.reportMinute = const Value.absent(),
    this.syncCursor = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.confirmAction = const Value.absent(),
    this.workerIdleSeconds = const Value.absent(),
    this.workerRefreshMode = const Value.absent(),
    this.workerPromptStyle = const Value.absent(),
    this.workerRefreshStartMinute = const Value.absent(),
    this.workerRefreshIntervalHours = const Value.absent(),
    this.workerRefreshEndMinute = const Value.absent(),
    this.settingsPassword = const Value.absent(),
    this.currentWorkerId = const Value.absent(),
    this.workerActiveAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deviceId = Value(deviceId),
       deviceName = Value(deviceName),
       environmentName = Value(environmentName);
  static Insertable<LocalSettingsRow> custom({
    Expression<String>? id,
    Expression<String>? deviceId,
    Expression<String>? deviceName,
    Expression<String>? environmentName,
    Expression<String>? serverUrl,
    Expression<String>? serverToken,
    Expression<String>? ownerEmail,
    Expression<bool>? dailyReportEnabled,
    Expression<int>? reportHour,
    Expression<int>? reportMinute,
    Expression<int>? syncCursor,
    Expression<DateTime>? lastSyncAt,
    Expression<String>? lastSyncError,
    Expression<bool>? confirmAction,
    Expression<int>? workerIdleSeconds,
    Expression<String>? workerRefreshMode,
    Expression<String>? workerPromptStyle,
    Expression<int>? workerRefreshStartMinute,
    Expression<int>? workerRefreshIntervalHours,
    Expression<int>? workerRefreshEndMinute,
    Expression<String>? settingsPassword,
    Expression<String>? currentWorkerId,
    Expression<DateTime>? workerActiveAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
      if (environmentName != null) 'environment_name': environmentName,
      if (serverUrl != null) 'server_url': serverUrl,
      if (serverToken != null) 'server_token': serverToken,
      if (ownerEmail != null) 'owner_email': ownerEmail,
      if (dailyReportEnabled != null)
        'daily_report_enabled': dailyReportEnabled,
      if (reportHour != null) 'report_hour': reportHour,
      if (reportMinute != null) 'report_minute': reportMinute,
      if (syncCursor != null) 'sync_cursor': syncCursor,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (confirmAction != null) 'confirm_action': confirmAction,
      if (workerIdleSeconds != null) 'worker_idle_seconds': workerIdleSeconds,
      if (workerRefreshMode != null) 'worker_refresh_mode': workerRefreshMode,
      if (workerPromptStyle != null) 'worker_prompt_style': workerPromptStyle,
      if (workerRefreshStartMinute != null)
        'worker_refresh_start_minute': workerRefreshStartMinute,
      if (workerRefreshIntervalHours != null)
        'worker_refresh_interval_hours': workerRefreshIntervalHours,
      if (workerRefreshEndMinute != null)
        'worker_refresh_end_minute': workerRefreshEndMinute,
      if (settingsPassword != null) 'settings_password': settingsPassword,
      if (currentWorkerId != null) 'current_worker_id': currentWorkerId,
      if (workerActiveAt != null) 'worker_active_at': workerActiveAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSettingsCompanion copyWith({
    Value<String>? id,
    Value<String>? deviceId,
    Value<String>? deviceName,
    Value<String>? environmentName,
    Value<String>? serverUrl,
    Value<String>? serverToken,
    Value<String>? ownerEmail,
    Value<bool>? dailyReportEnabled,
    Value<int>? reportHour,
    Value<int>? reportMinute,
    Value<int>? syncCursor,
    Value<DateTime?>? lastSyncAt,
    Value<String?>? lastSyncError,
    Value<bool>? confirmAction,
    Value<int>? workerIdleSeconds,
    Value<String>? workerRefreshMode,
    Value<String>? workerPromptStyle,
    Value<int>? workerRefreshStartMinute,
    Value<int>? workerRefreshIntervalHours,
    Value<int>? workerRefreshEndMinute,
    Value<String>? settingsPassword,
    Value<String?>? currentWorkerId,
    Value<DateTime?>? workerActiveAt,
    Value<int>? rowid,
  }) {
    return LocalSettingsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      environmentName: environmentName ?? this.environmentName,
      serverUrl: serverUrl ?? this.serverUrl,
      serverToken: serverToken ?? this.serverToken,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      dailyReportEnabled: dailyReportEnabled ?? this.dailyReportEnabled,
      reportHour: reportHour ?? this.reportHour,
      reportMinute: reportMinute ?? this.reportMinute,
      syncCursor: syncCursor ?? this.syncCursor,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      confirmAction: confirmAction ?? this.confirmAction,
      workerIdleSeconds: workerIdleSeconds ?? this.workerIdleSeconds,
      workerRefreshMode: workerRefreshMode ?? this.workerRefreshMode,
      workerPromptStyle: workerPromptStyle ?? this.workerPromptStyle,
      workerRefreshStartMinute:
          workerRefreshStartMinute ?? this.workerRefreshStartMinute,
      workerRefreshIntervalHours:
          workerRefreshIntervalHours ?? this.workerRefreshIntervalHours,
      workerRefreshEndMinute:
          workerRefreshEndMinute ?? this.workerRefreshEndMinute,
      settingsPassword: settingsPassword ?? this.settingsPassword,
      currentWorkerId: currentWorkerId ?? this.currentWorkerId,
      workerActiveAt: workerActiveAt ?? this.workerActiveAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (environmentName.present) {
      map['environment_name'] = Variable<String>(environmentName.value);
    }
    if (serverUrl.present) {
      map['server_url'] = Variable<String>(serverUrl.value);
    }
    if (serverToken.present) {
      map['server_token'] = Variable<String>(serverToken.value);
    }
    if (ownerEmail.present) {
      map['owner_email'] = Variable<String>(ownerEmail.value);
    }
    if (dailyReportEnabled.present) {
      map['daily_report_enabled'] = Variable<bool>(dailyReportEnabled.value);
    }
    if (reportHour.present) {
      map['report_hour'] = Variable<int>(reportHour.value);
    }
    if (reportMinute.present) {
      map['report_minute'] = Variable<int>(reportMinute.value);
    }
    if (syncCursor.present) {
      map['sync_cursor'] = Variable<int>(syncCursor.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (confirmAction.present) {
      map['confirm_action'] = Variable<bool>(confirmAction.value);
    }
    if (workerIdleSeconds.present) {
      map['worker_idle_seconds'] = Variable<int>(workerIdleSeconds.value);
    }
    if (workerRefreshMode.present) {
      map['worker_refresh_mode'] = Variable<String>(workerRefreshMode.value);
    }
    if (workerPromptStyle.present) {
      map['worker_prompt_style'] = Variable<String>(workerPromptStyle.value);
    }
    if (workerRefreshStartMinute.present) {
      map['worker_refresh_start_minute'] = Variable<int>(
        workerRefreshStartMinute.value,
      );
    }
    if (workerRefreshIntervalHours.present) {
      map['worker_refresh_interval_hours'] = Variable<int>(
        workerRefreshIntervalHours.value,
      );
    }
    if (workerRefreshEndMinute.present) {
      map['worker_refresh_end_minute'] = Variable<int>(
        workerRefreshEndMinute.value,
      );
    }
    if (settingsPassword.present) {
      map['settings_password'] = Variable<String>(settingsPassword.value);
    }
    if (currentWorkerId.present) {
      map['current_worker_id'] = Variable<String>(currentWorkerId.value);
    }
    if (workerActiveAt.present) {
      map['worker_active_at'] = Variable<DateTime>(workerActiveAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('environmentName: $environmentName, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('serverToken: $serverToken, ')
          ..write('ownerEmail: $ownerEmail, ')
          ..write('dailyReportEnabled: $dailyReportEnabled, ')
          ..write('reportHour: $reportHour, ')
          ..write('reportMinute: $reportMinute, ')
          ..write('syncCursor: $syncCursor, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('confirmAction: $confirmAction, ')
          ..write('workerIdleSeconds: $workerIdleSeconds, ')
          ..write('workerRefreshMode: $workerRefreshMode, ')
          ..write('workerPromptStyle: $workerPromptStyle, ')
          ..write('workerRefreshStartMinute: $workerRefreshStartMinute, ')
          ..write('workerRefreshIntervalHours: $workerRefreshIntervalHours, ')
          ..write('workerRefreshEndMinute: $workerRefreshEndMinute, ')
          ..write('settingsPassword: $settingsPassword, ')
          ..write('currentWorkerId: $currentWorkerId, ')
          ..write('workerActiveAt: $workerActiveAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyReportsTable extends DailyReports
    with TableInfo<$DailyReportsTable, DailyReportRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _environmentNameMeta = const VerificationMeta(
    'environmentName',
  );
  @override
  late final GeneratedColumn<String> environmentName = GeneratedColumn<String>(
    'environment_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reportDateMeta = const VerificationMeta(
    'reportDate',
  );
  @override
  late final GeneratedColumn<String> reportDate = GeneratedColumn<String>(
    'report_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerEmailMeta = const VerificationMeta(
    'ownerEmail',
  );
  @override
  late final GeneratedColumn<String> ownerEmail = GeneratedColumn<String>(
    'owner_email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    environmentName,
    reportDate,
    ownerEmail,
    subject,
    body,
    status,
    createdAt,
    sentAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyReportRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('environment_name')) {
      context.handle(
        _environmentNameMeta,
        environmentName.isAcceptableOrUnknown(
          data['environment_name']!,
          _environmentNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentNameMeta);
    }
    if (data.containsKey('report_date')) {
      context.handle(
        _reportDateMeta,
        reportDate.isAcceptableOrUnknown(data['report_date']!, _reportDateMeta),
      );
    } else if (isInserting) {
      context.missing(_reportDateMeta);
    }
    if (data.containsKey('owner_email')) {
      context.handle(
        _ownerEmailMeta,
        ownerEmail.isAcceptableOrUnknown(data['owner_email']!, _ownerEmailMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerEmailMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {environmentName, reportDate},
  ];
  @override
  DailyReportRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyReportRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      environmentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_name'],
      )!,
      reportDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_date'],
      )!,
      ownerEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_email'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $DailyReportsTable createAlias(String alias) {
    return $DailyReportsTable(attachedDatabase, alias);
  }
}

class DailyReportRow extends DataClass implements Insertable<DailyReportRow> {
  final String id;
  final String environmentName;
  final String reportDate;
  final String ownerEmail;
  final String subject;
  final String body;
  final String status;
  final DateTime createdAt;
  final DateTime? sentAt;
  final String? lastError;
  const DailyReportRow({
    required this.id,
    required this.environmentName,
    required this.reportDate,
    required this.ownerEmail,
    required this.subject,
    required this.body,
    required this.status,
    required this.createdAt,
    this.sentAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['environment_name'] = Variable<String>(environmentName);
    map['report_date'] = Variable<String>(reportDate);
    map['owner_email'] = Variable<String>(ownerEmail);
    map['subject'] = Variable<String>(subject);
    map['body'] = Variable<String>(body);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  DailyReportsCompanion toCompanion(bool nullToAbsent) {
    return DailyReportsCompanion(
      id: Value(id),
      environmentName: Value(environmentName),
      reportDate: Value(reportDate),
      ownerEmail: Value(ownerEmail),
      subject: Value(subject),
      body: Value(body),
      status: Value(status),
      createdAt: Value(createdAt),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory DailyReportRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyReportRow(
      id: serializer.fromJson<String>(json['id']),
      environmentName: serializer.fromJson<String>(json['environmentName']),
      reportDate: serializer.fromJson<String>(json['reportDate']),
      ownerEmail: serializer.fromJson<String>(json['ownerEmail']),
      subject: serializer.fromJson<String>(json['subject']),
      body: serializer.fromJson<String>(json['body']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'environmentName': serializer.toJson<String>(environmentName),
      'reportDate': serializer.toJson<String>(reportDate),
      'ownerEmail': serializer.toJson<String>(ownerEmail),
      'subject': serializer.toJson<String>(subject),
      'body': serializer.toJson<String>(body),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  DailyReportRow copyWith({
    String? id,
    String? environmentName,
    String? reportDate,
    String? ownerEmail,
    String? subject,
    String? body,
    String? status,
    DateTime? createdAt,
    Value<DateTime?> sentAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => DailyReportRow(
    id: id ?? this.id,
    environmentName: environmentName ?? this.environmentName,
    reportDate: reportDate ?? this.reportDate,
    ownerEmail: ownerEmail ?? this.ownerEmail,
    subject: subject ?? this.subject,
    body: body ?? this.body,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  DailyReportRow copyWithCompanion(DailyReportsCompanion data) {
    return DailyReportRow(
      id: data.id.present ? data.id.value : this.id,
      environmentName: data.environmentName.present
          ? data.environmentName.value
          : this.environmentName,
      reportDate: data.reportDate.present
          ? data.reportDate.value
          : this.reportDate,
      ownerEmail: data.ownerEmail.present
          ? data.ownerEmail.value
          : this.ownerEmail,
      subject: data.subject.present ? data.subject.value : this.subject,
      body: data.body.present ? data.body.value : this.body,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyReportRow(')
          ..write('id: $id, ')
          ..write('environmentName: $environmentName, ')
          ..write('reportDate: $reportDate, ')
          ..write('ownerEmail: $ownerEmail, ')
          ..write('subject: $subject, ')
          ..write('body: $body, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('sentAt: $sentAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    environmentName,
    reportDate,
    ownerEmail,
    subject,
    body,
    status,
    createdAt,
    sentAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyReportRow &&
          other.id == this.id &&
          other.environmentName == this.environmentName &&
          other.reportDate == this.reportDate &&
          other.ownerEmail == this.ownerEmail &&
          other.subject == this.subject &&
          other.body == this.body &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.sentAt == this.sentAt &&
          other.lastError == this.lastError);
}

class DailyReportsCompanion extends UpdateCompanion<DailyReportRow> {
  final Value<String> id;
  final Value<String> environmentName;
  final Value<String> reportDate;
  final Value<String> ownerEmail;
  final Value<String> subject;
  final Value<String> body;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> sentAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const DailyReportsCompanion({
    this.id = const Value.absent(),
    this.environmentName = const Value.absent(),
    this.reportDate = const Value.absent(),
    this.ownerEmail = const Value.absent(),
    this.subject = const Value.absent(),
    this.body = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyReportsCompanion.insert({
    required String id,
    required String environmentName,
    required String reportDate,
    required String ownerEmail,
    required String subject,
    required String body,
    required String status,
    required DateTime createdAt,
    this.sentAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       environmentName = Value(environmentName),
       reportDate = Value(reportDate),
       ownerEmail = Value(ownerEmail),
       subject = Value(subject),
       body = Value(body),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<DailyReportRow> custom({
    Expression<String>? id,
    Expression<String>? environmentName,
    Expression<String>? reportDate,
    Expression<String>? ownerEmail,
    Expression<String>? subject,
    Expression<String>? body,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? sentAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (environmentName != null) 'environment_name': environmentName,
      if (reportDate != null) 'report_date': reportDate,
      if (ownerEmail != null) 'owner_email': ownerEmail,
      if (subject != null) 'subject': subject,
      if (body != null) 'body': body,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (sentAt != null) 'sent_at': sentAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyReportsCompanion copyWith({
    Value<String>? id,
    Value<String>? environmentName,
    Value<String>? reportDate,
    Value<String>? ownerEmail,
    Value<String>? subject,
    Value<String>? body,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? sentAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return DailyReportsCompanion(
      id: id ?? this.id,
      environmentName: environmentName ?? this.environmentName,
      reportDate: reportDate ?? this.reportDate,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (environmentName.present) {
      map['environment_name'] = Variable<String>(environmentName.value);
    }
    if (reportDate.present) {
      map['report_date'] = Variable<String>(reportDate.value);
    }
    if (ownerEmail.present) {
      map['owner_email'] = Variable<String>(ownerEmail.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyReportsCompanion(')
          ..write('id: $id, ')
          ..write('environmentName: $environmentName, ')
          ..write('reportDate: $reportDate, ')
          ..write('ownerEmail: $ownerEmail, ')
          ..write('subject: $subject, ')
          ..write('body: $body, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('sentAt: $sentAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $FridgesTable fridges = $FridgesTable(this);
  late final $WorkersTable workers = $WorkersTable(this);
  late final $RefrigerationLogsTable refrigerationLogs =
      $RefrigerationLogsTable(this);
  late final $AlertsTable alerts = $AlertsTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final $DailyReportsTable dailyReports = $DailyReportsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    fridges,
    workers,
    refrigerationLogs,
    alerts,
    syncOutbox,
    localSettings,
    dailyReports,
  ];
}

typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String name,
  Value<String?> sku,
  Value<bool> listed,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> sku,
  Value<bool> listed,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, ProductRow> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RefrigerationLogsTable, List<RefrigerationLogRow>>
  _refrigerationLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.refrigerationLogs,
        aliasName: 'products__id__refrigeration_logs__product_id',
      );

  $$RefrigerationLogsTableProcessedTableManager get refrigerationLogsRefs {
    final manager = $$RefrigerationLogsTableTableManager(
      $_db,
      $_db.refrigerationLogs,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _refrigerationLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AlertsTable, List<AlertRow>> _alertsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.alerts,
    aliasName: 'products__id__alerts__product_id',
  );

  $$AlertsTableProcessedTableManager get alertsRefs {
    final manager = $$AlertsTableTableManager(
      $_db,
      $_db.alerts,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_alertsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get listed => $composableBuilder(
    column: $table.listed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> refrigerationLogsRefs(
    Expression<bool> Function($$RefrigerationLogsTableFilterComposer f) f,
  ) {
    final $$RefrigerationLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refrigerationLogs,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefrigerationLogsTableFilterComposer(
            $db: $db,
            $table: $db.refrigerationLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> alertsRefs(
    Expression<bool> Function($$AlertsTableFilterComposer f) f,
  ) {
    final $$AlertsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alerts,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlertsTableFilterComposer(
            $db: $db,
            $table: $db.alerts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get listed => $composableBuilder(
    column: $table.listed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<bool> get listed =>
      $composableBuilder(column: $table.listed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> refrigerationLogsRefs<T extends Object>(
    Expression<T> Function($$RefrigerationLogsTableAnnotationComposer a) f,
  ) {
    final $$RefrigerationLogsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.refrigerationLogs,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RefrigerationLogsTableAnnotationComposer(
                $db: $db,
                $table: $db.refrigerationLogs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> alertsRefs<T extends Object>(
    Expression<T> Function($$AlertsTableAnnotationComposer a) f,
  ) {
    final $$AlertsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alerts,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlertsTableAnnotationComposer(
            $db: $db,
            $table: $db.alerts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          ProductRow,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (ProductRow, $$ProductsTableReferences),
          ProductRow,
          PrefetchHooks Function({bool refrigerationLogsRefs, bool alertsRefs})
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<bool> listed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                sku: sku,
                listed: listed,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> sku = const Value.absent(),
                Value<bool> listed = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                sku: sku,
                listed: listed,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductsTable, ProductRow>(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({refrigerationLogsRefs = false, alertsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (refrigerationLogsRefs) db.refrigerationLogs,
                    if (alertsRefs) db.alerts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (refrigerationLogsRefs)
                        await $_getPrefetchedData<
                          ProductRow,
                          $ProductsTable,
                          RefrigerationLogRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._refrigerationLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).refrigerationLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (alertsRefs)
                        await $_getPrefetchedData<
                          ProductRow,
                          $ProductsTable,
                          AlertRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._alertsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).alertsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      ProductRow,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (ProductRow, $$ProductsTableReferences),
      ProductRow,
      PrefetchHooks Function({bool refrigerationLogsRefs, bool alertsRefs})
    >;
typedef $$FridgesTableCreateCompanionBuilder = FridgesCompanion Function({
  required String id,
  required String name,
  required double minCelsius,
  required double maxCelsius,
  Value<int> rowid,
});
typedef $$FridgesTableUpdateCompanionBuilder = FridgesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<double> minCelsius,
  Value<double> maxCelsius,
  Value<int> rowid,
});

final class $$FridgesTableReferences
    extends BaseReferences<_$AppDatabase, $FridgesTable, FridgeRow> {
  $$FridgesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RefrigerationLogsTable, List<RefrigerationLogRow>>
  _refrigerationLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.refrigerationLogs,
        aliasName: 'fridges__id__refrigeration_logs__fridge_id',
      );

  $$RefrigerationLogsTableProcessedTableManager get refrigerationLogsRefs {
    final manager = $$RefrigerationLogsTableTableManager(
      $_db,
      $_db.refrigerationLogs,
    ).filter((f) => f.fridgeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _refrigerationLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FridgesTableFilterComposer
    extends Composer<_$AppDatabase, $FridgesTable> {
  $$FridgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minCelsius => $composableBuilder(
    column: $table.minCelsius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxCelsius => $composableBuilder(
    column: $table.maxCelsius,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> refrigerationLogsRefs(
    Expression<bool> Function($$RefrigerationLogsTableFilterComposer f) f,
  ) {
    final $$RefrigerationLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.refrigerationLogs,
      getReferencedColumn: (t) => t.fridgeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefrigerationLogsTableFilterComposer(
            $db: $db,
            $table: $db.refrigerationLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FridgesTableOrderingComposer
    extends Composer<_$AppDatabase, $FridgesTable> {
  $$FridgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minCelsius => $composableBuilder(
    column: $table.minCelsius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxCelsius => $composableBuilder(
    column: $table.maxCelsius,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FridgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FridgesTable> {
  $$FridgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get minCelsius => $composableBuilder(
    column: $table.minCelsius,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxCelsius => $composableBuilder(
    column: $table.maxCelsius,
    builder: (column) => column,
  );

  Expression<T> refrigerationLogsRefs<T extends Object>(
    Expression<T> Function($$RefrigerationLogsTableAnnotationComposer a) f,
  ) {
    final $$RefrigerationLogsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.refrigerationLogs,
          getReferencedColumn: (t) => t.fridgeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RefrigerationLogsTableAnnotationComposer(
                $db: $db,
                $table: $db.refrigerationLogs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FridgesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FridgesTable,
          FridgeRow,
          $$FridgesTableFilterComposer,
          $$FridgesTableOrderingComposer,
          $$FridgesTableAnnotationComposer,
          $$FridgesTableCreateCompanionBuilder,
          $$FridgesTableUpdateCompanionBuilder,
          (FridgeRow, $$FridgesTableReferences),
          FridgeRow,
          PrefetchHooks Function({bool refrigerationLogsRefs})
        > {
  $$FridgesTableTableManager(_$AppDatabase db, $FridgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FridgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FridgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FridgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> minCelsius = const Value.absent(),
                Value<double> maxCelsius = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FridgesCompanion(
                id: id,
                name: name,
                minCelsius: minCelsius,
                maxCelsius: maxCelsius,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double minCelsius,
                required double maxCelsius,
                Value<int> rowid = const Value.absent(),
              }) => FridgesCompanion.insert(
                id: id,
                name: name,
                minCelsius: minCelsius,
                maxCelsius: maxCelsius,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FridgesTable, FridgeRow>(table),
                  $$FridgesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({refrigerationLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (refrigerationLogsRefs) db.refrigerationLogs,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (refrigerationLogsRefs)
                    await $_getPrefetchedData<
                      FridgeRow,
                      $FridgesTable,
                      RefrigerationLogRow
                    >(
                      currentTable: table,
                      referencedTable: $$FridgesTableReferences
                          ._refrigerationLogsRefsTable(db),
                      managerFromTypedResult: (p0) => $$FridgesTableReferences(
                        db,
                        table,
                        p0,
                      ).refrigerationLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.fridgeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FridgesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FridgesTable,
      FridgeRow,
      $$FridgesTableFilterComposer,
      $$FridgesTableOrderingComposer,
      $$FridgesTableAnnotationComposer,
      $$FridgesTableCreateCompanionBuilder,
      $$FridgesTableUpdateCompanionBuilder,
      (FridgeRow, $$FridgesTableReferences),
      FridgeRow,
      PrefetchHooks Function({bool refrigerationLogsRefs})
    >;
typedef $$WorkersTableCreateCompanionBuilder = WorkersCompanion Function({
  required String id,
  required String name,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$WorkersTableUpdateCompanionBuilder = WorkersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$WorkersTableFilterComposer
    extends Composer<_$AppDatabase, $WorkersTable> {
  $$WorkersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkersTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkersTable> {
  $$WorkersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkersTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkersTable> {
  $$WorkersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WorkersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkersTable,
          WorkerRow,
          $$WorkersTableFilterComposer,
          $$WorkersTableOrderingComposer,
          $$WorkersTableAnnotationComposer,
          $$WorkersTableCreateCompanionBuilder,
          $$WorkersTableUpdateCompanionBuilder,
          (WorkerRow, BaseReferences<_$AppDatabase, $WorkersTable, WorkerRow>),
          WorkerRow,
          PrefetchHooks Function()
        > {
  $$WorkersTableTableManager(_$AppDatabase db, $WorkersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkersCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => WorkersCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkersTable, WorkerRow>(table),
                  BaseReferences<_$AppDatabase, $WorkersTable, WorkerRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkersTable,
      WorkerRow,
      $$WorkersTableFilterComposer,
      $$WorkersTableOrderingComposer,
      $$WorkersTableAnnotationComposer,
      $$WorkersTableCreateCompanionBuilder,
      $$WorkersTableUpdateCompanionBuilder,
      (WorkerRow, BaseReferences<_$AppDatabase, $WorkersTable, WorkerRow>),
      WorkerRow,
      PrefetchHooks Function()
    >;
typedef $$RefrigerationLogsTableCreateCompanionBuilder =
    RefrigerationLogsCompanion Function({
      required String id,
      required String movementId,
      required String productId,
      required String productNameSnapshot,
      required String fridgeId,
      required LogEventType eventType,
      required double temperatureCelsius,
      required DateTime occurredAt,
      required DateTime createdAt,
      Value<String> originDeviceId,
      Value<String> workerNameSnapshot,
      Value<DateTime?> dueAt,
      Value<int> quantity,
      Value<int> rowid,
    });
typedef $$RefrigerationLogsTableUpdateCompanionBuilder =
    RefrigerationLogsCompanion Function({
      Value<String> id,
      Value<String> movementId,
      Value<String> productId,
      Value<String> productNameSnapshot,
      Value<String> fridgeId,
      Value<LogEventType> eventType,
      Value<double> temperatureCelsius,
      Value<DateTime> occurredAt,
      Value<DateTime> createdAt,
      Value<String> originDeviceId,
      Value<String> workerNameSnapshot,
      Value<DateTime?> dueAt,
      Value<int> quantity,
      Value<int> rowid,
    });

final class $$RefrigerationLogsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RefrigerationLogsTable,
          RefrigerationLogRow
        > {
  $$RefrigerationLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('refrigeration_logs__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FridgesTable _fridgeIdTable(_$AppDatabase db) =>
      db.fridges.createAlias('refrigeration_logs__fridge_id__fridges__id');

  $$FridgesTableProcessedTableManager get fridgeId {
    final $_column = $_itemColumn<String>('fridge_id')!;

    final manager = $$FridgesTableTableManager(
      $_db,
      $_db.fridges,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fridgeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AlertsTable, List<AlertRow>> _alertsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.alerts,
    aliasName: 'refrigeration_logs__id__alerts__log_id',
  );

  $$AlertsTableProcessedTableManager get alertsRefs {
    final manager = $$AlertsTableTableManager(
      $_db,
      $_db.alerts,
    ).filter((f) => f.logId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_alertsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RefrigerationLogsTableFilterComposer
    extends Composer<_$AppDatabase, $RefrigerationLogsTable> {
  $$RefrigerationLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementId => $composableBuilder(
    column: $table.movementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LogEventType, LogEventType, String>
  get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerNameSnapshot => $composableBuilder(
    column: $table.workerNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FridgesTableFilterComposer get fridgeId {
    final $$FridgesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fridgeId,
      referencedTable: $db.fridges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FridgesTableFilterComposer(
            $db: $db,
            $table: $db.fridges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> alertsRefs(
    Expression<bool> Function($$AlertsTableFilterComposer f) f,
  ) {
    final $$AlertsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alerts,
      getReferencedColumn: (t) => t.logId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlertsTableFilterComposer(
            $db: $db,
            $table: $db.alerts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RefrigerationLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $RefrigerationLogsTable> {
  $$RefrigerationLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementId => $composableBuilder(
    column: $table.movementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerNameSnapshot => $composableBuilder(
    column: $table.workerNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FridgesTableOrderingComposer get fridgeId {
    final $$FridgesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fridgeId,
      referencedTable: $db.fridges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FridgesTableOrderingComposer(
            $db: $db,
            $table: $db.fridges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RefrigerationLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefrigerationLogsTable> {
  $$RefrigerationLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get movementId => $composableBuilder(
    column: $table.movementId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LogEventType, String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workerNameSnapshot => $composableBuilder(
    column: $table.workerNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FridgesTableAnnotationComposer get fridgeId {
    final $$FridgesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fridgeId,
      referencedTable: $db.fridges,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FridgesTableAnnotationComposer(
            $db: $db,
            $table: $db.fridges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> alertsRefs<T extends Object>(
    Expression<T> Function($$AlertsTableAnnotationComposer a) f,
  ) {
    final $$AlertsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alerts,
      getReferencedColumn: (t) => t.logId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlertsTableAnnotationComposer(
            $db: $db,
            $table: $db.alerts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RefrigerationLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RefrigerationLogsTable,
          RefrigerationLogRow,
          $$RefrigerationLogsTableFilterComposer,
          $$RefrigerationLogsTableOrderingComposer,
          $$RefrigerationLogsTableAnnotationComposer,
          $$RefrigerationLogsTableCreateCompanionBuilder,
          $$RefrigerationLogsTableUpdateCompanionBuilder,
          (RefrigerationLogRow, $$RefrigerationLogsTableReferences),
          RefrigerationLogRow,
          PrefetchHooks Function({
            bool productId,
            bool fridgeId,
            bool alertsRefs,
          })
        > {
  $$RefrigerationLogsTableTableManager(
    _$AppDatabase db,
    $RefrigerationLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RefrigerationLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RefrigerationLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RefrigerationLogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> movementId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productNameSnapshot = const Value.absent(),
                Value<String> fridgeId = const Value.absent(),
                Value<LogEventType> eventType = const Value.absent(),
                Value<double> temperatureCelsius = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<String> workerNameSnapshot = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RefrigerationLogsCompanion(
                id: id,
                movementId: movementId,
                productId: productId,
                productNameSnapshot: productNameSnapshot,
                fridgeId: fridgeId,
                eventType: eventType,
                temperatureCelsius: temperatureCelsius,
                occurredAt: occurredAt,
                createdAt: createdAt,
                originDeviceId: originDeviceId,
                workerNameSnapshot: workerNameSnapshot,
                dueAt: dueAt,
                quantity: quantity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String movementId,
                required String productId,
                required String productNameSnapshot,
                required String fridgeId,
                required LogEventType eventType,
                required double temperatureCelsius,
                required DateTime occurredAt,
                required DateTime createdAt,
                Value<String> originDeviceId = const Value.absent(),
                Value<String> workerNameSnapshot = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RefrigerationLogsCompanion.insert(
                id: id,
                movementId: movementId,
                productId: productId,
                productNameSnapshot: productNameSnapshot,
                fridgeId: fridgeId,
                eventType: eventType,
                temperatureCelsius: temperatureCelsius,
                occurredAt: occurredAt,
                createdAt: createdAt,
                originDeviceId: originDeviceId,
                workerNameSnapshot: workerNameSnapshot,
                dueAt: dueAt,
                quantity: quantity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RefrigerationLogsTable, RefrigerationLogRow>(
                    table,
                  ),
                  $$RefrigerationLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({productId = false, fridgeId = false, alertsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (alertsRefs) db.alerts],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (productId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.productId,
                            referencedTable: $$RefrigerationLogsTableReferences
                                ._productIdTable(db),
                            referencedColumn: $$RefrigerationLogsTableReferences
                                ._productIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (fridgeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.fridgeId,
                            referencedTable: $$RefrigerationLogsTableReferences
                                ._fridgeIdTable(db),
                            referencedColumn: $$RefrigerationLogsTableReferences
                                ._fridgeIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (alertsRefs)
                        await $_getPrefetchedData<
                          RefrigerationLogRow,
                          $RefrigerationLogsTable,
                          AlertRow
                        >(
                          currentTable: table,
                          referencedTable: $$RefrigerationLogsTableReferences
                              ._alertsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RefrigerationLogsTableReferences(
                                db,
                                table,
                                p0,
                              ).alertsRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.logId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RefrigerationLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RefrigerationLogsTable,
      RefrigerationLogRow,
      $$RefrigerationLogsTableFilterComposer,
      $$RefrigerationLogsTableOrderingComposer,
      $$RefrigerationLogsTableAnnotationComposer,
      $$RefrigerationLogsTableCreateCompanionBuilder,
      $$RefrigerationLogsTableUpdateCompanionBuilder,
      (RefrigerationLogRow, $$RefrigerationLogsTableReferences),
      RefrigerationLogRow,
      PrefetchHooks Function({bool productId, bool fridgeId, bool alertsRefs})
    >;
typedef $$AlertsTableCreateCompanionBuilder = AlertsCompanion Function({
  required String id,
  required AlertSeverity severity,
  required AlertKind kind,
  Value<String?> productId,
  Value<String?> logId,
  required String message,
  required DateTime createdAt,
  Value<DateTime?> acknowledgedAt,
  Value<String> originDeviceId,
  Value<int> rowid,
});
typedef $$AlertsTableUpdateCompanionBuilder = AlertsCompanion Function({
  Value<String> id,
  Value<AlertSeverity> severity,
  Value<AlertKind> kind,
  Value<String?> productId,
  Value<String?> logId,
  Value<String> message,
  Value<DateTime> createdAt,
  Value<DateTime?> acknowledgedAt,
  Value<String> originDeviceId,
  Value<int> rowid,
});

final class $$AlertsTableReferences
    extends BaseReferences<_$AppDatabase, $AlertsTable, AlertRow> {
  $$AlertsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('alerts__product_id__products__id');

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<String>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RefrigerationLogsTable _logIdTable(_$AppDatabase db) => db
      .refrigerationLogs
      .createAlias('alerts__log_id__refrigeration_logs__id');

  $$RefrigerationLogsTableProcessedTableManager? get logId {
    final $_column = $_itemColumn<String>('log_id');
    if ($_column == null) return null;
    final manager = $$RefrigerationLogsTableTableManager(
      $_db,
      $_db.refrigerationLogs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_logIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AlertsTableFilterComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AlertSeverity, AlertSeverity, String>
  get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<AlertKind, AlertKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get acknowledgedAt => $composableBuilder(
    column: $table.acknowledgedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RefrigerationLogsTableFilterComposer get logId {
    final $$RefrigerationLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.logId,
      referencedTable: $db.refrigerationLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefrigerationLogsTableFilterComposer(
            $db: $db,
            $table: $db.refrigerationLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get acknowledgedAt => $composableBuilder(
    column: $table.acknowledgedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RefrigerationLogsTableOrderingComposer get logId {
    final $$RefrigerationLogsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.logId,
      referencedTable: $db.refrigerationLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RefrigerationLogsTableOrderingComposer(
            $db: $db,
            $table: $db.refrigerationLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AlertSeverity, String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AlertKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get acknowledgedAt => $composableBuilder(
    column: $table.acknowledgedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RefrigerationLogsTableAnnotationComposer get logId {
    final $$RefrigerationLogsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.logId,
          referencedTable: $db.refrigerationLogs,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RefrigerationLogsTableAnnotationComposer(
                $db: $db,
                $table: $db.refrigerationLogs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AlertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertsTable,
          AlertRow,
          $$AlertsTableFilterComposer,
          $$AlertsTableOrderingComposer,
          $$AlertsTableAnnotationComposer,
          $$AlertsTableCreateCompanionBuilder,
          $$AlertsTableUpdateCompanionBuilder,
          (AlertRow, $$AlertsTableReferences),
          AlertRow,
          PrefetchHooks Function({bool productId, bool logId})
        > {
  $$AlertsTableTableManager(_$AppDatabase db, $AlertsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<AlertSeverity> severity = const Value.absent(),
                Value<AlertKind> kind = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> logId = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> acknowledgedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsCompanion(
                id: id,
                severity: severity,
                kind: kind,
                productId: productId,
                logId: logId,
                message: message,
                createdAt: createdAt,
                acknowledgedAt: acknowledgedAt,
                originDeviceId: originDeviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required AlertSeverity severity,
                required AlertKind kind,
                Value<String?> productId = const Value.absent(),
                Value<String?> logId = const Value.absent(),
                required String message,
                required DateTime createdAt,
                Value<DateTime?> acknowledgedAt = const Value.absent(),
                Value<String> originDeviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsCompanion.insert(
                id: id,
                severity: severity,
                kind: kind,
                productId: productId,
                logId: logId,
                message: message,
                createdAt: createdAt,
                acknowledgedAt: acknowledgedAt,
                originDeviceId: originDeviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlertsTable, AlertRow>(table),
                  $$AlertsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false, logId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$AlertsTableReferences
                            ._productIdTable(db),
                        referencedColumn: $$AlertsTableReferences
                            ._productIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (logId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.logId,
                        referencedTable: $$AlertsTableReferences._logIdTable(
                          db,
                        ),
                        referencedColumn: $$AlertsTableReferences
                            ._logIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertsTable,
      AlertRow,
      $$AlertsTableFilterComposer,
      $$AlertsTableOrderingComposer,
      $$AlertsTableAnnotationComposer,
      $$AlertsTableCreateCompanionBuilder,
      $$AlertsTableUpdateCompanionBuilder,
      (AlertRow, $$AlertsTableReferences),
      AlertRow,
      PrefetchHooks Function({bool productId, bool logId})
    >;
typedef $$SyncOutboxTableCreateCompanionBuilder = SyncOutboxCompanion Function({
  required String id,
  required String entityType,
  required String entityId,
  required String operation,
  required String payloadJson,
  required SyncStatus status,
  Value<int> attemptCount,
  Value<String?> lastError,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$SyncOutboxTableUpdateCompanionBuilder = SyncOutboxCompanion Function({
  Value<String> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payloadJson,
  Value<SyncStatus> status,
  Value<int> attemptCount,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SyncOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxTable,
          SyncOutboxRow,
          $$SyncOutboxTableFilterComposer,
          $$SyncOutboxTableOrderingComposer,
          $$SyncOutboxTableAnnotationComposer,
          $$SyncOutboxTableCreateCompanionBuilder,
          $$SyncOutboxTableUpdateCompanionBuilder,
          (
            SyncOutboxRow,
            BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxRow>,
          ),
          SyncOutboxRow,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableManager(_$AppDatabase db, $SyncOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<SyncStatus> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String operation,
                required String payloadJson,
                required SyncStatus status,
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncOutboxTable, SyncOutboxRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncOutboxTable,
                    SyncOutboxRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxTable,
      SyncOutboxRow,
      $$SyncOutboxTableFilterComposer,
      $$SyncOutboxTableOrderingComposer,
      $$SyncOutboxTableAnnotationComposer,
      $$SyncOutboxTableCreateCompanionBuilder,
      $$SyncOutboxTableUpdateCompanionBuilder,
      (
        SyncOutboxRow,
        BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxRow>,
      ),
      SyncOutboxRow,
      PrefetchHooks Function()
    >;
typedef $$LocalSettingsTableCreateCompanionBuilder =
    LocalSettingsCompanion Function({
      required String id,
      required String deviceId,
      required String deviceName,
      required String environmentName,
      Value<String> serverUrl,
      Value<String> serverToken,
      Value<String> ownerEmail,
      Value<bool> dailyReportEnabled,
      Value<int> reportHour,
      Value<int> reportMinute,
      Value<int> syncCursor,
      Value<DateTime?> lastSyncAt,
      Value<String?> lastSyncError,
      Value<bool> confirmAction,
      Value<int> workerIdleSeconds,
      Value<String> workerRefreshMode,
      Value<String> workerPromptStyle,
      Value<int> workerRefreshStartMinute,
      Value<int> workerRefreshIntervalHours,
      Value<int> workerRefreshEndMinute,
      Value<String> settingsPassword,
      Value<String?> currentWorkerId,
      Value<DateTime?> workerActiveAt,
      Value<int> rowid,
    });
typedef $$LocalSettingsTableUpdateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<String> id,
      Value<String> deviceId,
      Value<String> deviceName,
      Value<String> environmentName,
      Value<String> serverUrl,
      Value<String> serverToken,
      Value<String> ownerEmail,
      Value<bool> dailyReportEnabled,
      Value<int> reportHour,
      Value<int> reportMinute,
      Value<int> syncCursor,
      Value<DateTime?> lastSyncAt,
      Value<String?> lastSyncError,
      Value<bool> confirmAction,
      Value<int> workerIdleSeconds,
      Value<String> workerRefreshMode,
      Value<String> workerPromptStyle,
      Value<int> workerRefreshStartMinute,
      Value<int> workerRefreshIntervalHours,
      Value<int> workerRefreshEndMinute,
      Value<String> settingsPassword,
      Value<String?> currentWorkerId,
      Value<DateTime?> workerActiveAt,
      Value<int> rowid,
    });

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentName => $composableBuilder(
    column: $table.environmentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverToken => $composableBuilder(
    column: $table.serverToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerEmail => $composableBuilder(
    column: $table.ownerEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dailyReportEnabled => $composableBuilder(
    column: $table.dailyReportEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reportHour => $composableBuilder(
    column: $table.reportHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reportMinute => $composableBuilder(
    column: $table.reportMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncCursor => $composableBuilder(
    column: $table.syncCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get confirmAction => $composableBuilder(
    column: $table.confirmAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workerIdleSeconds => $composableBuilder(
    column: $table.workerIdleSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerRefreshMode => $composableBuilder(
    column: $table.workerRefreshMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerPromptStyle => $composableBuilder(
    column: $table.workerPromptStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workerRefreshStartMinute => $composableBuilder(
    column: $table.workerRefreshStartMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workerRefreshIntervalHours => $composableBuilder(
    column: $table.workerRefreshIntervalHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workerRefreshEndMinute => $composableBuilder(
    column: $table.workerRefreshEndMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingsPassword => $composableBuilder(
    column: $table.settingsPassword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentWorkerId => $composableBuilder(
    column: $table.currentWorkerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get workerActiveAt => $composableBuilder(
    column: $table.workerActiveAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentName => $composableBuilder(
    column: $table.environmentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverToken => $composableBuilder(
    column: $table.serverToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerEmail => $composableBuilder(
    column: $table.ownerEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dailyReportEnabled => $composableBuilder(
    column: $table.dailyReportEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reportHour => $composableBuilder(
    column: $table.reportHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reportMinute => $composableBuilder(
    column: $table.reportMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncCursor => $composableBuilder(
    column: $table.syncCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get confirmAction => $composableBuilder(
    column: $table.confirmAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workerIdleSeconds => $composableBuilder(
    column: $table.workerIdleSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerRefreshMode => $composableBuilder(
    column: $table.workerRefreshMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerPromptStyle => $composableBuilder(
    column: $table.workerPromptStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workerRefreshStartMinute => $composableBuilder(
    column: $table.workerRefreshStartMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workerRefreshIntervalHours => $composableBuilder(
    column: $table.workerRefreshIntervalHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workerRefreshEndMinute => $composableBuilder(
    column: $table.workerRefreshEndMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingsPassword => $composableBuilder(
    column: $table.settingsPassword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentWorkerId => $composableBuilder(
    column: $table.currentWorkerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get workerActiveAt => $composableBuilder(
    column: $table.workerActiveAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get environmentName => $composableBuilder(
    column: $table.environmentName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverUrl =>
      $composableBuilder(column: $table.serverUrl, builder: (column) => column);

  GeneratedColumn<String> get serverToken => $composableBuilder(
    column: $table.serverToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerEmail => $composableBuilder(
    column: $table.ownerEmail,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dailyReportEnabled => $composableBuilder(
    column: $table.dailyReportEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reportHour => $composableBuilder(
    column: $table.reportHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reportMinute => $composableBuilder(
    column: $table.reportMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncCursor => $composableBuilder(
    column: $table.syncCursor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get confirmAction => $composableBuilder(
    column: $table.confirmAction,
    builder: (column) => column,
  );

  GeneratedColumn<int> get workerIdleSeconds => $composableBuilder(
    column: $table.workerIdleSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workerRefreshMode => $composableBuilder(
    column: $table.workerRefreshMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workerPromptStyle => $composableBuilder(
    column: $table.workerPromptStyle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get workerRefreshStartMinute => $composableBuilder(
    column: $table.workerRefreshStartMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get workerRefreshIntervalHours => $composableBuilder(
    column: $table.workerRefreshIntervalHours,
    builder: (column) => column,
  );

  GeneratedColumn<int> get workerRefreshEndMinute => $composableBuilder(
    column: $table.workerRefreshEndMinute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settingsPassword => $composableBuilder(
    column: $table.settingsPassword,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentWorkerId => $composableBuilder(
    column: $table.currentWorkerId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get workerActiveAt => $composableBuilder(
    column: $table.workerActiveAt,
    builder: (column) => column,
  );
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSettingsRow,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (
            LocalSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $LocalSettingsTable,
              LocalSettingsRow
            >,
          ),
          LocalSettingsRow,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String> environmentName = const Value.absent(),
                Value<String> serverUrl = const Value.absent(),
                Value<String> serverToken = const Value.absent(),
                Value<String> ownerEmail = const Value.absent(),
                Value<bool> dailyReportEnabled = const Value.absent(),
                Value<int> reportHour = const Value.absent(),
                Value<int> reportMinute = const Value.absent(),
                Value<int> syncCursor = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<bool> confirmAction = const Value.absent(),
                Value<int> workerIdleSeconds = const Value.absent(),
                Value<String> workerRefreshMode = const Value.absent(),
                Value<String> workerPromptStyle = const Value.absent(),
                Value<int> workerRefreshStartMinute = const Value.absent(),
                Value<int> workerRefreshIntervalHours = const Value.absent(),
                Value<int> workerRefreshEndMinute = const Value.absent(),
                Value<String> settingsPassword = const Value.absent(),
                Value<String?> currentWorkerId = const Value.absent(),
                Value<DateTime?> workerActiveAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion(
                id: id,
                deviceId: deviceId,
                deviceName: deviceName,
                environmentName: environmentName,
                serverUrl: serverUrl,
                serverToken: serverToken,
                ownerEmail: ownerEmail,
                dailyReportEnabled: dailyReportEnabled,
                reportHour: reportHour,
                reportMinute: reportMinute,
                syncCursor: syncCursor,
                lastSyncAt: lastSyncAt,
                lastSyncError: lastSyncError,
                confirmAction: confirmAction,
                workerIdleSeconds: workerIdleSeconds,
                workerRefreshMode: workerRefreshMode,
                workerPromptStyle: workerPromptStyle,
                workerRefreshStartMinute: workerRefreshStartMinute,
                workerRefreshIntervalHours: workerRefreshIntervalHours,
                workerRefreshEndMinute: workerRefreshEndMinute,
                settingsPassword: settingsPassword,
                currentWorkerId: currentWorkerId,
                workerActiveAt: workerActiveAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deviceId,
                required String deviceName,
                required String environmentName,
                Value<String> serverUrl = const Value.absent(),
                Value<String> serverToken = const Value.absent(),
                Value<String> ownerEmail = const Value.absent(),
                Value<bool> dailyReportEnabled = const Value.absent(),
                Value<int> reportHour = const Value.absent(),
                Value<int> reportMinute = const Value.absent(),
                Value<int> syncCursor = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<bool> confirmAction = const Value.absent(),
                Value<int> workerIdleSeconds = const Value.absent(),
                Value<String> workerRefreshMode = const Value.absent(),
                Value<String> workerPromptStyle = const Value.absent(),
                Value<int> workerRefreshStartMinute = const Value.absent(),
                Value<int> workerRefreshIntervalHours = const Value.absent(),
                Value<int> workerRefreshEndMinute = const Value.absent(),
                Value<String> settingsPassword = const Value.absent(),
                Value<String?> currentWorkerId = const Value.absent(),
                Value<DateTime?> workerActiveAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion.insert(
                id: id,
                deviceId: deviceId,
                deviceName: deviceName,
                environmentName: environmentName,
                serverUrl: serverUrl,
                serverToken: serverToken,
                ownerEmail: ownerEmail,
                dailyReportEnabled: dailyReportEnabled,
                reportHour: reportHour,
                reportMinute: reportMinute,
                syncCursor: syncCursor,
                lastSyncAt: lastSyncAt,
                lastSyncError: lastSyncError,
                confirmAction: confirmAction,
                workerIdleSeconds: workerIdleSeconds,
                workerRefreshMode: workerRefreshMode,
                workerPromptStyle: workerPromptStyle,
                workerRefreshStartMinute: workerRefreshStartMinute,
                workerRefreshIntervalHours: workerRefreshIntervalHours,
                workerRefreshEndMinute: workerRefreshEndMinute,
                settingsPassword: settingsPassword,
                currentWorkerId: currentWorkerId,
                workerActiveAt: workerActiveAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSettingsTable, LocalSettingsRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSettingsTable,
                    LocalSettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSettingsRow,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (
        LocalSettingsRow,
        BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSettingsRow>,
      ),
      LocalSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$DailyReportsTableCreateCompanionBuilder =
    DailyReportsCompanion Function({
      required String id,
      required String environmentName,
      required String reportDate,
      required String ownerEmail,
      required String subject,
      required String body,
      required String status,
      required DateTime createdAt,
      Value<DateTime?> sentAt,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$DailyReportsTableUpdateCompanionBuilder =
    DailyReportsCompanion Function({
      Value<String> id,
      Value<String> environmentName,
      Value<String> reportDate,
      Value<String> ownerEmail,
      Value<String> subject,
      Value<String> body,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> sentAt,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$DailyReportsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyReportsTable> {
  $$DailyReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentName => $composableBuilder(
    column: $table.environmentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportDate => $composableBuilder(
    column: $table.reportDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerEmail => $composableBuilder(
    column: $table.ownerEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyReportsTable> {
  $$DailyReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentName => $composableBuilder(
    column: $table.environmentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportDate => $composableBuilder(
    column: $table.reportDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerEmail => $composableBuilder(
    column: $table.ownerEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyReportsTable> {
  $$DailyReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get environmentName => $composableBuilder(
    column: $table.environmentName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reportDate => $composableBuilder(
    column: $table.reportDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerEmail => $composableBuilder(
    column: $table.ownerEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$DailyReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyReportsTable,
          DailyReportRow,
          $$DailyReportsTableFilterComposer,
          $$DailyReportsTableOrderingComposer,
          $$DailyReportsTableAnnotationComposer,
          $$DailyReportsTableCreateCompanionBuilder,
          $$DailyReportsTableUpdateCompanionBuilder,
          (
            DailyReportRow,
            BaseReferences<_$AppDatabase, $DailyReportsTable, DailyReportRow>,
          ),
          DailyReportRow,
          PrefetchHooks Function()
        > {
  $$DailyReportsTableTableManager(_$AppDatabase db, $DailyReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> environmentName = const Value.absent(),
                Value<String> reportDate = const Value.absent(),
                Value<String> ownerEmail = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyReportsCompanion(
                id: id,
                environmentName: environmentName,
                reportDate: reportDate,
                ownerEmail: ownerEmail,
                subject: subject,
                body: body,
                status: status,
                createdAt: createdAt,
                sentAt: sentAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String environmentName,
                required String reportDate,
                required String ownerEmail,
                required String subject,
                required String body,
                required String status,
                required DateTime createdAt,
                Value<DateTime?> sentAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyReportsCompanion.insert(
                id: id,
                environmentName: environmentName,
                reportDate: reportDate,
                ownerEmail: ownerEmail,
                subject: subject,
                body: body,
                status: status,
                createdAt: createdAt,
                sentAt: sentAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyReportsTable, DailyReportRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DailyReportsTable,
                    DailyReportRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyReportsTable,
      DailyReportRow,
      $$DailyReportsTableFilterComposer,
      $$DailyReportsTableOrderingComposer,
      $$DailyReportsTableAnnotationComposer,
      $$DailyReportsTableCreateCompanionBuilder,
      $$DailyReportsTableUpdateCompanionBuilder,
      (
        DailyReportRow,
        BaseReferences<_$AppDatabase, $DailyReportsTable, DailyReportRow>,
      ),
      DailyReportRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$FridgesTableTableManager get fridges =>
      $$FridgesTableTableManager(_db, _db.fridges);
  $$WorkersTableTableManager get workers =>
      $$WorkersTableTableManager(_db, _db.workers);
  $$RefrigerationLogsTableTableManager get refrigerationLogs =>
      $$RefrigerationLogsTableTableManager(_db, _db.refrigerationLogs);
  $$AlertsTableTableManager get alerts =>
      $$AlertsTableTableManager(_db, _db.alerts);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
  $$DailyReportsTableTableManager get dailyReports =>
      $$DailyReportsTableTableManager(_db, _db.dailyReports);
}
