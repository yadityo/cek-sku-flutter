
import 'package:postgres/postgres.dart';

class PostgresService {
  final String host;
  final String databaseName;
  final String username;
  final String password;
  final int port;

  PostgresService({
    required this.host,
    required this.databaseName,
    required this.username,
    required this.password,
    this.port = 5432,
  });

  
  Future<Connection> _getConnection() async {
    // print('DEBUG: Mencoba connect ke Host: $host lewat Port: $port');
    return await Connection.open(
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
  }

  
  Future<bool> testConnection() async {
    Connection? conn;
    try {
      conn = await _getConnection();
      
      await conn.execute('SELECT 1');
      return true;
    } catch (e) {
      rethrow;
    } finally {
      await conn?.close();
    }
  }

  
  Future<Map<String, dynamic>?> searchProduct(String keyword) async {
    Connection? conn;
    try {
      conn = await _getConnection();

      
      final result = await conn.execute(
        Sql.named(
          'SELECT "Description" as name, "SKU" as sku, "EndQty" as quantity '
          'FROM "trStock" '
          'WHERE "Description" ILIKE @keyword OR "SKU" ILIKE @keyword '
          'ORDER BY "LastUpdate" DESC LIMIT 1'
        ),
        parameters: {'keyword': '%$keyword%'},
      );

      if (result.isEmpty) return null;

      final row = result.first;
      
      return {
        'name': row[0],     
        'sku': row[1],      
        'quantity': row[2], 
      };

    } catch (e) {
      rethrow;
    } finally {
      await conn?.close();
    }
  }
}