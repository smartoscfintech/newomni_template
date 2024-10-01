import Foundation
import DeepLinksKit
import Factory
import ___VARIABLE_packageNameWithPrefix___UI
import XCoordinator
import OCBKit
import OCBBaseScreenKit
import UIKit
import ThemeKit
import L10n

final class ___VARIABLE_packageNameWithPrefix___Coordinator: NavigationCoordinator<___VARIABLE_packageNameWithPrefix___Route> {
    private let token: String
    
    init(
        token: String,
        rootViewController: RootViewController
    ) {
        self.token = token
        super.init(rootViewController: rootViewController)
    }
    
    override func prepareTransition(for route: ___VARIABLE_packageNameWithPrefix___Route) -> NavigationTransition {
        switch route {
        case .backToHome:
            return .popToRoot()
        }
    }
}