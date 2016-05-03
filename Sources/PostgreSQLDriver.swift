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
    let database: PostgreSQL!

    private init() {
        database = nil
    }

    public init(connectionInfo: String) throws {
        self.database = PostgreSQL(connectionInfo: connectionInfo)
        try self.database.connect()
    }

    public func execute<T: Model>(_ query: Query<T>) throws -> [[String: Value]] {
        let sql = P_SQL(query: query)
		let sqlStatement = sql.statement //Statement is a computed property that builds sql.values Values is empty before statement is first called
        let values: [String] = sql.values.map { return $0.string }
		
        let statement = self.database.createStatement(withQuery: sqlStatement, values: values)
		
        do {
            let result = try statement.execute()
            return dataFromResult(result)
        } catch PostgresSQLError.CannotEstablishConnection {
            throw DriverError.Generic(message: "Connection lost or cannot be established")
        } catch PostgresSQLError.ColumnNotFound {
            throw DriverError.Generic(message: "Invalid Column name")
        } catch PostgresSQLError.IndexOutOfRange {
            throw DriverError.Generic(message: "Index out of range")
        } catch PostgresSQLError.InvalidSQL(let message) {
            throw DriverError.Generic(message: message)
        } catch PostgresSQLError.NoQuery {
            throw DriverError.Generic(message: "No query created")
        } catch PostgresSQLError.NoResults {
            throw DriverError.Generic(message: "No results")
        }
    }

    // MARK: - Internal
    // TODO: have return values not be just strings
    
    internal func dataFromResult(_ result: PSQLResult) -> [[String: Value]] {
        guard result.rowCount > 0 && result.columnCount > 0 else {
            return []
        }
        
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
}
