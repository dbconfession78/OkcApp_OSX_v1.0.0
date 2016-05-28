//
//  ViewController.swift
//  Created by Stuart Kuredjian on 5/17/16.
//  Copyright © 2016 s.Ticky Games. All rights reserved.
//

import Cocoa

let queue = NSOperationQueue()
var cookies = [NSHTTPCookie]()

class ViewController: NSViewController {
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
	@IBOutlet weak var resetButton: NSButton!
	@IBOutlet weak var outputLabel2: NSTextField!

	var isLoggedIn = false
	var isLogging = false
	var isRunning = false
	var isVisiting = false
	var shouldHideProfiles = false
	var shouldUseProxy = false
	var accessToken: String = String()
	var cookies = [NSHTTPCookie]()
	var totalProfilesVisited:Int = 0
	var timerIsOn = false
	var previouslyVisitedProfileCount = Int()
	var username = String()
	var password = String()
	
	@IBAction func autoWatchButtonActionPerformed(sender: AnyObject) {
		let username = "sgk2004"
		let password = "hyrenkosa"
		visitProfile(username)
		
		checkAccountStatus(username, password: password)
	}
	
	@IBAction func loginButtonActionPerformed(sender: AnyObject) {
		if !isLoggedIn {
			self.username = usernameTextField.stringValue
			self.password = passwordTextField.stringValue
			self.accessToken = login(self.username, password: self.password)
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
			self.setUIRunState()
		})
		NSThread.sleepForTimeInterval(0.5)
		let thread2 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
		dispatch_async(thread2, {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
				let maxLimitsPerCycle = 100
				if visits <= maxLimitsPerCycle {
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
					cycles = (visits / maxLimitsPerCycle) + 1
					finalCycleLimit = visits % maxLimitsPerCycle
					
					for _ in 1..<cycles {
						self.isRunning = true
						self.run(maxLimitsPerCycle)
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
				print("Visited \(self.totalProfilesVisited) profile(s)")
			})
		})
	}
	
	@IBAction func resetButtonActionPerformed(sender: AnyObject) {
		resetRun()
		
	}
	
	// TEST BUTTON ACTION PERFORMED
	@IBAction func testButtonActionPerformed(sender: AnyObject) {
		
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setUILoggedOutState()
		shouldHideProfiles = false
		shouldUseProxy = false
		hideProfilesCheckBox.state = NSOffState
		useProxyCheckbox.state = NSOffState
		
		login(usernameTextField.stringValue, password: passwordTextField.stringValue)
	}
	
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
			let request = Request(URL: URL!, method: method, params: params)
			request.username = username
			request.password = password
			request.isRequesting = true
			
			queue.addOperation(request)
