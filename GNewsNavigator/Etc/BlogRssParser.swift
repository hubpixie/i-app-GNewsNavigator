//
//  BlogRssParser.swift
//  GNewsNavigator
//
//  Created by venus.janne on 11/23/15.
//  Copyright © 2015 venus.janne. All rights reserved.
//

import UIKit

protocol BlogRssParserDelegate:NSObjectProtocol {
    func processCompleted()
    
    func processHasErrors()
}

class BlogRssParser: NSObject, XMLParserDelegate {
    var Google_URL: String = "http://news.google.com/news?hl=%@&&ie=UTF-8&oe=UTF-8&ned=us&output=rss&topic=%@"
    var FROM_PUBDATE_FORMAT: String = "EEE, dd MMM yyyy HH:mm:ss zz"
    
    //---------Private Vars
    var _rssItems: [BlogRss]? = []
    var _retrieverQueue: OperationQueue?
    //---------Properties
//    @property(nonatomic, strong) BlogRss * currentItem;
//    @property(nonatomic, strong) NSMutableString * currentItemValue;
//    @property(readonly) NSMutableArray * rssItems;
//    
//    @property(nonatomic, weak) id<BlogRssParserDelegate> delegate;
//    @property(nonatomic, strong) NSOperationQueue *retrieverQueue;
//    @property(nonatomic, strong) NSString * mainURL;
    
    //--private var
    fileprivate var currentItem: BlogRss?
    fileprivate var currentItemValue: String?
    fileprivate var mainURL: String?

    //--properties
    var delegate: BlogRssParserDelegate?
    var rssItems: [BlogRss] {
        get {
            return _rssItems!
        }
    }
    var retrieverQueue : OperationQueue {
        if nil == _retrieverQueue {
            _retrieverQueue = OperationQueue()
            _retrieverQueue!.maxConcurrentOperationCount = 1
        }
        return _retrieverQueue!
    }
    
    
    //--Methods
    override init() {
    }
    
    convenience init(url:String) {
        self.init()
        _rssItems = []
        self.mainURL = url
    }
    
    func startProcess() {
        let method: Selector = #selector(BlogRssParser.fetchAndParseRss)
        _rssItems!.removeAll()
        //var op: NSOperation = NSOperation(target: self, selector: method, object: nil)
        //_retrieverQueue!.addOperation(op)
        
        self.retrieverQueue.addOperation() {
            // do something in the background
            
            OperationQueue.main.addOperation() {
                // when done, update your UI and/or model on the main queue
                self.perform(method, with: nil )
            }
        }
    }
    
    func fetchAndParseRss() -> Bool {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        URLCache.shared.memoryCapacity = 0
        URLCache.shared.diskCapacity = 0
        var urlObj: URL? = nil
        var success: Bool = false
        urlObj = URL(string: self.mainURL!)
        if urlObj == nil {
            return success
        }
        let parser: XMLParser = XMLParser(contentsOf: urlObj!)!
        parser.delegate = self
        parser.shouldProcessNamespaces = true
        parser.shouldReportNamespacePrefixes = true
        parser.shouldResolveExternalEntities = false
        success = parser.parse()
        (_rssItems! as NSArray).sortedArray(comparator: {(_first, _second) -> ComparisonResult in
            let first:BlogRss = _first as! BlogRss
            let second:BlogRss = _second as! BlogRss
            return second.pubDate!.compare(first.pubDate!)
            
        })
        //print("BlogRssParser::fetchAndParseRss error=%@, (%@)", ex.name, ex.description)
        return success
        
    }
    
