import Foundation

public protocol Registry {
    func register<T>(_ type: T.Type, closure: @escaping (Resolver) -> T)
}

public protocol Resolver {
    func resolve<T>(_ type: T.Type) -> T
}

public protocol Assembly {
    func assemble(_ registry: Registry)
}

public protocol Container: Registry, Resolver {}

public final class DefaultContainer: Container {
    private let parent: Resolver?
    private var factories: [ObjectIdentifier: ReferenceResolver] = [:]

    public init(parent: Resolver? = nil) {
        self.parent = parent
    }

    // MARK: - Registry

    public func register<T>(_ type: T.Type, closure: @escaping (Resolver) -> T) {
        let identifier = identifier(of: type)
        factories[identifier] = SingletonReferenceResolver(factory: closure)
    }

    // MARK: - Resolver

    public func resolve<T>(_ type: T.Type) -> T {
        guard let instance = resolveIfPossible(type) else {
            fatalError("Cannot resolve \(type)")
        }
        return instance
    }

    // MARK: - Private

    private func resolveIfPossible<T>(_ type: T.Type) -> T? {
        let identifier = identifier(of: type)
        if let factory = factories[identifier] {
            return factory.resolve(with: self) as? T
        }
        if let parent {
            return parent.resolve(type)
        }
        return nil
    }

    // swiftformat:disable all
    private func identifier(of type: (some Any).Type) -> ObjectIdentifier {
        ObjectIdentifier(type)
    }
    // swiftformat:enable all
}

public final class Assembler {
    private let container: Container

    public init(container: Container) {
        self.container = container
    }

    public func assemble(_ assemblies: [Assembly]) -> Assembler {
        assemblies.forEach {
            $0.assemble(container)
        }
        return self
    }

    public func resolver() -> Resolver {
        container
    }
}

private protocol ReferenceResolver {
    func resolve(with resolver: Resolver) -> Any
}

private final class SingletonReferenceResolver: ReferenceResolver {
    private var singleInstance: Any?

    private let factory: (Resolver) -> Any

    init(factory: @escaping (Resolver) -> Any) {
        self.factory = factory
    }

    func resolve(with resolver: Resolver) -> Any {
        if let singleInstance {
            return singleInstance
        }
        let newSingleInstance = factory(resolver)
        singleInstance = newSingleInstance
        return newSingleInstance
    }
}
