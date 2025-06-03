//
//  AcceleraSpacer.swift
//  Accelera
//
//  Created by Evgeny Boganov on 20.09.2022.
//

import Foundation

import UIKit

class AcceleraSpacer: AcceleraBlock {
    override func prepare(completion: @escaping () -> Void) {
        if element.height == nil {
            element.setAttribute("height", value: "10")
        }
        super.prepare(completion: completion)
    }
}
