//
//  Reachability.swift
//  RESTAPIModule
//
//  Created by Yu Juno on 2020/12/28.
//

import Foundation

class Reachability {
	///
	/// 	Reachability is a custom class,
	/// 	which uses one of the common approaches to check the Internet connection.
	///
	static func isConnectedToInternet() -> Bool {
		let hostname = "google.com"
		let hostinfo = gethostbyname2(hostname, AF_INET6)//AF_INET6
		if hostinfo != nil {
			return true // internet available
		}
		return false // no internet
	}
}
