import XCTest
@testable import URL

// TODO:
// Test plan.
//================
// - PercentEscaping: long strings, short strings, escape sets, unescaping, round-tripping
// - hasNonURLCodePoints
// - WebURLParser.Components.QueryParameters

let testBasic_printResults = true

final class URLTests: XCTestCase {

   /// Tests a handful of basic situations demonstrating the major features of the parser.
   /// These tests are not meant to be exhaustive; for something more comprehensive, see the WHATWG constructor tests.
   ///
   /// Note that these tests operate at the `WebURLParser.Components` level, not the `WebURL` object model-level.
   ///
   func testBasic() {

       let testData: [(String, WebURLParser.Components?)] = [

        // Leading, trailing whitespace.
        ("        http://www.google.com   ", WebURLParser.Components(
            scheme: .http,
            username: "", password: "", host: .domain("www.google.com"), port: nil,
            path: [""], query: nil, fragment: nil, cannotBeABaseURL: false)
        ),

        // Non-ASCII characters in path.
        ("http://mail.yahoo.com/€uronews/", WebURLParser.Components(
            scheme: .http,
            username: "", password: "", host: .domain("mail.yahoo.com"), port: nil,
            path: ["%E2%82%ACuronews", ""], query: nil, fragment: nil, cannotBeABaseURL: false)
        ),

        // Spaces in credentials.
        ("ftp://%100myUsername:sec ret ))@ftp.someServer.de:21/file/thing/book.txt", WebURLParser.Components(
            scheme: .ftp,
            username: "%100myUsername", password: "sec%20ret%20))", host: .domain("ftp.someserver.de"), port: nil,
            path: ["file", "thing", "book.txt"], query: nil, fragment: nil, cannotBeABaseURL: false)
        ),

        // Windows drive letters.
        ("file:///C|/demo", WebURLParser.Components(
            scheme: .file,
            username: "", password: "", host: .empty, port: nil,
            path: ["C:", "demo"], query: nil, fragment: nil, cannotBeABaseURL: false)
        ),

        // '..' in path.
        ("http://www.test.com/../athing/anotherthing/.././something/", WebURLParser.Components(
            scheme: .http,
            username: "", password: "", host: .domain("www.test.com"), port: nil,
            path: ["athing", "something", ""], query: nil, fragment: nil, cannotBeABaseURL: false)
        ),

        // IPv6 address.
        ("https://[::ffff:192.168.0.1]/aThing", WebURLParser.Components(
            scheme: .https,
            username: "", password: "", host: .ipv6Address(IPAddress.V6("::ffff:c0a8:1")!), port: nil,
            path: ["aThing"], query: nil, fragment: nil, cannotBeABaseURL: false)
        ),

        // IPv4 address.
        ("https://192.168.0.1/aThing", WebURLParser.Components(
            scheme: .https,
            username: "", password: "", host: .ipv4Address(IPAddress.V4("192.168.0.1")!), port: nil,
            path: ["aThing"], query: nil, fragment: nil, cannotBeABaseURL: false)
        ),
        
        // Invalid IPv4 address (trailing non-hex-digit makes it a domain).
        ("https://0x3h", WebURLParser.Components(
            scheme: .https,
            username: "", password: "", host: .domain("0x3h"), port: nil,
            path: [""], query: nil, fragment: nil, cannotBeABaseURL: false)
        ),
    	
        // Invalid IPv4 address (overflows, otherwise correctly-formatted).
       ("https://234.266.2", nil),

        // Non-ASCII opaque host.
        ("tp://www.bücher.de", WebURLParser.Components(
            scheme: .other("tp"),
            username: "", password: "", host: .opaque(OpaqueHost("www.b%C3%BCcher.de")!), port: nil,
            path: [], query: nil, fragment: nil, cannotBeABaseURL: false)
        ),

        // Emoji opaque host.
        ("tp://👩‍👩‍👦‍👦️/family", WebURLParser.Components(
            scheme: .other("tp"),
            username: "", password: "",
            host: .opaque(OpaqueHost("%F0%9F%91%A9%E2%80%8D%F0%9F%91%A9%E2%80%8D%F0%9F%91%A6%E2%80%8D%F0%9F%91%A6%EF%B8%8F")!), port: nil,
            path: ["family"], query: nil, fragment: nil, cannotBeABaseURL: false)
        ),

        // ==== Everything below is XFAIL while host parsing is still being implemented ==== //

        //Non-ASCII domain.
        // ("http://www.bücher.de", WebURLParser.Components(
        //     scheme: "http",
        //     authority: .init(username: nil, password: nil, host: .domain("www.xn--bcher-kva.de"), port: nil),
        //     path: [""], query: nil, fragment: nil, cannotBeABaseURL: false)
        // ),
       ]
    
        fileprivate func debugPrint(_ url: String, _ parsedComponents: WebURLParser.Components?) {
            print("URL:\t|\(url)|")
            if let results = parsedComponents {
                print("Results:\n\(WebURL(components: results).debugDescription)")
            } else {
                print("Results:\nFAIL")
            }
            print("===================")
        }

    
       if testBasic_printResults {
           print("===================")
       }
       for (input, expectedComponents) in testData {
            let results = WebURLParser.parse(input)
            XCTAssertEqual(results, expectedComponents, "Failed to correctly parse \(input)")
            if testBasic_printResults {
                debugPrint(input, results)
            }
        }
        if testBasic_printResults {
            print("===================")
        }
   }
}

// Percent-escaping tests.

extension URLTests {
    
     func testPercentEscaping() {
           let testStrings: [String] = [
             "hello, world", // ASCII
             "👩‍👩‍👦‍👦️", // Long unicode
             "%🐶️",   // Leading percent
             "%z🐶️",  // Leading percent + one nonhex
             "%3🐶️",  // Leading percent + one hex
             "%3z🐶️", // Leading percent + one hex + one nonhex
             "🐶️%",   // Trailing percent
             "🐶️%z",  // Trailing percent + one nonhex
             "🐶️%3",  // Trailing percent + one hex
             "🐶️%3z", // Trailing percent + one hex + one nonhex
             // "%100" FIXME: Percent escaping doesn't round-trip.
           ]
           for string in testStrings {
    //           let escaped = string.percentEscaped(where: { _ in false })
    //           let decoded = escaped.removingPercentEscaping() //PercentEscaping.decodeString(utf8: escaped.utf8)

    //           XCTAssertEqual(Array(string.utf8), Array(decoded.utf8))
    //            print("--------------")
    //            print("original: '\(string)'\t\tUTF8: \(Array(string.utf8))")
    //            print("decoded : '\(decoded)'\t\tUTF8: \(Array(decoded.utf8))")
    //            print("escaped:  '\(escaped)'\t\tUTF8: \(Array(escaped.utf8))")
            }
       }
}
