require 'time'

module Cauterize
  class RubyBuilder
    attr_reader :rb
    def initialize(rb_file, name="cauterize")
      @rb = rb_file
      @name = name.camel
    end

    def build
      build_rb
    end

    def build_rb
      f = []

      f << "# WARNING: This is generated code. Do not edit this file directly."
      f << ""
      f << "require_relative './cauterize_ruby_builtins'"
      f << ""
      f << "module #{Cauterize.get_name.camel}"
      f << ""
      f << "  CAUTERIZE_GEN_VERSION = \"#{Cauterize.get_version}\""
      f << "  CAUTERIZE_GEN_DATE = \"#{DateTime.now.to_s}\""
      f << ""

      f << "  CAUTERIZE_MODEL_HASH_LEN = #{BaseType.digest_class.new.length}"
      f << "  CAUTERIZE_MODEL_HASH = [#{BaseType.model_hash.bytes.to_a.join(", ")}]"
      f << ""

      instances = BaseType.all_instances
      builders = instances.map {|i| Builders.get(:ruby, i)}
      builders.each { |b| b.class_defn(f) }
      f << "end"
      f << ""

      File.open(@rb, "wb") do |fh|
        fh.write(f.join("\n").to_s)
      end
    end

  end
end
