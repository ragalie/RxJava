classes    = [Java::Rx::Observable, Java::RxObservables::BlockingObservable]
superclass = Java::RxUtilFunctions::Function.java_class

classes.each do |klass|
  function_methods = klass.java_class.declared_instance_methods.select do |method|
    method.public? && method.parameter_types.any? {|type| superclass.assignable_from?(type)}
  end

  methods_by_name = function_methods.group_by(&:name)
  methods_by_name.delete_if do |_, methods|
    signatures_by_function_state = methods.map {|m| m.parameter_types.map {|type| superclass.assignable_from?(type)}}
    signatures_by_function_state != signatures_by_function_state.uniq
  end

  types_by_name_and_signature = Hash[methods_by_name.values.flatten.map do |method|
    [[method.name, *method.parameter_types.map {|type| superclass.assignable_from?(type).to_s}].join(" "), method.parameter_types]
  end]

  methods_by_name.keys.each do |method_name|
    klass.send(:alias_method, "#{method_name}_without_wrapping", method_name)
    klass.send(:remove_method, method_name)
    klass.send(:define_method, method_name) do |*args, &block|
      key = [method_name, *(args + [block].compact).map {|a| a.is_a?(Proc)}].join(" ")

      if types = types_by_name_and_signature[key]
        args = args.each_with_index.map do |arg, idx|
          if arg.is_a?(Proc) && key[idx]
            arg.to_java(types[idx].ruby_class)
          else
            arg
          end
        end

        if block && key[args.length]
          block = block.to_java(types[args.length].ruby_class)
        end
      end

      send("#{method_name}_without_wrapping", *(args + [block].compact))
    end
  end
end
