import Fluent

do {
    print("Hello, Fluent")
    
    //* Change this to setup your test *//
    
    Database.driver = try PostgreSQLDriver(connectionInfo: "host='localhost' port='5432' dbname='demodb0' user='princeugwuh' password=''")
    
    if let t = Query<User>().with("id", .Equals, 1).all() {
        print("TEST \(t.first!.name)")
    }
    
    print("FIRST \(User.first()!.name)")
    print("LAST \(User.last()!.name)")
    if let user = User.findOne(1) {
        print(user.name)
        
        user.name = "Amy Ugwuh"
        user.save()
    }
    
} catch {
    print("ISSUE CONNECTING")
}