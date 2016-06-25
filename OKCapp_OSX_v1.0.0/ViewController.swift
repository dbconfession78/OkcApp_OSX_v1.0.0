//
//  ViewController.swift
//  Created by Stuart Kuredjian on 5/17/16.
//  Copyright © 2016 s.Ticky Games. All rights reserved.
//

//TODO: ManageAccounts class (add, delete, edit acounts)
//TODO: MatcheSearcher class
//TODO: RunManager class
//TODO: Schedule class

import Cocoa

let queue = NSOperationQueue()
var cookies = [NSHTTPCookie]()

class ViewController: NSViewController {
	
	// OUTLETS
	@IBOutlet weak var usernameTextField: NSTextField!
	@IBOutlet weak var passwordTextField: NSTextField!
	@IBOutlet weak var loginButton: NSButton!
	@IBOutlet weak var hideProfilesCheckBox: NSButton!
	@IBOutlet weak var useProxyCheckbox: NSButton!
	@IBOutlet weak var runButton: NSButton!
	@IBOutlet weak var visitsTextField: NSTextField!
	@IBOutlet weak var visitedCounterLabel: NSTextField!
	@IBOutlet weak var proxyHostTextField: NSTextField!
	@IBOutlet weak var proxyPortTextField: NSTextField!
	@IBOutlet weak var proxyUserTextField: NSTextField!
	@IBOutlet weak var proxyPwTextField: NSTextField!
	@IBOutlet weak var runTimeLabel: NSTextField!
	@IBOutlet weak var outputLabel1: NSTextField!
	@IBOutlet weak var outputLabel2: NSTextField!
	@IBOutlet weak var outputLabel3: NSTextField!
	@IBOutlet weak var outputLabel4: NSTextField!
	@IBOutlet weak var outputLabel5: NSTextField!
	@IBOutlet weak var outputLabel6: NSTextField!
	@IBOutlet weak var resetButton: NSButton!
	@IBOutlet weak var usernameComboBox: NSComboBox!
	@IBOutlet weak var addAccountButton: NSButton!
	@IBOutlet weak var manageAccountButton: NSButton!
	@IBOutlet weak var removeAccountButton: NSButton!
	@IBOutlet weak var applyChangesButton: NSButton!
	@IBOutlet weak var autoWatchButton: NSButton!
	@IBOutlet weak var proxyHostLabel: NSTextField!
	@IBOutlet weak var proxyPortLabel: NSTextField!
	@IBOutlet weak var proxyUserLabel: NSTextField!
	@IBOutlet weak var proxyPwLabel: NSTextField!
	@IBOutlet weak var deleteInboxButton: NSButton!
	
	var isLoggedIn = false
	var isLogging = false
	var isRunning = false
	var isVisiting = false
	var isHiding = false
	var shouldHideProfiles = false
	var shouldUseProxy = false
	var accessToken: String = String()
	var cookies = [NSHTTPCookie]()
	var totalProfilesVisited:Int = 0
	var timerIsOn = false
	var previouslyVisitedProfileCount = Int()
	var username = String()
	var password = String()
	var userIds = [String]()
	var usernames = [String]()
	var loopMisfireCount = 0
	var previousTotalProfilesVisited = 0
	var timerForTesting = 0.000
	var timerForHiding = 0.000
	var stopwatch = 0.0
	
	var stopwatchIsOn = false
	let okcDomain = "https://www.okcupid.com/"
	var startTime = ""

	// TEST BUTTON ACTION PERFORMED
	@IBAction func testButtonActionPerformed(sender: AnyObject) {
		
	}
	
	//TODO: finish autowatch
	@IBAction func autoWatchButtonActionPerformed(sender: AnyObject) {
		let username = "sgk2004"
		let password = "hyrenkosa"
		visitProfile(username)
		
		checkAccountStatus(username, password: password)
	}
	
	@IBAction func applyChangesButtonActionPerformed(sender: AnyObject) {
		manageAccountButton.hidden = false
		addAccountButton.hidden = true
		removeAccountButton.hidden = true
		applyChangesButton.hidden = true
	}
	
	@IBAction func addAccountButtonActionPerformed(sender: AnyObject) {
		let username = usernameTextField.stringValue
		let password = passwordTextField.stringValue
		let passwordKey = "\(username) account: username"
		let usernameKey = "\(username) account: password"
	
		NSUserDefaults.standardUserDefaults().removeObjectForKey("Accounts")
	}
	
