//
//  ViewController.swift
//  RatingBox
//
//  Created by Talon on 07/06/2025.
//  Copyright (c) 2025 Talon. All rights reserved.
//

import UIKit
import RatingBox
import Network


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        showRatingScreen()
    }
    
    // MARK: - 使用示例
    // 在App中调用
    func showRatingScreen() {
        let networkService = MockNetworkService()
        let tracker = MockTracker()
        let viewModel = RatingViewModel(networkService: networkService, tracker: tracker)
        let ratingVC = RatingViewController(viewModel: viewModel)

        // 用模态方式呈现
        ratingVC.modalPresentationStyle = .formSheet
        present(ratingVC, animated: true)
    }
    
}

