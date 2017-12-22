import Foundation
import WebKit


/// Delegate to receive authorizing payment events.
@objc public protocol OmiseAuthorizingPaymentViewControllerDelegate: class {
    /// A delegation method called when the authorizing payment process is completed.
    /// - parameter viewController: The authorizing payment controller that call this method
    /// - parameter redirectedURL: A URL returned from the authorizing payment process.
    func omiseAuthorizingPaymentViewController(_ viewController: OmiseAuthorizingPaymentViewController, didCompleteAuthorizingPaymentWithRedirectedURL redirectedURL: URL)
    /// A delegation method called when user cancel the authorizing payment process.
    func omiseAuthorizingPaymentViewControllerDidCancel(_ viewController: OmiseAuthorizingPaymentViewController)
    /// A delegation method calledn when an URL is failed to handle in the authorizing payment process.
    /// - parameter viewController: The authorizing payment controller that call this method
    /// - parameter failedURL: A URL that was failed to handle in the authorizing payment process.
    @objc optional func omiseAuthorizingPaymentViewController(_ viewController: OmiseAuthorizingPaymentViewController,
                                               didFailedToLoadURL failedURL: URL)
    /// Asks the delegate whether to open another app to proceed the authroizing payment process on another app.
    /// 
    /// Some payment methods need to authorized with external application,
    /// for example some Alipay customers may want to authorize their payments via the Alipay app.
    ///
    /// The default behavior will open those external app. You can implement this method to control the behavior.
    /// 
    /// - Parameters:
    ///    - viewController: The authorizing payment controller that call this method.
    ///    - url: A URL with a custom URL scheme that will open external application.
    /// - Returns: `true` if the delegate want to proceed the authorizing payment process in another app,
    /// `false` to disallow that
    @objc optional func omiseAuthorizingPaymentViewController(_ viewController: OmiseAuthorizingPaymentViewController,
                                                              shouldProceedAuthorizationOnAnotherAppWithURL url: URL?) -> Bool
}


@available(*, renamed: "OmiseAuthorizingPaymentViewController")
public typealias Omise3DSViewController = OmiseAuthorizingPaymentViewController
@available(*, renamed: "OmiseAuthorizingPaymentViewControllerDelegate")
public typealias Omise3DSViewControllerDelegate = OmiseAuthorizingPaymentViewControllerDelegate


/*:
 Drop-in authorizing payment handler view controller that automatically display the authorizing payment verification form
 which supports `3DS`, `Internet Banking` and other offsite payment methods those need to be authorized via a web browser.
 
 - remark:
   This is still an experimental API. If you encountered with any problem with this API, please feel free to report to Omise.
 */
public class OmiseAuthorizingPaymentViewController: UIViewController {
    private let webView: WKWebView = WKWebView(frame: CGRect.zero, configuration: WKWebViewConfiguration())
    