	@IBAction func removeAccountButtonActionPerformed(sender: AnyObject) {
	}
	
	@IBAction func manageAccountButtonActionPerformed(sender: AnyObject) {
		applyChangesButton.hidden = false
		addAccountButton.hidden = false
		removeAccountButton.hidden = false
		manageAccountButton.hidden = true
	}
	
	@IBAction func loginButtonActionPerformed(sender: AnyObject) {
		if !isLoggedIn {
			self.username = usernameTextField.stringValue
			self.password = passwordTextField.stringValue
			self.accessToken = login(self.username, password: self.password)
			let visitors = visitorCount()
			let messages = messageCount()
			outputLabel4.stringValue = "Visitors: \(visitors)"
			outputLabel2.stringValue = "Messages: \(messages)"
		} else {
			logout()
		}
	}

	@IBAction func hideProfilesCheckboxActionPerformed(sender: AnyObject) {
		if shouldHideProfiles == false {
			shouldHideProfiles = true
			hideProfilesCheckBox.state = NSOnState
		} else {
			shouldHideProfiles = false
			hideProfilesCheckBox.state = NSOffState
		}
	}
	
	@IBAction func useProxyCheckboxActionPerformed(sender: AnyObject) {
		if shouldUseProxy == false{
			shouldUseProxy = true
			useProxyCheckbox.state = NSOnState
		} else {
			shouldUseProxy = false
			useProxyCheckbox.state = NSOffState
		}
	}
	
	@IBAction func runButtonActionPerformed(sender: AnyObject) {
		startTime = currentTime()
		print("Start Time: \(startTime)\n")
		resetRun()
		let visits = Int(self.visitsTextField.stringValue)!
		var cycles:Int!
		var finalCycleLimit:Int!
		
		let thread1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
		dispatch_async(thread1, {
			if !self.isRunning {
				self.runButton.title = "Stop Run"
				self.startRunTimer()
			} else {
				self.runButton.title = "Run"
				dispatch_async(dispatch_get_main_queue(), {
					self.setUILoggedInState()
				})
			}
		})
		dispatch_async(dispatch_get_main_queue(),  {
			self.setUIRunningState()
		})
		
//		NSThread.sleepForTimeInterval(0.5)
//		let thread2 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
//		dispatch_async(thread2, {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
				let maxVisitsPerCycle = 50
				if visits <= maxVisitsPerCycle {
					self.isRunning = true
					self.run(visits)
					
					while self.previouslyVisitedProfileCount > 0 {
						let limit = self.previouslyVisitedProfileCount
						self.previouslyVisitedProfileCount = 0
						self.isRunning = true
						
						self.run(limit)
						while self.isRunning == true {
							NSThread.sleepForTimeInterval(0.0)
						}
					}
				} else {
					cycles = (visits / maxVisitsPerCycle) + 1
					finalCycleLimit = visits % maxVisitsPerCycle
					
					for _ in 1..<cycles {
						self.isRunning = true
						self.run(maxVisitsPerCycle)
					}
					
					if finalCycleLimit > 0 {
						self.isRunning = true
						self.run(finalCycleLimit)
					}
					
					while self.previouslyVisitedProfileCount > 0 {
						let limit = self.previouslyVisitedProfileCount
						self.previouslyVisitedProfileCount = 0
						self.run(limit)
					}
				}
				while self.isRunning {
					NSThread.sleepForTimeInterval(0)
				}
				
				dispatch_async(dispatch_get_main_queue(), {
					self.runButton.title = "Run"
					self.outputLabel1.stringValue = "Visited: \(self.totalProfilesVisited)  Skipped: \(self.previouslyVisitedProfileCount)"
					self.timerIsOn = false
					dispatch_async(dispatch_get_main_queue(), {
						self.setUILoggedInState()
					})
				})
				print("\n\nVisited \(self.totalProfilesVisited) profile(s)")
			})
