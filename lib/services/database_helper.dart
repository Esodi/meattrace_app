import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../models/animal.dart';
import '../models/shop_receipt.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'meattrace.db');
    return await openDatabase(
      path,
      version: 4, // Increment version to trigger migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE product_categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        processing_unit INTEGER NOT NULL,
        animal INTEGER NOT NULL,
        product_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        created_at TEXT NOT NULL,
        name TEXT NOT NULL,
        batch_number TEXT NOT NULL,
        weight REAL NOT NULL,
        weight_unit TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT NOT NULL,
        manufacturer TEXT NOT NULL,
        category TEXT,
        timeline TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE animals (
        id INTEGER PRIMARY KEY,
        farmer INTEGER NOT NULL,
        species TEXT NOT NULL,
        animal_id TEXT,
        animal_name TEXT,
        age INTEGER NOT NULL,
        weight REAL NOT NULL,
        breed TEXT,
        farm_name TEXT,
        health_status TEXT,
        created_at TEXT NOT NULL,
        slaughtered INTEGER NOT NULL,
        slaughtered_at TEXT,
        synced INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE shop_receipts (
        id INTEGER PRIMARY KEY,
        shop INTEGER NOT NULL,
        product INTEGER NOT NULL,
        received_quantity REAL NOT NULL,
        received_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Add missing columns to animals table
      final columnsToAdd = [
        'animal_name TEXT',
        'breed TEXT',
        'farm_name TEXT',
        'health_status TEXT',
        'synced INTEGER NOT NULL DEFAULT 1',
      ];

      for (final columnDef in columnsToAdd) {
        try {
          await db.execute('ALTER TABLE animals ADD COLUMN $columnDef');
        } catch (e) {
          // Column might already exist, ignore error
        }
      }
    }
    if (oldVersion < 4) {
      // Make category column nullable by recreating the table
      try {
        // Create new table without NOT NULL on category
        await db.execute('''
          CREATE TABLE products_new (
            id INTEGER PRIMARY KEY,
            processing_unit INTEGER NOT NULL,
            animal INTEGER NOT NULL,
            product_type TEXT NOT NULL,
            quantity REAL NOT NULL,
            created_at TEXT NOT NULL,
            name TEXT NOT NULL,
            batch_number TEXT NOT NULL,
            weight REAL NOT NULL,
            weight_unit TEXT NOT NULL,
            price REAL NOT NULL,
            description TEXT NOT NULL,
            manufacturer TEXT NOT NULL,
            category TEXT,
            timeline TEXT
          )
        ''');

        // Copy data
        await db.execute('''
          INSERT INTO products_new (id, processing_unit, animal, product_type, quantity, created_at, name, batch_number, weight, weight_unit, price, description, manufacturer, category, timeline)
          SELECT id, processing_unit, animal, product_type, quantity, created_at, name, batch_number, weight, weight_unit, price, description, manufacturer, category, timeline FROM products
        ''');

        // Drop old table and rename
        await db.execute('DROP TABLE products');
        await db.execute('ALTER TABLE products_new RENAME TO products');
      } catch (e) {
        // If migration fails, ignore for now
      }
    }
  }

  // ProductCategory operations
  Future<void> insertCategories(List<ProductCategory> categories) async {
    final db = await database;
    final batch = db.batch();
    for (final category in categories) {
      batch.insert('product_categories', {
        'id': category.id,
        'name': category.name,
        'description': category.description,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<ProductCategory>> getCategories() async {
    final db = await database;
    final maps = await db.query('product_categories');
    return maps.map((map) => ProductCategory.fromJson(map)).toList();
  }

  // Product operations
  Future<void> insertProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();
    for (final product in products) {
      batch.insert('products', {
        'id': product.id,
        'processing_unit': product.processingUnit,
        'animal': product.animal,
        'product_type': product.productType,
        'quantity': product.quantity,
        'created_at': product.createdAt.toIso8601String(),
        'name': product.name,
        'batch_number': product.batchNumber,
        'weight': product.weight,
        'weight_unit': product.weightUnit,
        'price': product.price,
        'description': product.description,
        'manufacturer': product.manufacturer,
        'category': product.category?.toString(),
        'timeline': product.timeline.map((e) => e.toMap()).toList().toString(), // Simple string
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  // Animal operations
  Future<void> insertAnimals(List<Animal> animals, {bool synced = true}) async {
    final db = await database;
    final batch = db.batch();
    for (final animal in animals) {
      batch.insert('animals', {
        'id': animal.id,
        'farmer': animal.farmer,
        'species': animal.species,
        'animal_id': animal.animalId,
        'animal_name': animal.animalName,
        'age': animal.age,
        'weight': animal.weight,
        'breed': animal.breed,
        'farm_name': animal.farmName,
        'health_status': animal.healthStatus,
        'created_at': animal.createdAt.toIso8601String(),
        'slaughtered': animal.slaughtered ? 1 : 0,
        'slaughtered_at': animal.slaughteredAt?.toIso8601String(),
        'synced': synced ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<Animal>> getAnimals() async {
    final db = await database;
    final maps = await db.query('animals');
    return maps.map((map) => Animal.fromMap(map)).toList();
  }

  Future<List<Animal>> getSlaughteredAnimals() async {
    final db = await database;
    final maps = await db.query(
      'animals',
      where: 'slaughtered = ?',
      whereArgs: [1],
    );
    return maps.map((map) => Animal.fromMap(map)).toList();
  }

  Future<List<Animal>> getUnsyncedAnimals() async {
    final db = await database;
    final maps = await db.query(
      'animals',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return maps.map((map) => Animal.fromMap(map)).toList();
  }

  Future<void> markAnimalAsSynced(int id) async {
    final db = await database;
    await db.update(
      'animals',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ShopReceipt operations
  Future<void> insertShopReceipts(List<ShopReceipt> receipts) async {
    final db = await database;
    final batch = db.batch();
    for (final receipt in receipts) {
      batch.insert('shop_receipts', {
        'id': receipt.id,
        'shop': receipt.shop,
        'product': receipt.product,
        'received_quantity': receipt.receivedQuantity,
        'received_at': receipt.receivedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<ShopReceipt>> getShopReceipts() async {
    final db = await database;
    final maps = await db.query('shop_receipts');
    return maps.map((map) => ShopReceipt.fromJson(map)).toList();
  }
}
