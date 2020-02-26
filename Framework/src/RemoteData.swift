//
//  RemoteData.swift
//  MetaZKit
//
//  Created by Brian Olsen on 22/02/2020.
//

import Foundation

@objc public class RemoteData : NSObject {
    private static let queue = DispatchQueue(label: "io.metaz.RemoteDataQueue")
    
    public let url : URL
    public let expectedMimeType : String

    private var _data : Data?
    @objc public var data : Data? {
        get {
            return self._data
        }
        set {
            DispatchQueue.main.sync {
                self.willChangeValue(for: \.data)
                self._data = newValue
                self.didChangeValue(for: \.data)
            }
        }
    }
    private var _loaded : Bool
    @objc public var isLoaded : Bool {
        get {
            return self._loaded
        }
        set {
            DispatchQueue.main.sync {
                self.willChangeValue(for: \.isLoaded)
                self._loaded = newValue
                self.didChangeValue(for: \.isLoaded)
            }
        }
    }
    private var _error : NSError?
    @objc public var error : NSError? {
        get {
            return self._error
        }
        set {
            DispatchQueue.main.sync {
                self.willChangeValue(for: \.error)
                self._error = newValue
                self.didChangeValue(for: \.error)
            }
        }
    }
    @objc public var userInfo : String?;

    @objc public convenience init(url: URL) {
        self.init(url: url, expectedMimeType: "*")
    }
    
    @objc public convenience init(imageUrl url: URL) {
        self.init(url: url, expectedMimeType: "image/*")
    }
    
    @objc public init(url: URL, expectedMimeType mime: String) {
        self.url = url
        self.expectedMimeType = mime
        _loaded = false
    }
    
    @objc public func loadData() {
        RemoteData.queue.async {
            var downloadData : Data?, responseError : NSError?
            let signal = DispatchSemaphore(value: 0)
            
            URLSession.dataTask(url: self.url) { (d, resp, err) in
                if let error = err {
                    let info = [NSLocalizedDescriptionKey: error.localizedDescription]
                    let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? 0

                    responseError = NSError(domain: NetworkRequestErrorDomain,
                                            code: statusCode,
                                            userInfo: info)
                } else if let response = resp {
                    if response.mimeType?.matches(mimeTypePattern: self.expectedMimeType) ?? false {
                        downloadData = d
                    } else {
                        let info = [NSLocalizedDescriptionKey: String(format: "Unsupported Media Type '%@'", response.mimeType ?? "")]
                        responseError = NSError(domain: NetworkRequestErrorDomain,
                                                code: 415,
                                                userInfo: info)
                    }
                } else {
                    let info = [NSLocalizedDescriptionKey: String(format: "Unknown error with URL '%@'", self.url.absoluteString)]
                    responseError = NSError(domain: NetworkRequestErrorDomain,
                                            code: 416,
                                            userInfo: info)
                }
                signal.signal()
            }.resume()
            signal.wait()
            self.data = downloadData
            self.error = responseError
            self.isLoaded = true
        }
    }
}
