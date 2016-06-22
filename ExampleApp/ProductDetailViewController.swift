import UIKit
import OmiseSDK

class ProductDetailViewController: UIViewController {
    var sdkClient: OmiseSDKClient {
        return OmiseSDKClient(publicKey: "pkey_test_4y7dh41kuvvawbhslxw")
    }
    
    @IBAction func modalBuyNowButtonTapped(sender: AnyObject) {
        let creditCardView = CreditCardPopoverController(client: sdkClient)
        creditCardView.delegate = self
        creditCardView.handleErrors = true
        creditCardView.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .Done, target: self, action: #selector(dismissCreditCardPopover))
        
        let navigationController = UINavigationController(rootViewController: creditCardView)
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    @IBAction func buyNowButtonTapped(sender: AnyObject) {
        let creditCardView = CreditCardPopoverController(client: sdkClient)
        creditCardView.delegate = self
        
        self.navigationController?.pushViewController(creditCardView, animated: true)
    }
    
    @objc private func dismissCreditCardPopover() {
        presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension ProductDetailViewController: CreditCardPopoverDelegate {
    func creditCardPopover(creditCardPopover: CreditCardPopoverController, didSucceededWithToken token: OmiseToken) {
        dismissCreditCardPopover()
        performSegueWithIdentifier("CompletePayment", sender: self)
    }
    
    func creditCardPopover(creditCardPopover: CreditCardPopoverController, didFailWithError error: ErrorType) {
        dismissCreditCardPopover()
    }
}

