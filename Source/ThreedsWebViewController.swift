import UIKit
import WebKit

/// A view controller to manage 3ds
public class ThreedsWebViewController: UIViewController,
    WKNavigationDelegate {

    // MARK: - Properties
    //public var is_paypal = false
    
    var webView: WKWebView!
    let successUrl: String
    let failUrl: String

    /// Delegate
    public weak var delegate: ThreedsWebViewControllerDelegate?
    
    public var leftBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
    public var rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_back"), style: .done, target: self, action: #selector(onTapBackButton))

    /// Url
    public var url: String?

    // MARK: - Initialization

    /// Initializes a web view controller adapted to handle 3dsecure.
    public init(successUrl: String, failUrl: String) {
        self.successUrl = successUrl
        self.failUrl = failUrl
        super.init(nibName: nil, bundle: nil)
    }

    /// Returns a newly initialized view controller with the nib file in the specified bundle.
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        successUrl = ""
        failUrl = ""
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    /// Returns an object initialized from data in a given unarchiver.
    required public init?(coder aDecoder: NSCoder) {
        successUrl = ""
        failUrl = ""
        super.init(coder: aDecoder)
    }
    
    @objc func onTapBackButton() {
       // if is_paypal{
        
        self.dismiss(animated: false) {
            self.delegate?.onCancel()
        }
       // }
       // else{
       //     self.navigationController?.popViewController(animated: true)
       // }

    }


    // MARK: - Lifecycle

    /// Creates the view that the controller manages.
    public override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        view = webView
    }

    /// Called after the controller's view is loaded into memory.
    public override func viewDidLoad() {
        super.viewDidLoad()

        
        rightBarButtonItem.tintColor = UIColor.hexColor(hex: "#004AB1")
        rightBarButtonItem.target = self
        rightBarButtonItem.action = #selector(onTapBackButton)
        navigationItem.leftBarButtonItem = rightBarButtonItem
        
        leftBarButtonItem.target = self
        leftBarButtonItem.action = nil
        navigationItem.rightBarButtonItem = leftBarButtonItem
        
        guard let authUrl = url else { return }
        let myURL = URL(string: authUrl)
        let myRequest = URLRequest(url: myURL!)
        webView.navigationDelegate = self
        webView.load(myRequest)
    }

    // MARK: - WKNavigationDelegate

    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        
        self.navigationController?.title = "الرجاء الانتظار..."

        return true
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Start to load")
        //Util.CustomMBProgressHUDShow(view: self.view)
        self.title = "الرجاء الانتظار..."
        
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("finish to load")
        self.title = ""

    }
    
    /// Called when the web view begins to receive web content.
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        shouldDismiss(absoluteUrl: webView.url!)
    }

    /// Called when a web view receives a server redirect.
    public func webView(_ webView: WKWebView,
                        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        
        var url_str:URL? = nil
        if let url = webView.url{
            if url.absoluteString.contains("syarah.com") || url.absoluteString.contains("syarahonline.com"){
                
                url_str = url
                shouldDismiss(absoluteUrl: url_str!)
                webView.stopLoading()
                return
            }
        }
        // stop the redirection
        
        shouldDismiss(absoluteUrl: webView.url!)
    }

    private func shouldDismiss(absoluteUrl: URL) {
        // get URL conforming to RFC 1808 without the query
        let url = "\(absoluteUrl.scheme ?? "https")://\(absoluteUrl.host ?? "localhost")\(absoluteUrl.path)"

        if url.contains(successUrl) {
            
            let token = getQueryStringParameter(url: absoluteUrl.absoluteString, param: "cko-payment-token")
            // success url, dismissing the page with the payment token
            self.dismiss(animated: true) {
                self.delegate?.onSuccess3D(token: token ?? "")
            //self.navigationController?.popViewController(animated: true)

            }
        } else if url.contains(failUrl) {
            // fail url, dismissing the page
            let token = getQueryStringParameter(url: absoluteUrl.absoluteString, param: "cko-payment-token")

            self.dismiss(animated: true) {
                self.delegate?.onFailure3D(token: token ?? "")
            }
            //self.navigationController?.popViewController(animated: true)
        }
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

}


extension UIColor {
    class func hexColor(hex: String)-> UIColor {
        var cString = hex.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString = cString.substring(from: cString.index(cString.startIndex, offsetBy: 1))
        }
        
        if (cString.count != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
