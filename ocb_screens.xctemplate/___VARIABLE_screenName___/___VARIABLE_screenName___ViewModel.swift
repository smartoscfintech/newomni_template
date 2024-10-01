import Combine
import Foundation
import OCBKit
import SMFLogger
import L10n

public final class ___VARIABLE_screenName___ViewModel {
    let context: Context
    private var cancellableSet: Set<AnyCancellable> = []

    public init(context: Context) {
        self.context = context
    }

    func setupSubscriptions() {
        cancellableSet = []
    }
}

public extension ___VARIABLE_screenName___ViewModel {
    struct Context {}
}
