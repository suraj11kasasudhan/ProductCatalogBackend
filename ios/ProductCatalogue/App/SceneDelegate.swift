import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        window.tintColor = .systemIndigo
        do {
            let api = CatalogueAPI(baseURL: try APIConfiguration.load().baseURL)
            let screens = CatalogueScreenFactory(service: api)
            let home = screens.catalogue(mode: .home)
            let browseNavigation = UINavigationController(rootViewController: home)
            browseNavigation.tabBarItem = UITabBarItem(title: "Browse", image: UIImage(systemName: "square.grid.2x2"), tag: 0)
            let search = screens.catalogue(mode: .search)
            let searchNavigation = UINavigationController(rootViewController: search)
            searchNavigation.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 1)
            let tabs = UITabBarController()
            tabs.viewControllers = [browseNavigation, searchNavigation]
            window.rootViewController = tabs
        } catch {
            let controller = UIViewController()
            controller.view.backgroundColor = .systemBackground
            let status = StatusView()
            status.translatesAutoresizingMaskIntoConstraints = false
            controller.view.addSubview(status)
            NSLayoutConstraint.activate([
                status.topAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.topAnchor),
                status.bottomAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.bottomAnchor),
                status.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
                status.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            ])
            status.show(message: error.localizedDescription)
            window.rootViewController = controller
        }
        self.window = window
        window.makeKeyAndVisible()
    }
}
