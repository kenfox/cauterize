module Cauterize
  module_function

  def fixed_array(name, desc=nil)
    a = Cauterize.fixed_arrays[name] || Cauterize.fixed_arrays[name] = FixedArray.new(name, desc)
    yield a if block_given?
    return a
  end

  def fixed_array!(name, &blk)
    if Cauterize.fixed_arrays[name]
      raise Exception.new("FixedArray with name #{name} already exists.")
    else
      Cauterize.fixed_array(name, &blk)
    end
  end

  def fixed_arrays
    @fixed_ararys ||= {}
  end

  class FixedArray < BaseType
    def initialize(name, desc=nil)
      super
    end

    def array_type(t = nil)
      if t
        @array_type = BaseType.find_type!(t)
      else
        @array_type
      end
    end

    def array_size(s = nil)
      if s
        @array_size = s
      else
        @array_size
      end
    end

    protected

    def local_hash(digest)
      digest.update(@array_size.to_s)
      @array_type.type_hash(digest)
    end
  end
end
