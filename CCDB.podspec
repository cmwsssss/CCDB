Pod::Spec.new do |spec|

  spec.name         = "CCDB"
  spec.version      = "1.0.3"
  spec.summary      = "CCDB is a database framwork built for Swift."

  spec.description  = <<-DESC
		     CCDB is a database framwork built for Swift.
                   DESC

  spec.homepage     = "https://github.com/cmwsssss/CCDB"

  spec.license      = "MIT"

  spec.author       = { "cmw" => "cmwsssss@hotmail.com" }

  spec.platform     = :ios, "13.0"

  spec.source       = { :git => "https://github.com/cmwsssss/CCDB.git", :tag => "1.0.3" }

  spec.source_files  = "CCDB", "CCDB/**/*.{swift,m,h}"
  spec.exclude_files = "CCDB/Exclude"

end
