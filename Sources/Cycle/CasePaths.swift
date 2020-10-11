import Foundation

public struct CasePath<Root, Value> {
    public let extract: (Root) -> Value?
    public let embed: (Value) -> Root
}

// Does not support associated values with labels
public extension CasePath {
    init(_ embed: @escaping (Value) -> Root) {
        self.extract = { root in
            let mirror = Mirror(reflecting: root)
            guard let child = mirror.children.first else { return nil }
            guard let value = child.value as? Value else { return nil }

            let newRoot = embed(value)
            let newMirror = Mirror(reflecting: newRoot)
            guard let newChild = newMirror.children.first else { return nil }

            guard child.label == newChild.label else { return nil }

            return value
        }

        self.embed = embed
    }
}

prefix operator /
public prefix func /<Root, Value>(_ embed: @escaping (Value) -> Root) -> CasePath<Root, Value> {
    .init(embed)
}
