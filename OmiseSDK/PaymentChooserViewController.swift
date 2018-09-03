import UIKit
import os


protocol PaymentCreatorTrampolineDelegate: AnyObject {
    func paymentCreatorTrampoline(_ trampoline: PaymentCreatorTrampoline, isRequestedToHandleCreatedSource source: Source)
    func paymentCreatorTrampoline(_ trampoline: PaymentCreatorTrampoline, isRequestedToHandleError error: Error)
    func paymentCreatorTrampolineIsRequestedToCancel(_ trampoline: PaymentCreatorTrampoline)
}

class PaymentCreatorTrampoline {
    weak var delegate: PaymentCreatorTrampolineDelegate?
    func handleCreatedSource(_ source: Source) {
        delegate?.paymentCreatorTrampoline(self, isRequestedToHandleCreatedSource: source)
    }
    
    func handleFailedError(_ error: Error) {
        delegate?.paymentCreatorTrampoline(self, isRequestedToHandleError: error)
    }
    
    func requestToCancel() {
        delegate?.paymentCreatorTrampolineIsRequestedToCancel(self)
    }
    
}

protocol PaymentCreator {
    var coordinator: PaymentCreatorTrampoline? { get }
    var client: Client? { get }
}


public enum PaymentChooserOption: StaticElementIterable, Equatable {
    case creditCard
    case installment
    case internetBanking
    case tescoLotus
    case conbini
    case payEasy
    case netBanking
    case alipay
    
    public static var allCases: [PaymentChooserOption] {
        return [
            .creditCard,
            .installment,
            .internetBanking,
            .tescoLotus,
            .conbini,
            .payEasy,
            .netBanking,
            .alipay,
        ]
    }
}

public protocol PaymentChooserViewControllerDelegate: AnyObject {
    func paymentChooserViewController(_ paymentChooserViewController: PaymentChooserViewController,
                                            didCreateSource source: Source)
    func paymentChooserViewController(_ paymentChooserViewController: PaymentChooserViewController,
                                            didFailedToCreateSourceWithError error: Error)
    func paymentChooserViewControllerDidCancel(_ paymentChooserViewController: PaymentChooserViewController)
}


@objc(OMSPaymentChooserViewController)
public class PaymentChooserViewController: AdaptableStaticTableViewController<PaymentChooserOption>, PaymentCreator {
    
    /// Omise public key for calling tokenization API.
    @objc public var publicKey: String? {
        didSet {
            guard let publicKey = publicKey else {
                if #available(iOS 10.0, *) {
                    os_log("Missing or invalid public key information - %{private}@", log: uiLogObject, type: .error, self.publicKey ?? "")
                }
                assertionFailure("Missing public key information. Please setting the public key before request token.")
                return
            }
            
            self.client = Client(publicKey: publicKey)
        }
    }
    
    var client: Client?
    
    let coordinator: PaymentCreatorTrampoline? = PaymentCreatorTrampoline()
    
    weak var delegate: PaymentChooserViewControllerDelegate?
    
    @objc public var showsCreditCardPayment: Bool = true
    @objc public var allowedPaymentMethods: [OMSSourceTypeValue] = PaymentChooserViewController.defaultAvailablePaymentMethods {
        didSet {
            showingValues = PaymentChooserOption.allCases.filter({
                switch $0 {
                case .creditCard:
                    return showsCreditCardPayment
                case .installment:
                    return allowedPaymentMethods.hasInstallmentSource
                case .internetBanking:
                    return allowedPaymentMethods.hasInternetBankingSource
                case .tescoLotus:
                    return allowedPaymentMethods.hasTescoLotusSource
                case .conbini, .payEasy, .netBanking:
                    return allowedPaymentMethods.hasEContextSource
                case .alipay:
                    return allowedPaymentMethods.hasAlipaySource
                }
            })
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        coordinator?.delegate = self
        
        showingValues = PaymentChooserOption.allCases.filter({
            switch $0 {
            case .creditCard:
                return showsCreditCardPayment
            case .installment:
                return allowedPaymentMethods.hasInstallmentSource
            case .internetBanking:
                return allowedPaymentMethods.hasInternetBankingSource
            case .tescoLotus:
                return allowedPaymentMethods.hasTescoLotusSource
            case .conbini, .payEasy, .netBanking:
                return allowedPaymentMethods.hasEContextSource
            case .alipay:
                return allowedPaymentMethods.hasAlipaySource
            }
        })
    }
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier, segue.destination) {
        case ("GoToInternetBankingChooserSegue"?, let controller as InternetBankingSourceChooserViewController):
            controller.showingValues = allowedPaymentMethods.compactMap({ $0.internetBankingSource })
            controller.coordinator = self.coordinator
        case ("GoToInstallmentBrandChooserSegue"?, let controller as InstallmentBankingSourceChooserViewController):
            controller.showingValues = allowedPaymentMethods.compactMap({ $0.installmentBrand })
            controller.coordinator = self.coordinator
        case (_, let controller as EContextInformationInputViewController):
            controller.coordinator = self.coordinator
        default:
            break
        }
        
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch element(forUIIndexPath: indexPath) {
        case .alipay:
            break
        case .tescoLotus:
            break
        default:
            super.tableView(tableView, didSelectRowAt: indexPath)
        }
    }
    
    public override func staticIndexPath(forValue value: PaymentChooserOption) -> IndexPath {
        switch value {
        case .creditCard:
            return IndexPath(row: 0, section: 0)
        case .installment:
            return IndexPath(row: 1, section: 0)
        case .internetBanking:
            return IndexPath(row: 2, section: 0)
        case .tescoLotus:
            return IndexPath(row: 3, section: 0)
        case .conbini:
            return IndexPath(row: 4, section: 0)
        case .payEasy:
            return IndexPath(row: 5, section: 0)
        case .netBanking:
            return IndexPath(row: 6, section: 0)
        case .alipay:
            return IndexPath(row: 7, section: 0)
        }
    }
    
}

