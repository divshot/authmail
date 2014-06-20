require 'spec_helper'

describe Authentication do
  let(:account){ Account.new(name: 'Test Account', origins: ['http://example.com'], redirect: 'http://example.com/auth') }
  subject{ Authentication.new(email: 'bob@example.com', account: account) }
  
  it 'should require that the redirect be on a supplied origin' do
    subject.redirect = 'http://boombo.com/auth'
    expect(subject).not_to be_valid
    expect(subject.errors[:redirect].size).to eq(1)
  end
  
  it 'should work if the redirect matches the origin' do
    subject.redirect = 'http://example.com/auth2'
    expect(subject).to be_valid
  end
end