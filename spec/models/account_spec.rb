require 'spec_helper'

describe Account do
  subject{ Account.new(name: 'Example', origins: ['http://example.com']) }
  
  describe '#valid_request?' do
    it 'should be valid if the origin matches' do
      expect(subject).to be_valid_request(double(env: {'HTTP_ORIGIN' => 'http://example.com'}))
    end
    
    it 'should be valid if the referer matches' do
      expect(subject).to be_valid_request(double(env: {'HTTP_REFERER' => 'http://example.com/blah'}))
    end
    
    it 'should not be valid without a match' do
      expect(subject).not_to be_valid_request(double(env: {'HTTP_ORIGIN' => 'http://foo.com'}))
    end
  end
end