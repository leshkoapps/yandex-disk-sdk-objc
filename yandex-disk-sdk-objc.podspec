Pod::Spec.new do |s|
  s.name         = 'yandex-disk-sdk-objc'
  s.version      = '1.0.0'
  s.summary      = 'A pleasant wrapper around the Yandex Disk Cloud API.'
  s.homepage     = 'https://github.com/yandex-disk/yandex-disk-sdk-objc'
  s.author       = { 'Yandex' => 'https://yandex.ru' }
  s.source       = { :git => 'https://github.com/leshkoapps/yandex-disk-sdk-objc.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.platform     = :ios, '9.0'

  s.source_files = ''sdk/*.{h,m}'
  s.framework    = 'Foundation'
  s.dependency 'KissXML'
end