import Foundation
import UIKit

/// A view controller that allows the user to enter card information.
open class CardViewController: UIViewController,
    AddressViewControllerDelegate,
    CardNumberInputViewDelegate,
    CvvInputViewDelegate,
    UITextFieldDelegate {

    // MARK: - Properties

    /// Card View
    public let cardView: CardView
    let cardUtils = CardUtils()

    let cardHolderNameState: InputState
    let billingDetailsState: InputState

    var billingDetailsAddress: CkoAddress?
    var notificationCenter = NotificationCenter.default
    let addressViewController = AddressViewController()

    /// List of available schemes
    public var availableSchemes: [CardScheme] = [.visa, .mastercard, .americanExpress,
                                                 .dinersClub, .discover, .jcb, .unionPay]

    /// Delegate
    public weak var delegate: CardViewControllerDelegate?

    // Scheme Icons
    private var lastSelected: UIImageView?

    /// Right bar button item
    public var rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                    target: self,
                                                    action: #selector(onTapDoneCardButton))
    public var leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                    target: self,
                                                    action: #selector(onTapBackButton))

    // MARK: - Initialization

    /// Returns a newly initialized view controller with the cardholder's name and billing details
    /// state specified.
    public init(cardHolderNameState: InputState, billingDetailsState: InputState) {
        self.cardHolderNameState = cardHolderNameState
        self.billingDetailsState = billingDetailsState
        cardView = CardView(cardHolderNameState: cardHolderNameState, billingDetailsState: billingDetailsState)
        super.init(nibName: nil, bundle: nil)
    }

    /// Returns a newly initialized view controller with the nib file in the specified bundle.
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        cardHolderNameState = .required
        billingDetailsState = .required
        cardView = CardView(cardHolderNameState: cardHolderNameState, billingDetailsState: billingDetailsState)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    /// Returns an object initialized from data in a given unarchiver.
    required public init?(coder aDecoder: NSCoder) {
        cardHolderNameState = .required
        billingDetailsState = .required
        cardView = CardView(cardHolderNameState: cardHolderNameState, billingDetailsState: billingDetailsState)
        super.init(coder: aDecoder)
    }

    // MARK: - Lifecycle

    /// Called after the controller's view is loaded into memory.
    override open func viewDidLoad() {
        super.viewDidLoad()
        rightBarButtonItem.target = self
        rightBarButtonItem.action = #selector(onTapDoneCardButton)
        navigationItem.rightBarButtonItem = leftBarButtonItem
        
        leftBarButtonItem.target = self
        leftBarButtonItem.action = #selector(onTapBackButton)
        navigationItem.leftBarButtonItem = rightBarButtonItem
        navigationItem.leftBarButtonItem?.isEnabled = false

        // add gesture recognizer
        cardView.addressTapGesture.addTarget(self, action: #selector(onTapAddressView))
        cardView.billingDetailsInputView.addGestureRecognizer(cardView.addressTapGesture)

        addressViewController.delegate = self
        addTextFieldsDelegate()

        // add schemes icons
        view.backgroundColor = .groupTableViewBackground
        cardView.schemeIconsStackView.setIcons(schemes: availableSchemes)
        setInitialDate()
    }

    /// Notifies the view controller that its view is about to be added to a view hierarchy.
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "cardViewControllerTitle".localized(forClass: CardViewController.self)
        registerKeyboardHandlers(notificationCenter: notificationCenter,
                                 keyboardWillShow: #selector(keyboardWillShow),
                                 keyboardWillHide: #selector(keyboardWillHide))
    }

    /// Notifies the view controller that its view is about to be removed from a view hierarchy.
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterKeyboardHandlers(notificationCenter: notificationCenter)
    }

    /// Called to notify the view controller that its view has just laid out its subviews.
    open override func viewDidLayoutSubviews() {
        view.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.leftAnchor.constraint(equalTo: view.safeLeftAnchor).isActive = true
        cardView.rightAnchor.constraint(equalTo: view.safeRightAnchor).isActive = true
        cardView.topAnchor.constraint(equalTo: view.safeTopAnchor).isActive = true
        cardView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor).isActive = true
    }

    private func setInitialDate() {
        
        //let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        //let components = calendar.dateComponents([.year], from: Date())
        
        let calendar = Calendar(identifier: .gregorian)
        let date = Date()
        
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let monthString = month < 10 ? "0\(month)" : "\(month)"
        cardView.expirationDateInputView.textField.text = "\(monthString)/\(year)"
    }

    @objc func onTapAddressView() {
        navigationController?.pushViewController(addressViewController, animated: true)
    }
    
    @objc func onTapBackButton() {

        dismiss(animated: true, completion: nil)
    }

    @objc func onTapDoneCardButton() {
        // Get the values
        let cardNumber = cardView.cardNumberInputView.textField.text!
        let expirationDate = cardView.expirationDateInputView.textField.text!
        let cvv = cardView.cvvInputView.textField.text!

        let cardNumberStandardized = cardUtils.standardize(cardNumber: cardNumber)
        // Validate the values
        guard
            let cardType = cardUtils.getTypeOf(cardNumber: cardNumberStandardized)
            else { return }
        let (expiryMonth, expiryYear) = cardUtils.standardize(expirationDate: expirationDate)
        // card number invalid
        let isCardNumberValid = cardUtils.isValid(cardNumber: cardNumberStandardized, cardType: cardType)
        let isExpirationDateValid = cardUtils.isValid(expirationMonth: expiryMonth, expirationYear: expiryYear)
        let isCvvValid = cardUtils.isValid(cvv: cvv, cardType: cardType)
        let isCardTypeValid = availableSchemes.contains(where: { cardType.scheme == $0 })

        // check if the card type is amongst the valid ones
        if !isCardTypeValid {
            let message = "cardTypeNotAccepted".localized(forClass: CardViewController.self)
            cardView.cardNumberInputView.showError(message: message)
        } else if !isCardNumberValid {
            let message = "cardNumberInvalid".localized(forClass: CardViewController.self)
            cardView.cardNumberInputView.showError(message: message)
        }
        if !isCvvValid {
            let message = "cvvInvalid".localized(forClass: CardViewController.self)
            cardView.cvvInputView.showError(message: message)
        }
        if !isCardNumberValid || !isExpirationDateValid || !isCvvValid || !isCardTypeValid { return }

        let card = CkoCardTokenRequest(number: cardNumberStandardized,
                                    expiryMonth: expiryMonth,
                                    expiryYear: expiryYear,
                                    cvv: cvv,
                                    name: cardView.cardHolderNameInputView.textField.text,
                                    billingAddress: billingDetailsAddress)
        self.delegate?.onTapDone(controller: self, card: card)
    }

    // MARK: - AddressViewControllerDelegate

    /// Executed when an user tap on the done button.
    public func onTapDoneButton(controller: AddressViewController, address: CkoAddress) {
        billingDetailsAddress = address
        let value = "\(address.addressLine1 ?? ""), \(address.city ?? "")"
        cardView.billingDetailsInputView.value.text = value
        validateFieldsValues()
        // return to CardViewController
        controller.navigationController?.popViewController(animated: true)
    }

    private func addTextFieldsDelegate() {
        cardView.cardNumberInputView.delegate = self
        cardView.cardHolderNameInputView.textField.delegate = self
        cardView.expirationDateInputView.textField.delegate = self
        cardView.cvvInputView.delegate = self
        cardView.cvvInputView.onChangeDelegate = self
    }

    private func validateFieldsValues() {
        let cardNumber = cardView.cardNumberInputView.textField.text!
        let expirationDate = cardView.expirationDateInputView.textField.text!
        let cvv = cardView.cvvInputView.textField.text!

        // check card holder's name
        if cardHolderNameState == .required && (cardView.cardHolderNameInputView.textField.text?.isEmpty)! {
            navigationItem.leftBarButtonItem?.isEnabled = false
            return
        }
        // check billing details
        if billingDetailsState == .required && billingDetailsAddress == nil {
            navigationItem.leftBarButtonItem?.isEnabled = false
            return
        }
        // values are not empty strings
        if cardNumber.isEmpty || expirationDate.isEmpty ||
            cvv.isEmpty {
            navigationItem.leftBarButtonItem?.isEnabled = false
            return
        }
        navigationItem.leftBarButtonItem?.isEnabled = true
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        scrollViewOnKeyboardWillShow(notification: notification, scrollView: cardView.scrollView, activeField: nil)
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        scrollViewOnKeyboardWillHide(notification: notification, scrollView: cardView.scrollView)
    }

    // MARK: - UITextFieldDelegate

    /// Tells the delegate that editing stopped for the specified text field.
    public func textFieldDidEndEditing(_ textField: UITextField) {
        validateFieldsValues()
    }

    /// Tells the delegate that editing stopped for the textfield in the specified view.
    public func textFieldDidEndEditing(view: UIView) {
        validateFieldsValues()

        if let superView = view as? CardNumberInputView {
            let cardNumber = superView.textField.text!
            let cardNumberStandardized = cardUtils.standardize(cardNumber: cardNumber)
            let cardType = cardUtils.getTypeOf(cardNumber: cardNumberStandardized)
            cardView.cvvInputView.cardType = cardType
        }
    }

    // MARK: - CardNumberInputViewDelegate

    /// Called when the card number changed.
    public func onChangeCardNumber(cardType: CardType?) {
        // reset if the card number is empty
        if cardType == nil && lastSelected != nil {
            cardView.schemeIconsStackView.arrangedSubviews.forEach { $0.alpha = 1 }
            lastSelected = nil
        }
        guard let type = cardType else { return }
        let index = availableSchemes.index(of: type.scheme)
        guard let indexScheme = index else { return }
        let imageView = cardView.schemeIconsStackView.arrangedSubviews[indexScheme] as? UIImageView

        if lastSelected == nil {
            cardView.schemeIconsStackView.arrangedSubviews.forEach { $0.alpha = 0.5 }
            imageView?.alpha = 1
            lastSelected = imageView
        } else {
            lastSelected!.alpha = 0.5
            imageView?.alpha = 1
            lastSelected = imageView
        }
    }

    // MARK: CvvInputViewDelegate

    public func onChangeCvv() {
        validateFieldsValues()
    }

}
