require 'json'

module Qu
  module Backend
    class Base
      include Logger
      attr_accessor :connection

      # Public: Override in subclass.
      def push(payload)
        payload.id = SecureRandom.uuid
        payload.perform
      end

      # Public: Override in subclass.
      def complete(payload)
      end

      # Public: Override in subclass.
      def abort(payload)
      end

      # Public: Override in subclass.
      def fail(payload)
      end

      # Public: Override in subclass.
      #
      # queue - Name of queue to pop from
      # count - Optional number of items to pop (if supported)
      def pop(queue = 'default', count = nil)
      end

      # Public: Override in subclass.
      def size(queue = 'default')
        0
      end

      # Public: Override in subclass.
      def clear(queue = 'default')
      end

      # Public: Override in subclass.
      def reconnect
      end

      private

      def dump(data)
        Qu.dump_json(data)
      end

      def load(data)
        Qu.load_json(data)
      end
    end
  end
end
