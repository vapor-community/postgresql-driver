import Fluent

class P_SQL<T: Model>: SQL<T> {
    var placeholderCount: Int = 0
    
    override var nextPlaceholder: String {
        placeholderCount += 1
        return "$\(placeholderCount)"
    }
    
    override var statement: String {
        placeholderCount = 0
        return super.statement
    }
    
    override init(query: Query<T>) {
        super.init(query: query)
    }
}

public class PostgreSQLDriver: Fluent.Driver {
    private(set) var database: PostgreSQL!

    private init() {

    }

    public init(connectionInfo: String) throws {
        self.database = PostgreSQL(connectionInfo: connectionInfo)
        try self.database.connect()
    }

    public func execute<T: Model>(query: Query<T>) throws -> [[String: Value]] {
        let sql = P_SQL(query: query)
        let statement = self.database.createStatement(withQuery: sql.statement, values: sql.values)
        do {
          if try statement.execute() {
            if let data = dataFromResult(statement.result) {
              return data
            }
          }
        } catch {
            print(statement.errorMessage)
        }
        return []
    }

    // MARK: - Internal
    // TODO: have return values not be just strings
    
    internal func dataFromResult(result: PSQLResult?) -> [[String: Value]]? {
      guard let result = result else { return nil }
      if result.rowCount > 0 && result.columnCount > 0 {
        var data: [[String: Value]] = []
        var row: Int = 0
        while row < result.rowCount {
            var item: [String: Value] = [:]
            var column: Int = 0
            while column < result.columnCount {
                item[result.columnName(column) ?? ""] = result.stringAt(row, columnIndex: column)
                column += 1
            }
            data.append(item)
            row += 1
        }
        return data
      }
      return nil
    }
}
