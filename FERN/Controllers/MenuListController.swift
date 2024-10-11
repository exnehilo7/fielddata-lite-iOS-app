//
//  MenuListController.swift
//  FERN
//
//  Created by Hopp, Dan on 6/14/24.
//
// Replaced by MenuListClass

//import SwiftUI
//
//// Create a Coordinator
//class MenuListBridgingCoordinator: ObservableObject {
//    var menuListController: MenuListController!
//}
//
//// The UIViewControllerRepresentable of the ViewController
//struct MenuListViewControllerRepresentable: UIViewControllerRepresentable {
//    var menuListBridgingCoordinator: MenuListBridgingCoordinator
//
//    func makeCoordinator() -> MenuListCoordinator {
//        return MenuListCoordinator(self)
//    }
//
//    func makeUIViewController(context: Context) -> some UIViewController {
//        let menuListViewController = MenuListController()
//        menuListViewController.menuListControllerBridgingCoordinator = menuListBridgingCoordinator
//        return menuListViewController
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
//        //
//    }
//
//    class MenuListCoordinator: NSObject {
//        let parent: MenuListViewControllerRepresentable
//        init(_ view: MenuListViewControllerRepresentable) {
//            self.parent = view
//        }
//    }
//}
