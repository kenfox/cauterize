describe Cauterize do
  before do
    @f = default_formatter
    reset_for_test
  end

  describe Scalar do
    describe :format_decl do
      it "declares an scalar" do
        scalar(:foo).format_decl(@f, "bar")
        @f.to_s.should == "foo bar;"
      end
    end

    describe :format_h_proto do
      it "does nothing" do
        scalar(:foo).format_h_proto(@f)
        @f.to_s.should == ""
      end
    end

    describe :format_h_defn do
      it "produces the packer" do
        scalar(:foo).format_h_defn(@f)
        @f.to_s.should match Regexp.escape("CAUTERIZE_STATUS_T Pack_foo(struct Cauterize * dst, foo * src);")
      end
      it "produces the unpacker" do
        scalar(:foo).format_h_defn(@f)
        @f.to_s.should match Regexp.escape("CAUTERIZE_STATUS_T Unpack_foo(struct Cauterize * src, foo * dst);")
      end
    end

    describe :format_c_defn do
      before { scalar(:foo).format_c_defn(@f) }

      it "formats the definition of the packing function" do
        @f.to_s.should match Regexp.escape("Pack_foo")
        @f.to_s.should match Regexp.escape("return")
      end

      it "formats the definition of the unpacking function" do
        @f.to_s.should match Regexp.escape("Unpack_foo")
        @f.to_s.should match Regexp.escape("return")
      end
    end

    describe :render_c do
      it "renders the type" do
        scalar(:foo).render_c.should == "foo"
      end
    end

    describe :pack_sym do
      it "is the symbol used for the packing function" do
        scalar(:foo).pack_sym.should == "Pack_foo"
      end
    end
    describe :unpack_sym do
      it "is the symbol used for the unpacking function" do
        scalar(:foo).unpack_sym.should == "Unpack_foo"
      end
    end
  end
end