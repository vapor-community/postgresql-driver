#if os(Linux)

import XCTest
@testable import FluentPostgreSQLTests

XCTMain([
    testCase(PostgreSQLDriverTests.allTests),
])

#endif
