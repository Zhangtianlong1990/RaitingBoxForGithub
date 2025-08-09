//
//  RatingBoxResource.swift
//  RatingBox
//
//  Created by 张天龙 on 2025/8/9.
//

import Foundation

class RatingBoxResource {
     static var bundle: Bundle {
         let frameworkBundle = Bundle(for: RatingBoxResource.self)
         guard let resourceBundleURL = frameworkBundle.url(forResource: "RatingBoxAssets", withExtension: "bundle"),
               let resourceBundle = Bundle(url: resourceBundleURL) else {
             fatalError("RatingBox.bundle not found!")
         }
         return resourceBundle
     }
 }
