import UIKit
import OmiseSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if let window = window, let rootViewController = window.rootViewController,
            let authorizingNavigationController = rootViewController.presentedViewController as? UINavigationController,
            let authorizingViewController = authorizingNavigationController.topViewController as? OmiseAuthorizingPaymentViewController {
            authorizingViewController.handleOpenedURL(url)
        }
        
        return true
    }
}
