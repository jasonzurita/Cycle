import Foundation
import Combine

public final class Store<Value, Action>: ObservableObject {
    private let reducer: Reducer<Value, Action, Any>
    @Published public private(set) var value: Value
    private let environment: Any
    private var viewCancellable: Cancellable?
    private var effectCancellers: [UUID: AnyCancellable] = [:]

    public init<Environment>(initialValue: Value,
                reducer: @escaping Reducer<Value, Action, Environment>,
                environment: Environment) {
        self.reducer = { value, action, environment in
            reducer(&value, action, environment as! Environment)
        }
        value = initialValue
        self.environment = environment
    }

    public func send(_ action: Action) {
        let effects = self.reducer(&self.value, action, environment)
        effects.forEach { effect in
            var canceller: AnyCancellable?
            var didComplete = false
            let uuid = UUID()
            canceller = effect.sink(
                receiveCompletion: { [weak self] _ in
                    didComplete = true
                    self?.effectCancellers[uuid] = nil
                },
                receiveValue: self.send
            )
            if !didComplete {
                effectCancellers[uuid] = canceller
            }
        }
    }

    public func view<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        let localStore = Store<LocalValue, LocalAction>(
            initialValue: toLocalValue(value),
            reducer: { localValue, localAction, environment in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return []
            }, environment: self.environment
        )
        localStore.viewCancellable = self.$value.sink { [weak localStore] newValue in
            localStore?.value = toLocalValue(newValue)
        }
        return localStore
    }
}
