import UIKit
import SnapKit
import Combine

// MARK: - ViewController
public class RatingViewController: UIViewController {
    private let viewModel: RatingViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // UI组件
    private let starsStackView = UIStackView()
    private let submitButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    
    public init(viewModel: RatingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 星星评分控件
        starsStackView.axis = .horizontal
        starsStackView.distribution = .fillEqually
        starsStackView.spacing = 8
        
        for i in 1...5 {
            let button = UIButton()
            button.tag = i
            button.setImage(UIImage(named: "star", in: RatingBoxResource.bundle, compatibleWith: nil), for: .normal)
            button.setImage(UIImage(named: "star_selected", in: RatingBoxResource.bundle, compatibleWith: nil), for: .selected)
            button.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            starsStackView.addArrangedSubview(button)
        }
        
        // 提交按钮
        submitButton.setTitle("提交评分", for: .normal)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        
        // 状态标签
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        
        // 布局
        let stackView = UIStackView(arrangedSubviews: [starsStackView, submitButton, statusLabel])
        stackView.axis = .vertical
        stackView.spacing = 20
        view.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(300)
        }
        
        starsStackView.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
    }
    
    private func bindViewModel() {
        // 绑定提交按钮状态
        viewModel.$isSubmitEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: submitButton)
            .store(in: &cancellables)
        
        // 绑定提交状态
        viewModel.$submissionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .idle:
                    self?.statusLabel.text = "请选择评分"
                    self?.statusLabel.textColor = .label
                case .submitting:
                    self?.statusLabel.text = "提交中..."
                    self?.statusLabel.textColor = .systemBlue
                case .success:
                    self?.statusLabel.text = "提交成功！感谢您的评分"
                    self?.statusLabel.textColor = .systemGreen
                case .failure(let error):
                    self?.statusLabel.text = "错误: \(error.localizedDescription)"
                    self?.statusLabel.textColor = .systemRed
                }
            }
            .store(in: &cancellables)
        
        // 绑定当前评分
        viewModel.$currentRating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rating in
                self?.updateStars(selected: rating)
            }
            .store(in: &cancellables)
    }
    
    private func updateStars(selected rating: Int) {
        for (index, view) in starsStackView.arrangedSubviews.enumerated() {
            if let starButton = view as? UIButton {
                starButton.isSelected = (index < rating)
            }
        }
    }
    
    @objc private func starTapped(_ sender: UIButton) {
        viewModel.ratingSelected.send(sender.tag)
    }
    
    @objc private func submitTapped() {
        viewModel.submitTapped.send()
    }
}

//// MARK: - 使用示例
//// 在App中调用
//func showRatingScreen(in viewController: UIViewController) {
//    let networkService = MockNetworkService()
//    let tracker = MockTracker()
//    let viewModel = RatingViewModel(networkService: networkService, tracker: tracker)
//    let ratingVC = RatingViewController(viewModel: viewModel)
//
//    // 用模态方式呈现
//    ratingVC.modalPresentationStyle = .formSheet
//    viewController.present(ratingVC, animated: true)
//}
