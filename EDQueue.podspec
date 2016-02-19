Pod::Spec.new do |s|
  s.name         = 'EDQueue'
  s.version      = '0.7.3'
  s.license      = 'MIT'
  s.summary      = 'A persistent background job queue for iOS.'
  s.homepage     = 'https://github.com/gelosi/queue'
  s.authors      = {'Andrew Sliwinski' => 'andrewsliwinski@acm.org', 'Francois Lambert' => 'flambert@mirego.com', 'Oleg Shanyuk' => 'oleg.shanyuk@gmail.com'}
  s.source       = { :git => 'https://github.com/gelosi/queue.git', :tag => 'v0.7.3' }
  s.platform     = :ios, '7.0'
  s.source_files = 'EDQueue'
  s.library      = 'sqlite3.0'
  s.requires_arc = true
  s.dependency 'FMDB', '~> 2.1'
end
