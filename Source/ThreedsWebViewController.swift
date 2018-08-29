import UIKit
import WebKit

/// A view controller to manage 3ds
public class ThreedsWebViewController: UIViewController,
    WKNavigationDelegate {

    // MARK: - Properties
    public var is_paypal = false
    
    var webView: WKWebView!
    let successUrl: String
    let failUrl: String

    /// Delegate
    public weak var delegate: ThreedsWebViewControllerDelegate?
    
    public var rightBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
    public var leftBarButtonItem = UIBarButtonItem(title: "للخلف", style: .done, target: self, action: #selector(onTapBackButton))

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
        if is_paypal{
            
            dismiss(animated: true, completion: nil)
        }
        else{
            self.navigationController?.popViewController(animated: true)
        }

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

        rightBarButtonItem.target = self
        rightBarButtonItem.action = nil
        navigationItem.rightBarButtonItem = leftBarButtonItem
        
        leftBarButtonItem.target = self
        leftBarButtonItem.action = #selector(onTapBackButton)
        navigationItem.leftBarButtonItem = rightBarButtonItem
        
        guard let authUrl = url else { return }
        let myURL = URL(string: authUrl)
        let myRequest = URLRequest(url: myURL!)
        webView.navigationDelegate = self
        webView.load(myRequest)
    }

    // MARK: - WKNavigationDelegate

    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
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
        
        if let url = webView.url{
            if url.absoluteString.contains("syarah.com"){
                
                webView.stopLoading()
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
           // self.dismiss(animated: true) {
                self.delegate?.onSuccess3D(token: token ?? "")
            self.navigationController?.popViewController(animated: true)

           // }
        } else if url.contains(failUrl) {
            // fail url, dismissing the page
            let token = getQueryStringParameter(url: absoluteUrl.absoluteString, param: "cko-payment-token")

            //self.dismiss(animated: true) {
                self.delegate?.onFailure3D(token: token ?? "")
            //}
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

}
