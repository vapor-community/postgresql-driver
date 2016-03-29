#if os(Linux)
    import CPostgreSQLLinux
#else
    import CPostgreSQLMac
#endif

public enum PostgresSQLError: ErrorProtocol {
    case CannotEstablishConnection, IndexOutOfRange, ColumnNotFound, InvalidSQL(message: String), NoQuery, NoResults
}

public class PostgreSQL {
    private(set) var connection: OpaquePointer!
    public var connectionInfo: String?
    public var connected: Bool {
        if let connection = connection where PQstatus(connection) == CONNECTION_OK {
            return true
        }
        return false
    }
    
    public init(connectionInfo: String) {
        self.connectionInfo = connectionInfo
    }
    
    deinit {
        try! close()
    }
    
    public func connect() throws {
        guard let connectionInfo = connectionInfo else {
            throw PostgresSQLError.CannotEstablishConnection
        }
        connection = PQconnectdb(connectionInfo)
        if !connected {
            throw PostgresSQLError.CannotEstablishConnection
        }
    }
    
    public func reset() throws {
        guard let connection = connection else {
            throw PostgresSQLError.CannotEstablishConnection
        }
        
        PQreset(connection)
    }
    
    public func close() throws {
        guard let connection = connection else {
            throw PostgresSQLError.CannotEstablishConnection
        }
        
        PQfinish(connection)
    }
    
    public func createStatement(withQuery query: String? = nil, values: [String]? = nil) -> PSQLStatement {
        let statement = PSQLStatement(connection: connection)
        statement.query = query
        statement.values = values
        return statement
    }
}

public class PSQLStatement {
    //private(set) var result: PSQLResult?
    private(set) var affectedRows: Int = -1
    private(set) var errorMessage: String = ""
    var query: String?
    var values: [String]?
    var connection: OpaquePointer?
    
    public init(connection: OpaquePointer?) {
        self.connection = connection
    }
    
    public func execute() throws -> PSQLResult {
        guard let connection = connection else {
            throw PostgresSQLError.CannotEstablishConnection
        }
        
        guard let query = query else {
            throw PostgresSQLError.NoQuery
        }
    
        let res: OpaquePointer
        if let values = values where values.count > 0 {
            let paramsValues = UnsafeMutablePointer<UnsafePointer<Int8>>.init(allocatingCapacity: values.count)
            
            var v = [[UInt8]]()
            for i in 0..<values.count {
                var ch = [UInt8](values[i].utf8)
                ch.append(0)
                v.append(ch)
                paramsValues[i] = UnsafePointer<Int8>(v.last!)
            }
            
            res = PQexecParams(connection, query, Int32(values.count), nil, paramsValues, nil, nil, Int32(0))
            
            defer {
                paramsValues.deinitialize()
                paramsValues.deallocateCapacity(values.count)
            }
        } else {
            res = PQexec(connection, query)
        }
        
        errorMessage = String(PQcmdTuples(res)) ?? ""
        switch PQresultStatus(res) {
        case PGRES_COMMAND_OK:
            break
        case PGRES_TUPLES_OK:
            return PSQLResult(result: res)
        case PGRES_COPY_OUT:
            PQclear(res)
        case PGRES_BAD_RESPONSE:
            PQclear(res)
        case PGRES_NONFATAL_ERROR:
            errorMessage = String(PQresultErrorMessage(res)) ?? ""
            PQclear(res)
            throw PostgresSQLError.InvalidSQL(message: errorMessage)
        case PGRES_FATAL_ERROR:
            errorMessage = String(PQresultErrorMessage(res)) ?? ""
            PQclear(res)
            throw PostgresSQLError.InvalidSQL(message: errorMessage)
        default:
            break
        }
        
        throw PostgresSQLError.NoResults
    }
}

public class PSQLResult {
    private(set) var result: OpaquePointer?
    private(set) var currentRow: Int = -1
    
    public var rowCount: Int {
        if let result = result {
            return Int(PQntuples(result))
        }
        return -1
    }
    
    public var columnCount: Int {
        if let result = result {
            return Int(PQnfields(result))
        }
        return -1
    }
    
    public var next: Bool {
        let rows = rowCount
        currentRow += 1
        
        if currentRow < rows {
            return true
        }
        return false
    }
    
    public var previous: Bool {
        if currentRow == -1 {
            currentRow = rowCount
        }
        
        currentRow -= 1
        
        if currentRow >= 0 {
            return true
        }
        return false
    }
    
    public init(result: OpaquePointer) {
        self.result = result
    }
    
    public func close() {
        guard let result = result else {
            return
        }
        PQclear(result)
    }
    
    public func columnName(index: Int) -> String? {
        guard let result = result else {
            return ""
        }
        return String(PQfname(result, Int32(index)))
    }
    
    public func isNullAt(rowIndex: Int, columnIndex: Int) -> Bool {
        guard let result = result else {
            return true
        }
        return 1 == PQgetisnull(result, Int32(rowIndex), Int32(columnIndex))
    }
    
    public func stringAt(rowIndex: Int, columnIndex: Int) -> String {
        guard let result = result else {
            return ""
        }
        return String(PQgetvalue(result, Int32(rowIndex), Int32(columnIndex))) ?? ""
    }
}
