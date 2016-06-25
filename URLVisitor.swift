//
//  URLVisitor.swift
//  OKCapp_OSX_v1.0.0
//
//  Created by Stuart Kuredjian on 6/3/16.
//  Copyright © 2016 s.Ticky Games. All rights reserved.
//

import Cocoa

class URLVisitor: NSObject {
	private var accountManager = AccountManager()
	private var URL = NSURL()
	private var params = String()
	private var method = "GET"
	private var contentsOfURL = String()
	private var sessionCookies = [NSHTTPCookie]()
	private var statusCode = Int()
	private var urlProtocol = ""
	private var authorizationHeader = ""
	private var accessTokenIsSet = false
	private var isWatching = false
	private var isConnected = false
	
	func URLVisitor(accountManager: AccountManager) {
		self.accountManager = accountManager
	}
	
	func getURL() -> NSURL {
		return self.URL
	}
	
	func setURL(url: NSURL) {
		accessTokenIsSet = self.accountManager.getAccessTokenIsSet()
		if accessTokenIsSet {
			
		}
		
		self.URL = url
	}
	
	func execute() {
		
	}
	
	func getURLProtocol() -> String {
		return self.urlProtocol
	}
	
	func getStatusCode() -> Int {
		return self.statusCode
	}
	
	func getSessionCookies() -> [NSHTTPCookie] {
		return self.sessionCookies
	}
	
	func setSessionCookies(sessionCookies: [NSHTTPCookie]) {
		self.sessionCookies = sessionCookies
	}
	
	func setParams(params: String) {
		self.params = params
	}
	
	func setMethod(method: String) {
		self.method = method
	}
	
	func getContentsOfURL() -> String {
		return self.contentsOfURL
	}
	
	func getIsConnected(isConnected: Bool) {
		self.isConnected = isConnected
	}
	
	func setIsWatching(isWatching: Bool) {
		
	}
	
	func setAuthorizationHeader(authorizationHeader: String) {
		self.authorizationHeader = authorizationHeader
	}
}
