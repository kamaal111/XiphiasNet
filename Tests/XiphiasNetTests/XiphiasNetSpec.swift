//
//  XiphiasNetSpec.swift
//  XiphiasNetTests
//
//  Created by Kamaal Farah on 28/11/2020.
//

import Quick
import Nimble
import Foundation
@testable import XiphiasNet

final class XiphiasNetSpec: QuickSpec {
    override func spec() {
        describe("request") {
            context("Make succesfull requests") {
                let apiURL = URL(string: "https://kamaal.io")!
                let configuration = URLSessionConfiguration.default
                configuration.protocolClasses = [MockURLProtocol.self]
                let urlSession = URLSession(configuration: configuration)
                let networker = XiphiasNet(urlSession: urlSession)

                it("makes requests") {
                    MockURLProtocol.requestHandler = { request in
                        let response = HTTPURLResponse(
                            url: apiURL,
                            statusCode: 200,
                            httpVersion: nil,
                            headerFields: nil)!

                        let jsonString = """
                        {
                            "message": "yes"
                        }
                        """
                        let data = jsonString.data(using: .utf8)
                        return (response, data)
                    }

                    let expectation = self.expectation(description: "Expectation")
                    Task {
                        let result: Result<Response<MockResponse>, XiphiasNet.Errors> = await networker
                            .request(from: apiURL)
                        let response = try result.get()
                        expect(response.data) == MockResponse(message: "yes")

                        expectation.fulfill()
                    }

                    self.wait(for: [expectation], timeout: 1.0)
                }
            }
        }
    }
}

struct MockResponse: Decodable, Hashable {
    let message: String
}

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let handler = MockURLProtocol.requestHandler!

        do {
            let (response, data) = try handler(request)

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }

            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}
