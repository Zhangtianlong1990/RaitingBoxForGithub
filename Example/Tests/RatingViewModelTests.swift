import XCTest
import Combine
import RatingBox
import Network

class RatingViewModelTests: XCTestCase {
    var viewModel: RatingViewModel!
    var mockNetworkService: MockNetworkService!
    var mockTracker: MockTracker!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockTracker = MockTracker()
        viewModel = RatingViewModel(
            networkService: mockNetworkService,
            tracker: mockTracker
        )
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        mockNetworkService = nil
        mockTracker = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        if case .idle = viewModel.submissionState {
            // Success
        } else {
            XCTFail("Expected idle state, got \(viewModel.submissionState)")
        }
        XCTAssertEqual(viewModel.currentRating, 0)
        XCTAssertFalse(viewModel.isSubmitEnabled)
    }
    
    // MARK: - Rating Selection Tests
    
    func testRatingSelectionUpdatesCurrentRating() {
        // When
        viewModel.ratingSelected.send(3)
        
        // Then
        XCTAssertEqual(viewModel.currentRating, 3)
    }
    
    // MARK: - Submit Button State Tests
    
    func testSubmitEnabledWhenRatingPositive() {
        // When: Select valid rating
        viewModel.ratingSelected.send(4)
        
        // Then
        XCTAssertTrue(viewModel.isSubmitEnabled)
    }
    
    func testSubmitDisabledWhenRatingZero() {
        // When: Reset to zero rating
        viewModel.ratingSelected.send(0)
        
        // Then
        XCTAssertFalse(viewModel.isSubmitEnabled)
    }
    
    // MARK: - Submission Flow Tests
    
    func testSuccessfulSubmissionFlow() {
        // Given
        let expectation = XCTestExpectation(description: "Submission success")
        mockNetworkService.submitRatingResult = .success(())
        viewModel.ratingSelected.send(5)
        
        var states: [RatingViewModel.SubmissionState] = []
        viewModel.$submissionState
            .dropFirst() // Skip initial idle state
            .sink { state in
                states.append(state)
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.submitTapped.send()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        // Verify state progression
        XCTAssertEqual(states.count, 2)
        if case .submitting = states.first {
            // Success
        } else {
            XCTFail("Expected first state to be submitting, got \(String(describing: states.first))")
        }
        if case .success = states.last {
            // Success
        } else {
            XCTFail("Expected last state to be success, got \(String(describing: states.last))")
        }
        
        // Verify dependencies
        XCTAssertEqual(mockNetworkService.submittedRating, 5)
        XCTAssertEqual(mockTracker.trackedRating, 5)
    }
    
    func testFailedSubmissionFlow() {
        // Given
        let expectation = XCTestExpectation(description: "Submission failure")
        let testError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockNetworkService.submitRatingResult = .failure(testError)
        viewModel.ratingSelected.send(2)

        var states: [RatingViewModel.SubmissionState] = []
        viewModel.$submissionState
            .dropFirst() // Skip initial idle state
            .sink { state in
                states.append(state)
                if case .failure = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.submitTapped.send()

        // Then
        wait(for: [expectation], timeout: 1.0)

        // Verify state progression
        XCTAssertEqual(states.count, 2)
        if case .submitting = states.first {
            // Success
        } else {
            XCTFail("Expected first state to be submitting, got \(String(describing: states.first))")
        }
        if case .failure(let error) = states.last {
            XCTAssertEqual(error as NSError, testError)
        } else {
            XCTFail("Expected failure state, got \(String(describing: states.last))")
        }

        // Verify dependencies
        XCTAssertEqual(mockNetworkService.submittedRating, 2)
        XCTAssertEqual(mockTracker.trackedRating, 2)
    }
    
    func testSubmitBlockedWhenDisabled() {
        // Given: No rating selected (submit disabled)
        let initialState = viewModel.submissionState
        
        // When
        viewModel.submitTapped.send()
        
        // Then: No state change
        XCTAssertTrue(viewModel.submissionState == initialState)
        XCTAssertFalse(mockNetworkService.submitRatingCalled)
        XCTAssertNil(mockTracker.trackedRating)
    }
    
    func testOnlyOneSubmissionAtATime() {
        // Given
        let expectation = XCTestExpectation(description: "Only one submission")
        mockNetworkService.submitRatingResult = .success(())
        viewModel.ratingSelected.send(4)
        
        var stateCount = 0
        viewModel.$submissionState
            .dropFirst()
            .sink { state in
                stateCount += 1
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When: Send multiple submit requests
        viewModel.submitTapped.send()
        viewModel.submitTapped.send() // Should be ignored
        viewModel.submitTapped.send() // Should be ignored
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        // Only one network call should be made
        XCTAssertEqual(mockNetworkService.submitCallCount, 1)
        XCTAssertEqual(stateCount, 2) // .submitting → .success
    }
    
    func testTrackerCalledBeforeNetworkRequest() {
        // Given
        let expectation = XCTestExpectation(description: "Tracker called first")
        mockNetworkService.submitRatingResult = .success(())
        viewModel.ratingSelected.send(3)
        
        var trackerCalled = false
        mockTracker.onTrack = {
            trackerCalled = true
            // Verify network call hasn't started yet
            XCTAssertFalse(self.mockNetworkService.submitRatingCalled)
        }
        
        viewModel.$submissionState
            .dropFirst()
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.submitTapped.send()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(trackerCalled)
    }
}

class MockNetworkService: NetworkServiceProtocol {
    var submitRatingCalled = false
    var submitCallCount = 0
    var submittedRating: Int?
    var submitRatingResult: Result<Void, Error> = .success(())
    
    func submitRating(_ rating: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        submitRatingCalled = true
        submitCallCount += 1
        submittedRating = rating
        completion(submitRatingResult)
    }
}

class MockTracker: TrackerProtocol {
    var trackedRating: Int?
    var onTrack: (() -> Void)?
    
    func trackRatingEvent(rating: Int) {
        trackedRating = rating
        onTrack?()
    }
}
