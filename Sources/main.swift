import Fluent

do {
    print("Hello, Fluent")
    
    //* Change this to setup your test *//
    
    Database.driver = try PostgreSQLDriver(connectionInfo: "host='localhost' port='5432' dbname='demodb0' user='princeugwuh' password=''")
    
    if let t = Query<User>().filter("id", .Equals, 1).all() {
        print("Using Query \(t.first!.name)")
    }
    
    if let t = User.find("id", .Equals, 1) {
        print("Using Model \(t.first!.name)")
    }
    
    if let uf = User.first() {
        print("FIRST \(uf.name)")
    }
    
    if let ul = User.last() {
        print("FIRST \(ul.name)")
    }
    
    if let user = User.find(1) {
        print("FOUND \(user.name)")
        
        user.name = "Steve Jobs"
        user.save()
    }
    
} catch {
    print("ISSUE CONNECTING")
}