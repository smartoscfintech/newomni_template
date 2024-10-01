#!/bin/bash

# Yêu cầu người dùng nhập các tham số
read -p "Enter packageName: " PACKAGE_NAME
read -p "Enter packageNameLowercase: " PACKAGE_NAME_LOWERCASE
read -p "Enter packageNameWithPrefix: " PACKAGE_NAME_WITH_PREFIX

# Khởi tạo mảng để lưu các đối tượng route và screenName
declare -a ROUTES

# Vòng lặp để yêu cầu người dùng nhập các giá trị cho route và screenName
while true; do
    read -p "Enter route (or type 'done' to finish): " ROUTE
    if [ "$ROUTE" == "done" ]; then
        break
    fi
    read -p "Enter screenName: " SCREEN_NAME
    ROUTES+=("$ROUTE:$SCREEN_NAME")
done

echo "Routes: ${ROUTES[@]}"

# Khởi tạo mảng để lưu các đối tượng route và deeplink
declare -a DEEPLINKS

# Vòng lặp để yêu cầu người dùng nhập các giá trị cho route và deeplink
while true; do
    read -p "Enter route-deeplink (or type 'done' to finish): " ROUTE
    if [ "$ROUTE" == "done" ]; then
        break
    fi
    read -p "Enter deeplink: " DEEPLINK
    DEEPLINKS+=("$ROUTE:$DEEPLINK")
done

echo "DEEPLINKS: ${DEEPLINKS[@]}"

# Tạo các file tương ứng dựa trên mảng ROUTES
# for ITEM in "${ROUTES[@]}"; do
#     IFS=":" read -r ROUTE SCREEN_NAME <<< "$ITEM"
#     FILE_PATH="$PACKAGE_NAME_WITH_PREFIX/Sources/${PACKAGE_NAME_WITH_PREFIX}UI/Screens/${SCREEN_NAME}.swift"
#     echo "Creating file: $FILE_PATH"
#     cat <<EOF > "$FILE_PATH"
# // This is a generated file for route: $ROUTE and screenName: $SCREEN_NAME
# import Foundation

# class ${SCREEN_NAME}ViewController: UIViewController {
#     override func viewDidLoad() {
#         super.viewDidLoad()
#         // Setup for $SCREEN_NAME
#     }
# }
# EOF
# done


mkdir -p "$PACKAGE_NAME_WITH_PREFIX"
mkdir -p "$PACKAGE_NAME_WITH_PREFIX/Sources/$PACKAGE_NAME_WITH_PREFIX"
mkdir -p "$PACKAGE_NAME_WITH_PREFIX/Sources/${PACKAGE_NAME_WITH_PREFIX}UI"
mkdir -p "$PACKAGE_NAME_WITH_PREFIX/Sources/${PACKAGE_NAME_WITH_PREFIX}UI/Interface"
mkdir -p "$PACKAGE_NAME_WITH_PREFIX/Sources/${PACKAGE_NAME_WITH_PREFIX}UI/Screens"
mkdir -p "$PACKAGE_NAME_WITH_PREFIX/Sources/${PACKAGE_NAME_WITH_PREFIX}UI/UI"

mkdir -p "${PACKAGE_NAME_WITH_PREFIX}Coordinator"


echo "// swift-tools-version: 5.7.1

import PackageDescription

