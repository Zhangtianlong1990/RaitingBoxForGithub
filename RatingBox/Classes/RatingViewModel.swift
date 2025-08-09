//
//  File.swift
//  RatingBox
//
//  Created by 张天龙 on 2025/8/9.
//

import Foundation
import Network
import Combine

public class RatingViewModel {
    // 依赖注入
    private let networkService: NetworkServiceProtocol
    private let tracker: TrackerProtocol
    
    // 输入
    public let ratingSelected = PassthroughSubject<Int, Never>()
    public let submitTapped = PassthroughSubject<Void, Never>()
    
    // 输出
    @Published public var currentRating: Int = 0
    @Published public var isSubmitEnabled: Bool = false
    @Published public var submissionState: SubmissionState = .idle
    
    public enum SubmissionState: Equatable {
        public static func == (lhs: RatingViewModel.SubmissionState, rhs: RatingViewModel.SubmissionState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.submitting, .submitting): return true
            case (.success, .success): return true
            case (.failure(let lError), (.failure(let rError))):
                return (lError as NSError) == (rError as NSError)
            default: return false
            }
        }
        
        case idle
        case submitting
        case success
        case failure(Error)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(networkService: NetworkServiceProtocol, tracker: TrackerProtocol) {
        self.networkService = networkService
        self.tracker = tracker
        
        setupBindings()
    }
    
    private func setupBindings() {
        // 评分变化处理
        ratingSelected
            .assign(to: \.currentRating, on: self)
            .store(in: &cancellables)
        
        // 提交按钮状态
        $currentRating
            .map { $0 > 0 }
            .assign(to: \.isSubmitEnabled, on: self)
            .store(in: &cancellables)
        
        // 修复后的提交操作代码
        submitTapped
            .filter { self.isSubmitEnabled && self.submissionState != .submitting }
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.submissionState = .submitting
                self?.tracker.trackRatingEvent(rating: self?.currentRating ?? 0)
            })
            .flatMap { [weak self] _ -> AnyPublisher<Result<Void, Error>, Never> in
                guard let self = self else {
                    return Just(.failure(NSError(domain: "SelfDeallocated", code: 0, userInfo: nil)))
                        .eraseToAnyPublisher()
                }
                
                return Future<Void, Error> { promise in
                    self.networkService.submitRating(self.currentRating) { result in
                        promise(result)
                    }
                }
                // 关键修改：保留原始结果，不要映射为成功
                .map { _ -> Result<Void, Error> in .success(()) }
                .catch { error -> Just<Result<Void, Error>> in
                    Just(.failure(error))
                }
                .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                switch result {
                case .success:
                    self?.submissionState = .success
                case .failure(let error):
                    self?.submissionState = .failure(error)
                }
            }
            .store(in: &cancellables)
    }
}
