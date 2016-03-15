import Fluent

public class PostgreSQLDriver: Fluent.Driver {
    private(set) var database: PostgreSQL!

    private init() {

    }

    public init(connectionInfo: String) {
        self.database = PostgreSQL(connectionInfo: connectionInfo)
        try! self.database.connect()
    }

    public func execute(dslContext: DSGenerator) -> [[String: StatementValue]]? {
        let statement = self.database.createStatement(withQuery: dslContext.parameterizedQuery, values: dslContext.queryValues)
        do {
          if try statement.execute() {
            if let data = dataFromResult(statement.result) {
              return data
            }
          }
        } catch { /* fail silently (for now) */ }
        return nil
    }

    // MARK: - Internal

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
