import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostgresService {
  final String host;
  final String databaseName;
  final String username;
  final String password;
  final int port;

  static Pool? _pool;
  static String? _activeConfigSignature;

  PostgresService({
    required this.host,
    required this.databaseName,
    required this.username,
    required this.password,
    this.port = 5432,
  });

  static String determinePassword(String storeCode) {
    final cleanCode = storeCode.trim();
    final upperCode = cleanCode.toUpperCase();
    
    if(upperCode.startsWith('Z')) {
      return 'ganola@$cleanCode';
    } else if (upperCode.startsWith('D')) {
      return 'beureum@$cleanCode';
    } else {
      return 'unknown@$cleanCode';
    }
  }

  static Future<PostgresService> createFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final serverIp = prefs.getString('server_ip') ?? '192.168.1.100';
    final dbName = prefs.getString('db_name') ?? 'inventory_db';
    final storeCode = prefs.getString('store_code') ?? '';
    final dbPassword = determinePassword(storeCode);

    return PostgresService(
      host: serverIp,
      databaseName: dbName,
      username: 'postgres',
      password: dbPassword,
    );
  }

  static Future<void> resetPool() async {
    if (_pool != null) {
      await _pool!.close(); // Tutup koneksi lama
      _pool = null;
      _activeConfigSignature = null;
    }
  }

  Future<void> _ensurePoolInitialized() async {
    final currentSignature = '$username:$password@$host:$port/$databaseName';

    if (_pool != null && _activeConfigSignature == currentSignature) {
      return;
    }

    await resetPool();

    _pool = Pool.withEndpoints(
      [ 
        Endpoint(
          host: host,
          database: databaseName,
          username: username,
          password: password,
          port: port,
        ),
      ],
      settings: PoolSettings(
        maxConnectionCount: 5,
        sslMode: SslMode.disable,
        queryTimeout: const Duration(seconds: 5),
      ),
    );
    
    _activeConfigSignature = currentSignature;
  }

  Future<bool> testConnection() async {
    Connection? conn;
    try {
      conn = await Connection.open(
        Endpoint(
          host: host,
          database: databaseName,
          username: username,
          password: password,
          port: port,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
          queryTimeout: const Duration(seconds: 3),
        ),
      );
      await conn.execute('SELECT 1');
      return true;
    } catch (e) {
      rethrow;
    } finally {
      await conn?.close();
    }
  }

  Future<Map<String, dynamic>?> searchProduct(String keyword) async {
    try {
      await _ensurePoolInitialized();

      final result = await _pool!.withConnection((connection) async {
        return await connection.execute(
          Sql.named(
            'SELECT "Description" as name, "SKU" as sku, "EndQty" as quantity '
            'FROM "trStock" '
            'WHERE "Description" ILIKE @keyword OR "SKU" ILIKE @keyword '
            'ORDER BY "LastUpdate" DESC LIMIT 1'
          ),
          parameters: {'keyword': '%$keyword%'},
        );
      });

      if (result.isEmpty) return null;

      final row = result.first;
      return {
        'name': row[0],
        'sku': row[1],
        'quantity': row[2],
      };

    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
         await resetPool();
      }
      rethrow;
    }
  }
}