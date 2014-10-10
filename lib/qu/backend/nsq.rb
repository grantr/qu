require 'krakow'
require 'securerandom'

# Only tell me about things I need to know
Krakow::Utils::Logging.level = :warn

module Qu
  module Backend
    # endpoints we need:
    # nsqd tcp://127.0.0.1:4150
    # nsqd http://127.0.0.1:4151 (only needed for size)
    # allow producer endpoint to be tcp:// or http://
    # nsqlookupd http://127.0.0.1:4161
    # consumer can use nsqlookupd OR nsqd tcp

    # Could potentially support nsq-ruby as well so producers don't have to
    # use celluloid (nsq-ruby is also threaded, but as no dependencies)
    # krakow http producer doesn't use celluloid
    # or get krakow to load celluloid only when needed (if only using http
    # producers, then no need to load celluloid)
    class NSQ < Base
      attr_writer :channel_name
      attr_accessor :abort_timeout

      def push(payload)
        payload.id = SecureRandom.uuid
        producer_for(payload.queue).write(dump(payload.attributes_for_push))
        payload
      end

      def complete(payload)
        payload.nsq_message.confirm
      end

      def abort(payload)
        payload.nsq_message.requeue
      end

      def fail(payload)
        payload.nsq_message.requeue
      end

      def touch(payload)
        payload.nsq_message.touch
      end

      def pop(queue_name = 'default')
        consumer = consumer_for(queue_name)
        unless consumer.queue.empty?
          message = consumer.queue.pop
          data = load(message.message)
          Payload.new(
            :id          => data['id'],
            :klass       => data['klass'],
            :args        => data['args'],
            :nsq_message => message
          )
        end
      end

      # See http://dev.bitly.com/nsq.html#v3_nsq_stats
      def size(queue_name = 'default')
        size = 0
        with_http_producer(queue_name) do |producer|
          stats = producer.stats.data
          if topic = stats['topics'].detect { |topic| topic['topic_name'] == queue_name }
            if channel = topic['channels'].detect { |channel| channel['channel_name'] == channel_name }
              size = channel['depth'] + channel['deferred_count']
            end
          end
        end
        size
      end

      def clear(queue_name = 'default')
        with_http_producer(queue_name) do |producer|
          producer.empty_topic
        end
      end

      def reconnect
        producers.each do |_, producer|
          producer.terminate
        end
        consumers.each do |_, consumer|
          consumer.terminate
        end
      end

      def producers
        @producers ||= {}
      end

      def producer_for(queue_name)
        #TODO thread safety
        producers[queue_name] ||= init_producer(queue_name)
      end

      def init_producer(queue_name)
        #TODO allow http producer
        options = {
          :host => '127.0.0.1',
          :port => '4150',
          :topic => queue_name
        }

        producer = Krakow::Producer.new(options)
        add_finalizer(producer)
        producer
      end

      def with_http_producer(queue_name)
        #TODO check for a cached http producer
        http_producer = Krakow::Producer::Http.new(
          :endpoint => 'http://127.0.0.1:4151',
          :topic => queue_name
        )
        result = yield http_producer
        result
      end

      def consumers
        @consumers ||= {}
      end

      def consumer_for(queue_name)
        #TODO thread safety
        consumers[queue_name] ||= init_consumer(queue_name)
      end

      def init_consumer(queue_name)
        #TODO allow direct to nsqd
        options = {
          :nsqlookupd => 'http://127.0.0.1:4161',
          :topic => queue_name,
          :channel => channel_name,
          :max_in_flight => 1,
          :connection_options => {
            :user_agent => "Qu/#{Qu::VERSION} (Krakow/#{Krakow::VERSION})"
          }
        }

        if @abort_timeout
          options[:connection_options][:msg_timeout] = @abort_timeout
        end

        consumer = Krakow::Consumer.new(options)
        add_finalizer(consumer)
        consumer
      end

      def add_finalizer(actor)
        ObjectSpace.define_finalizer(self, lambda { self.class.finalize_actor(actor) })
      end

      def channel_name
        @channel_name ||= 'qu'
      end

      def self.finalize_actor(actor)
        actor.terminate
      end

      def connection=(connection)
        @connection = connection
      end

      # TODO Could create an object that includes addresses?
      def connection
        @connection ||= OpenStruct.new(:name => 'hello')
      end
    end
  end
end
