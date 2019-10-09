platform :ios, '9.0'

target 'V2EX' do
    use_frameworks!

    # Yep.
    inhibit_all_warnings!

    # Pods for V2EX

    # Networking
    pod 'Alamofire'
    pod 'Kingfisher'

    # Rx
    pod 'RxSwift', '~> 4.0' #, git: 'https://github.com/ReactiveX/RxSwift.git', branch: 'rxswift4.0-swift4.0'
    pod 'RxCocoa', '~> 4.0'
    pod 'NSObject+Rx'
    pod 'RxOptional'

    # UI
    pod 'SnapKit'
    pod 'UIView+Positioning'
    pod 'PKHUD'
    pod 'SwiftMessages'
    pod 'StatefulViewController'
    pod 'SKPhotoBrowser'
    pod 'PullToRefreshKit' , git: 'https://github.com/aidevjoe/PullToRefreshKit.git'
    pod 'Aquaman'

    # Parse
    pod 'Kanna'

    # Rich text
    pod 'YYText', git: 'https://github.com/aidevjoe/YYText'
    pod 'MarkdownView'

    # Misc
    pod 'IQKeyboardManagerSwift'
    pod 'PasswordExtension'
    pod 'DeviceKit'
    
    # Analytics And Crashes
    pod 'AppCenter'
    
#    pod 'JPush'

    # Debug only
#    pod 'Bagel', :configurations => ['Debug']
    pod 'LookinServer', :configurations => ['Debug']
    pod 'Reveal-SDK', '~> 20', :configurations => ['Debug']
end

post_install do |installer|

    # 需要指定编译版本的第三方库名称
    swift3_targets = ['StatefulViewController']
    installer.pods_project.targets.each do |target|
        if swift3_targets.include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end
    end
end
