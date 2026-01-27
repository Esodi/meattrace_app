import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../models/animal.dart';
import '../models/shop_receipt.dart';
import '../models/inventory.dart';
import '../models/order.dart';
import '../models/external_vendor.dart';

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
      version: 16, // Increment version for external vendor support
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // onOpen ensures missing compatibility columns are added for existing installs
      onOpen: (db) async {
        try {
          await _ensureColumnExists(db, 'animals', 'weight', 'REAL');
        } catch (e) {
          // ignore - best effort
        }
      },
    );
  }

  // Debug method to check table schema
  Future<void> debugTableSchema(String tableName) async {
    final db = await database;
    final result = await db.rawQuery("PRAGMA table_info($tableName)");
    print("🔍 [DatabaseHelper] Schema for table '$tableName':");
    for (final column in result) {
      print(
        "   Column: ${column['name']} - Type: ${column['type']} - NotNull: ${column['notnull']} - Default: ${column['dflt_value']}",
      );
    }
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
        live_weight REAL,
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
        abbatoir INTEGER NOT NULL,
        species TEXT NOT NULL,
        animal_id TEXT,
        animal_name TEXT,
        age INTEGER NOT NULL,
        live_weight REAL,
        weight REAL,
        breed TEXT,
        abbatoir_name TEXT,
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

    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY,
        shop INTEGER NOT NULL,
        product INTEGER NOT NULL,
        quantity REAL NOT NULL,
        min_stock_level REAL NOT NULL,
        last_updated TEXT NOT NULL,
        shop_username TEXT,
        is_low_stock INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY,
        customer INTEGER NOT NULL,
        shop INTEGER NOT NULL,
        status TEXT NOT NULL,
        total_amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        delivery_address TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE slaughter_parts (
        id INTEGER PRIMARY KEY,
        part_id TEXT UNIQUE,
        animal INTEGER NOT NULL,
        part_type TEXT NOT NULL,
        weight REAL NOT NULL,
        weight_unit TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        transferred_to INTEGER,
        transferred_to_name TEXT,
        transferred_at TEXT,
        received_by INTEGER,
        received_at TEXT,
        received_by_username TEXT,
        used_in_product INTEGER NOT NULL DEFAULT 0,
        is_selected_for_transfer INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Add missing columns to animals table
      final columnsToAdd = [
        'animal_name TEXT',
        'breed TEXT',
        'abbatoir_name TEXT',
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
    if (oldVersion < 9) {
      // Add abbatoir_name column if missing (fix for schema mismatch)
      try {
        await db.execute('ALTER TABLE animals ADD COLUMN abbatoir_name TEXT');
      } catch (e) {
        // Column might already exist, ignore error
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
            live_weight REAL,
            weight REAL, // Keep old column for backward compatibility
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
          INSERT INTO products_new (id, processing_unit, animal, product_type, quantity, created_at, name, batch_number, live_weight, weight_unit, price, description, manufacturer, category, timeline)
          SELECT id, processing_unit, animal, product_type, quantity, created_at, name, batch_number, weight, weight_unit, price, description, manufacturer, category, timeline FROM products
        ''');

        // Drop old table and rename
        await db.execute('DROP TABLE products');
        await db.execute('ALTER TABLE products_new RENAME TO products');
      } catch (e) {
        // If migration fails, ignore for now
      }

      // Create inventory table if it doesn't exist
      try {
        await db.execute('''
          CREATE TABLE inventory (
            id INTEGER PRIMARY KEY,
            shop INTEGER NOT NULL,
            product INTEGER NOT NULL,
            quantity REAL NOT NULL,
            min_stock_level REAL NOT NULL,
            last_updated TEXT NOT NULL,
            shop_username TEXT,
            is_low_stock INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY,
            customer INTEGER NOT NULL,
            shop INTEGER NOT NULL,
            status TEXT NOT NULL,
            total_amount REAL NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            delivery_address TEXT,
            notes TEXT
          )
        ''');
      } catch (e) {
        // Table might already exist, ignore error
      }

      // Create shop_receipts table if it doesn't exist
      try {
        await db.execute('''
          CREATE TABLE shop_receipts (
            id INTEGER PRIMARY KEY,
            shop INTEGER NOT NULL,
            product INTEGER NOT NULL,
            received_quantity REAL NOT NULL,
            received_at TEXT NOT NULL
          )
        ''');
      } catch (e) {
        // Table might already exist, ignore error
      }
    }
    if (oldVersion < 7) {
      // Ensure inventory table exists
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS inventory (
            id INTEGER PRIMARY KEY,
            shop INTEGER NOT NULL,
            product INTEGER NOT NULL,
            quantity REAL NOT NULL,
            min_stock_level REAL NOT NULL,
            last_updated TEXT NOT NULL,
            shop_username TEXT,
            is_low_stock INTEGER NOT NULL
          )
        ''');
      } catch (e) {
        // Table might already exist, ignore error
      }

      // Create orders table if it doesn't exist
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY,
            customer INTEGER NOT NULL,
            shop INTEGER NOT NULL,
            status TEXT NOT NULL,
            total_amount REAL NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            delivery_address TEXT,
            notes TEXT
          )
        ''');
      } catch (e) {
        // Table might already exist, ignore error
      }
    }
    if (oldVersion < 8) {
      // Add live_weight column to animals table
      try {
        await db.execute('ALTER TABLE animals ADD COLUMN live_weight REAL');
      } catch (e) {
        // Column might already exist, ignore error
      }
    }
    if (oldVersion < 10) {
      // Fix weight column name inconsistency - rename 'weight' to 'live_weight' in products table
      try {
        // Check if 'weight' column exists in products table and rename it
        final result = await db.rawQuery("PRAGMA table_info(products)");
        final hasWeightColumn = result.any(
          (column) => column['name'] == 'weight',
        );

        if (hasWeightColumn) {
          // SQLite doesn't support direct column rename, so we need to recreate the table
          await db.execute('ALTER TABLE products ADD COLUMN live_weight REAL');
          await db.execute(
            'UPDATE products SET live_weight = weight WHERE weight IS NOT NULL',
          );
          // Note: We can't drop the old column in SQLite without recreating the table
          // The old 'weight' column will remain but won't be used
        }
      } catch (e) {
        // Migration might fail, ignore for now
      }
    }
    if (oldVersion < 11) {
      // Add weight column to animals table for backward compatibility
      try {
        await db.execute('ALTER TABLE animals ADD COLUMN weight REAL');
      } catch (e) {
        // Column might already exist, ignore error
      }
    }
    if (oldVersion < 12) {
      // Ensure weight column exists in animals table (fix for schema mismatch)
      try {
        await db.execute('ALTER TABLE animals ADD COLUMN weight REAL');
      } catch (e) {
        // Column might already exist, ignore error
      }
    }
    if (oldVersion < 13) {
      // Create SlaughterPart table for new installations
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS slaughter_parts (
            id INTEGER PRIMARY KEY,
            part_id TEXT UNIQUE,
            animal INTEGER NOT NULL,
            part_type TEXT NOT NULL,
            weight REAL NOT NULL,
            weight_unit TEXT NOT NULL,
            description TEXT,
            created_at TEXT NOT NULL,
            transferred_to INTEGER,
            transferred_to_name TEXT,
            transferred_at TEXT,
            received_by INTEGER,
            received_at TEXT,
            received_by_username TEXT,
            used_in_product INTEGER NOT NULL DEFAULT 0,
            is_selected_for_transfer INTEGER NOT NULL DEFAULT 0
          )
        ''');
      } catch (e) {
        // Table might already exist, ignore error
      }
    }
    if (oldVersion < 14) {
      // Add abbatoir column to animals table if missing (fix for schema mismatch after rename)
      try {
        await db.execute(
          'ALTER TABLE animals ADD COLUMN abbatoir INTEGER DEFAULT 0',
        );
      } catch (e) {
        // Column might already exist, ignore error
      }
    }
    if (oldVersion < 15) {
      // Fix for "NOT NULL constraint failed: animals.farmer"
      // The local DB has a legacy 'farmer' column that is NOT NULL.
      // Since we can't easily DROP COLUMN in SQLite, we'll recreate the table.
      // This is safe because animals is a cache and will be refetched.
      try {
        await db.execute('DROP TABLE IF EXISTS animals');
        await db.execute('''
          CREATE TABLE animals (
            id INTEGER PRIMARY KEY,
            abbatoir INTEGER NOT NULL,
            species TEXT NOT NULL,
            animal_id TEXT,
            animal_name TEXT,
            age INTEGER NOT NULL,
            live_weight REAL,
            weight REAL,
            breed TEXT,
            abbatoir_name TEXT,
            health_status TEXT,
            created_at TEXT NOT NULL,
            slaughtered INTEGER NOT NULL,
            slaughtered_at TEXT,
            synced INTEGER NOT NULL DEFAULT 1
          )
        ''');
      } catch (e) {
        print('Error reconstructing animals table: $e');
      }
    }
    if (oldVersion < 16) {
      // Create external_vendors table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS external_vendors (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            contact_info TEXT,
            location TEXT,
            category TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      } catch (e) {
        print('Error creating external_vendors table: $e');
      }

      // Add external source tracking columns to animals table
      final animalColumns = [
        'is_external_source INTEGER NOT NULL DEFAULT 0',
        'external_vendor_id INTEGER',
        'external_vendor_name TEXT',
        'acquisition_price REAL',
        'acquisition_date TEXT',
        'origin_type TEXT DEFAULT "BORN_HERE"',
      ];

      for (final columnDef in animalColumns) {
        try {
          await db.execute('ALTER TABLE animals ADD COLUMN $columnDef');
        } catch (e) {
          // Column might already exist
        }
      }

      // Add external source tracking columns to products table
      final productColumns = [
        'is_external_source INTEGER NOT NULL DEFAULT 0',
        'external_vendor_id INTEGER',
        'external_vendor_name TEXT',
        'acquisition_price REAL',
      ];

      for (final columnDef in productColumns) {
        try {
          await db.execute('ALTER TABLE products ADD COLUMN $columnDef');
        } catch (e) {
          // Column might already exist
        }
      }
    }
  }

  // Ensure a column exists on a table; add it if missing (best-effort compatibility)
  Future<void> _ensureColumnExists(
    Database db,
    String table,
    String columnName,
    String columnType,
  ) async {
    try {
      final info = await db.rawQuery("PRAGMA table_info($table)");
      final hasColumn = info.any((column) => column['name'] == columnName);
      if (!hasColumn) {
        await db.execute(
          'ALTER TABLE $table ADD COLUMN $columnName $columnType',
        );
      }
    } catch (e) {
      // Ignore - best effort to fix schema mismatches
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
        'live_weight': product.weight, // Use live_weight instead of weight
        'weight_unit': product.weightUnit,
        'price': product.price,
        'description': product.description,
        'manufacturer': product.manufacturer,
        'category': product.category?.toString(),
        'timeline': product.timeline
            .map((e) => e.toMap())
            .toList()
            .toString(), // Simple string
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

    // Check whether the legacy 'weight' column exists before inserting to avoid errors
    final tableInfo = await db.rawQuery("PRAGMA table_info(animals)");
    final hasWeightColumn = tableInfo.any((c) => c['name'] == 'weight');

    for (final animal in animals) {
      final map = {
        'id': animal.id,
        'abbatoir': animal.abbatoir,
        'species': animal.species,
        'animal_id': animal.animalId,
        'animal_name': animal.animalName,
        'age': animal.age,
        'live_weight': animal.liveWeight,
        'breed': animal.breed,
        'abbatoir_name': animal.abbatoirName,
        'health_status': animal.healthStatus,
        'created_at': animal.createdAt.toIso8601String(),
        'slaughtered': animal.slaughtered ? 1 : 0,
        'slaughtered_at': animal.slaughteredAt?.toIso8601String(),
        'synced': synced ? 1 : 0,
      };

      if (hasWeightColumn) {
        map['weight'] =
            animal.liveWeight; // populate legacy column only if present
      }

      batch.insert(
        'animals',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  Future<List<Animal>> getAnimals() async {
    final db = await database;
    final maps = await db.query('animals');
    return maps.map((map) => Animal.fromMap(map)).toList();
  }

  Future<void> clearAnimals() async {
    final db = await database;
    await db.delete('animals');
  }

  Future<void> clearProducts() async {
    final db = await database;
    await db.delete('products');
  }

  Future<void> clearInventory() async {
    final db = await database;
    await db.delete('inventory');
  }

  Future<void> clearCategories() async {
    final db = await database;
    await db.delete('product_categories');
  }

  /// Clear all user data from database (animals, products, inventory, etc.)
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('animals');
      await txn.delete('products');
      await txn.delete('inventory');
      await txn.delete('shop_receipts');
      await txn.delete('orders');
      // Keep product_categories as they are system-wide
    });
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
    final maps = await db.query('animals', where: 'synced = ?', whereArgs: [0]);
    return maps.map((map) => Animal.fromMap(map)).toList();
  }

  Future<void> markAnimalAsSynced(int id) async {
    final db = await database;
    await db.update('animals', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
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

  // Inventory operations
  Future<void> insertInventory(List<Inventory> inventory) async {
    final db = await database;
    final batch = db.batch();
    for (final item in inventory) {
      batch.insert('inventory', {
        'id': item.id,
        'shop': item.shop,
        'product': item.product,
        'quantity': item.quantity,
        'min_stock_level': item.minStockLevel,
        'last_updated': item.lastUpdated.toIso8601String(),
        'shop_username': item.shopUsername,
        'is_low_stock': item.isLowStock ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<Inventory>> getInventory() async {
    final db = await database;
    final maps = await db.query('inventory');
    return maps.map((map) => Inventory.fromMap(map)).toList();
  }

  // Order operations
  Future<void> insertOrders(List<Order> orders) async {
    final db = await database;
    final batch = db.batch();
    for (final order in orders) {
      batch.insert('orders', {
        'id': order.id,
        'customer': order.customer,
        'shop': order.shop,
        'status': order.status,
        'total_amount': order.totalAmount,
        'created_at': order.createdAt.toIso8601String(),
        'updated_at': order.updatedAt.toIso8601String(),
        'delivery_address': order.deliveryAddress,
        'notes': order.notes,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<Order>> getOrders() async {
    final db = await database;
    final maps = await db.query('orders', orderBy: 'created_at DESC');
    return maps.map((map) => Order.fromJson(map)).toList();
  }

  // External Vendor operations
  Future<int> insertExternalVendor(ExternalVendor vendor) async {
    final db = await database;
    return await db.insert(
      'external_vendors',
      vendor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExternalVendor>> getExternalVendors() async {
    final db = await database;
    final maps = await db.query('external_vendors', orderBy: 'name ASC');
    return maps.map((map) => ExternalVendor.fromMap(map)).toList();
  }
}
