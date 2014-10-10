require 'spec_helper'
require 'qu-nsq'

describe Qu::Backend::NSQ do

  it_should_behave_like 'a backend'
  it_should_behave_like 'a backend interface'
end