//			request.threadPriority = 0
			request.completionBlock = {() -> () in
				request.execute()
			}
			while request.isRequesting {
				NSThread.sleepForTimeInterval(0.0)
			}
			print(request.responseHeaders)
			
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
		}
		self.accessToken = accessToken
		return accessToken
	}
	
	func logout() {
		isLoggedIn = false
		clearCookies()
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
		let request = Request(URL: NSURL(string: "https://www.okcupid.com/visitors")!, method: "GET", params: "")
		request.isRequesting = true
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			request.execute()
		})
		while request.isRequesting == true{
			NSThread.sleepForTimeInterval(0.0)
		}
		
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
	
	func run(limit: Int) {
		var profilesVisited = 0
		let visitInterval: NSTimeInterval = 7.0
		let thread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
	
		dispatch_async(thread, {
			let JSON = "{\"gentation\":[17],\"gender_tags\":\"2\",\"last_login\":\"3600\",\"located_anywhere\":\"1\",\"limit\":\"\(limit)\"}"
			let url = "https://www.okcupid.com/apitun/match/search?"
			
			var params = "&access_token=\(self.accessToken)&_json=\(JSON)"
			params = self.addPercentEscapes(params)
			let request = Request(URL: NSURL(string: url+params)!, method: "GET", params: "")
			request.isRequesting = true
			
			queue.addOperation(request)
//			request.threadPriority = 0
			request.completionBlock = {() -> () in
				request.execute()
			}
			while request.isRequesting {
				NSThread.sleepForTimeInterval(0.5)
			}
			
			let pattern = "(\"username\") : \"([\\w\\\\ÆÐƎƏƐƔĲŊŒ\\u1E9EÞǷȜæðǝəɛɣĳŋœĸſßþƿȝĄƁÇĐƊĘĦĮƘŁØƠŞȘŢȚŦŲƯY̨Ƴąɓçđɗęħįƙłøơşșţțŧųưy̨ƴÁÀÂÄǍĂĀÃÅǺĄÆǼǢƁĆĊĈČÇĎḌĐƊÐÉÈĖÊËĚĔĒĘẸƎƏƐĠĜįịĳĵķƙĸĺļłľŀŉńn̈ňñņŋóòôöǒŏōõőọøǿơœŔŘŖŚŜŠŞȘṢ\\u1E9EŤŢṬŦÞÚÙÛÜǓŬŪŨŰŮŲỤƯẂẀŴẄǷÝỲŶŸȲỸƳŹŻŽẒŕřŗſśŝšşșṣßťţṭŧþúùûüǔŭūũűůųụưẃẁŵẅƿýỳŷÿȳỹƴźżžẓ±-]+)\","
			
			let contentsOfURL = request.contentsOfURL as String
			
			//parse profiles
			var profiles: [NSString] = [NSString]()
			do {
				let regex = try NSRegularExpression(pattern: pattern, options: [])
				let matches = regex.matchesInString(contentsOfURL, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, contentsOfURL.characters.count))
				for match in matches {
					profiles.append((contentsOfURL as NSString).substringWithRange(match.rangeAtIndex(2)))
				}
			} catch {
				
			}
			
			/* visit user profiles based on match results */
			var didVisitProfile = false
			for (index, profile) in profiles.enumerate() {
				let thread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
				print("\(index+1). \(profiles[index]): ", terminator: "")
				dispatch_async(dispatch_get_main_queue(), {
					self.outputLabel1.stringValue = "\(profile as String):"
				})
				self.isVisiting = true
				dispatch_async(thread, {
						didVisitProfile = self.visitProfile(profile)
					})
					while self.isVisiting {
						NSThread.sleepForTimeInterval(0.5)
					}
					// If visited, "OK" to console
					if didVisitProfile {
						print("OK")
						dispatch_async(dispatch_get_main_queue(), {
							profilesVisited += 1
							self.totalProfilesVisited += 1
							self.visitedCounterLabel.stringValue = String(self.totalProfilesVisited)
						})
						// "OK" to UI
						dispatch_async(dispatch_get_main_queue(), {
							self.outputLabel1.stringValue = "\(profile): OK" as String
							if self.shouldHideProfiles {
								// "Hiding" to UI
								let originString = self.outputLabel1.stringValue
								dispatch_async(dispatch_get_main_queue(), {
									self.outputLabel1.stringValue = "\(originString) ...Hiding"
								})
								self.hideProfile(profile as String)
							}
						})
					} else {
						print("FAIL")
					}
					
					if limit != index+1 {
						NSThread.sleepForTimeInterval(visitInterval)
					} else {
						break
					}
			}
			self.isRunning = false
		})
		
		while isRunning {
			NSThread.sleepForTimeInterval(0.0)
		}
	}
	
	func setUIRunState() {
		hideProfilesCheckBox.enabled = false
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
			let request = Request(URL: URL!, method: "GET", params: "")
			
			request.isRequesting = true
			queue.addOperation(request)
//			request.threadPriority = 0
			request.completionBlock = {() -> () in
				request.execute()
			}
			while request.isRequesting {
				NSThread.sleepForTimeInterval(1.0)
			}
			
			NSThread.sleepForTimeInterval(1)
			if request.contentsOfURL.containsString("<title>\(profile) /") {
				didVisitProfile = true
			} else {
				didVisitProfile = false
			}
			isVisiting = false
		}
		
		return didVisitProfile
	}
	
	func hideProfile(profile: String) {
		let URL = NSURL(string: "https://www.okcupid.com/1/apitun/profile/\(profile)/hide")
		let params = ""
		let request = Request(URL: URL!, method: "POST", params: params)
		request.isRequesting = true
		let accessToken = addPercentEscapes(self.accessToken)
		request.authorization = "Bearer \(accessToken)"
		queue.addOperation(request)
//		request.threadPriority = 0
		request.completionBlock = {() -> () in
			request.execute()
		}
		while request.isRequesting {
			NSThread.sleepForTimeInterval(0.0)
		}
	}
	
	func unhideProfile(profile: String) {
		let URL = NSURL(string: "https://www.okcupid.com/apitun/profile/\(profile)/unhide")
		let params = "&access_token=\(self.accessToken)"
		let request = Request(URL: URL!, method: "POST", params: params)
		request.isRequesting = true
		queue.addOperation(request)
//		request.threadPriority = 0
		request.completionBlock = {() -> () in
			request.execute()
		}
		while request.isRequesting {
			NSThread.sleepForTimeInterval(0.0)
		}
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
				if second != 59 {
					second += 01
				} else {
					second = 00
					if minute != 59 {
						minute += 01
					} else {
						minute = 00
						hour += 01
					}
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
			//Append to file
			fileHandle.seekToEndOfFile()
			fileHandle.writeData(contentToAppend.dataUsingEncoding(NSUTF8StringEncoding)!)
		}
		else {
			//Create new file
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

