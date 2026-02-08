require 'rails_helper'

RSpec.describe WardCodeMapper, type: :service do
  describe '.normalize' do
    it 'converts KML format to database format' do
      expect(WardCodeMapper.normalize('F/N')).to eq('F NORTH')
      expect(WardCodeMapper.normalize('F/S')).to eq('F SOUTH')
      expect(WardCodeMapper.normalize('G/N')).to eq('G NORTH')
      expect(WardCodeMapper.normalize('R/C')).to eq('R/Central')
    end

    it 'handles already normalized codes' do
      expect(WardCodeMapper.normalize('F NORTH')).to eq('F NORTH')
      expect(WardCodeMapper.normalize('L')).to eq('L')
      expect(WardCodeMapper.normalize('R/Central')).to eq('R/Central')
    end

    it 'handles case variations' do
      expect(WardCodeMapper.normalize('f/n')).to eq('F NORTH')
      expect(WardCodeMapper.normalize('r/central')).to eq('R/Central')
      expect(WardCodeMapper.normalize('R CENTRAL')).to eq('R/Central')
    end

    it 'returns nil for blank input' do
      expect(WardCodeMapper.normalize(nil)).to be_nil
      expect(WardCodeMapper.normalize('')).to be_nil
      expect(WardCodeMapper.normalize('  ')).to be_nil
    end

    it 'returns original for unmapped codes' do
      expect(WardCodeMapper.normalize('UNKNOWN')).to eq('UNKNOWN')
      expect(WardCodeMapper.normalize('X')).to eq('X')
    end
  end

  describe '.to_kml_format' do
    it 'converts database format to KML format' do
      expect(WardCodeMapper.to_kml_format('F NORTH')).to eq('F/N')
      expect(WardCodeMapper.to_kml_format('F SOUTH')).to eq('F/S')
      expect(WardCodeMapper.to_kml_format('R/Central')).to eq('R/C')
    end

    it 'returns nil for blank input' do
      expect(WardCodeMapper.to_kml_format(nil)).to be_nil
      expect(WardCodeMapper.to_kml_format('')).to be_nil
    end

    it 'returns original for unmapped codes' do
      expect(WardCodeMapper.to_kml_format('UNKNOWN')).to eq('UNKNOWN')
    end
  end

  describe '.valid_ward_code?' do
    it 'checks if ward exists' do
      ward = wards(:ward_one)

      allow(Ward).to receive(:exists?).with(ward_code: 'F NORTH').and_return(true)
      expect(WardCodeMapper.valid_ward_code?('F/N')).to be true

      allow(Ward).to receive(:exists?).with(ward_code: 'UNKNOWN').and_return(false)
      expect(WardCodeMapper.valid_ward_code?('UNKNOWN')).to be false

      expect(WardCodeMapper.valid_ward_code?(nil)).to be false
    end
  end

  describe '.find_ward' do
    it 'finds ward by any format' do
      mock_ward = instance_double('Ward')
      allow(Ward).to receive(:find_by).with(ward_code: 'F NORTH').and_return(mock_ward)

      result = WardCodeMapper.find_ward('F/N')
      expect(result).to eq(mock_ward)

      allow(Ward).to receive(:find_by).with(ward_code: 'UNKNOWN').and_return(nil)
      expect(WardCodeMapper.find_ward('UNKNOWN')).to be_nil
    end
  end

  describe '.all_formats' do
    it 'returns all possible formats' do
      formats = WardCodeMapper.all_formats('F/N')

      expect(formats).to include('F/N')
      expect(formats).to include('F NORTH')
      expect(formats.length).to eq(2)
    end

    it 'handles unmapped codes' do
      formats = WardCodeMapper.all_formats('UNKNOWN')

      expect(formats).to include('UNKNOWN')
      expect(formats.length).to eq(1)
    end
  end

  describe '.normalize_batch' do
    it 'processes multiple ward codes' do
      input = ['F/N', 'G/S', 'L', nil, '']
      expected = ['F NORTH', 'G SOUTH', 'L']

      expect(WardCodeMapper.normalize_batch(input)).to eq(expected)
    end

    it 'returns empty array for blank input' do
      expect(WardCodeMapper.normalize_batch(nil)).to eq([])
      expect(WardCodeMapper.normalize_batch([])).to eq([])
    end
  end

  describe 'mappings' do
    it 'are comprehensive for Mumbai wards' do
      mumbai_ward_codes = ['A', 'B', 'C', 'D', 'E', 'F/N', 'F/S', 'G/N', 'G/S', 'R/C']

      mumbai_ward_codes.each do |code|
        normalized = WardCodeMapper.normalize(code)
        expect(normalized).not_to be_nil, "Ward code #{code} should have a mapping"
        expect(normalized.to_s.strip).not_to eq('')
      end
    end
  end
end
