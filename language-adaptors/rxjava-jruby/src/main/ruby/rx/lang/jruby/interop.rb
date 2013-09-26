require 'pp'

klasses  = [Java::Rx::Observable, Java::RxObservables::BlockingObservable]
function = Java::RxUtilFunctions::Function.java_class

WRAPPERS = {
  Java::RxUtilFunctions::Action         => Java::RxLangJruby::JRubyActionWrapper,
  Java::Rx::Observable::OnSubscribeFunc => Java::RxLangJruby::JRubyOnSubscribeFuncWrapper
}

WRAPPERS.default = Java::RxLangJruby::JRubyFunctionWrapper

klasses.each do |klass|
  function_methods = klass.java_class.declared_instance_methods.select do |method|
    method.public? && method.parameter_types.any? {|type| function.assignable_from?(type)}
  end

  parameter_types = {}
  function_methods.each do |method|
    parameter_types[method.name] ||= []

    method.parameter_types.each_with_index do |type, idx|
      next unless function.assignable_from?(type)

      constructor = WRAPPERS.find do |java_class, wrapper|
        type.ruby_class.ancestors.include?(java_class)
      end

      constructor = (constructor && constructor.last) || WRAPPERS.default

      parameter_types[method.name][idx] ||= []
      parameter_types[method.name][idx] << constructor
    end
  end

  parameter_types.each_pair do |method_name, types|
    types.map! do |type|
      next type.first if type && type.uniq.length == 1
      nil
    end
  end

  parameter_types.each_pair do |method_name, types|
    next if types.all?(&:nil?)

    klass.send(:alias_method, "#{method_name}_without_wrapping", method_name)
    klass.send(:define_method, method_name) do |*args, &block|
      args = args.each_with_index.map do |arg, idx|
        if arg.is_a?(Proc) && types[idx]
          types[idx].new(JRuby.runtime.get_current_context, arg)
        else
          arg
        end
      end

      if block && types[args.length]
        block = types[args.length].new(JRuby.runtime.get_current_context, block)
      end

      send("#{method_name}_without_wrapping", *(args + [block].compact))
    end
  end
end
