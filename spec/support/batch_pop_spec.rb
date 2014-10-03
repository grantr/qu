shared_examples_for 'batch pop support' do
  let(:payload1) { Qu::Payload.new(:klass => SimpleJob) }
  let(:payload2) { Qu::Payload.new(:klass => SimpleJob) }
  let(:payload3) { Qu::Payload.new(:klass => SimpleJob) }

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
