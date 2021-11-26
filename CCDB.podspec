Pod::Spec.new do |spec|

  spec.name         = "CCDB"
  spec.version      = "1.0.0"
  spec.summary      = "CCDB is a database framwork built for Swift."

  spec.description  = <<-DESC
		     CCDB is a database framwork built for Swift.
                   DESC

  spec.homepage     = "https://github.com/cmwsssss/CCDB"

  spec.license      = "MIT"

  spec.author       = { "cmw" => "cmwsssss@hotmail.com" }

  spec.platform     = :ios, "13.0"

  spec.source       = { :git => "https://github.com/cmwsssss/CCDB.git", :tag => "1.0.0" }

  spec.source_files  = "CCDB", "CCDB/**/*.{swift}"
  spec.exclude_files = "CCDB/Exclude"

end
