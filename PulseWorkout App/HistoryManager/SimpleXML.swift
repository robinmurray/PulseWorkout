//
//  SimpleXML.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 04/09/2023.
//

import Foundation

enum ElementType {
    case prolog, comment, normal
}
class XMLElement {
    var elementType: ElementType = .normal
    var name: String
    var value: String?
    var attributes: [String:String] = [:]
    var elList: [XMLElement] = []
    var parent: XMLElement?
    var depth: Int
    
    init(name: String, parent: XMLElement?) {
        self.name = name
        self.parent = parent
        depth = 0
        if parent != nil {
            depth = parent!.depth + 1
        }
    }
    
    func addValue(name: String, value: String, attributes: [String:String] = [:]) {
        let newElement = XMLElement(name: name, parent: self)
        newElement.value = value
        newElement.attributes = attributes
        elList.append(newElement)
    }

    func addNode(name: String, attributes: [String:String] = [:]) -> XMLElement {
        let newElement = XMLElement(name: name, parent: self)
        newElement.attributes = attributes
        elList.append(newElement)
        
        return newElement
    }

    func addComment(comment: String) {
        let newElement = XMLElement(name: comment, parent: self)
        newElement.elementType = .comment
        elList.append(newElement)
    }

    func addProlog(prolog: String) {
        let newElement = XMLElement(name: prolog, parent: self)
        newElement.elementType = .prolog
        elList.append(newElement)
    }
    
    func serialize() -> String {
        
        var ser: String = ""
        var startTag: String
        var endTag: String
        let indent = String(repeating: " ", count: max(depth - 1, 0))
        
        switch elementType {
        case .prolog:
            startTag = "<?"
            endTag = "?>\n"

        case .comment:
            startTag = "<!-- "
            endTag = " -->\n"
            
        case .normal:
            startTag = "<"
            endTag = ">\n"
        }
        
        if elList.count > 0 {
            
            if parent != nil {
                ser = indent + startTag + name

                for (attributeName, attributeValue) in attributes {
                    ser += " \(attributeName)=\"\(attributeValue)\""
                }
                ser += endTag
            }
            
            for el in elList {
                ser += el.serialize()
            }
            if parent != nil {
                ser += indent + "</\(name)>\n"
            }
            
            return ser
        }

        if value != nil {
            return indent + "<\(name)>\(value!)</\(name)>\n"
        }
        return indent + startTag + name + endTag
    }

}

class XMLDocument {
    var root: XMLElement = XMLElement(name: "root", parent: nil)
    
    func addNode(name: String, attributes: [String:String] = [:]) -> XMLElement {
        return root.addNode(name: name, attributes: attributes)
    }
    
    func addValue(name: String, value: String, attributes: [String:String] = [:]) {
        root.addValue(name: name, value: value, attributes: attributes)
    }

    func addComment(comment: String) {
        root.addComment(comment: comment)
    }

    func addProlog(prolog: String) {
        root.addProlog(prolog: prolog)
    }

    func serialize() -> String {
        return root.serialize()
    }
}
