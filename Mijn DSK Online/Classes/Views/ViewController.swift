//
//  ViewController.swift
//  Mijn DSK Online
//
//  Created by Lloyd Keijzer on 21/01/2019.
//  Copyright © 2019 Lloyd Keijzer. All rights reserved.
//

import UIKit
import WebKit

final class ViewController: UIViewController {

    enum FailReason {
        case invalidUrl
        case pageDoesNotExist
        case couldNotLoadPage
        
        var message: String {
            switch self {
            case .invalidUrl:
                return "TODO: localized invalid url message here"
            case .pageDoesNotExist:
                return "TODO: localized page does not exist message here"
            case .couldNotLoadPage:
                return "TODO: localized could not load page message here"
            }
        }
    }
    
    @IBOutlet private weak var mainWebview: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainWebView()
        load(string: "https://mijn.dskonline.nl")
    }
    
    func load(url: URL) {
        mainWebview.load(URLRequest(url: url))
    }
    
    func load(string: String) {
        guard let url = URL(string: string) else {
            print("didFail: \(string), \(FailReason.invalidUrl.message)")
            return
        }
        load(url: url)
    }
}

private extension ViewController {
    
    func setupMainWebView() {
        mainWebview.allowsBackForwardNavigationGestures = true
        mainWebview.navigationDelegate = self
        mainWebview.scrollView.delegate = self
    }
    
    
}

extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        guard
            let response = navigationResponse.response as? HTTPURLResponse,
            let url = navigationResponse.response.url
        else {
            decisionHandler(.cancel)
            return
        }
        
        if let headerFields = response.allHeaderFields as? [String: String] {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            cookies.forEach { (cookie) in
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else { return }
        print("DOM is loaded: \(url.absoluteString)")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard let url = webView.url?.absoluteString else { return }
        print("didFail: \(url), \(FailReason.couldNotLoadPage.message)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard let url = webView.url?.absoluteString else { return }
        print("didFail: \(url), \(FailReason.pageDoesNotExist.message)")
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}

extension ViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.decelerationRate = .normal
    }
}
