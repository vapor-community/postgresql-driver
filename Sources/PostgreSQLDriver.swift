import Fluent

public class PostgreSQLDriver: Fluent.Driver {
    private(set) var database: PostgreSQL!

    private init() {

    }

    public init(connectionInfo: String) throws {
        self.database = PostgreSQL(connectionInfo: connectionInfo)
        try self.database.connect()
    }

    public func execute(context: DSGenerator) -> [[String: StatementValue]]? {
        var context = context
        context.placeholderFormat = "$%c" // change placeholder
        
        let statement = self.database.createStatement(withQuery: context.parameterizedQuery, values: context.queryValues)
        do {
          if try statement.execute() {
            if let data = dataFromResult(statement.result) {
              return data
            }
          }
        } catch {
            print(statement.errorMessage)
        }
        return nil
    }

    // MARK: - Internal
    // TODO: have return values not be just strings
    
    internal func dataFromResult(result: PSQLResult?) -> [[String: StatementValue]]? {
      guard let result = result else { return nil }
      if result.rowCount > 0 && result.columnCount > 0 {
        var data: [[String: StatementValue]] = []
        var row: Int = 0
        while row < result.rowCount {
            var item: [String: StatementValue] = [:]
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