extension PaymentChooserViewController: PaymentCreatorTrampolineDelegate {
    func paymentCreatorTrampoline(_ trampoline: PaymentCreatorTrampoline, isRequestedToHandleCreatedSource source: Source) {
        delegate?.paymentChooserViewController(self, didCreateSource: source)
    }
    
    func paymentCreatorTrampoline(_ trampoline: PaymentCreatorTrampoline, isRequestedToHandleError error: Error) {
        delegate?.paymentChooserViewController(self, didFailedToCreateSourceWithError: error)
    }
    
    func paymentCreatorTrampolineIsRequestedToCancel(_ trampoline: PaymentCreatorTrampoline) {
        delegate?.paymentChooserViewControllerDidCancel(self)
    }
    
}


extension Array where Element == OMSSourceTypeValue {
    public var hasInternetBankingSource: Bool {
        return self.contains(where: { $0.isInternetBankingSource })
    }
    
    public var hasInstallmentSource: Bool {
        return self.contains(where: { $0.isInstallmentSource })
    }
    
    public var hasTescoLotusSource: Bool {
        return self.contains(.billPaymentTescoLotus)
    }
    
    public var hasAlipaySource: Bool {
        return self.contains(.alipay)
    }
    
    public var hasEContextSource: Bool {
        return self.contains(.eContext)
    }
}


extension PaymentChooserViewController {
    public static let defaultAvailablePaymentMethods: [OMSSourceTypeValue] = [
        .internetBankingBAY,
        .internetBankingKTB,
        .internetBankingSCB,
        .internetBankingBBL,
        .alipay,
        .billPaymentTescoLotus,
        .installmentBAY,
        .installmentFirstChoice,
        .installmentBBL,
        .installmentKTC,
        .installmentKBank,
    ]
    
    public static let internetBankingAvailablePaymentMethods: [OMSSourceTypeValue] = [
        .internetBankingBAY,
        .internetBankingKTB,
        .internetBankingSCB,
        .internetBankingBBL,
    ]
    
    public static let installmentsBankingAvailablePaymentMethods: [OMSSourceTypeValue] = [
        .installmentBAY,
        .installmentFirstChoice,
        .installmentBBL,
        .installmentKTC,
        .installmentKBank,
    ]
    
    public static let billPaymentAvailablePaymentMethods: [OMSSourceTypeValue] = [
        .billPaymentTescoLotus,
    ]
    
    public static let barcodeAvailablePaymentMethods: [OMSSourceTypeValue] = [
        .barcodeAlipay,
    ]
}


extension OMSSourceTypeValue {
    
    var installmentBrand: PaymentInformation.Installment.Brand? {
        switch self {
        case .installmentBAY:
            return .bay
        case .installmentFirstChoice:
            return .firstChoice
        case .installmentBBL:
            return .bbl
        case .installmentKTC:
            return .ktc
        case .installmentKBank:
            return .kBank
        default:
            return nil
        }
    }
    
    var isInstallmentSource: Bool {
        switch self {
        case .installmentBAY, .installmentFirstChoice, .installmentBBL, .installmentKTC, .installmentKBank:
            return true
        default:
            return false
        }

    }
    
    var internetBankingSource: PaymentInformation.InternetBanking? {
        switch self {
        case .internetBankingBAY:
            return .bay
        case .internetBankingKTB:
            return .ktb
        case .internetBankingSCB:
            return .scb
        case .internetBankingBBL:
            return .bbl
        default:
            return nil
        }
    }
    
    var isInternetBankingSource: Bool {
        switch self {
        case .internetBankingBAY, .internetBankingKTB, .internetBankingSCB, .internetBankingBBL:
            return true
        default:
            return false
        }
    }
}


