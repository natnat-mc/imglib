-- load modules before so that patches are actually effective
(require 'json').null=(require 'JSON').null
require 'mooncake'

-- patch stuff
require './fs'
require './mooncake'
require './res'
