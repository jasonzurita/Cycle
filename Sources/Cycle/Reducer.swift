import Foundation
import Combine

public typealias Reducer<Value, Action, Environment> = (inout Value, Action, Environment) -> [Effect<Action>]

public func combine<Value, Action, Environment>(
    _ reducers: Reducer<Value, Action, Environment>...
) -> Reducer<Value, Action, Environment> {
    return { value, action, environment in
        let effects = reducers.flatMap { $0(&value, action, environment) }
        return effects
    }
}

public func pullback<GlobalValue, LocalValue, GlobalAction, LocalAction, GlobalEnvironment, LocalEnvironment>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction, LocalEnvironment>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: CasePath<GlobalAction, LocalAction>,
    toLocalEnvironment: @escaping (GlobalEnvironment) -> LocalEnvironment
) -> Reducer<GlobalValue, GlobalAction, GlobalEnvironment> {
    return { globalValue, globalAction, globalEnvironment in
        guard let localAction = action.extract(globalAction) else { return [] }
        let localEnvironment = toLocalEnvironment(globalEnvironment)
        let localEffects = reducer(&globalValue[keyPath: value], localAction, localEnvironment)
        let globalEffects: [Effect<GlobalAction>] = localEffects.map { localEffect in
            localEffect.map(action.embed).eraseToEffect()
        }
        return globalEffects
    }
}

public func logging<Value, Action, Environment>(
    _ reducer: @escaping Reducer<Value, Action, Environment>
) -> Reducer<Value, Action, Environment> {
    return { value, action, environment in
        let effects = reducer(&value, action, environment)
        let newValue = value
        return [
            .fireAndForget {
                print("Action: \(action)")
                print("Value:")
                dump(newValue)
                print("---")
            },
        ] + effects
    }
}
