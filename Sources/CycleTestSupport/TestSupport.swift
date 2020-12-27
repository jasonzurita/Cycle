#if !os(watchOS)
import Combine
import XCTest
import Cycle

public enum StepType<Action> {
    case send(Action)
    case receive(Action)
    case receiveFireAndForget
}

public struct Step<Value, Action> {
    let file: StaticString
    let line: UInt
    let type: StepType<Action>
    let update: (inout Value) -> Void

    public init(
        file: StaticString = #filePath,
        line: UInt = #line,
        _ type: StepType<Action>,
        update expectedStateChange: @escaping (inout Value) -> Void = { _ in }
    ) {
        self.file = file
        self.line = line
        self.type = type
        self.update = expectedStateChange
    }
}

public func assert<Value: Equatable, Action: Equatable,  Environment>(
    initialValue: Value,
    reducer: (inout Value, Action, Environment) -> [Effect<Action>],
    environment: Environment,
    steps: Step<Value, Action>...,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    var value = initialValue
    var effects: [Effect<Action>] = []
    var cancellables: [AnyCancellable] = []

    steps.forEach { step in
        var expected = value

        switch step.type {
        case let .send(stepAction):
            guard effects.isEmpty else {
                XCTFail("Action sent before handling \(effects.count) pending effect(s).", file: file, line: line)
                return
            }
            effects.append(contentsOf: reducer(&value, stepAction, environment))
        case let .receive(stepAction):
            guard !effects.isEmpty else {
                XCTFail("No pending effects to receive", file: file, line: line)
                return
            }
            let effect = effects.removeFirst()
            var action: Action!
            let receivedCompletion = XCTestExpectation(description: "receivedCompletion")

            effect.sink { _ in
                receivedCompletion.fulfill()
            } receiveValue: { action = $0 }
            .store(in: &cancellables)

            if XCTWaiter.wait(for: [receivedCompletion], timeout: 0.01) != .completed {
                XCTFail("Timed out waiting for the effect to complete.", file: step.file, line: step.line)
            }
            XCTAssertEqual(action, stepAction, file: step.file, line: step.line)
            if let a = action {
                effects.append(contentsOf: reducer(&value, a,  environment))
            }
        case .receiveFireAndForget:
            guard !effects.isEmpty else {
                XCTFail("No pending effects to receive", file: file, line: line)
                return
            }
            let effect = effects.removeFirst()
            let receivedCompletion = XCTestExpectation(description: "receivedCompletion")
            effect.sink { _ in
                receivedCompletion.fulfill()
            } receiveValue: { _ in
                XCTFail("No value should have been received from a fire and forget effect", file: file, line: line)
            }
            .store(in: &cancellables)

            if XCTWaiter.wait(for: [receivedCompletion], timeout: 0.01) != .completed {
                XCTFail("Timed out waiting for the effect to complete.", file: step.file, line: step.line)
            }
        }
        step.update(&expected)
        XCTAssertEqual(value, expected, file: step.file, line: step.line)
    }

    XCTAssertTrue(effects.isEmpty, "Assertion failed to handle \(effects.count) pending effect(s).", file: file, line: line)
}
#endif
