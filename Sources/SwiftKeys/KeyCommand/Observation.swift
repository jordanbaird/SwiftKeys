//
//  Observation.swift
//  SwiftKeys
//

// MARK: - KeyCommand Observation

extension KeyCommand {
    /// The result type of a call to ``KeyCommand/observe(_:handler:)``.
    ///
    /// You can pass an instance of this type into the ``KeyCommand/removeObservation(_:)``
    /// method, or similar, to permanently remove the observation and stop the execution
    /// of its handler.
    public struct Observation {

        // MARK: Properties

        private let handler: VoidHandler

        /// The event type of the observation.
        public let eventType: EventType

        // MARK: Initializers

        /// Creates an observation that executes the given handler when it receives the
        /// given event type.
        ///
        /// Pass the returned instance into the ``KeyCommand`` type's ``KeyCommand/addObservation(_:)``
        /// method. Note, however that the alternative method of creation, the ``KeyCommand`` type's
        /// ``KeyCommand/observe(_:handler:)`` method is generally preferred over this.
        ///
        /// ```swift
        /// let keyCommand = KeyCommand(name: "ToggleSettings")
        ///
        /// let observation = KeyCommand.Observation(.keyDown) {
        ///     print("Running observation handler.")
        /// }
        ///
        /// keyCommand.addObservation(observation)
        /// ```
        public init(_ eventType: EventType, handler: @escaping () -> Void) {
            self.eventType = eventType
            self.handler = VoidHandler(block: handler)
        }

        // MARK: Methods

        func perform() {
            handler.perform()
        }
    }
}

// MARK: Observation: Equatable
extension KeyCommand.Observation: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.handler == rhs.handler
    }
}

// MARK: Observation: Hashable
extension KeyCommand.Observation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(handler)
    }
}

// MARK: - Array<Observation>

extension [KeyCommand.Observation] {
    func performObservations(where predicate: (KeyCommand.EventType) throws -> Bool) rethrows {
        for observation in self where try predicate(observation.eventType) {
            observation.perform()
        }
    }

    func performObservations(matching eventType: KeyCommand.EventType?) {
        performObservations { type in
            type == eventType
        }
    }
}
