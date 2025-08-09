//
//  MockTracker.swift
//  RatingBox
//
//  Created by 张天龙 on 2025/8/9.
//

import Foundation

// MARK: - 埋点协议与实现
public protocol TrackerProtocol {
    func trackRatingEvent(rating: Int)
}

public class MockTracker: TrackerProtocol {
    public init() {
        
    }
    public func trackRatingEvent(rating: Int) {
        print("📊 埋点事件: 用户评分 \(rating) 星")
    }
}
