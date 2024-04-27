//
//  String+Base64.swift
//  PopcornTime
//
//  Created by Hadi Sharghi on 2024-04-27.
//  Copyright © 2024 PopcornTime. All rights reserved.
//

import Foundation

extension String {

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

}
