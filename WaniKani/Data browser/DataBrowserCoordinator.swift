//
//  DataBrowserCoordinator.swift
//  WaniKani
//
//  Created by Andrii Kharchyshyn on 5/19/17.
//  Copyright © 2017 haawa. All rights reserved.
//

import UIKit
import WaniPersistance
import WaniModel

class DataBrowserCoordinator: NSObject, Coordinator {

    fileprivate let presenter: UINavigationController
    fileprivate let searchDataProvider: SearchItemsDataProvider
    fileprivate weak var dataBrowserViewController: DataBrowserViewController?

    init(presenter: UINavigationController, persistance: Persistance) {
        self.presenter = presenter
        self.searchDataProvider = SearchItemsDataProvider(persistance: persistance)
        super.init()
        searchDataProvider.delegate = self
        let tabItem: UITabBarItem = UITabBarItem(title: "Search", image: #imageLiteral(resourceName: "icon-search"), selectedImage: nil)
        presenter.tabBarItem = tabItem
    }

    fileprivate func showKanji(kanji: KanjiInfo) {
        let kanjiViewController: KanjiDetailViewController = KanjiDetailViewController.instantiateViewController()
        kanjiViewController.kanji = kanji
        kanjiViewController.navigationItem.title = kanji.character
        presenter.pushViewController(kanjiViewController, animated: true)
    }

    fileprivate func showRadical(radical: RadicalInfo) {
        let radicalViewController: RadicalDetailViewController = RadicalDetailViewController.instantiateViewController()
        radicalViewController.radical = radical
        radicalViewController.navigationItem.title = radical.character
        presenter.pushViewController(radicalViewController, animated: true)
    }
}

// MARK: - Coordinator
extension DataBrowserCoordinator {
    func start() {
        let dataBrowserViewController: DataBrowserViewController = DataBrowserViewController.instantiateViewController()
        _ = dataBrowserViewController.view
//        if dataBrowserViewController.traitCollection.forceTouchCapability == .available {
            dataBrowserViewController.registerForPreviewing(with: self, sourceView: dataBrowserViewController.view)
//        }
        dataBrowserViewController.delegate = self
        presenter.isNavigationBarHidden = true
        presenter.pushViewController(dataBrowserViewController, animated: false)
        self.dataBrowserViewController = dataBrowserViewController
    }
}

// MARK: - SearchItemsDataProviderDelegate
extension DataBrowserCoordinator: SearchItemsDataProviderDelegate {
    func newListViewModel(listViewModel: ListViewModel) {
        dataBrowserViewController?.dataSource = listViewModel
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension DataBrowserCoordinator: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let dataBrowserViewController = dataBrowserViewController else { return nil }
        let location = dataBrowserViewController.view.convert(location, to: dataBrowserViewController.collectionView)
        guard let indexPath = dataBrowserViewController.collectionView?.indexPathForItem(at: location) else { return nil }
        guard let cell = dataBrowserViewController.collectionView?.cellForItem(at: indexPath) else { return nil }
        guard let item = dataBrowserViewController.dataSource?.cellDataItemForIndexPath(indexPath: indexPath)?.viewModel as? SearchItemCellViewModel else { return nil }

        var viewController: UIViewController?

        switch item.reviewItem {
        case .kanji(let kanji):
            let kanjiViewController: KanjiDetailViewController = KanjiDetailViewController.instantiateViewController()
            kanjiViewController.kanji = kanji
            let previewHeight = kanjiViewController.view.bounds.width * 0.5 + 15
            kanjiViewController.preferredContentSize = CGSize(width: 0.0, height: previewHeight * 2)
            viewController = kanjiViewController
        case .radical(let radical):
            let radicalViewController: RadicalDetailViewController = RadicalDetailViewController.instantiateViewController()
            radicalViewController.radical = radical
            radicalViewController.navigationItem.title = radical.character
            let previewHeight = radicalViewController.view.bounds.width * 0.5 + 15
            radicalViewController.preferredContentSize = CGSize(width: 0.0, height: previewHeight)
            viewController = radicalViewController
        default: break
        }
        previewingContext.sourceRect = cell.frame

        return viewController
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        presenter.pushViewController(viewControllerToCommit, animated: true)
    }
}

// MARK: - DataBrowserViewControllerDelegate
extension DataBrowserCoordinator: DataBrowserViewControllerDelegate {
    func itemSelected(reviewItem: ReviewItem) {
        switch reviewItem {
        case .kanji(let kanji): showKanji(kanji: kanji)
        case .radical(let radical): showRadical(radical: radical)
        default: break
        }
    }

    func searchTextDidChange(newText: String) {
        searchDataProvider.searchText = newText
    }

    func searchCancelPressed() {
        searchDataProvider.searchText = nil
    }
}
