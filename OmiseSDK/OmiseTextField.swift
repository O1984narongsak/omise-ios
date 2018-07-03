import Foundation
import UIKit


/// Delegate for receiving SDK-specific text field events.
public protocol OmiseTextFieldValidationDelegate {
    /// A delegate method that will be called when the data validity of the text field is changed.
    func textField(_ field: OmiseTextField, didChangeValidity isValid: Bool)
}


/// Base UITextField subclass for SDK's text fields.
@objc public class OmiseTextField: UITextField {
    
    @IBInspectable @objc var errorTextColor: UIColor! = CreditCardFormViewController.defaultErrorMessageTextColor {
        didSet {
            if errorTextColor == nil {
                errorTextColor = CreditCardFormViewController.defaultErrorMessageTextColor
            }
            updateTextColor()
        }
    }
    
    private var normalTextColor: UIColor?
    
    public override var text: String? {
        didSet {
            // UITextField doesn't send editing changed control event when we set its text property
            textDidChange()
            updateTextColor()
        }
    }
    
    public override var textColor: UIColor? {
        get {
            return normalTextColor
        }
        set {
            normalTextColor = newValue
            updateTextColor()
        }
    }
    
    private func updateTextColor() {
        super.textColor = isValid || isFirstResponder ? normalTextColor ?? .black : errorTextColor;
    }
    
    /// Boolean indicating wether current input is valid or not.
    public var isValid: Bool {
        return true
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initializeInstance()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeInstance()
    }
    
    init() {
        super.init(frame: CGRect.zero)
        initializeInstance()
    }
    
    private func initializeInstance() {
        normalTextColor = super.textColor
        
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        addTarget(self, action: #selector(didBeginEditing), for: .editingDidBegin)
        addTarget(self, action: #selector(didEndEditing), for: .editingDidEnd)
    }
    
    @objc func didBeginEditing() {
        updateTextColor()
    }
    
    @objc func didEndEditing() {
        updateTextColor()
    }
    
    @objc func textDidChange() {}
}
