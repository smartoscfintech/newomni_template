import Foundation
import DeepLinksKit
import Factory
import SMFLogger
import OCBKit
import ___VARIABLE_packageNameWithPrefix___

final class ___VARIABLE_packageNameWithPrefix___DeeplinkHandler: DeepLinkHandler {
    var coordinatorResolver: CoordinatorResolver?
    
    func canOpenURL(_ url: URL) -> Bool {
        let path = url.absoluteString
        
        return DeeplinkPath.___VARIABLE_packageName___.allCases.contains {
            path.contains($0.rawValue)
        }
    }
    
    func openURL(_ url: URL) {
        guard
            let ___VARIABLE_packageNameLowercase___Coordinator = coordinatorResolver?.resolve___VARIABLE_packageName___Coordinator(),
            let validPath = DeeplinkPath.___VARIABLE_packageName___(url: url)
        else {
            return
        }
        switch validPath {
        case .main:
//            ___VARIABLE_packageNameLowercase___Coordinator.trigger(.)
        }
    }
    
}

extension DeeplinkPath.___VARIABLE_packageName___ {
    public init?(url: URL) {
        let path = url.path
        if path == DeeplinkPath.___VARIABLE_packageName___.main.rawValue {
            self = .main
            return
        }

        return nil
    }
}

//FIXME: need move to DeeplinkPath.swift
extension DeeplinkPath {
    public enum ___VARIABLE_packageName___: String, CaseIterable {
        case main = "/main"

        public static var allCases: [___VARIABLE_packageName___] = [
            .main
        ]
    }
}


//FIXME: need move to CoordinatorResolver.swift
private(set) var ___VARIABLE_packageNameLowercase___Coordinator: ___VARIABLE_packageNameWithPrefix___Coordinator?
func resolve___VARIABLE_packageName___Coordinator() -> ___VARIABLE_packageNameWithPrefix___Coordinator? {
    guard let navigationController = activedNavigationController() else {
        return nil
    }
    guard let ___VARIABLE_packageNameLowercase___Coordinator else {
        let coordinator = ___VARIABLE_packageNameWithPrefix___Coordinator(token: token,
            rootViewController: navigationController
        )
        ___VARIABLE_packageNameLowercase___Coordinator = coordinator
        return coordinator
    }
    
    return ___VARIABLE_packageNameLowercase___Coordinator
}