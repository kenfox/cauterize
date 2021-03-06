require 'tmpdir'
require 'fileutils'

module Cauterize
  describe Cauterize::CBuilder do
    before do
      @tempdir = Dir.mktmpdir
      @h_path = File.join(@tempdir, "testing.h")
      @c_path = File.join(@tempdir, "testing.c")

      @cb = CBuilder.new(@h_path, @c_path, "testing")
    end
    after { FileUtils.rm_rf @tempdir }

    describe :initialize do
      it "saves the h and c paths" do
        @cb.h.should == @h_path
        @cb.c.should == @c_path
      end
    end

    describe :build do
      before do
        Cauterize.set_version("1.2.3")

        Cauterize.scalar(:small_uint) {|t| t.type_name(:uint8)}

        Cauterize.fixed_array(:mac_address) do |fa|
          fa.array_type :small_uint
          fa.array_size 6
        end

        Cauterize.variable_array(:mac_table) do |t|
          t.array_type :mac_address
          t.array_size 64
        end

        Cauterize.variable_array(:name) do |va|
          va.array_type :small_uint
          va.array_size 32
        end

        Cauterize.enumeration(:gender) do |e|
          e.value :male
          e.value :female
        end

        Cauterize.composite(:place) do |c|
          c.field :name, :name
          c.field :elevation, :uint32
        end

        Cauterize.composite(:person) do |c|
          c.field :first_name, :name
          c.field :last_name, :name
          c.field :gender, :gender
        end

        Cauterize.composite(:dog) do |c|
          c.checksum
          c.field :name, :name
          c.field :gender, :gender
          c.field :leg_count, :small_uint
        end

        Cauterize.group(:creature) do |g|
          g.field :person, :person
          g.field :dog, :dog
        end

        @cb.build
        @h_text = File.read(@cb.h)
        @h_lines = @h_text.lines.to_a
        @c_text = File.read(@cb.c)
        @c_lines = @c_text.lines.to_a
      end

      describe "header generation" do
        it "informs the user the code is generated" do
          @h_text.should include("generated code. Do not edit")
        end

        it "externs 'c'" do
          @h_lines.should include("extern \"C\" {\n")
        end

        it "creates a VERSION define" do
          @h_lines.should include("#define GEN_VERSION (\"1.2.3\")\n")
        end

        it "creates a DATE define" do
          @h_lines.any?{|l| l.match /GEN_DATE/}.should be_true
        end

        it "prevents multiple inclusion in headers" do
          @h_lines[2].should match /#ifndef TESTING_H_\d+/
          @h_lines[3].should match /#define TESTING_H_\d+/
          @h_lines[-2].should match /#endif \/\* TESTING_H_\d+ \*\//
          @h_lines.last.should == "\n"
        end

        it "includes prototype information for all defined types" do
          @h_text.should match "struct name;"
          @h_text.should match "struct person;"
          @h_text.should match "struct place;"
        end

        it "includes enumeration and structure definitions" do
          @h_text.should match /gender/
          @h_text.should match /MALE = 0/
          @h_text.should match /FEMALE = 1/
        end

        it "includes constant (enum) definitions for fixed and variable arrays" do
          @h_text.should match /FIXED_ARRAY_LENGTH_mac_address/
          @h_text.should match /VARIABLE_ARRAY_MAX_LENGTH_mac_table/
          @h_text.should match /VARIABLE_ARRAY_MAX_LENGTH_name/
        end

        it "includes constant (enum) definitions for maximum encoded length" do
          @h_text.should match /MAX_ENCODED_LENGTH_small_uint/
          @h_text.should match /MAX_ENCODED_LENGTH_mac_address/
          @h_text.should match /MAX_ENCODED_LENGTH_mac_table/
          @h_text.should match /MAX_ENCODED_LENGTH_name/
          @h_text.should match /MAX_ENCODED_LENGTH_gender/
          @h_text.should match /MAX_ENCODED_LENGTH_place/
          @h_text.should match /MAX_ENCODED_LENGTH_person/
          @h_text.should match /MAX_ENCODED_LENGTH_dog/
          @h_text.should match /MAX_ENCODED_LENGTH_creature/
        end
      end

      describe "c body generation" do
        it "informs the user the code is generated" do
          @c_text.should include("generated code. Do not edit")
        end

        it "includes the generated header file" do
          @c_text.should match /#include "testing.h"/
        end

        it "uses the fixed array length constant (enum) define" do
          @c_text.should match /FIXED_ARRAY_LENGTH_mac_address/
        end

        it "does not compute checksum on persons" do
          @c_text.match(/Unpack_person.*?return CA_OK/m) { |code|
            code[0].should match /first_name/
            code[0].should_not match /Checksum/
          }
          @c_text.match(/Pack_person.*?return CA_OK/m) { |code|
            code[0].should match /first_name/
            code[0].should_not match /Checksum/
          }
        end

        it "computes the checksum on dogs" do
          @c_text.match(/Pack_dog.*?return CA_OK/m) { |code|
            code[0].should match /leg_count/
            code[0].should match /Checksum/
          }
          @c_text.match(/Unpack_dog.*?return CA_OK/m) { |code|
            code[0].should match /leg_count/
            code[0].should match /Checksum/
          }
        end
      end

      describe "compilation" do
        it "can be built" do
          caut_dir = "#{File.dirname(__FILE__)}/../support/c/src"

          res = Dir.chdir @tempdir do
            File.open("test_main.c", "wb") do |fh|
              syms = BaseType.all_instances.map do |i|
                b = Builders.get(:c, i)
                [b.packer_sym, b.unpacker_sym]
              end.flatten
              fh.write(gen_test_main(syms))
            end

            cmd = %W{
              gcc -Wall -Wextra -Werror
              -I#{caut_dir}
              #{@cb.c}
              #{caut_dir}/cauterize.c
              test_main.c
              -o testing.bin 2>&1
            }.join(" ")

            `#{cmd}`
          end

          res.should == ""
        end
      end
    end
  end
end
