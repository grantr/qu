module Qu
  class BatchJob < Job
    include Enumerable

    def self.batch_size(size = nil)
      @batch_size = size if size
      @batch_size ||= 1
    end

    def self.batch_job?
      true
    end

    def full?
      batch.size >= self.class.batch_size
    end

    def batch
      if payload.respond_to?(:each)
        payload
      else
        payload.nil? ? [] : [payload]
      end
    end

    def each(&block)
      batch.each do |current_payload|
        @current_payload = current_payload
        yield *current_payload.args
        @current_payload = nil
      end
    end

    def each_payload(&block)
      batch.each do |current_payload|
        @current_payload = current_payload
        yield current_payload
        @current_payload = nil
      end
    end
  end
end