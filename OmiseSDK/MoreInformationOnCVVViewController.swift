import UIKit


protocol MoreInformationOnCVVViewControllerDelegate: AnyObject {
    func moreInformationOnCVVViewControllerDidAskToClose(_ controller: MoreInformationOnCVVViewController)
}


class MoreInformationOnCVVViewController: UIViewController {
    static let preferredWidth: CGFloat = 240
    
    weak var delegate: MoreInformationOnCVVViewControllerDelegate?
    
    @IBAction func askToClose(_ sender: AnyObject) {
        delegate?.moreInformationOnCVVViewControllerDidAskToClose(self)
    }
}


class OverlayPanelTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var alertPresentationController: OverlayPanelPresentationController?
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        alertPresentationController = OverlayPanelPresentationController(presentedViewController: presented, presenting: presenting)
        return alertPresentationController
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        alertPresentationController?.isPresenting = true
        return alertPresentationController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        alertPresentationController?.isPresenting = false
        return alertPresentationController
    }
}

class OverlayPanelPresentationController: UIPresentationController {
    var isPresenting = false
    fileprivate let dimmingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red:0.26, green:0.27, blue:0.28, alpha:0.5)
        view.alpha = 0.0
        
        return view
    }()
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else {
            return
        }
        
        if dimmingView.superview !== containerView {
            containerView.insertSubview(dimmingView, at: 0)
            
            if #available(iOS 9.0, *) {
                NSLayoutConstraint.activate([
                    dimmingView.topAnchor.constraint(equalTo: containerView.topAnchor),
                    dimmingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                    dimmingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    dimmingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    ])
            } else {
                let views = ["dimmingView": dimmingView] as [String: UIView]
                let constraints = NSLayoutConstraint.constraints(withVisualFormat: "|[dimmingView]|", options: [], metrics: nil, views: views) +
                    NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimmingView]|", options: [], metrics: nil, views: views)
                containerView.addConstraints(constraints)
            }
        }
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }
        
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1.0
        })
    }
    
    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }
        
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        })
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return super.frameOfPresentedViewInContainerView
        }
        let presentedViewSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView.bounds.size)
        return containerView.bounds.centeredRectWithSize(presentedViewSize)
    }
    
    override func containerViewWillLayoutSubviews() {
        guard let presentedView = self.presentedView else {
            return
        }
        
        let frameOfPresentedViewInContainerView = self.frameOfPresentedViewInContainerView
        
        presentedView.frame = frameOfPresentedViewInContainerView
        
        let presentedLayer: CALayer = presentedView.layer
        presentedLayer.cornerRadius = 10
        presentedLayer.shadowOffset = CGSize(width: 0, height: 2)
        presentedLayer.shadowColor = UIColor(red:0.27, green:0.29, blue:0.32, alpha:0.25).cgColor
        presentedLayer.shadowOpacity = 1
        presentedLayer.shadowRadius = 4
        
        presentedLayer.shadowPath = UIBezierPath(
            roundedRect: CGRect(origin: .zero, size: frameOfPresentedViewInContainerView.size),
            cornerRadius: 10
            ).cgPath
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        guard let viewController = container as? UIViewController, viewController === presentedViewController else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
        
        let preferredContentSizeWidth = MoreInformationOnCVVViewController.preferredWidth
        
        let calculatedPreferredContentSize = viewController.view.systemLayoutSizeFitting(
            CGSize(width: min(preferredContentSizeWidth, parentSize.width), height: UILayoutFittingCompressedSize.height),
            withHorizontalFittingPriority: UILayoutPriority.required,
            verticalFittingPriority: UILayoutPriority.fittingSizeLevel
        )
        let preferredContentSizeHeight = min(
            ceil(calculatedPreferredContentSize.height),
            parentSize.height
        )
        
        return CGSize(width: preferredContentSizeWidth, height: preferredContentSizeHeight)
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        guard let container = container as? UIViewController, container === presentedViewController,
            let containerView = containerView, container.view.isDescendant(of: containerView) else {
                return
        }
        
        UIView.animate(withDuration: 0.18) { 
            container.view.frame = self.frameOfPresentedViewInContainerView
        }
    }
}


extension OverlayPanelPresentationController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .overCurrentContext
    }
}

extension OverlayPanelPresentationController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.18
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = isPresenting ? UITransitionContextViewControllerKey.to : UITransitionContextViewControllerKey.from
        
        guard let controller = transitionContext.viewController(forKey: key) else {
            return
        }
        
        if isPresenting {
            transitionContext.containerView.addSubview(controller.view)
        }
        
        let presentedFrame = transitionContext.finalFrame(for: controller)
        var dismissedFrame = presentedFrame
        dismissedFrame.origin.y += 100
        
        let initialFrame = isPresenting ? dismissedFrame : presentedFrame
        let finalFrame = isPresenting ? presentedFrame : dismissedFrame
        
        let initialAlpha: CGFloat = isPresenting ? 0.0 : 1.0
        let finalAlpha: CGFloat = isPresenting ? 1.0 : 0.0
        let options = isPresenting ? UIViewAnimationOptions.curveEaseOut : .curveEaseIn
        
        let animationDuration = transitionDuration(using: transitionContext)
        controller.view.frame = initialFrame
        controller.view.alpha = initialAlpha
        
        
        let animationBlock: () -> () = {
            controller.view.frame = finalFrame
            controller.view.alpha = finalAlpha
        }

        if #available(iOSApplicationExtension 10.0, *) {
            let animator = UIViewPropertyAnimator(duration: animationDuration, timingParameters: UISpringTimingParameters())
            animator.addAnimations(animationBlock)
            animator.addCompletion({ position in
                transitionContext.completeTransition(position == UIViewAnimatingPosition.end)
            })
            animator.startAnimation()
        } else {
            UIView.animate(
                withDuration: animationDuration, delay: 0.0, options: options, animations: animationBlock,
                completion: { finished in
                    transitionContext.completeTransition(finished)
            })
        }
    }
}


extension CGRect {
    public func centeredRectWithSize(_ size: CGSize) -> CGRect {
        let origin = CGPoint(
            x: midX - (size.width / 2),
            y: midY - (size.height / 2)
        )
        
        return CGRect(origin: origin, size: size)
    }
}