let package = Package(
    name: \"$PACKAGE_NAME_WITH_PREFIX\",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: \"$PACKAGE_NAME_WITH_PREFIX\",
            targets: [\"$PACKAGE_NAME_WITH_PREFIX\"]
        ),
        .library(
            name: \"${PACKAGE_NAME_WITH_PREFIX}UI\",
            targets: [\"${PACKAGE_NAME_WITH_PREFIX}UI\"]
        )
    ],
    dependencies: [
        .package(path: \"../OCBKit\"),
        .package(path: \"../OCBScreenKit\"),
        .package(path: \"../NetworkServiceKit\"),
        .package(path: \"../AnalyticsKit\"),
        .package(path: \"../DeepLinksKit\"),
        .package(path: \"../OCBPreferencesKit\"),
        .package(path: \"../PublicLibs/checkouts/CombineCocoa\"),
    ],
    targets: [
        .target(
            name: \"$PACKAGE_NAME_WITH_PREFIX\",
            dependencies: [
                .product(name: \"OCBKit\", package: \"OCBKit\"),
                \"OCBPreferencesKit\"
            ]
        ),
        .target(
            name: \"${PACKAGE_NAME_WITH_PREFIX}UI\",
            dependencies: [
                \"$PACKAGE_NAME_WITH_PREFIX\",
                \"OCBPreferencesKit\",
                \"CombineCocoa\",
                \"AnalyticsKit\",
                \"DeepLinksKit\",
                .product(name: \"OCBBaseScreenKit\", package: \"OCBScreenKit\"),
                .product(name: \"APIClient\", package: \"NetworkServiceKit\")
            ]
        )
    ]
)
" > "$PACKAGE_NAME_WITH_PREFIX/Package.swift"

# Tạo chuỗi kết quả từ mảng ROUTES
RESULT_ROUTE_CASE=""
RESULT_ROUTE_NAVIGATION=""
RESULT_ROUTE_COORDINATOR_NAVIGATION=""
RESULT_ROUTE_COORDINATOR_MAIN=""
RESULT_ROUTE_COORDINATOR_EXTENSION=""

for ITEM in "${ROUTES[@]}"; do
    IFS=":" read -r ROUTE SCREEN_NAME <<< "$ITEM"
    RESULT_ROUTE_CASE+="case $ROUTE\n    "
    ROUTE_CAPITALIZED="$(tr '[:lower:]' '[:upper:]' <<< ${ROUTE:0:1})${ROUTE:1}"
    RESULT_ROUTE_NAVIGATION+="func routeTo$ROUTE_CAPITALIZED()\n    "
    RESULT_ROUTE_COORDINATOR_NAVIGATION+="func routeTo$ROUTE_CAPITALIZED(){\n        trigger(.$ROUTE)\n    }\n\n    "
    RESULT_ROUTE_COORDINATOR_MAIN+="case .$ROUTE:\n            return make${ROUTE_CAPITALIZED}Transition()\n        "
    RESULT_ROUTE_COORDINATOR_EXTENSION+="func make${ROUTE_CAPITALIZED}Transition() -> NavigationTransition {
        let context = ${SCREEN_NAME}ViewController.ViewModel.Context()
        let controller = ${SCREEN_NAME}ViewController(context: context)
        controller.router = self
        return .push(controller)
    }\n\n    "
done

echo "" > "$PACKAGE_NAME_WITH_PREFIX/Sources/$PACKAGE_NAME_WITH_PREFIX/$PACKAGE_NAME_WITH_PREFIX.swift"
echo -e "import Foundation
import OCBKit
import $PACKAGE_NAME_WITH_PREFIX

public protocol ${PACKAGE_NAME_WITH_PREFIX}Navigation: AnyObject {
    func routeBackToHome()
    $RESULT_ROUTE_NAVIGATION
}" > "$PACKAGE_NAME_WITH_PREFIX/Sources/${PACKAGE_NAME_WITH_PREFIX}UI/Interface/${PACKAGE_NAME_WITH_PREFIX}Navigation.swift"

echo -e "import Foundation
import DeepLinksKit
import Factory
import ${PACKAGE_NAME_WITH_PREFIX}UI
import XCoordinator
import OCBKit
import OCBBaseScreenKit
import UIKit
import ThemeKit
import L10n

final class ${PACKAGE_NAME_WITH_PREFIX}Coordinator: NavigationCoordinator<${PACKAGE_NAME_WITH_PREFIX}Route> {
    private let token: String
    
    init(
        token: String,
        rootViewController: RootViewController
    ) {
        self.token = token
        super.init(rootViewController: rootViewController)
    }
    
    override func prepareTransition(for route: ${PACKAGE_NAME_WITH_PREFIX}Route) -> NavigationTransition {
        switch route {
        case .backToHome:
            return .popToRoot()
        $RESULT_ROUTE_COORDINATOR_MAIN
        }
    }
}

extension ${PACKAGE_NAME_WITH_PREFIX}Coordinator {
    $RESULT_ROUTE_COORDINATOR_EXTENSION
}" > "${PACKAGE_NAME_WITH_PREFIX}Coordinator/${PACKAGE_NAME_WITH_PREFIX}Coordinator.swift"

echo -e "import Foundation
import XCoordinator
import ${PACKAGE_NAME_WITH_PREFIX}UI
import OCBKit

extension ${PACKAGE_NAME_WITH_PREFIX}Coordinator: ${PACKAGE_NAME_WITH_PREFIX}Navigation {
    func routeBackToHome() {
        trigger(.backToHome)
    }
    
    $RESULT_ROUTE_COORDINATOR_NAVIGATION
}" > "${PACKAGE_NAME_WITH_PREFIX}Coordinator/${PACKAGE_NAME_WITH_PREFIX}Coordinator+Navigation.swift"

echo -e "import Foundation
import XCoordinator
import OCBKit

enum ${PACKAGE_NAME_WITH_PREFIX}Route: Route {
    case backToHome
    $RESULT_ROUTE_CASE
}" > "${PACKAGE_NAME_WITH_PREFIX}Coordinator/${PACKAGE_NAME_WITH_PREFIX}Route.swift"


# deeplink
DEEPLINK_PATH_ENUM=""
DEEPLINK_PATH_ENUM_ARRAY=""
DEEPLINK_PATH_INIT=""
DEEPLINK_IMPLEMENT=""
for ITEM in "${DEEPLINKS[@]}"; do
    IFS=":" read -r ROUTE DEEPLINK <<< "$ITEM"
    DEEPLINK_PATH_ENUM+="case $DEEPLINK = \"/$DEEPLINK\"\n        "
    DEEPLINK_PATH_ENUM_ARRAY+=".$DEEPLINK, "
    DEEPLINK_PATH_INIT+="if path == DeeplinkPath.$PACKAGE_NAME.$DEEPLINK.rawValue {
            self = .$DEEPLINK
            return
        }\n\n        "
    DEEPLINK_IMPLEMENT+="case .$DEEPLINK:
            ${PACKAGE_NAME_LOWERCASE}Coordinator.trigger(.$ROUTE)\n        "
done
DEEPLINK_PATH_ENUM_ARRAY="${DEEPLINK_PATH_ENUM_ARRAY%?}"

echo -e "import Foundation
import DeepLinksKit
import Factory
import SMFLogger
import OCBKit
import $PACKAGE_NAME_WITH_PREFIX

final class ${PACKAGE_NAME_WITH_PREFIX}DeeplinkHandler: DeepLinkHandler {
    var coordinatorResolver: CoordinatorResolver?
    
    func canOpenURL(_ url: URL) -> Bool {
        let path = url.absoluteString
        
        return DeeplinkPath.$PACKAGE_NAME.allCases.contains {
            path.contains(\$0.rawValue)
        }
    }
    
    func openURL(_ url: URL) {
        guard
            let ${PACKAGE_NAME_LOWERCASE}Coordinator = coordinatorResolver?.resolve${PACKAGE_NAME}Coordinator(),
            let validPath = DeeplinkPath.$PACKAGE_NAME(url: url)
        else {
            return
        }
        switch validPath {
        $DEEPLINK_IMPLEMENT
        }
    }
    
}

extension DeeplinkPath.$PACKAGE_NAME {
    public init?(url: URL) {
        let path = url.path
        $DEEPLINK_PATH_INIT
        return nil
    }
}" > "${PACKAGE_NAME_WITH_PREFIX}DeeplinkHandler.swift"



# Tạo các màn hình theo route và screenName đã nhập
for ITEM in "${ROUTES[@]}"; do
    IFS=":" read -r ROUTE SCREEN_NAME <<< "$ITEM"
mkdir -p "$PACKAGE_NAME_WITH_PREFIX/Sources/${PACKAGE_NAME_WITH_PREFIX}UI/Screens/${SCREEN_NAME}"

#Tạo ViewController
echo -e "import Combine
import CombineCocoa
import Foundation
import OCBKit
import OCBKitUI
import UIKit
import XCoordinator
import ThemeKit
import SMFLogger
import L10n
import OCBBaseScreenKit
import SharedResources
import APIClient
import SnapKit

public final class ${SCREEN_NAME}ViewController: NavigableBaseViewController {
    public typealias ViewModel = ${SCREEN_NAME}ViewModel
    public weak var router: ${PACKAGE_NAME_WITH_PREFIX}Navigation?

    private let viewModel: ViewModel
    private var cancellableSet: Set<AnyCancellable> = []

    public init(context: ViewModel.Context) {
        self.viewModel = .init(context: context)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupSubscriptions()
    }
    
    private func setupUI() {
        navigationBar.prefersLargeTitles = true
        navigationBar.largeTitleLabel.font = .preferredFont(for: .heading2)
        //title = L10n.
        view.backgroundColor = OCBColor.backgroundsMobileFoundation()
    }
    
    private func setupSubscriptions() {
        cancellableSet = []
    }
}" > "$PACKAGE_NAME_WITH_PREFIX/Sources/${PACKAGE_NAME_WITH_PREFIX}UI/Screens/${SCREEN_NAME}/${SCREEN_NAME}ViewController.swift"


#tạo ViewModel
echo -e "import Combine
import Foundation
import OCBKit
import SMFLogger
import L10n

public final class ${SCREEN_NAME}ViewModel {
    let context: Context
    private var cancellableSet: Set<AnyCancellable> = []

    public init(context: Context) {
        self.context = context
    }

    func setupSubscriptions() {
        cancellableSet = []
    }
}

public extension ${SCREEN_NAME}ViewModel {
    struct Context {
        public init() {}
    }
}" > "$PACKAGE_NAME_WITH_PREFIX/Sources/${PACKAGE_NAME_WITH_PREFIX}UI/Screens/${SCREEN_NAME}/${SCREEN_NAME}ViewModel.swift"



    # RESULT_ROUTE_CASE+="case $ROUTE\n    "
    # ROUTE_CAPITALIZED="$(tr '[:lower:]' '[:upper:]' <<< ${ROUTE:0:1})${ROUTE:1}"
    # RESULT_ROUTE_NAVIGATION+="func routeTo$ROUTE_CAPITALIZED()\n    "
    # RESULT_ROUTE_COORDINATOR_NAVIGATION+="func routeTo$ROUTE_CAPITALIZED(){\n        trigger(.$ROUTE)\n    }\n\n    "
    # RESULT_ROUTE_COORDINATOR_MAIN+="case .$ROUTE:\n            return make${ROUTE_CAPITALIZED}Transition()\n        "
    # RESULT_ROUTE_COORDINATOR_EXTENSION+="func make${ROUTE_CAPITALIZED}Transition() -> NavigationTransition {
    #     let context = ${SCREEN_NAME}ViewController.ViewModel.Context()
    #     let controller = ${SCREEN_NAME}ViewController(context: context)
    #     controller.router = self
    #     return .push(controller)
    # }\n\n    "
done




#thêm các hướng dẫn setup vào các file đã tồn tại

echo -e "
//FIXME: need move to DeeplinkPath.swift
extension DeeplinkPath {
    public enum $PACKAGE_NAME: String, CaseIterable {
        $DEEPLINK_PATH_ENUM

        public static var allCases: [$PACKAGE_NAME] = [
            $DEEPLINK_PATH_ENUM_ARRAY
        ]
    }
}


//FIXME: need move to CoordinatorResolver.swift
private(set) var ${PACKAGE_NAME_LOWERCASE}Coordinator: ${PACKAGE_NAME_WITH_PREFIX}Coordinator?
func resolve${PACKAGE_NAME}Coordinator() -> ${PACKAGE_NAME_WITH_PREFIX}Coordinator? {
    guard let navigationController = activedNavigationController() else {
        return nil
    }
    guard let ${PACKAGE_NAME_LOWERCASE}Coordinator else {
        let coordinator = ${PACKAGE_NAME_WITH_PREFIX}Coordinator(token: token,
            rootViewController: navigationController
        )
        ${PACKAGE_NAME_LOWERCASE}Coordinator = coordinator
        return coordinator
    }
    
    return ${PACKAGE_NAME_LOWERCASE}Coordinator
}

//FIXME: add ${PACKAGE_NAME_WITH_PREFIX}DeeplinkHandler() to DeepLinksService

" > "TODO.swift"

echo "-----------DONE-------------"