//
//  User.swift
//  RESTAPIModule
//
//  Created by Yu Juno on 2020/12/28.
//

import Foundation

typealias JSON = [String: Any]

// MARK: - 1. Model
struct User {
	var id: String
	var email: String?
	var name: String?
}

// MARK: - 2. Parser
extension User {
	
/// 		To preserve the original default constructor of User,
/// 		we add the constructor through an extension on the User type.
	
	init?(json: JSON) {
		guard let id = json["id"] as? String else { return nil }
		self.id = id
		self.email = json["email"] as? String
		self.name = json["name"] as? String
	}
}

// MARK: - 3. Error
enum ServiceError: Error {
	case noInternetConnection
	case custom(String)
	case other
}

extension ServiceError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .noInternetConnection:
			return "No internet connection"
		case .other:
			return "Something went wrong"
		case .custom(let message):
			return message
		}
	}
}


extension ServiceError {
	init(json: JSON) {
		if let message = json["message"] as? String {
			self = .custom(message)
		} else {
			self = .other
		}
	}
}

// MARK: - 4. Client

/// 	The client component will be an intermediary
/// 	between the application and the backend server.
///		It’s a critical component that will define how the application
///		and the server will communicate,
///		yet it will know nothing about the data models and their structures.
///		The client will be responsible for invoking specific URLs with
///		provided parameters and returning incoming JSON data parsed as JSON objects.

enum RequestMethod: String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case delete = "DELETE"
}

final class WebClient {
	private var baseUrl: String
	
	init(baseUrl: String) {
		self.baseUrl = baseUrl
	}
	
	func load(
		path: String,
		method: RequestMethod,
		params: JSON,
		completion: @escaping (Any?, ServiceError?) -> ()
	) -> URLSessionDataTask? {

///
/// 	1. Check availability of the Internet connection.
///
		guard Reachability.isConnectedToInternet() else {
			completion(nil, ServiceError.noInternetConnection)
			return nil
		}

///
/// 	2. Adding common parameters
///
//		var parameters = params
//		if let token = KeychainWrapper.itemForKey("application_token") {
//				parameters["token"] = token
//		}

///
///  3. Create the URLRequest object, using the constructor from the extension.
///
		let request = URLRequest(
			baseUrl: baseUrl,
			path: path,
			method: method,
			params: params)
///
///  4. Send the request to the server. We use the URLSession object to send data to the server.
///
		let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
///
///  5. Parsing incoming data
///
			var object: Any? = nil
			if let data = data {
				object = try? JSONSerialization.jsonObject(
					with: data,
					options: [])
			}
			
			if let httpResponse = response as? HTTPURLResponse,
				 (200..<300) ~= httpResponse.statusCode {
				///
				/// We check the status code of the response.
				/// If it is a success code (i.e., in the range between 200 and 299),
				/// we call the completion closure with the JSON object.
				///
				completion(object, nil)
			} else {
				///
				/// Otherwise, we transform the JSON object
				/// into a ServiceError object and
				/// call the completion closure with that error object.
				///
				let error = (object as? JSON).flatMap(ServiceError.init) ?? ServiceError.other
				completion(nil, error)
			}
		}
		task.resume()
		return task
	}
}


extension URL {
	init(
		baseUrl: String,
		path: String,
		params: JSON,
		method: RequestMethod
	) {
		var components = URLComponents(string: baseUrl)!
		components.path += path
		
		switch method {
		case .get, .delete:
			components.queryItems = params.map {
				URLQueryItem(
					name: $0.key,
					value: String(describing: $0.value)
				)
			}
		default:
			break
		}
		self = components.url!
	}
}

extension URLRequest {
	init(
		baseUrl: String,
		path: String,
		method: RequestMethod,
		params: JSON
	) {
		let url = URL(
			baseUrl: baseUrl,
			path: path,
			params: params,
			method: method)
		self.init(url: url)
		httpMethod = method.rawValue
		setValue("application/json", forHTTPHeaderField: "Accept")
		setValue("application/json", forHTTPHeaderField: "Content-Type")
		switch method {
		case .post, .put:
			httpBody = try! JSONSerialization.data(
				withJSONObject: params,
				options: [])
		default:
			break
		}
	}
}


// MARK: - 6. Services
final class FriendsService {
	private let client = WebClient(baseUrl: "https://your_server_host/api/v1")
	
	@discardableResult
	func loadFriends(
		forUser user: User,
		completion: @escaping ([User]?, ServiceError?) -> ()
	) -> URLSessionDataTask? {
		let param: JSON = ["user_id": user.id]
		return client.load(
			path: "/friends", method: .get, params: param) { (result, error) in
			let dictionaries = result as? [JSON]
			completion(dictionaries?.compactMap(User.init), error)
		}
	}
}
