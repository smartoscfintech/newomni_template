import Combine
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

public final class ___VARIABLE_screenName___ViewController: NavigableBaseViewController {
    public typealias ViewModel = ___VARIABLE_screenName___ViewModel
    public weak var router: ___VARIABLE_packageNameWithPrefix___Navigation?

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
}
