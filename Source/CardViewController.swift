import Foundation
import UIKit

/// A view controller that allows the user to enter card information.
public class CardViewController: UIViewController,
    AddressViewControllerDelegate,
    CardNumberInputViewDelegate,
    CvvInputViewDelegate,
    UITextFieldDelegate {

    // MARK: - Properties

    /// Card View
    public let cardView: CardView
    let cardUtils = CardUtils()
    public let payButton = UIButton()

    public let checkoutApiClient: CheckoutAPIClient?

    let cardHolderNameState: InputState
    let billingDetailsState: InputState

    public var billingDetailsAddress: CkoAddress?
    public var billingDetailsPhone: CkoPhoneNumber?
    var notificationCenter = NotificationCenter.default
    public let addressViewController: AddressViewController

    /// List of available schemes
    public var availableSchemes: [CardScheme] = [.visa, .mastercard, .americanExpress,
                                                 .dinersClub, .discover, .jcb, .unionPay]

    /// Delegate
    public weak var delegate: CardViewControllerDelegate?

    // Scheme Icons
    private var lastSelected: UIImageView?

    /// Right bar button item
    public var leftBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)//UIBarButtonItem(barButtonSystemItem: .save,
                                                     // target: self,
                                                     // action: #selector(onTapDoneCardButton))
    
    public var rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_back"), style: .done, target: CardViewController.self, action: #selector(onTapBackButton))
    
    
    var topConstraint: NSLayoutConstraint?

    // MARK: - Initialization

    /// Returns a newly initialized view controller with the cardholder's name and billing details
    /// state specified. You can specified the region using the Iso2 region code ("UK" for "United Kingdom")
    public init(checkoutApiClient: CheckoutAPIClient, cardHolderNameState: InputState,
                billingDetailsState: InputState, defaultRegionCode: String? = nil) {
        self.checkoutApiClient = checkoutApiClient
        self.cardHolderNameState = cardHolderNameState
        self.billingDetailsState = billingDetailsState
        cardView = CardView(cardHolderNameState: cardHolderNameState, billingDetailsState: billingDetailsState)
        addressViewController = AddressViewController(initialCountry: "you", initialRegionCode: defaultRegionCode)
        super.init(nibName: nil, bundle: nil)
    }

    /// Returns a newly initialized view controller with the nib file in the specified bundle.
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        cardHolderNameState = .required
        billingDetailsState = .required
        cardView = CardView(cardHolderNameState: cardHolderNameState, billingDetailsState: billingDetailsState)
        addressViewController = AddressViewController()
        checkoutApiClient = nil
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    /// Returns an object initialized from data in a given unarchiver.
    required public init?(coder aDecoder: NSCoder) {
        cardHolderNameState = .required
        billingDetailsState = .required
        cardView = CardView(cardHolderNameState: cardHolderNameState, billingDetailsState: billingDetailsState)
        addressViewController = AddressViewController()
        checkoutApiClient = nil
        super.init(coder: aDecoder)
    }

    // MARK: - Lifecycle

    /// Called after the controller's view is loaded into memory.
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        payButton.backgroundColor = UIColor.hexColor(hex: "#00B362")
        payButton.setTitle("buttonPayGo".localized(forClass: CardViewController.self), for: .normal)
        payButton.setTitleColor(.white, for: .normal)
        payButton.titleLabel?.font = UIFont.systemFont(ofSize: 16,weight: .bold)
        payButton.addTarget(self, action: #selector(onTapDoneCardButton), for: .touchUpInside)
        payButton.layer.cornerRadius = 4
        self.payButton.isEnabled = false
        self.payButton.alpha = 0.5
        view.addSubview(payButton)

        rightBarButtonItem.tintColor = UIColor.hexColor(hex: "#004AB1")
        rightBarButtonItem.target = self
        rightBarButtonItem.action = #selector(onTapBackButton)
        navigationItem.leftBarButtonItem = rightBarButtonItem
        //leftBarButtonItem.target = self
        //leftBarButtonItem.tintColor = UIColor.hexColor(hex: "#004AB1")
        //leftBarButtonItem.action = #selector(onTapDoneCardButton)
        navigationItem.rightBarButtonItem = leftBarButtonItem
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        
    
        // add gesture recognizer
        cardView.addressTapGesture.addTarget(self, action: #selector(onTapAddressView))
        cardView.billingDetailsInputView.addGestureRecognizer(cardView.addressTapGesture)

        addressViewController.delegate = self
        addTextFieldsDelegate()

        // add schemes icons
        view.backgroundColor = .groupTableViewBackground
        cardView.schemeIconsStackView.setIcons(schemes: availableSchemes)
        setInitialDate()

        self.automaticallyAdjustsScrollViewInsets = false
        
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            //navigationController?.navigationBar.compactAppearance
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
            navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
        }

    }

    /// Notifies the view controller that its view is about to be added to a view hierarchy.
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "cardViewControllerTitle".localized(forClass: CardViewController.self)
        registerKeyboardHandlers(notificationCenter: notificationCenter,
                                 keyboardWillShow: #selector(keyboardWillShow),
                                 keyboardWillHide: #selector(keyboardWillHide))
    }

    /// Notifies the view controller that its view is about to be removed from a view hierarchy.
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterKeyboardHandlers(notificationCenter: notificationCenter)
    }

    /// Called to notify the view controller that its view has just laid out its subviews.
    public override func viewDidLayoutSubviews() {
        view.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.leftAnchor.constraint(equalTo: view.safeLeftAnchor).isActive = true
        cardView.rightAnchor.constraint(equalTo: view.safeRightAnchor).isActive = true

        self.topConstraint = cardView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor)
        if #available(iOS 11.0, *) {
            cardView.topAnchor.constraint(equalTo: view.safeTopAnchor).isActive = true
        } else {
            self.topConstraint?.isActive = true
        }
        cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        if #available(iOS 11.0, *) {} else {
            cardView.scrollView.contentSize = CGSize(width: self.view.frame.width,
                                                        height: self.view.frame.height + 10)
        }
        
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.leftAnchor.constraint(equalTo: view.safeLeftAnchor,constant: 24).isActive = true
        payButton.rightAnchor.constraint(equalTo: view.safeRightAnchor,constant: -24).isActive = true
        payButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        if #available(iOS 11.0, *) {
            payButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor,constant: -40).isActive = true
        } else {
            payButton.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor,constant: -40).isActive = true
        }
        self.view.bringSubviewToFront(payButton)

        
    }

    /// MARK: Methods
    public func setDefault(regionCode: String) {
        addressViewController.regionCodeSelected = regionCode
    }

    private func setInitialDate() {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date()
        let month = calendar.component(.month, from: date)
        let year = String(calendar.component(.year, from: date))
        let monthString = month < 10 ? "0\(month)" : "\(month)"
        cardView.expirationDateInputView.textField.text =
            "\(monthString)/\(year.substring(with: NSRange(location: 2, length: 2)))"
    }

    @objc func onTapAddressView() {
        navigationController?.pushViewController(addressViewController, animated: true)
    }

    @objc func onTapDoneCardButton() {
        
        payButton.isEnabled = false
        payButton.alpha = 0.5
        leftBarButtonItem.isEnabled = false
        // Get the values
        let cardNumber = convert(toEnglishNumber: cardView.cardNumberInputView.textField.text!)
        let expirationDate = cardView.expirationDateInputView.textField.text!
        let cvv = convert(toEnglishNumber: cardView.cvvInputView.textField.text!)

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
        if !isCardNumberValid || !isExpirationDateValid || !isCvvValid || !isCardTypeValid {
            
            payButton.isEnabled = true
            leftBarButtonItem.isEnabled = true
            payButton.alpha = 1.0
            return
            
        }

        let card = CkoCardTokenRequest(number: cardNumberStandardized,
                                       expiryMonth: expiryMonth,
                                       expiryYear: expiryYear,
                                       cvv: cvv,
                                       name: cardView.cardHolderNameInputView.textField.text,
                                       billingAddress: billingDetailsAddress,
                                       phone: billingDetailsPhone)
        if let checkoutApiClientUnwrap = checkoutApiClient {
            self.delegate?.onSubmit(controller: self)
            checkoutApiClientUnwrap.createCardToken(card: card, successHandler: { cardToken in
                self.leftBarButtonItem.isEnabled = true
                self.payButton.isEnabled = true
                self.payButton.alpha = 1.0
                self.delegate?.onTapDone(controller: self, cardToken: cardToken, status: .success)
            }, errorHandler: { _ in
                self.leftBarButtonItem.isEnabled = true
                self.payButton.isEnabled = true
                self.payButton.alpha = 1.0
                self.delegate?.onTapDone(controller: self, cardToken: nil, status: .success)
            })
        }
    }

    // MARK: - AddressViewControllerDelegate

    /// Executed when an user tap on the done button.
    public func onTapDoneButton(controller: AddressViewController, address: CkoAddress, phone: CkoPhoneNumber) {
        billingDetailsAddress = address
        let value = "\(address.addressLine1 ?? ""), \(address.city ?? "")"
        cardView.billingDetailsInputView.value.text = value
        validateFieldsValues()
        // return to CardViewController
        self.topConstraint?.isActive = false
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
            navigationItem.rightBarButtonItem?.isEnabled = false
            self.payButton.isEnabled = false
            self.payButton.alpha = 0.5
            return
        }
        // check billing details
        if billingDetailsState == .required && billingDetailsAddress == nil {
            navigationItem.rightBarButtonItem?.isEnabled = false
            self.payButton.isEnabled = false
            self.payButton.alpha = 0.5
            return
        }
        // values are not empty strings
        if cardNumber.isEmpty || expirationDate.isEmpty ||
            cvv.isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
            self.payButton.isEnabled = false
            self.payButton.alpha = 0.5
            return
        }
        navigationItem.rightBarButtonItem?.isEnabled = true
        self.payButton.isEnabled = true
        self.payButton.alpha = 1.0
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
        let index = availableSchemes.firstIndex(of: type.scheme)
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

    func convert(toEnglishNumber: String) -> String {
        let formatter = NumberFormatter()
        var st = toEnglishNumber
        formatter.locale = Locale(identifier: "ar")
        //let count = toEnglishNumber.characters.count
        
        for i in 0..<10 {
            let num = i
            st = st.replacingOccurrences(of: formatter.string(from: NSNumber.init(value: num))!, with: String(num))
        }
        return st

    }
    
    @objc func onTapBackButton() {

           dismiss(animated: true, completion: nil)
    }

}
