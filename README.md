# PostgreSQL Driver
![Swift](http://img.shields.io/badge/swift-3.1-brightgreen.svg)
[![Build Status](https://travis-ci.org/vapor-community/postgresql-driver.svg?branch=master)](https://travis-ci.org/vapor-community/postgresql-driver)

A Fluent driver for PostgreSQL

## Fluent
[Fluent](https://github.com/vapor/fluent.git) provides an easy, simple, and safe API for working with your persisted data.  Fluent uses the PostgreSQL driver to talk to your PostgreSQL database.

See the [Fluent query documentation](https://docs.vapor.codes/2.0/fluent/query/) for examples on interacting with data in PostgreSQL.

## Raw
Sometimes you need to bypass Fluent and send raw queries to the database.

```swift
let result = try postgresqlDriver.raw("SELECT version()")
```

Note: If you are using Vapor, you can get access to the PostgreSQL Driver with `drop.postgresql()`

## Transaction
If you are performing multiple queries that depend on each other, you can use transactions to make sure nothing gets saved to the database if one of the queries fails.

```swift
try postgresqlDriver.transaction { conn in
  // delete user's pets, then delete user
  // if one of these fails, the transaction will rollback
  try user.pets.makeQuery(conn).delete()
  try user.makeQuery(conn).delete()
}
```

Warning: Make sure to use the connection supplied to the closure for all queries you want included in the transaction.

## Manual
You can also manually send a query to the driver without going through Fluent.

```swift
let query = try User.makeQuery()
...

let results = try postgresqlDriver.query(query)
```