//		})
	}
	
	@IBAction func resetButtonActionPerformed(sender: AnyObject) {
		resetRun()
	}
	
	@IBAction func deleteInboxButtonActionPerformed(sender: AnyObject) {
		deleteInbox()
	}
	
	@IBAction func refreshVisitorCountMenuItemActionPerformed(sender: AnyObject) {
		refreshVisitorCount()
	}
	
	func refreshVisitorCount() {
		let refreshVisitorCountThread = dispatch_queue_create("Refresh Visitor Count Thread", DISPATCH_QUEUE_SERIAL)
		dispatch_async(refreshVisitorCountThread, {
			let visitors = String(self.visitorCount())
			dispatch_async(dispatch_get_main_queue(), {
				self.outputLabel4.stringValue = "Visitors: \(visitors)"
			})
			
		})
	}
	
	@IBAction func refreshMessageCountMenuItemActionPerformed(sender: AnyObject) {
		refreshMessageCount()
	}
	
	func refreshMessageCount() {
		let refreshMessageCountThread = dispatch_queue_create("Refresh Message Count Thread", DISPATCH_QUEUE_SERIAL)
		dispatch_async(refreshMessageCountThread, {
			let messages = String(self.messageCount())
			dispatch_async(dispatch_get_main_queue(), {
				self.outputLabel2.stringValue = "Messages: \(messages)"
			})
			
		})
		
		
	}
	
	@IBAction func hideVisitorsMenuItemActionPerformed(sender: AnyObject) {
		dispatch_async(dispatch_queue_create("Hide Visitors Thread", DISPATCH_QUEUE_SERIAL), {
			while true {
				let visitorIds = self.userIdsToHide()
				if visitorIds.count == 0 {
					break
				}
				//		self.isHiding = true
				for visitorId in visitorIds {
					self.hideProfile(visitorId)
				}
			}
			
			dispatch_async(dispatch_get_main_queue(), {
				let visitors = String(self.visitorCount())
				self.outputLabel4.stringValue = "Visitors: \(visitors)"
				
			})
		})

	}
	
	// FUNCTIONS
	override func viewDidLoad() {
		super.viewDidLoad()

		setUILoggedOutState()
		shouldHideProfiles = false
		shouldUseProxy = false
		hideProfilesCheckBox.state = NSOffState
		useProxyCheckbox.state = NSOffState
		outputLabel1.stringValue = ""
		outputLabel2.stringValue = ""
		outputLabel3.stringValue = ""
		outputLabel4.stringValue = ""
		outputLabel5.stringValue = ""
		outputLabel6.stringValue = ""

		if NSUserDefaults.standardUserDefaults().objectForKey("Accounts") == nil {
			let dict = NSDictionary()
			NSUserDefaults.standardUserDefaults().setObject(dict, forKey: "Accounts")
		}
		
		populateComboBox()
		
		/* FOR TESTING */
		hideProfilesCheckboxActionPerformed(hideProfilesCheckBox)
		login(usernameTextField.stringValue, password: passwordTextField.stringValue)
		
		/* Unavailable Features */
		manageAccountButton.hidden = true
		autoWatchButton.hidden = true
		usernameComboBox.hidden = true
		useProxyCheckbox.hidden = true
		proxyHostTextField.hidden = true
		proxyPortTextField.hidden = true
		proxyUserTextField.hidden = true
		proxyPwTextField.hidden = true
		proxyHostLabel.hidden = true
		proxyPortLabel.hidden = true
		proxyUserLabel.hidden = true
		proxyPwLabel.hidden = true
	
	}
	
	func userIdsToHide() -> [String] {
			var visitorIds = [String]()
			var usernames = [String]()
			let url = "https://www.okcupid.com/visitors"
			let URL = NSURL(string: url)
			let request = Request(URL: URL!, method: "GET", params: "", json: [:])
			let hideVisitorsThread = dispatch_queue_create("Hide Visitors Thread", DISPATCH_QUEUE_CONCURRENT)
			dispatch_async(hideVisitorsThread, {
				request.execute()
			})
			self.requestWatcher(request)
			let contentsOfURL = request.contentsOfURL
			
			// parse user ids
			do {
				let regex = try NSRegularExpression(pattern: "data\\-uid\\=\"([0-9]+)\"", options: [])
				let matches = regex.matchesInString(contentsOfURL as String, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, contentsOfURL.length))
				if matches.count != 0 {
					for match in matches {
						let visitorId = contentsOfURL.substringWithRange(match.rangeAtIndex(1))
						visitorIds.append(visitorId)
					}
				}
			} catch {
				
			}
		return visitorIds
	}
	
	func messageCount() -> Int {
		var messageCount = Int()
		
		let url = "https://www.okcupid.com/home"
		let nsURL = NSURL(string: url)!
		let request = Request(URL: nsURL, method: "GET", params: "", json: [:])
		
		queue.addOperation(request)
		request.isRequesting = true
		request.completionBlock = { () -> () in
			request.execute()
		}
		
		while request.isRequesting {
			NSThread.sleepForTimeInterval(0.0)
		}
		
		// parse message count
		do {
			let contentsOfURL = request.contentsOfURL
			let regex = try NSRegularExpression(pattern: "\"nav_mailbox_badge\"\\sclass=\"badge pink\">\\s<span class=\"count\">\\s([0-9]+)\\s</span>", options: [])
			let matches = regex.matchesInString(contentsOfURL as String, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, contentsOfURL.length))
			if matches.count == 1 {
				messageCount = Int(contentsOfURL.substringWithRange(matches[0].rangeAtIndex(1)))!
//				print("messageCount = \(messageCount)")
			} else {
				print("Unable to parse message count from home page")
			}
		} catch {
			
		}
		
		return messageCount
	}
	
	internal func visitorCount() -> Int {
		// get home page
		var visitorCount = Int()
		let url = "https://www.okcupid.com/home"
		let nsURL = NSURL(string: url)!
		let request = Request(URL: nsURL, method: "GET", params: "", json: [:])
	
		queue.addOperation(request)
		request.isRequesting = true
		request.completionBlock = { () -> () in
				request.execute()
		}
		
		while request.isRequesting {
			NSThread.sleepForTimeInterval(0.0)
		}

		// parse visitor count
		do {

			let contentsOfURL = request.contentsOfURL
			let regex = try NSRegularExpression(pattern: "\"nav_visitors_badge\"\\sclass=\"badge\">\\s<span class=\"count\">\\s([0-9]+)\\s</span>", options: [])
			let matches = regex.matchesInString(contentsOfURL as String, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, contentsOfURL.length))
			
			if matches.count == 1 {
				visitorCount = Int(contentsOfURL.substringWithRange(matches[0].rangeAtIndex(1)))!
//				print("visitorCount = \(visitorCount)")
			} else {
				print("Unable to parse visitor count from home page")
			}
		} catch {
			
		}
		return visitorCount
	}
	
	func deleteInbox() {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			while true {
				let pathForInboxDropdown = "messages?okc_api=1&messages_dropdown_ajax=1&folder=1&reset_gns=1"
				let url = NSURL(string: "\(self.okcDomain+pathForInboxDropdown)")!
				let requestMessages = Request(URL: url, method: "GET", params: "", json: [:])
				requestMessages.isRequesting = true
				queue.addOperation(requestMessages)
				requestMessages.completionBlock = { () -> () in
					requestMessages.execute()
				}
				self.requestWatcher(requestMessages)
				let contentsOfURL = requestMessages.contentsOfURL
				var threadIdsArray = [String]()
				var threadIdsString = ""
				do {
					let regex = try NSRegularExpression(pattern: "\"threadid\" : \"([0-9]+)\"", options: [])
					let matches = regex.matchesInString((contentsOfURL as String), options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, contentsOfURL.length))
					for match in matches {
						let threadId = contentsOfURL.substringWithRange(match.rangeAtIndex(1))
						threadIdsArray.append(threadId)
					}
				} catch {
					
				}
				print("messages: \(threadIdsArray.count)")
				if threadIdsArray.count == 0 {
					dispatch_async(dispatch_get_main_queue(), {
						self.outputLabel2.stringValue = "Inbox Deleted"
					})
					break
				}
				
				for (index, threadId) in threadIdsArray.enumerate() {
					if index == threadIdsArray.startIndex {
						threadIdsString = "\"\(threadId)\""
					} else{
						threadIdsString += ", \"\(threadId)\""
					}
				}
				
				let url2 = "https://www.okcupid.com/apitun/messages/threads?&access_token=\(self.accessToken)&threadids=[\(threadIdsString)]&_method=DELETE"
				let encodedURL2 = url2.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLFragmentAllowedCharacterSet())
				
				let requestDeleteThreadId = Request(URL: NSURL(string: encodedURL2!)!, method: "GET", params: "", json: [:])
				
				requestDeleteThreadId.isRequesting = true
				
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
					requestDeleteThreadId.execute()
				})
				self.requestWatcher(requestDeleteThreadId)
			}
		})
	}
	
	func currentTime() -> String {
		let formatter = NSDateFormatter()
		var amPm = ""
		let date = NSDate()
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components([ .Hour, .Minute, .Second], fromDate: date)
		let hour = Int(components.hour)
		if hour == 0 || hour < 12 {
			amPm = "AM"
		} else {
			amPm = "PM"
		}

		formatter.dateFormat = "M/d/yy h:m:ss"
		let resultString: String = formatter.stringFromDate(NSDate())
		return resultString + " " + amPm
	}
	
	func populateComboBox() {
		let accountcount = NSUserDefaults.standardUserDefaults().arrayForKey("")?.count
	}
	
	//TODO: change so that parsing for self.accessToken is it's own function, 
	// then remove -> String from login function
	func login(username: String, password: String) -> String {
		var accessToken = String()
		let thread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
		isLogging = true
		dispatch_async(thread, {
			if username == self.usernameTextField.stringValue {
				self.clearCookies()
			}
			self.cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!
			
			let URL = NSURL(string: "https://www.okcupid.com/login")
			let method = "POST"
			let params = "&username=\(username)&password=\(password)&okc_api=1"
			let request = Request(URL: URL!, method: method, params: params, json: [:])
			request.username = username
			request.password = password
			request.isRequesting = true
			
			queue.addOperation(request)
			
			request.threadPriority = 0
			request.completionBlock = {() -> () in
				request.execute()
			}
			
			self.requestWatcher(request)
//			print(request.responseHeaders)
			
			do {
				let contentsOfURL = request.getContentsOfURL(URL!)
				let regex = try NSRegularExpression(pattern: "ACCESS_TOKEN = \"([0-9A-Za-z\\W.]+)\";", options: [])
				
				let matches = regex.matchesInString(contentsOfURL as String, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, contentsOfURL.length))
				
				switch matches.count {
					
				case 0:
					print("login failed:  unable to parse access token")
					self.isLoggedIn = false
					
				case 1:
					accessToken = (contentsOfURL).substringWithRange(matches[0].rangeAtIndex(1))
					print("Logged in!")
					print("\nACCESS_TOKEN=\(accessToken)\n")
					self.isLoggedIn = true
					dispatch_async(dispatch_get_main_queue(), {
						self.setUILoggedInState()
					})
				default:
					print("login failed:  multiples access tokens found")
					self.isLoggedIn = false
				}
				
				self.isLogging = false
			} catch {
				
			}
		})
		
		while isLogging {
			NSThread.sleepForTimeInterval(0.0)
		}
		
		if self.isLoggedIn {
			if(username == self.usernameTextField.stringValue) {
				self.loginButton.title = "Logout"
			}
			dispatch_async(dispatch_queue_create("Auto-Refresh Visitors/Message Thread", DISPATCH_QUEUE_SERIAL), {
				while true {
					self.refreshMessageCount()
					NSThread.sleepForTimeInterval(0.5)
					self.refreshVisitorCount()
					

					NSThread.sleepForTimeInterval(300.0)
					print("laughter")
				}
			})
		}
		self.accessToken = accessToken
		return accessToken
	}
	
	func logout() {
		let request = Request(URL: NSURL(string: "https://www.okcupid.com/logout")!, method: "GET", params: "", json: [:])
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			self.accessToken = ""
			self.clearCookies()
			request.execute()
		})
		
		isLoggedIn = false

		loginButton.title = "Login"
		setUILoggedOutState()
	}
	
	func addPercentEscapes(var string:  String) -> String {
		string = string.stringByReplacingOccurrencesOfString(",", withString: "%2C")
		string = string.stringByReplacingOccurrencesOfString(";", withString: "%3B")
		string = string.stringByReplacingOccurrencesOfString(":", withString: "%3A")
		string = string.stringByReplacingOccurrencesOfString("\"", withString: "%22")
		string = string.stringByReplacingOccurrencesOfString("{", withString: "%7B")
		string = string.stringByReplacingOccurrencesOfString("}", withString: "%7D")
		string = string.stringByReplacingOccurrencesOfString("-", withString: "%2D")
		string = string.stringByReplacingOccurrencesOfString(" ", withString: "%20")
		return string
	}
	
	func checkAccountStatus(username: String, password: String) {
		_ = login(username, password: password)
		let request = Request(URL: NSURL(string: "https://www.okcupid.com/visitors")!, method: "GET", params: "", json: [:])
		request.isRequesting = true
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			request.execute()
		})
		
		self.requestWatcher(request)
		let contentsOfURL = request.contentsOfURL
		if contentsOfURL.containsString(self.username) {
			dispatch_async(dispatch_get_main_queue(), {
				self.outputLabel2.stringValue = "Visible"
			})
			print("Profile is visible")
		} else {
			dispatch_async(dispatch_get_main_queue(), {
				self.outputLabel2.stringValue = "Not Visible"
			})
			print("Profile is NOT visisble.")
		}
	}
	
	func requestWatcher(request: Request) {
		request.isRequesting = true
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
		var seconds = 0
			while request.isRequesting {
				if !request.isRequesting {
					break
				}
				if seconds >= 10 {
					self.loopMisfireCount += 1
					request.isRequesting = false
					break
				}
				NSThread.sleepForTimeInterval(1.0)
				seconds += 1
			}
		})
		while request.isRequesting {
			NSThread.sleepForTimeInterval(0)
		}
	}
	
	func run(limit: Int) {
		var limit = limit
		var profilesVisited = 0
		let visitInterval: NSTimeInterval = (7.0)
		var didVisitProfile: Bool?
		var contentsOfURL = NSString()
		var jsonResponse:AnyObject
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
			do {
				let json = ["gender_tags":2, "gentation":[21], "i_want":"men", "last_login":3600, "located_anywhere":1, "minimum_age":18, "maximum_age":99, "order_by":"LOGIN", "orientation_tags":5, "they_want":"women", "limit":limit]
				
				let url = NSURL(string: "https://www.okcupid.com/1/apitun/match/search")
				let request = Request(URL: url!, method: "POST", params: "", json: json as! [String : NSObject])
				
				request.isRequesting = true
				queue.addOperation(request)
				request.completionBlock = {() -> () in
					request.execute()
				}
				
				self.requestWatcher(request)
	
				// parse usernames and userid
				do {
					let data = request.data
					let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
					
					if let usernames = json["data"] as? [[String: AnyObject]] {
						for username in usernames {
							if let username = username["username"] as? String {
								self.usernames.append(username)
							}
						}
					}

					if let userIds = json["data"] as? [[String: AnyObject]] {
						for userId in userIds {
							if let userId = userId["userid"] as? String {
								self.userIds.append(userId)
							}
						}
					}
				} catch {
					
				}
				
				/* visit user profiles based on match results */
				for (index, username) in self.usernames.enumerate() {
					var stopwatchSeconds = 0.0
					var isCounting = true
					
					/* ********************/
					let runThread = dispatch_queue_create("Run Thread", DISPATCH_QUEUE_CONCURRENT)
					
					dispatch_async(runThread, {
						while isCounting {
							NSThread.sleepForTimeInterval(1.0)
							stopwatchSeconds += 1.0
						}
					})
					
					print("Start: \(self.startTime)")
					print("Now:   \(self.currentTime())")
					print("UI:            \(self.runTimeLabel.stringValue)")
					print("\(self.totalProfilesVisited+1). \(self.usernames[index])\n  (A) Visiting...")
					dispatch_async(dispatch_get_main_queue(), {
						self.outputLabel3.stringValue = ""
						self.outputLabel1.stringValue = "\(username as String)"
					})
					
					self.isVisiting = true
					
					dispatch_async(runThread, {
						didVisitProfile = self.visitProfile(self.usernames[index])
					})
					
					while self.isVisiting {
						if !self.isVisiting {
							break
						}
					}

					while didVisitProfile == nil {
						NSThread.sleepForTimeInterval(0.0)
					}
					
					dispatch_async(runThread, {
						
					})
					
					
					
					if (didVisitProfile != nil && didVisitProfile != false) {
						print("  (B) OK")
					}
					
					if self.shouldHideProfiles {
						print("  (C) Hiding...")
						self.isHiding = true

						dispatch_async(runThread, {
							// *-*
							self.hideProfile(self.userIds[index] as String)
							
						})

						// *-*
						while self.isHiding {
							if !self.isHiding {
								break
							}
						}
					}
					
					if (didVisitProfile != nil && didVisitProfile != false) {
						self.previousTotalProfilesVisited = self.totalProfilesVisited
						dispatch_async(dispatch_get_main_queue(), {
							profilesVisited += 1
							self.totalProfilesVisited += 1
							self.visitedCounterLabel.stringValue = String(self.totalProfilesVisited)
						})
					} else {
						print("FAIL")
					}
					
					if self.previouslyVisitedProfileCount == self.totalProfilesVisited {
						NSThread.sleepForTimeInterval(0.0) //TODO:  what is this for?
					}
					
					if limit != index+1 {
						NSThread.sleepForTimeInterval(visitInterval)
						isCounting = false
					} else {
						break
					}
					print("\n   -Visit/Hide Time: \(stopwatchSeconds) seconds\n")
				}
			} catch {
				
			}
			NSThread.sleepForTimeInterval(0.5)
			self.isRunning = false
		})
		visitCrashCorrector(visitInterval)
	}
	
	func visitCrashCorrector(visitInterval: Double) {
		var seconds = 0.0
		while isRunning {
			NSThread.sleepForTimeInterval(1.0)
			if isVisiting || isHiding {
				seconds += 1.0
				if seconds >= (visitInterval*2) {
					isVisiting = false
					isHiding = false
					loopMisfireCount += 1
				}
			} else {
				seconds = 0.0
			}
		}
	}
	
	func setUIRunningState() {
		hideProfilesCheckBox.enabled = true
		loginButton.enabled = false
		resetButton.enabled = false
		useProxyCheckbox.enabled = false
		proxyPwTextField.enabled = false
		proxyUserTextField.enabled = false
		proxyPortTextField.enabled = false
		proxyHostTextField.enabled = false
	}
	
	func parseProfileNames(pattern:String, contentsOfURL: String) -> [NSString] {
		var profiles: [NSString] = [NSString]()
		do {
			let regex = try NSRegularExpression(pattern: pattern, options: [])
			let matches = regex.matchesInString(contentsOfURL, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, contentsOfURL.characters.count))
			for match in matches {
				profiles.append((contentsOfURL as NSString).substringWithRange(match.rangeAtIndex(0)))
			}
		} catch {
			
		}
		return profiles
	}
	
	func visitProfile(profile: NSString) -> Bool {
		let url = "https://www.okcupid.com/profile/\(profile)"
		let encodedURL = url.stringByAddingPercentEncodingWithAllowedCharacters(
			NSCharacterSet.URLFragmentAllowedCharacterSet()),
		URL = NSURL(string: encodedURL!)
		var didVisitProfile = false
		
		if URL != nil {
			let request = Request(URL: URL!, method: "GET", params: "", json: [:])
			request.isRequesting = true
			queue.addOperation(request)
			request.completionBlock = {() -> () in
				request.execute()
			}
			
			self.requestWatcher(request)
		
			NSThread.sleepForTimeInterval(1.0) // TEST WITHOUT THIS LINE
			if request.contentsOfURL.containsString("<title>\(profile) /") {
				didVisitProfile = true
			} else {
				didVisitProfile = false
			}
			
			isVisiting = false
		}

		return didVisitProfile
	}
	
	func hideProfile(userId: String) {
		var url = "https://www.okcupid.com/1/apitun/profile/\(userId)/hide"
		var URL = NSURL(string: url)
		let params = ""
		if URL != nil {
			let request = Request(URL: URL!, method: "POST", params: params, json: [:])
			request.isRequesting = true
			let accessToken = addPercentEscapes(self.accessToken)
			request.authorization = "Bearer \(accessToken)"
			queue.addOperation(request)
			request.threadPriority = 0
			
			/* EXECUTE HIDE TREAD */
			request.completionBlock = {() -> () in
				// *-*
				request.execute()
			}
			// *-*
			self.requestWatcher(request)
			
			// UI UPDATE THREAD
			dispatch_async(dispatch_get_main_queue(), {
				var status: String
				if request.statusCode == 200{
					status = "OK"
				} else {
					status = "FAIL"
				}

				
				NSThread.sleepForTimeInterval(1.0)
				if status == "OK" {
					self.outputLabel3.stringValue = "Hidden"
				}
				print("  (D) \(status)", terminator: "\n   -Misfires: \(self.loopMisfireCount)")
				self.isHiding = false
			})
			
			while self.isHiding {
				NSThread.sleepForTimeInterval(0.0)
			}
		}
	}
	
	func unhideProfile(userId: String) {
		let URL = NSURL(string: "https://www.okcupid.com/apitun/profile/\(userId)/unhide")
		let params = "&access_token=\(self.accessToken)"
		let request = Request(URL: URL!, method: "POST", params: params, json: [:])
		request.isRequesting = true
		queue.addOperation(request)
		request.threadPriority = 0
		request.completionBlock = {() -> () in
			request.execute()
		}
		
		self.requestWatcher(request)
	}
	
	func resetRun() {
		previouslyVisitedProfileCount = 0
		totalProfilesVisited = 0
		visitedCounterLabel.stringValue = String(totalProfilesVisited)
		runTimeLabel.stringValue = "00:00:00"
	}
	
	func clearCookies() {
		print("clearing cookies...")
		cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!
		for cookie in cookies {
			print("Deleting: \(cookie.name)")
			NSHTTPCookieStorage.sharedHTTPCookieStorage().deleteCookie(cookie)
		}
		cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!
		if (cookies.count == 0) {
			print("cookies have been cleared.\n")
		}
	}
	
	func startRunTimer() {
		let thread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
		dispatch_async(thread, {
			self.timerIsOn = true
			var hour = 00
			var minute = 00
			var second = 00
			while self.timerIsOn {
				NSThread.sleepForTimeInterval(1.0)
				if second == 59 {
					if minute == 59 {
						hour += 1
						minute = 0
					} else {
						minute += 1
					}
					second = 0
				} else {
					second += 1
				}
				
				var hourAsString = String(hour)
				var minuteAsString = String(minute)
				var secondAsString = String(second)
				
				if hour < 10 {
					hourAsString = "0\(String(hour))"
				}
				if minute < 10 {
					minuteAsString = "0\(String(minute))"
				}
				if second < 10 {
					secondAsString = "0\(String(second))"
				}
				
				dispatch_async(dispatch_get_main_queue(), {
					self.runTimeLabel.stringValue = "\(hourAsString):\(minuteAsString):\(secondAsString)"
				})
				
			}
		})
		
	}
	
	func setUILoggedInState() {
		usernameTextField.enabled = false
		passwordTextField.enabled = false
		hideProfilesCheckBox.enabled = true
		loginButton.enabled = true
		runButton.enabled = true
		resetButton.enabled = true
		useProxyCheckbox.enabled = true
		proxyHostTextField.enabled = true
		proxyPortTextField.enabled = true
		proxyUserTextField.enabled = true
		proxyPwTextField.enabled = true
	}
	
	func setUILoggedOutState() {
		usernameTextField.enabled = true
		passwordTextField.enabled = true
		hideProfilesCheckBox.enabled = false
		loginButton.enabled = true
		runButton.enabled = false
		resetButton.enabled = false
		useProxyCheckbox.enabled = false
		proxyHostTextField.enabled = false
		proxyPortTextField.enabled = false
		proxyUserTextField.enabled = false
		proxyPwTextField.enabled = false
	}
	
	// !! NOT USED !!
	func writeTextToFile(content: String, fileName: String) {
		let contentToAppend = content + "\n"
		let filePath = NSHomeDirectory() + "/Documents/" + fileName
		
		//check if the file exists
		if let fileHandle = NSFileHandle(forWritingAtPath: filePath) {
			// append to file
			fileHandle.seekToEndOfFile()
			fileHandle.writeData(contentToAppend.dataUsingEncoding(NSUTF8StringEncoding)!)
		}
		else {
			// create new file
			do {
				try contentToAppend.writeToFile(filePath, atomically: true, encoding: NSUTF8StringEncoding)
			} catch {
				print("Error creating \(filePath)")
			}
		}
	}
	
	// !! NOT USED !!
	func readFile(file: String) -> NSString{
		var fileContents = NSString()
		
		do {
			let path = NSHomeDirectory() + "/Documents/" + file
			fileContents = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
		} catch {
			
		}
		
		return fileContents
	}
}

