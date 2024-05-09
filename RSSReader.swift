import Foundation

public class RSSItem {
    public var title: String = ""
    public var pubDate: String = ""
    public var content: String = ""    
}

public struct RSSFeed {
    public var title: String = ""
    public var description: String = ""    
    public var items: [RSSItem] = []
}

public class RSSParser: NSObject, XMLParserDelegate {
    
    private var parser: XMLParser?
    
    private var data: Data?
    
    var completionHandler: (RSSFeed)->() = {feed in}
    
    public func makeRequest(with url:URL, completionHandler: @escaping (RSSFeed)->() ) {
        self.completionHandler = completionHandler
        self.startLoading(with: url)
    }    
    
    private func startLoading(with url: URL) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let error = error {
                self.handleClientError(error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                self.handleServerError(response!)
                return
            }
            
            if let mimeType = httpResponse.mimeType, mimeType == "application/rss+xml", let data = data {
                DispatchQueue.main.async { [self] in
                    self.data = data
                    if let d = self.data {
                        parseData(d)
                    }
                }
            }
        }
        task.resume()
    }
    
    private func parseData(_ data: Data){
        self.parser = XMLParser(data: data)
        
        if self.parser != nil {
            self.parser!.delegate = self
            self.parser!.parse()
        }
    }
    
    private func handleClientError(_ error: any Error) {
        print("Client error...\(error)")
    }
    
    private func handleServerError(_: URLResponse) {
        print("Server error...")
    }
    //XMLParserDelegate
//    extension RSSParser {
        private var feed = RSSFeed()
        private var currentItem: RSSItem?
        private var currentElement: String = ""
        
    enum Node: String {
        case item = "item"
        case title = "title"
        case description = "description"    
        case pubDate = "pubDate"
        case content = "content:encoded"
    }
        
        
        public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [String : String]) {
            if (elementName==Node.item.rawValue) {
                self.currentItem = RSSItem()
            }
            self.currentElement = ""
        }
        
        public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if (elementName == Node.item.rawValue){
                if let item = self.currentItem {
                    self.feed.items.append(item)
                }
                self.currentItem = nil
                return
            }
            
            if let item = self.currentItem {
                if (elementName == Node.title.rawValue) {
                    item.title = self.currentElement
                }
                if (elementName == Node.pubDate.rawValue) {
                    item.pubDate = self.currentElement
                }
                if (elementName == Node.content.rawValue) {
                    item.content = self.currentElement
                }
            } else {
                if (elementName == Node.title.rawValue) {
                    feed.title.append(self.currentElement)
                }
                if (elementName == Node.description.rawValue) {
                    feed.description.append(self.currentElement)                    
                }
            }
            
            
        }
        
        public func parserDidEndDocument(_ parser: XMLParser) {
            self.completionHandler(self.feed)
        }
        
        public func parser(_ parser: XMLParser, foundCharacters string: String) {
            if let item = self.currentItem {
                if (string.trimmingCharacters(in: .whitespacesAndNewlines) != "") {
                    self.currentElement.append(string)
                }
            }
        }
        
    }
//}

extension Array {
    var mutableLast: Element! {
        get {
            precondition(count > 0)
            return last
        }
        set {
            precondition(count > 0)
            self[count - 1] = newValue
        }
    }
}
