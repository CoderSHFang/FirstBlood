Pod::Spec.new do |spec|
  # 库名称
  spec.name         = "FirstBlood"
  # 版本号
  spec.version      = "0.0.1"
  # Swift版本
  spec.swift_versions   = "5.0"
  # 库简短介绍,以后search到简介
  spec.summary      = "my firstBlood"
  # 开源库地址，或者是博客、社交地址等
  spec.homepage     = "https://github.com/Fat-Brother/FirstBlood"
  # 开源协议
  spec.license      = "MIT"
  # 开源库作者
  spec.author             = { "Fat-Brother" => "email@address.com" }
  # 最低支持 iOS build 的平台
  spec.platform     = :ios, "10.0"
  # 最低开发
  spec.ios.deployment_target = "10.0"
  # 开源库 GitHub 的路径与 tag 值，GitHub路径后必须有 .git,tag 实际就是上面的版本
  spec.source       = { :git => "https://github.com/Fat-Brother/FirstBlood.git", :tag => spec.version }
  # 源库资源文件
  spec.source_files  = "FirstBlood", "SourceFiles/**/*.{h,m,swift}"
  spec.exclude_files = "Classes/Exclude"
  
  spec.requires_arc = true
  
  #项目的依赖库等等
  spec.dependency  "AFNetworking"
  spec.dependency  "SDWebImage"
  spec.dependency  "SSZipArchive"
end