    func refreshChanges() {
        var langStr: String? = UserDefaults.standard.string(forKey: "language_key")
        if langStr == nil {
            langStr = "ja"
        }
        var topicStr: String? = UserDefaults.standard.string(forKey: "topic_key")
        if topicStr == nil {
            topicStr = "h"
        }
        self.mainURL = String(format: Google_URL, langStr!, topicStr!)
    }
    

    
    //func parser(parser: NSXMLParser, didStartElement  elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [String : String]) {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        var elementName = elementName
        if nil != qName {
            elementName = qName!
        }
        if (elementName == "item") {
            self.currentItem = BlogRss()
        }
        else {
            if (elementName == "title") || (elementName == "description") || (elementName == "link") || (elementName == "guid") || (elementName == "pubDate") {
                self.currentItemValue = String()
            }
            else {
                self.currentItemValue = nil
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        var elementName = elementName
        if self.currentItem == nil {
            return
        }
        if nil != qName {
            elementName = qName!
        }
        if (elementName == "title") {
            self.currentItem!.title = currentItemValue
        }
        else {
            if (elementName == "description") {
                self.currentItem!.extraHtml = currentItemValue
                self.currentItem!.description = stripTags(currentItemValue!, startPart: "<", endPart: ">", skipPart: "\"'", partLen: 80)
                self.currentItem!.mediaUrl = getTagAttrbuteValue(currentItem!.extraHtml!, tagName: "img", attrName: "src")
                if currentItem!.mediaUrl != nil {
                    self.currentItem!.mediaUrl = "http:" + currentItem!.mediaUrl!
                }
            }
            else {
                if (elementName == "link") {
                    self.currentItem!.linkUrl = currentItemValue
                }
                else {
                    if (elementName == "guid") {
                        self.currentItem!.guidUrl = currentItemValue
                    }
                    else {
                        if (elementName == "pubDate") {
                            self.currentItem!.pubDate = setGMTDate(currentItemValue!, dateFormat: FROM_PUBDATE_FORMAT)
                        }
                        else {
                            if (elementName == "item") {
                                _rssItems!.append(currentItem!)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if nil != currentItemValue {
            currentItemValue?.append(string)
        }
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        switch(parseError) {
        case XMLParser.ErrorCode.delegateAbortedParseError:
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            (delegate as! UIViewController).performSelector(onMainThread: Selector(("processHasErrors")), with: nil, waitUntilDone: false)
        default:
            return
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        (delegate as! UIViewController).performSelector(onMainThread: Selector(("processCompleted")), with: nil, waitUntilDone: false)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func stripTags(_ str: String, startPart startStr: String, endPart endStr: String, skipPart skipStr: String, partLen len: Int) -> String {
        var sbuf:String = String(repeating: " ", count: str.characters.count)
        let scanner: Scanner = Scanner(string:str)
        scanner.charactersToBeSkipped = nil
        var s: NSString? = ""
        while !scanner.isAtEnd {
            scanner.scanString("<br>", into: nil)
            scanner.scanUpTo(startStr, into: &s)
            if s != nil {
                sbuf.append(s! as String)
            }
            scanner.scanUpTo(endStr, into: nil)
            if !scanner.isAtEnd {
                scanner.scanLocation += 1
            }
            s = nil
        }
        //strip some charactors, i.e spaces.
        sbuf = sbuf.replacingOccurrences(of: "&nbsp;", with: " ")
        var sIndex:String.Index = sbuf.characters.endIndex
        var retStr: String = sbuf.trimmingCharacters(in: CharacterSet.whitespaces)
        if retStr.characters.count > len {
            sIndex = retStr.characters.index(retStr.startIndex, offsetBy: retStr.characters.count - len)
            retStr = retStr.replacingOccurrences(of: retStr.substring(from: sIndex), with: "...")
        }
        return retStr
    }
    
    func getTagValue(_ xmlStr: String, tagName tagNameStr: String) -> String {
        let ret: String = ""
        return ret
    }
    
    func getTagAttrbuteValue(_ xmlStr: String, tagName tagNameStr: String, attrName attrNameStr: String) -> String? {
        var attrValue: NSString? = nil
        let sScanner: Scanner = Scanner(string: xmlStr)
        sScanner.scanUpTo("<\(tagNameStr)", into: nil)
        repeat {
            sScanner.scanUpTo("\(attrNameStr)=", into: nil)
            let charset: CharacterSet = CharacterSet(charactersIn: "\"'")
            sScanner.scanUpToCharacters(from: charset, into: nil)
            sScanner.scanCharacters(from: charset, into: nil)
            sScanner.scanUpToCharacters(from: charset, into: &attrValue)
        } while !sScanner.isAtEnd
        return attrValue as String?
    }
    
    func setGMTDate(_ dateStr: String, dateFormat formatStr: String) -> Date {
        let df: DateFormatter = DateFormatter()
        df.dateFormat = formatStr
        let enLocale: Locale = Locale(identifier: "en_US")
        df.locale = enLocale
        let date: Date = df.date(from: dateStr)!
        return date
    }
    
}
