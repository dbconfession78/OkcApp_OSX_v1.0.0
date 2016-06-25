//
//  AccountManager.swift
//  OKCapp_OSX_v1.0.0
//
//  Created by Stuart Kuredjian on 6/3/16.
//  Copyright © 2016 s.Ticky Games. All rights reserved.
//

import Cocoa

class AccountManager: NSObject {
	//	private ProxyManager proxyManager
	//	private Preferences _prefs
	//	private Thread loginThread
	//	private Thread deleteInboxThread
	//	private Boolean isUsingAlt = false
	
	public var urlVisitor = URLVisitor()
	public var viewController = ViewController()

	public var index = Int()
	private var username = String()
	private var account = String()
	private var accessToken = String()
	private var contentsOfURL = String()
	private var locId = String()
	private var sessionCookies = [NSHTTPCookie]()
	private var urlProtocol = String()
	private var covertSkypeText = String()
	private var skypeID = String()
	private var visitorCount = String()
	
	private var isLoggedIn = false
	private var lastRunCompleted = true
	private var accessTokenIsSet = false
	private var isRefreshing = false
	private var isDeletingInbox = false
	private var isRunning = false
	private var isUnhiding = false
	private var isLogging = false
	private var isHiding = false
	
	public var loginSettingsDict = NSDictionary()
	private var searchSettingsDict = NSDictionary()
	private var runStateDict = NSDictionary()
	private var watchedProfiles = [String]()
	private var bannedProfiles = [String]()
	private var closedProfiles = [String]()
	
	private func onLoad() {
		
	}
	
	public func getAccessTokenIsSet() -> Bool {
		return self.accessTokenIsSet
	}
	
	public func login(userName: String) {
		
	}
	
	public func fetchNewVistors() -> [String] {
		var newVisitors = [String]()
		
		return newVisitors
	}
	
	func parseAccessToken() -> String {
		var accessToken = ""
		
		return accessToken
	}
	
	func getSessionCookies() -> [NSHTTPCookie] {
		return self.sessionCookies
	}
	
	func setProxySettings() {
		
	}
	
	func logout() {
		
	}
	
	func getUsername() -> String{
		return self.username
	}
	
	
	func getAccountManager() -> AccountManager {
		return self
	}
	
	func getAccessToken() -> String {
		return self.accessToken
	}
	
	func deleteInbox() {
		
	}
	
	func parseMessageIds() -> [String] {
		var messageIds = [String]()
		
		return messageIds
	}
	
	func parseMessageCount() {
		
	}
	
	func getIsLoggedIn() -> Bool {
		return self.isLoggedIn
	}
	
	func fetchBannedProfiles() -> [String] {
		return self.bannedProfiles
	}
	
	func writeBannedProfileToFile(profile: String, bannedTime: String, bannedDate: String) {
		
	}
	
	func readBanTimeFromFile(bannedProfile: String) -> String {
		var banTime = ""
		
		return banTime
	}
	
	func readBanDateFromFile() -> String {
		var banDate = ""
		
		return banDate
	}
	
	func getURLProtocol() -> String {
		return self.urlProtocol
	}
	
	func postWebsiteBannedProfileText() {
		
	}
	
	func postWebsiteVisibleProfileText() {
		
	}
	
	func getLastRunCompleted() -> Bool {
		return self.lastRunCompleted
	}
	
	func getIsLogging() -> Bool {
		return self.isLogging
	}
	
	func setIsLogging(isLogging: Bool) {
		self.isLogging = isLogging
	}
	
	func readHiddenUsersFromFile() -> [String] {
		var hiddenUsers = [String]()
		
		return hiddenUsers
	}
	
}
