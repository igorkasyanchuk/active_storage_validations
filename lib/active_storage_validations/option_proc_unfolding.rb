module ActiveStorageValidations
  module OptionProcUnfolding

    def unfold_procs(record, object, only_keys)
      case object
      when Hash
        object.merge(object) { |key, value| only_keys&.exclude?(key) ? {} : unfold_procs(record, value, nil) }
      when Array
        object.map { |o| unfold_procs(record, o, only_keys) }
      else
        object.is_a?(Proc) ? object.call(record) : object
      end
    end

  end
end