    /// Authorized URL given from Omise in the created `Charge` object.
    public var authorizedURL: URL? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            startAuthorizingPaymentProcess()
        }
    }
    
    /// The expected return URL patterns described in the URLComponents object.
    ///
    /// The rule is the scheme and host must be matched and must have the path as a prefix.
    /// Example: if the return URL is `https://www.example.com/products/12345` the expected return URL patterns should have a URLComponents with scheme of `https`, host of `www.example.com` and the path of `/products/`
    public var expectedReturnURLPatterns: [URLComponents] = []
    
    /// A delegate object that will recieved the authorizing payment events.
    public weak var delegate: OmiseAuthorizingPaymentViewControllerDelegate?
    
    /// A factory method for creating a authorizing payment view controller comes in UINavigationController stack.
    ///
    /// - parameter authorizedURL: The authorized URL given in `Charge` object that will be set to `OmiseAuthorizingPaymentViewController`
    /// - parameter expectedReturnURLPatterns: The expected return URL patterns.
    /// - parameter delegate: A delegate object that will recieved authorizing payment events.
    ///
    /// - returns: A UINavigationController with `OmiseAuthorizingPaymentViewController` as its root view controller
    @objc public static func makeAuthorizingPaymentViewControllerNavigationWithAuthorizedURL(_ authorizedURL: URL, expectedReturnURLPatterns: [URLComponents], delegate: OmiseAuthorizingPaymentViewControllerDelegate) -> UINavigationController {
        let storyboard = UIStoryboard(name: "OmiseSDK", bundle: Bundle(for: OmiseAuthorizingPaymentViewController.self))
        let navigationController = storyboard.instantiateViewController(withIdentifier: "DefaultAuthorizingPaymentViewControllerWithNavigation") as! UINavigationController
        let viewController = navigationController.topViewController as! OmiseAuthorizingPaymentViewController
        viewController.authorizedURL = authorizedURL
        viewController.expectedReturnURLPatterns = expectedReturnURLPatterns
        viewController.delegate = delegate
        
        return navigationController
    }
    
    /// A factory method for creating a authorizing payment view controller comes in UINavigationController stack.
    ///
    /// - parameter authorizedURL: The authorized URL given in `Charge` object that will be set to `OmiseAuthorizingPaymentViewController`
    /// - parameter expectedReturnURLPatterns: The expected return URL patterns.
    /// - parameter delegate: A delegate object that will recieved authorizing payment events.
    ///
    /// - returns: An `OmiseAuthorizingPaymentViewController` with given authorized URL and delegate.
    @objc public static func makeAuthorizingPaymentViewControllerWithAuthorizedURL(_ authorizedURL: URL, expectedReturnURLPatterns: [URLComponents], delegate: OmiseAuthorizingPaymentViewControllerDelegate) -> OmiseAuthorizingPaymentViewController {
        let storyboard = UIStoryboard(name: "OmiseSDK", bundle: Bundle(for: OmiseAuthorizingPaymentViewController.self))
        let viewController = storyboard.instantiateViewController(withIdentifier: "DefaultAuthorizingPaymentViewController") as! OmiseAuthorizingPaymentViewController
        viewController.authorizedURL = authorizedURL
        viewController.expectedReturnURLPatterns = expectedReturnURLPatterns
        viewController.delegate = delegate
        
        return viewController
    }
    
    public override func loadView() {
        super.loadView()
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        if #available(iOS 9.0, *) {
            webView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            webView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        } else {
            let views = ["webView": webView] as [String: UIView]
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "|[webView]|", options: [], metrics: nil, views: views) +
                NSLayoutConstraint.constraints(withVisualFormat: "V:|[webView]|", options: [], metrics: nil, views: views)
            view.addConstraints(constraints)
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAuthorizingPaymentProcess()
    }
    
    private func startAuthorizingPaymentProcess() {
        guard let authorizedURL = authorizedURL, !expectedReturnURLPatterns.isEmpty else {
            assertionFailure("Insufficient authorizing payment information")
            return
        }
        
        let request = URLRequest(url: authorizedURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0)
        webView.load(request)
    }
    
    fileprivate func verifyPaymentURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                return false
        }
        
        return expectedReturnURLPatterns.contains(where: { expectedURLComponents -> Bool in
            return expectedURLComponents.scheme == components.scheme && expectedURLComponents.host == components.host && components.path.hasPrefix(expectedURLComponents.path)
        })
    }
    
    @IBAction func cancelAuthorizingPaymentProcess(_ sender: UIBarButtonItem) {
        delegate?.omiseAuthorizingPaymentViewControllerDidCancel(self)
    }
}

extension OmiseAuthorizingPaymentViewController: WKNavigationDelegate {
    private class func canHandlesURLSchemeByDefault(_ scheme: String) -> Bool {
        if #available(iOS 11.0, *) {
            return WKWebView.handlesURLScheme(scheme)
        } else {
            return Set(["https", "http", "about" /* for about:blank */]).contains(scheme)
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        let actionPolicy: WKNavigationActionPolicy
        defer {
            decisionHandler(actionPolicy)
        }
        
        guard let url = navigationAction.request.url else {
            actionPolicy = .cancel
            return
        }
        
        if verifyPaymentURL(url) {
            actionPolicy = .cancel
            delegate?.omiseAuthorizingPaymentViewController(self, didCompleteAuthorizingPaymentWithRedirectedURL: url)
        } else if let scheme = url.scheme, OmiseAuthorizingPaymentViewController.canHandlesURLSchemeByDefault(scheme) {
            actionPolicy = .allow
        } else {
            actionPolicy = .cancel
            guard delegate?.omiseAuthorizingPaymentViewController?(self, shouldProceedAuthorizationOnAnotherAppWithURL: url) ?? true else {
                return
            }
            
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: { success in
                    if !success {
                        self.delegate?.omiseAuthorizingPaymentViewController?(self, didFailedToLoadURL: url)
                    }
                })
            } else if !UIApplication.shared.openURL(url) {
                delegate?.omiseAuthorizingPaymentViewController?(self, didFailedToLoadURL: url)
            }
        }
    }
}

