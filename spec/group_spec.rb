module Cauterize
  describe Cauterize do
    describe :group do
      it { creates_a_named_object(:group, Group) }
      it { retrieves_obj_with_identical_name(:group) }
      it { yields_the_object(:group) }
      it { adds_object_to_hash(:group, Cauterize.groups) }
    end

    describe :group! do
      it { creates_a_named_object(:group!, Group) }
      it { raises_exception_with_identical_name(:group!) }
      it { yields_the_object(:group!) }
      it { adds_object_to_hash(:group!, Cauterize.groups) }
    end

    describe :groups do
      it { is_hash_of_created_objs(:group, Cauterize.groups) }
    end

    describe GroupField do
      describe :initialize do
        it "creats a GroupField" do
          t = Cauterize.scalar(:type)
          f = GroupField.new(:name, :type)
          f.name.should == :name
          f.type.should be t
        end
      end
    end

    describe Group do
      describe :initialize do
        it "makes a new Group" do
          Group.new(:foo).name == :foo
        end

        it "creates the tag enum" do
          e = Group.new(:foo).tag_enum
          e.name.should == :group_foo_type
          e.values == {}
        end
      end

      it { can_be_documented(Cauterize::Group) }

      describe :field do
        it "adds a field to the Group" do
          a = Cauterize.scalar(:aaa)
          b = Cauterize.scalar(:bbb)
          grp = Cauterize.group(:foo) do |g|
            g.field(:a, :aaa)
            g.field(:b, :bbb)
          end

          grp.fields.values.map(&:name).should == [:a, :b]
        end

        it "errors on duplicate field names" do
          a = Cauterize.scalar(:aaa)
          lambda {
            grp = Cauterize.group(:foo) do |g|
              g.field(:a, :aaa)
              g.field(:a, :aaa)
            end
          }.should raise_error /Field name a already used/
        end

        it "errors on non-existant types" do
          lambda {
            grp = Cauterize.group(:foo) do |g|
              g.field(:a, :aaa)
            end
          }.should raise_error /name aaa does not correspond to a type/
        end

        it "adds a new value to the enum for each field" do
          a = Cauterize.scalar(:aaa)
          b = Cauterize.scalar(:bbb)
          grp = Cauterize.group(:foo) do |g|
            g.field(:a, :aaa)
            g.field(:b, :bbb)
          end

          grp.tag_enum.values.keys.should =~ [:GROUP_FOO_TYPE_A, :GROUP_FOO_TYPE_B]
        end

        it "allows nil types" do
          grp = Cauterize.group(:empty) do |g|
            g.dataless(:a)
            g.dataless(:b)
          end

          grp.tag_enum.values.keys.should =~ [:GROUP_EMPTY_TYPE_A, :GROUP_EMPTY_TYPE_B]
        end
      end

      describe ".tag_enum" do
        it "is the enumeration used for the type tag" do
          Group.new(:foo).tag_enum.class.should be Cauterize::Enumeration
        end
      end

      describe "enum_sym" do
        it "returns the enumeration symbol for a field name" do
          Cauterize.group(:foo).enum_sym(:a_field).should == :GROUP_FOO_TYPE_A_FIELD
        end
      end
    end
  end
end
