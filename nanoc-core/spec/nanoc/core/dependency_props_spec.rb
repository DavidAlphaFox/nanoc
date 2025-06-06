# frozen_string_literal: true

describe Nanoc::Core::DependencyProps do
  let(:props) { described_class.new }

  let(:props_all) do
    described_class.new(raw_content: true, attributes: true, compiled_content: true, path: true)
  end

  describe '#inspect' do
    subject { props.inspect }

    context 'nothing active' do
      it { is_expected.to eql('Props(____)') }
    end

    context 'attributes active' do
      let(:props) { described_class.new(attributes: true) }

      it { is_expected.to eql('Props(_a__)') }
    end

    context 'attributes and compiled_content active' do
      let(:props) { described_class.new(attributes: true, compiled_content: true) }

      it { is_expected.to eql('Props(_ac_)') }
    end

    context 'compiled_content active' do
      let(:props) { described_class.new(compiled_content: true) }

      it { is_expected.to eql('Props(__c_)') }
    end
  end

  describe '#to_s' do
    subject { props.to_s }

    context 'nothing active' do
      it { is_expected.to eql('____') }
    end

    context 'attributes active' do
      let(:props) { described_class.new(attributes: true) }

      it { is_expected.to eql('_a__') }
    end

    context 'attributes and compiled_content active' do
      let(:props) { described_class.new(attributes: true, compiled_content: true) }

      it { is_expected.to eql('_ac_') }
    end

    context 'compiled_content active' do
      let(:props) { described_class.new(compiled_content: true) }

      it { is_expected.to eql('__c_') }
    end
  end

  describe '#raw_content?' do
    subject { props.raw_content? }

    context 'nothing active' do
      it { is_expected.to be(false) }
    end

    context 'raw_content active' do
      let(:props) { described_class.new(raw_content: true) }

      it { is_expected.to be(true) }
    end

    context 'raw_content and compiled_content active' do
      let(:props) { described_class.new(raw_content: true, compiled_content: true) }

      it { is_expected.to be(true) }
    end

    context 'compiled_content active' do
      let(:props) { described_class.new(compiled_content: true) }

      it { is_expected.to be(false) }
    end

    context 'all active' do
      let(:props) { described_class.new(raw_content: true, attributes: true, compiled_content: true, path: true) }

      it { is_expected.to be(true) }
    end

    context 'raw_content is empty list' do
      let(:props) { described_class.new(raw_content: []) }

      it { is_expected.to be(false) }
    end

    context 'raw_content is non-empty list' do
      let(:props) { described_class.new(raw_content: ['/asdf.*']) }

      it { is_expected.to be(true) }
    end
  end

  describe '#attributes?' do
    subject { props.attributes? }

    context 'nothing active' do
      it { is_expected.to be(false) }
    end

    context 'attributes active' do
      let(:props) { described_class.new(attributes: true) }

      it { is_expected.to be(true) }
    end

    context 'attributes and compiled_content active' do
      let(:props) { described_class.new(attributes: true, compiled_content: true) }

      it { is_expected.to be(true) }
    end

    context 'compiled_content active' do
      let(:props) { described_class.new(compiled_content: true) }

      it { is_expected.to be(false) }
    end

    context 'all active' do
      let(:props) { described_class.new(raw_content: true, attributes: true, compiled_content: true, path: true) }

      it { is_expected.to be(true) }
    end

    context 'attributes is empty list' do
      let(:props) { described_class.new(attributes: []) }

      it { is_expected.to be(false) }
    end

    context 'attributes is non-empty list' do
      let(:props) { described_class.new(attributes: [:donkey]) }

      it { is_expected.to be(true) }
    end
  end

  describe '#compiled_content?' do
    # …
  end

  describe '#path?' do
    # …
  end

  describe '#merge' do
    subject { props.merge(other_props).active }

    context 'nothing + nothing' do
      let(:props) { described_class.new }
      let(:other_props) { described_class.new }

      it { is_expected.to eql(Set.new) }
    end

    context 'nothing + some' do
      let(:props) { described_class.new }
      let(:other_props) { described_class.new(raw_content: true) }

      it { is_expected.to eql(Set.new([:raw_content])) }
    end

    context 'nothing + all' do
      let(:props) { described_class.new }
      let(:other_props) { props_all }

      it { is_expected.to eql(Set.new(%i[raw_content attributes compiled_content path])) }
    end

    context 'some + nothing' do
      let(:props) { described_class.new(compiled_content: true) }
      let(:other_props) { described_class.new }

      it { is_expected.to eql(Set.new([:compiled_content])) }
    end

    context 'some + others' do
      let(:props) { described_class.new(compiled_content: true) }
      let(:other_props) { described_class.new(raw_content: true) }

      it { is_expected.to eql(Set.new(%i[raw_content compiled_content])) }
    end

    context 'some + all' do
      let(:props) { described_class.new(compiled_content: true) }
      let(:other_props) { props_all }

      it { is_expected.to eql(Set.new(%i[raw_content attributes compiled_content path])) }
    end

    context 'all + nothing' do
      let(:props) { props_all }
      let(:other_props) { described_class.new }

      it { is_expected.to eql(Set.new(%i[raw_content attributes compiled_content path])) }
    end

    context 'some + all' do
      let(:props) { props_all }
      let(:other_props) { described_class.new(compiled_content: true) }

      it { is_expected.to eql(Set.new(%i[raw_content attributes compiled_content path])) }
    end

    context 'all + all' do
      let(:props) { props_all }
      let(:other_props) { props_all }

      it { is_expected.to eql(Set.new(%i[raw_content attributes compiled_content path])) }
    end
  end

  describe '#merge_attributes' do
    subject { props.merge(other_props).attributes }

    let(:props_attrs_true) do
      described_class.new(attributes: true)
    end

    let(:props_attrs_false) do
      described_class.new(attributes: false)
    end

    let(:props_attrs_list_a) do
      described_class.new(attributes: %i[donkey giraffe])
    end

    let(:props_attrs_list_b) do
      described_class.new(attributes: %i[giraffe zebra])
    end

    context 'false + false' do
      let(:props) { props_attrs_false }
      let(:other_props) { props_attrs_false }

      it { is_expected.to be(false) }
    end

    context 'false + true' do
      let(:props) { props_attrs_false }
      let(:other_props) { props_attrs_true }

      it { is_expected.to be(true) }
    end

    context 'false + list' do
      let(:props) { props_attrs_false }
      let(:other_props) { props_attrs_list_a }

      it { is_expected.to be_a(Array) }
      it { is_expected.to match_array(%i[donkey giraffe]) }
    end

    context 'true + false' do
      let(:props) { props_attrs_true }
      let(:other_props) { props_attrs_false }

      it { is_expected.to be(true) }
    end

    context 'true + true' do
      let(:props) { props_attrs_true }
      let(:other_props) { props_attrs_true }

      it { is_expected.to be(true) }
    end

    context 'true + list' do
      let(:props) { props_attrs_true }
      let(:other_props) { props_attrs_list_a }

      it { is_expected.to be(true) }
    end

    context 'list + false' do
      let(:props) { props_attrs_list_a }
      let(:other_props) { props_attrs_false }

      it { is_expected.to be_a(Array) }
      it { is_expected.to match_array(%i[donkey giraffe]) }
    end

    context 'list + true' do
      let(:props) { props_attrs_list_a }
      let(:other_props) { props_attrs_true }

      it { is_expected.to be(true) }
    end

    context 'list + list' do
      let(:props) { props_attrs_list_a }
      let(:other_props) { props_attrs_list_b }

      it { is_expected.to be_a(Set) }
      it { is_expected.to match_array(%i[donkey giraffe zebra]) }
    end
  end

  describe '#merge_raw_content' do
    subject { props.merge(other_props).raw_content }

    let(:props_raw_content_true) do
      described_class.new(raw_content: true)
    end

    let(:props_raw_content_false) do
      described_class.new(raw_content: false)
    end

    let(:props_raw_content_list_a) do
      described_class.new(raw_content: %w[donkey giraffe])
    end

    let(:props_raw_content_list_b) do
      described_class.new(raw_content: %w[giraffe zebra])
    end

    context 'false + false' do
      let(:props) { props_raw_content_false }
      let(:other_props) { props_raw_content_false }

      it { is_expected.to be(false) }
    end

    context 'false + true' do
      let(:props) { props_raw_content_false }
      let(:other_props) { props_raw_content_true }

      it { is_expected.to be(true) }
    end

    context 'false + list' do
      let(:props) { props_raw_content_false }
      let(:other_props) { props_raw_content_list_a }

      it { is_expected.to be_a(Array) }
      it { is_expected.to match_array(%w[donkey giraffe]) }
    end

    context 'true + false' do
      let(:props) { props_raw_content_true }
      let(:other_props) { props_raw_content_false }

      it { is_expected.to be(true) }
    end

    context 'true + true' do
      let(:props) { props_raw_content_true }
      let(:other_props) { props_raw_content_true }

      it { is_expected.to be(true) }
    end

    context 'true + list' do
      let(:props) { props_raw_content_true }
      let(:other_props) { props_raw_content_list_a }

      it { is_expected.to be(true) }
    end

    context 'list + false' do
      let(:props) { props_raw_content_list_a }
      let(:other_props) { props_raw_content_false }

      it { is_expected.to be_a(Array) }
      it { is_expected.to match_array(%w[donkey giraffe]) }
    end

    context 'list + true' do
      let(:props) { props_raw_content_list_a }
      let(:other_props) { props_raw_content_true }

      it { is_expected.to be(true) }
    end

    context 'list + list' do
      let(:props) { props_raw_content_list_a }
      let(:other_props) { props_raw_content_list_b }

      it { is_expected.to be_a(Set) }
      it { is_expected.to match_array(%w[donkey giraffe zebra]) }
    end
  end

  describe '#active' do
    subject { props.active }

    context 'nothing active' do
      let(:props) { described_class.new }

      it { is_expected.to eql(Set.new) }
    end

    context 'raw_content active' do
      let(:props) { described_class.new(raw_content: true) }

      it { is_expected.to eql(Set.new([:raw_content])) }
    end

    context 'attributes active' do
      let(:props) { described_class.new(attributes: true) }

      it { is_expected.to eql(Set.new([:attributes])) }
    end

    context 'compiled_content active' do
      let(:props) { described_class.new(compiled_content: true) }

      it { is_expected.to eql(Set.new([:compiled_content])) }
    end

    context 'path active' do
      let(:props) { described_class.new(path: true) }

      it { is_expected.to eql(Set.new([:path])) }
    end

    context 'attributes and compiled_content active' do
      let(:props) { described_class.new(attributes: true, compiled_content: true) }

      it { is_expected.to eql(Set.new(%i[attributes compiled_content])) }
    end

    context 'all active' do
      let(:props) { described_class.new(raw_content: true, attributes: true, compiled_content: true, path: true) }

      it { is_expected.to eql(Set.new(%i[raw_content attributes compiled_content path])) }
    end
  end

  describe '#to_h' do
    subject { props.to_h }

    context 'nothing' do
      let(:props) { described_class.new }

      it { is_expected.to eql(raw_content: false, attributes: false, compiled_content: false, path: false) }
    end

    context 'some' do
      let(:props) { described_class.new(attributes: true, compiled_content: true) }

      it { is_expected.to eql(raw_content: false, attributes: true, compiled_content: true, path: false) }
    end

    context 'all' do
      let(:props) { props_all }

      it { is_expected.to eql(raw_content: true, attributes: true, compiled_content: true, path: true) }
    end
  end
end
