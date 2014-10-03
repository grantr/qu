class SimpleJob < Qu::Job
end

class CustomQueue < Qu::Job
  queue :custom
end

shared_examples_for 'a backend interface' do
  let(:payload) { Qu::Payload.new(:klass => SimpleJob) }

  it "can push a payload" do
    subject.push payload
  end

  it "can complete a payload" do
    subject.complete payload
  end

  it "can abort a payload" do
    subject.abort payload
  end

  it "can fail a payload" do
    subject.fail payload
  end

  it "can pop" do
    subject.pop
  end

  it "can pop from specific queue" do
    subject.pop('foo')
  end

  it "can get size of default queue" do
    subject.size
  end

  it "can get size of specific queue" do
    subject.size('foo')
  end

  it "can clear default queue" do
    subject.clear
  end

  it "can clear specific queue" do
    subject.clear('foo')
  end

  it 'can reconnect' do
    subject.reconnect
  end

end

shared_examples_for 'a backend' do
  let(:payload) { Qu::Payload.new(:klass => SimpleJob) }

  before do
    subject.clear(payload.queue)
  end

  describe 'push' do
    it 'should return a payload' do
      subject.push(payload).should be_instance_of(Qu::Payload)
    end

    it 'should set the payload id' do
      subject.push(payload)
      payload.id.should_not be_nil
    end

    it 'should add a job to the queue' do
      subject.push(payload)
      payload.queue.should == 'default'
      subject.size(payload.queue).should == 1
    end

    it 'should assign a different job id for the same job pushed multiple times' do
      first = subject.push(payload).id
      second = subject.push(payload).id
      first.should_not eq(second)
    end

    it 'should enqueue the attributes for push' do
      payload.should_receive(:attributes_for_push).and_return({})
      subject.push(payload)
    end
  end

  describe 'pop' do
    it 'should return next job' do
      subject.push(payload)
      subject.pop(payload.queue).id.should == payload.id
    end

    it 'should not return an already popped job' do
      subject.push(payload)
      subject.push(payload.dup)
      subject.pop(payload.queue).id.should_not == subject.pop(payload.queue).id
    end

    it 'should not return job from different queue' do
      subject.push(payload)
      subject.pop('video').should be_nil
    end

    it 'should properly persist args' do
      payload.args = ['a', 'b']
      subject.push(payload)
      subject.pop(payload.queue).args.should == ['a', 'b']
    end

    it 'should properly persist a hash argument' do
      payload.args = [{:a => 1, :b => 2}]
      subject.push(payload)
      subject.pop(payload.queue).args.should == [{'a' => 1, 'b' => 2}]
    end
  end

  describe 'complete' do
    it 'should be defined and accept payload' do
      subject.complete(payload)
    end
  end

  describe 'abort' do
    before do
      subject.push(payload)
    end

    it 'should add the job back on the queue' do
      popped_payload = subject.pop(payload.queue)
      popped_payload.id.should == payload.id
      subject.size(payload.queue).should == 0
      subject.abort(popped_payload)
      subject.size(payload.queue).should == 1
    end
  end

  describe 'fail' do
    it 'should be defined and accept payload' do
      subject.fail(payload)
    end
  end

  describe 'size' do
    it 'should use the default queue by default' do
      subject.size.should == 0
      subject.push(payload)
      subject.size.should == 1
    end
  end

  describe 'clear' do
    it 'should clear jobs for given queue' do
      subject.push(payload)
      subject.size(payload.queue).should == 1
      subject.clear(payload.queue)
      subject.size(payload.queue).should == 0
    end

    it 'should not clear jobs for a different queue' do
      subject.push(payload)
      subject.clear('other')
      subject.size(payload.queue).should == 1
    end
  end

  describe 'connection=' do
    it 'should allow setting the connection' do
      connection = double('a connection')
      subject.connection = connection
      subject.connection.should == connection
    end

    it 'should provide a default connection' do
      subject.connection.should_not be_nil
    end
  end
end

shared_examples_for 'batch pop support' do
  let(:payload1) { Qu::Payload.new(:klass => SimpleJob) }
  let(:payload2) { Qu::Payload.new(:klass => SimpleJob) }
  let(:payload3) { Qu::Payload.new(:klass => SimpleJob) }

  it 'should signal batch pop support' do
    subject.supports_batch_pop?.should == true
  end

  it 'should pop multiple items' do
    subject.push(payload1)
    subject.push(payload2)
    payloads = subject.pop(payload1.queue, 2)
    payloads.map(&:id).should == [payload1.id, payload2.id]
  end

  it 'should pop no more items than exist in the queue' do
    subject.push(payload1)
    subject.push(payload2)
    subject.pop(payload1.queue, 3).size.should == 2
  end

  it 'should return a single item when count is 1' do
    subject.push(payload1)
    subject.pop(payload1.queue, 1).id.should == payload1.id
  end

  it 'should return nil when count is 0' do
    subject.push(payload1)
    subject.pop(payload1.queue, 0).should == nil
  end

  it 'should return an array when count is > 1' do
    subject.push(payload1)
    subject.pop(payload1.queue, 2).map(&:id).should == [payload1.id]
    subject.pop(payload1.queue, 2).should == []
  end

  it 'should not return already popped jobs' do
    subject.push(payload1)
    subject.push(payload2)
    subject.push(payload3)
    payloads = subject.pop(payload1.queue, 2)
    payloads.map(&:id).should == [payload1.id, payload2.id]
    payloads = subject.pop(payload1.queue, 2)
    payloads.map(&:id).should == [payload3.id]
  end
end
