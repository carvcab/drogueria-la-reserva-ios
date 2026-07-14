platform :ios, '16.0'

target 'LaReserva' do
  use_frameworks!
  use_modular_headers!

  pod 'FirebaseCore', '~> 11.0'
  pod 'FirebaseFirestore', '~> 11.0'
  pod 'FirebaseStorage', '~> 11.0'
  pod 'FirebaseAuth', '~> 11.0'
  pod 'FirebaseAnalytics', '~> 11.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
