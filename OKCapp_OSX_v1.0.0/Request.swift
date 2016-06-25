//
//  Request.swift
//
//  Created by Stuart Kuredjian on 5/17/16.
//  Copyright © 2016 s.Ticky Games. All rights reserved.
//

import Cocoa

class Request: NSOperation {
	private var URL = NSURL()
	private var method = String()
	private var params = String()
	private var json = [:]
	var data: NSData?
	var username = String()
	var password = String()
	var usernames = [String]()
	var userIds = [String]()
	var statusCode = Int()
	var requestHeaders = NSDictionary()
	var cookies = [NSHTTPCookie]()
	var responseHeaders = NSHTTPURLResponse()
	var accessToken = String()
	var authorization = String()
	var jsonResponse:AnyObject!
	var requestMisfireCount = Int()
	
	var contentsOfURL:NSString = ""
	var isRequesting = false
	var task = NSURLSessionDataTask()
	
	init(URL: NSURL, method: String, params: String, json: [String:NSObject]) {
		self.URL = URL
		self.method = method
		self.params = params
		self.json = json
	}
	
	override func main() -> () {
		// whatever is done here will execute before anything else
	}
	
	func execute() {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			self.requestLoopCorrector()
		})
		let session = NSURLSession.sharedSession()
		let request = NSMutableURLRequest(URL: URL)
		request.HTTPMethod = self.method
		
		/* JSON DATA or PARAMS */
		if json.count > 0 {
			do {
				let jsonData = try NSJSONSerialization.dataWithJSONObject(self.json, options: .PrettyPrinted)
				request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
				request.HTTPBody = jsonData
			} catch {
				
			}
		} else {
			request.HTTPBody = self.params.dataUsingEncoding(NSUTF8StringEncoding)
		}
		
		/* Authorization Header */
		if authorization != "" {
			request.setValue(authorization, forHTTPHeaderField: "Authorization")
		}
		self.task = session.dataTaskWithRequest(request) {
			(data, response, error) in
			
			NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookies(self.cookies, forURL: self.URL, mainDocumentURL: nil)
			if data != nil {
				self.data = data!
				
				do {
					self.responseHeaders = response as! NSHTTPURLResponse
					self.cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(self.URL)!
					self.statusCode = self.responseHeaders.statusCode
					
					switch self.statusCode {
						
					case 200:
						self.contentsOfURL = try NSString(contentsOfURL: self.URL, encoding: NSUTF8StringEncoding)
					case 400:
						print("400: page not found on web")
						
					case 404:
						print("404: page not found on server")
						
					case 407:
						print("407: failed authenticate proxy credentials")
						
					default:
						print("unable to get statusCode")
					}
				} catch {
					
				}
				self.isRequesting = false
			} else {
				print("No data found!")
				return
			}
		}
		self.task.resume()
	}
	
	func requestLoopCorrector() {
		var seconds = 0.0
		while isRequesting {
			NSThread.sleepForTimeInterval(1.0)
			if isRequesting {
				seconds += 1.0
				if seconds >= (20.0) {
					isRequesting = false
					requestMisfireCount += 1
					print("request misfire: \(requestMisfireCount)")
					break
				}
			} else {
				seconds = 0.0
			}
		}
	}
	
	func addRequestHeaders(requestHeaders: NSDictionary) {
		self.requestHeaders = requestHeaders
	}
	
	func getContentsOfURL(URL: NSURL) -> NSString {
		return self.contentsOfURL
	}
	
}
