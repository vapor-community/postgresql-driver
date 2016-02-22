import CPostgreSQL

public enum PostgresSQLError: ErrorType {
    case ConnectionException, IndexOutOfRangeException, NoSuchColumnException, SQLException
}

public class PostgreSQL {
    private(set) var connection: COpaquePointer!
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
        throw PostgresSQLError.ConnectionException
      }
      connection = PQconnectdb(connectionInfo)
      if !connected {
          throw PostgresSQLError.ConnectionException
      }
  }

  public func reset() throws {
    guard let connection = connection else {
        throw PostgresSQLError.ConnectionException
    }

    PQreset(connection)
  }

  public func close() throws {
    guard let connection = connection else {
        throw PostgresSQLError.ConnectionException
    }

    PQfinish(connection)
  }

  public func createStatement(withQuery query: String? = nil) -> PSQLStatement {
    let statement = PSQLStatement(connection: connection)
    statement.query = query
    return statement
  }
}

public class PSQLStatement {
  private(set) var result: PSQLResult?
  private(set) var affectedRows: Int = -1
  private(set) var errorMessage: String?
  var query: String?
  var connection: COpaquePointer?

  public init(connection: COpaquePointer?) {
    self.connection = connection
  }

  public func execute() throws -> Bool {
      guard let connection = connection else {
        return false
      }

      guard let query = query else {
        return false
      }

      var retVal = false
      let intResult = PQexec(connection, query)

      errorMessage = String.fromCString(PQcmdTuples(intResult))

      switch PQresultStatus(intResult) {
      case PGRES_COMMAND_OK:
          retVal = true
          //affectedRows = PQclear(intResult)
      case PGRES_TUPLES_OK:
          result = PSQLResult(result: intResult)
          retVal = true
      case PGRES_COPY_OUT:
          retVal = true
          PQclear(intResult)
      case PGRES_BAD_RESPONSE:
          retVal = false
          PQclear(intResult)
      case PGRES_NONFATAL_ERROR:
          retVal = true
          errorMessage = String.fromCString(PQresultErrorMessage(intResult))
          PQclear(intResult)
      case PGRES_FATAL_ERROR:
          retVal = false
          errorMessage = String.fromCString(PQresultErrorMessage(intResult))
          PQclear(intResult)
          throw PostgresSQLError.SQLException
      default:
        break
      }
      return retVal
    }

    public func close() {

    }
}

public class PSQLResult {
  private(set) var result: COpaquePointer?
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

  public init(result: COpaquePointer) {
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
    return String.fromCString(PQfname(result, Int32(index)))
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
		return String.fromCString(PQgetvalue(result, Int32(rowIndex), Int32(columnIndex))) ?? ""
	}
}
