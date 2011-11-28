
Testing Wrap do

##
#
  testing 'that wrap can be included in a class' do
    assert do
      Class.new do
        include Wrap
      end
    end
  end

##
#
  testing 'that a method can be wrapped ***after*** it is defined' do
    assert do
      wrapped_class do
        def foo() 42 end

        assert{ new.foo() == 42 }

        wrap :foo

        assert{ new.foo() == 42 }
      end
    end
  end

##
#
  testing 'that a method can be wrapped ***before*** it is defined' do
    assert do
      wrapped_class do
        assert_raises(NoMethodError){ new.foo() }

        wrap :foo

        assert_nothing_raised{ new.foo() }
      end
    end
  end

##
#
  testing 'that wrapping gives :before and :after goodness' do
    assert do
      wrapped_class do
        wrap :foo

        define_method(:foo){ accum.push(42) }

        before(:foo){ accum.push(:before) }
        after(:foo){ accum.push(:after) }

        assert {
          c = new
          c.foo()
          c.accum == [:before, 42, :after]
        }
      end
    end
  end

##
#
  testing 'that callbacks are halted with "false" iff they return "false"' do
    assert do
      wrapped_class do
        wrap :foo

        define_method(:foo){ accum.push(42) }

        before(:foo){ accum.push(:foo) }
        before(:foo){ accum.push(:bar); return false}
        before(:foo){ accum.push(:foobar) }

        assert {
          c = new
          c.foo()
          c.accum == [:foo, :bar]
        }
      end
    end
  end

##
#
  testing 'that callbacks can be halted with "halt!"' do
    assert do
      wrapped_class do
        wrap :foo

        define_method(:foo){ accum.push(42) }

        before(:foo){ accum.push(:foo) }
        before(:foo){ accum.push(:bar); halt!}
        before(:foo){ accum.push(:foobar) }

        assert {
          c = new
          c.foo()
          c.accum == [:foo, :bar]
        }
      end
    end

    assert do
      wrapped_class do
        wrap :foo

        define_method(:foo){ accum.push(42) }

        after(:foo){ accum.push(:foo) }
        after(:foo){ accum.push(:bar); halt!}
        after(:foo){ accum.push(:foobar) }

        assert {
          c = new
          c.foo()
          c.accum == [42, :foo, :bar]
        }
      end
    end
  end

##
#
  testing 'that :before callbacks are passed the number of args they can eat, and no more' do
    c =
      assert do
        wrapped_class do
          wrap :foo

          define_method(:foo){|*a|}

          before(:foo){|x| accum.push([x]) }
          before(:foo){|x,y| accum.push([x,y]) }
          before(:foo){|x,y,z| accum.push([x,y,z]) }
        end
      end
    
    assert do
      o = c.new
      o.foo(1,2,3)
      assert o.accum === [[1], [1,2], [1,2,3]]
      true
    end
  end

##
#
  testing 'that :after callbacks are passed result of the method they follow, iff possible' do
    c =
      assert do
        wrapped_class do
          wrap :foo

          define_method(:foo){ result = [1,2,3] }

          after(:foo){ accum.push(:nada) }
          after(:foo){|result| accum.push(result) }
        end
      end
    
    assert do
      o = c.new
      o.foo()
      assert o.accum === [:nada, [1,2,3]]
      true
    end
  end

##
#
  testing 'that callbacks are inherited cleverly' do
    c =
      assert do
        wrapped_class do
          wrap :foo

          define_method(:foo){}

          before(:foo){ accum.push(:before_superclass) }
          after(:foo){ accum.push(:after_superclass) }
        end
      end

    assert do
      o = c.new
      o.foo()
      assert o.accum === [:before_superclass, :after_superclass]
    end

    b =
      assert do
        Class.new(c) do
          before(:foo){ accum.push(:before_subclass) }
          after(:foo){ accum.push(:after_subclass) }
        end
      end

    assert do
      o = b.new
      o.foo()
      assert o.accum === [:before_superclass, :before_subclass,    :after_subclass, :after_superclass]
    end
  end


private
  def wrapped_class(&block)
    tc = self

    c =
      Class.new do
        include Wrap

        const_set(:TC, tc)

        def self.method_missing(method, *args, &block)
          case method.to_s
            when /^\Aassert/
              const_get(:TC).send(method, *args, &block)
            else
              super
          end
        end

        def accum
          @accum ||= []
        end

        module_eval(&block)
      end

    c
  end
end


BEGIN {
  testdir = File.dirname(File.expand_path(__FILE__))
  rootdir = File.dirname(testdir)
  libdir = File.join(rootdir, 'lib')
  require File.join(libdir, 'wrap')
  require File.join(testdir, 'testing')
}
