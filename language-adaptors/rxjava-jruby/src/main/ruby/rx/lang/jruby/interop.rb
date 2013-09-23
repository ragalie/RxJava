klasses  = [Java::Rx::Observable, Java::RxObservables::BlockingObservable]
function = Java::RxUtilFunctions::Function.java_class

WRAPPERS = {
  Java::RxUtilFunctions::Action.java_class       => Java::RxLangJruby::JRubyActionWrapper,
  Java::RxObservable::OnSubscribeFunc.java_class => Java::RxLangJruby::JRubyOnSubscribeFuncWrapper
}

WRAPPERS.default = Java::RxLangJruby::JRubyFunctionWrapper

klasses.each do |klass|
  function_methods = klass.java_class.declared_instance_methods.select do |method|
    method.public? && method.parameter_types.any? {|type| function.assignable_from?(type)}
  end

  parameter_types = function_methods.group_by(&:name).each_with_object({}) do |(method_name, methods), memo|
    types = methods.map(&:parameter_types).select {|type| function.assignable_from?(type)}.flatten.uniq
    raise ArgumentError, "More than one function type for #{method_name}" if types.length > 1

    memo[method_name] = WRAPPERS[types.first]
  end

  function_methods.map(&:name).uniq.each do |method_name|
    klass.class_eval <<EOS
      def #{method_name}(*args, &block)
        args.map! do |arg|
          if arg.is_a?(Proc)
            #{parameter_types[method_name]}.new(arg)
          else
            arg
          end
        end

        if block_given?
          block = #{parameter_types[method_name]}.new(block)
        end

        super(*args, &block)
      end
EOS
  end
end
