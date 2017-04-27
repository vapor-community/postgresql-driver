import Fluent
import Random

extension Builder {
    // Adds a foreign key constraint from a local
    // column to a column on the foreign entity.
    public func foreignKey<E: Entity>(
        _ localColumn: String,
        references foreignColumn: String,
        on entity: E.Type = E.self
        ) {
        raw("CONSTRAINT _fluent_foreignkey_\(random) FOREIGN KEY (\(localColumn)) REFERENCES \(E.entity) (\(foreignColumn))")
    }
}

extension Builder {
    fileprivate var random: String {
        return OSRandom()
            .bytes(count: 3)
            .hexEncoded
            .makeString()
    }
}
