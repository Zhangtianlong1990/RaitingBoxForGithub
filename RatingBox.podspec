Pod::Spec.new do |s|
  s.name             = 'RatingBox'
  s.version          = '0.2.2'
  s.summary          = 'A customizable rating component for iOS apps'
  s.description      = <<-DESC
  RatingBox is a customizable, MVVM-based rating component for iOS applications.
  It features Combine-based data binding, dependency injection for services,
  and supports both light/dark modes. Perfect for collecting user feedback.
                       DESC
  s.homepage         = 'https://gitee.com/talon163/rating-box2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Talon' => '1126223047@qq.com' }
  s.source           = { :git => 'https://gitee.com/talon163/rating-box2.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'
  s.swift_versions = ['5.0']
  s.source_files = 'RatingBox/Classes/**/*'
  
  s.resource_bundles = {
    'RatingBoxAssets' => ['RatingBox/Assets/RatingBox.xcassets'],
    'RatingBoxMedia' => ['RatingBox/Assets/Media.xcassets']
  }

  # 添加依赖
  s.dependency 'Network', '0.1.2'
  s.dependency 'SnapKit', '~> 5.0'  # 允许任何 5.x.x 版本
end
