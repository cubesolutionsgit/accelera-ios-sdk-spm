//
//  HTMLParser.swift
//  Testing
//
//  Created by Evgeny Boganov on 08.08.2022.
//

import Foundation
import libxml2

class HTMLParser: NSObject {
    
    private var parser: XMLParser?
    
    private var currentElement: Element?
    private var root: Element?
    private var elements = [Element]()
    
    
    private var completion: ((Result<Element, Error>) -> Void)?
        
    private let tagsToReplace = ["br", "b", "/b", "u", "/u", "i", "/i", "strong", "/strong"]
    
    func parse(html: String, completion: @escaping ((Result<Element, Error>) -> Void)) {
        
        var newHtml = html
        // TODO: use regexp
        tagsToReplace.forEach { tag in
            newHtml = newHtml.replacingOccurrences(of: "<\(tag)>", with: "!@#\(tag)!@#")
        }
        
        guard let data = newHtml.data(using: .utf8) else {
            completion(.failure(HTMLParserError.nonValidHTML))
            return
        }
        
        self.parse(data: data, completion: completion)
    }
    
    func parse(data: Data, completion: @escaping ((Result<Element, Error>) -> Void)) {
        self.completion = completion

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        self.parser = parser
        
    }
    
    deinit {
        self.completion = nil
        self.parser?.delegate = nil
        self.parser = nil
    }

}

extension HTMLParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        elements.append(Element(name: elementName, attributes: attributeDict))
        if (root == nil) {
            root = elements.first
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        guard let currentElement = elements.last,
        !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        
        var text = string
        tagsToReplace.forEach { tag in
            text = text.replacingOccurrences(of: "!@#\(tag)!@#", with: "<\(tag)>")
        }
        
        if currentElement.text != nil {
            currentElement.text! += text.trimmingCharacters(in: .newlines)
        } else {
            currentElement.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    
        //print("end", elementName,  elements.map{$0.name});
        let element = elements.removeLast()
        guard let parent = elements.last else {
            return
        }
    
        parent.children.append(element)
        
        //print("end parent:", parent.name, parent.children.map { $0.name })
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
        if let root = root {
            self.completion?(.success(root))
        } else {
            self.completion?(.failure(HTMLParserError.emptyHTML))
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.completion?(.failure(parseError))
    }
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        self.completion?(.failure(validationError))
    }
}
