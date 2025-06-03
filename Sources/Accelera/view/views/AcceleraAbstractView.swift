//
//  AcceleraAbstractView.swift
//  Accelera
//
//  Created by Evgeny Boganov on 19.08.2022.
//

import Foundation
import UIKit

class AcceleraAbstractView: Equatable {
    
    init(element: AcceleraRenderingElement, type: UIView.Type) {
        self.element = element
        self.type = type
    }
        
    var id = UUID()
    var element: AcceleraRenderingElement
    var type: UIView.Type
    var descendents = [AcceleraAbstractView]()
    
    private var _view: UIView?
    var view: UIView {
        if let v = self._view {
            return v
        }
        let v = type.init()
        self._view = v
        return v
    }
        
    func create() {
        // just to init lazily
        let _ = self.view
    }
    
    func prepare(completion: @escaping () -> Void) {
        completion()
    }
    
    func render(parent: AcceleraAbstractView, previousSibling: AcceleraAbstractView?, last: Bool) {
        
    }
    
    static func == (lhs: AcceleraAbstractView, rhs: AcceleraAbstractView) -> Bool {
        return lhs.id == rhs.id
      }
}

extension AcceleraAbstractView: CustomStringConvertible {
    var description: String {
        return "\n\(id)\nelement: \(element)\ndescendents: \(descendents)\n"
    }
}
