import Fluent

print("Hello, Fluent")

//* Change this to setup your test *//
Database.driver = PostgreSQLDriver(connectionInfo: "host='localhost' port='5432' dbname='demodb0' user='princeugwuh' password=''")

if let t = Query<User>().with("id", .Equals, 1).all() {
    print("WITH \(t.first!.name)")
}

print("FIRST \(User.first()!.name)")
print("LAST \(User.last()!.name)")
if let user = User.findOne(1) {
    print("FIND \(user.name)")
    
    user.name = "John Jacobs"
    user.save()
}