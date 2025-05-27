module RubyLsp
  module ActiveStorageValidations
    class Hover
      include RubyLsp::Requests::Support::Common

      def initialize(response_builder, dispatcher)
        @response_builder = response_builder
        dispatcher.register(self, :pair_node)
      end

      def on_pair_node(node)
        key_node = node.key

        return unless key_node.type == :label && key_node.value == "size"

        @response_builder.push(
          Prism::Location.new(key_node.location.start_offset, key_node.location.end_offset),
          {
            kind: "markdown",
            value: "**`size` validator (ActiveStorage Validations)**\n\n" \
                   "Validates the size of an attached file or image.\n\n" \
                   "[📘 Documentation](https://github.com/rails/active_storage_validations#size)"
          }
        )
      end
    end
  end
end
