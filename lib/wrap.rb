##
#
  module Wrap; end

##
#
  class << Wrap
    Version = '0.5.0' unless defined?(Version)

    def version
      Version
    end

    def dependencies
      {
        'map'        =>  [ 'map'         , ' >= 4.7.1'   ]
      }
    end
  end

##
#
  begin
    require 'rubygems'
    Wrap.dependencies.each{|name, dependency| gem(*dependency)}
  rescue LoadError
    nil
  end

##
#
  require 'map'

##
#
  module Wrap
    def Wrap.included(other)
      super
    ensure
      other.send(:instance_eval, &ClassMethods)
      other.send(:class_eval, &InstanceMethods)
    end

    def Wrap.code_for(name)
      <<-__
        def #{ name }(*args, &block)
          if running_callbacks?(#{ name.inspect })
            return wrapped_#{ name }(*args, &block)
          end

          running_callbacks(#{ name.inspect }) do
            catch(:halt) do
              return false unless run_callbacks(:before, #{ name.inspect }, args)

              begin
                result = wrapped_#{ name }(*args, &block)
              ensure
                run_callbacks(:after, #{ name.inspect }, [result]) unless $!
              end
            end
          end
        end
      __
    end

    ClassMethods = proc do
      def method_added(name)
        return super if wrapping?
        begin
          super
        ensure
          rewrap!(name) if wrapped?(name)
        end
      end

      def include(other)
        super
      ensure
        other.instance_methods.each do |name|
          if wrapped?(name)
            begin
              remove_method(name)
            rescue NameError
              nil
            end
            rewrap!(name)
          end
        end
      end

      def wrap(name, *args, &block)
        define_method(name){} unless method_defined?(name)
        wrap!(name)
      end

      def wrapped?(name)
        method_defined?("wrapped_#{ name }")
      end

      def wrap!(name)
        name = name.to_s
        method = instance_method(name)

        wrapping! name do
          name = name.to_s
          wrapped_name = "wrapped_#{ name }"

          begin
            remove_method(wrapped_name)
          rescue NameError
            nil
          end

          alias_method(wrapped_name, name)

          module_eval(Wrap.code_for(name))
        end
      end

      def rewrap!(name)
        wrap!(name)
      end

      def wrapping!(name, &block)
        name = name.to_s
        @wrapping ||= []

        return if @wrapping.last == name

        @wrapping.push(name)

        begin
          block.call
        ensure
          @wrapping.pop
        end
      end

      def wrapping?(*name)
        @wrapping ||= []

        if name.empty?
          !@wrapping.empty?
        else
          @wrapping.last == name.last.to_s
        end
      end

      def callbacks
        @callbacks ||= Map.new
      end

      def initialize_callbacks!(name)
        callbacks[name] ||= Map[ :before, [], :after, [] ]
        callbacks[name]
      end

      def before(name, *args, &block)
        cb = initialize_callbacks!(name)
        cb.before.push(args.shift || block)
      end

      def after(name, *args, &block)
        cb = initialize_callbacks!(name)
        cb.after.push(args.shift || block)
      end
    end

    InstanceMethods = proc do
      def running_callbacks(name, &block)
        name = name.to_s
        @running_callbacks ||= []
        return block.call() if @running_callbacks.last == name

        @running_callbacks.push(name)

        begin
          block.call()
        ensure
          @running_callbacks.pop
        end
      end

      def running_callbacks?(*name)
        @running_callbacks ||= []

        if name.empty?
          @running_callbacks.last
        else
          @running_callbacks.last == name.last.to_s
        end
      end

      def run_callbacks(which, name, argv)
        which = which.to_s.to_sym
        name = name.to_s
        list = []

        self.class.ancestors.each do |ancestor|
          break unless ancestor.respond_to?(:callbacks)

          if ancestor.callbacks.is_a?(Map) and ancestor.callbacks[name].is_a?(Map)
            callbacks = ancestor.callbacks[name][which]
            accumulate = (which == :before ? :unshift : :push)
            list.send(accumulate, *callbacks) if callbacks.is_a?(Array)
          end
        end

        list.each do |callback|
          block = callback.respond_to?(:call) ? callback : proc{ send(callback.to_s.to_sym) }
          args = argv.slice(0 .. (block.arity > 0 ? block.arity : -1))
          result = instance_exec(*args, &block)
          return false if result == false
        end

        true
      end

      def halt!(*args)
        value = args.size == 0 ? false : args.shift
        throw(:halt, value)
      end
    end
  end