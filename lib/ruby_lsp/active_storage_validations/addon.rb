module RubyLsp
  module ActiveStorageValidations
    class Addon < ::RubyLsp::Addon
      def activate(global_state, message_queue)
        @message_queue = message_queue
      end

      def name
        "Ruby LSP ActiveStorage Validations"
      end

      def version
        "0.1.0"
      end

      def create_hover_listener(response_builder, node_context, dispatcher)
        RubyLsp::ActiveStorageValidations::Hover.new(response_builder, dispatcher)
      end
    end
  end
end
