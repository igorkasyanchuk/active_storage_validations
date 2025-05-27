module RubyLsp
  module ActiveStorageValidations
    class Hover
      include RubyLsp::Requests::Support::Common

      def initialize(response_builder, dispatcher)
        @response_builder = response_builder
        dispatcher.register(self, :symbol_node)
      end

      def on_symbol_node(node)
        if node.value == :size
          @response_builder.push(
            Prism::Location.new(node.location.start_offset, node.location.end_offset),
            {
              kind: "markdown",
              value: "**`size` (ActiveStorage Validations)**\n\n" \
                     "Validates the size of an attached file.\n\n" \
                     "[Documentation](https://github.com/rails/active_storage_validations#size)"
            }
          )
        end
      end
    end
  end
end
