# Unit spec of the template components built for 360dialog (no HTTP).
#
#   ruby -Ilib -S rspec spec/api360degree/build_parameters_spec.rb
#
require 'json'
require 'faraday'
require 'api360degree'

RSpec.describe Api360degree::WhatsApp do

  subject(:client) { described_class.new('test-key') }

  def build(placeholders)
    client.send(:build_parameters, placeholders)
  end

  it 'builds header and body text parameters' do
    expect(build(header: ['Ana'], body: ['R-1', 'mañana'])).to eq([
      { 'type' => 'header', 'parameters' => [{ type: 'text', text: 'Ana' }] },
      { 'type' => 'body', 'parameters' => [{ type: 'text', text: 'R-1' }, { type: 'text', text: 'mañana' }] }
    ])
  end

  it 'builds a url button with a text parameter' do
    expect(build(buttons: { 0 => { sub_type: 'url', parameters: ['abc'] } })).to eq([
      { 'type' => 'button', 'sub_type' => 'url', 'index' => 0, 'parameters' => [{ type: 'text', text: 'abc' }] }
    ])
  end

  it 'builds a quick_reply button with a text parameter' do
    expect(build(buttons: { 1 => { sub_type: 'quick_reply', parameters: ['yes'] } })).to eq([
      { 'type' => 'button', 'sub_type' => 'quick_reply', 'index' => 1, 'parameters' => [{ type: 'text', text: 'yes' }] }
    ])
  end

  it 'builds a copy_code button with its code as coupon_code' do
    expect(build(body: ['R-1'], buttons: { 0 => { sub_type: 'copy_code', parameters: ['ABC123'] } })).to eq([
      { 'type' => 'body', 'parameters' => [{ type: 'text', text: 'R-1' }] },
      { 'type' => 'button', 'sub_type' => 'copy_code', 'index' => 0,
        'parameters' => [{ type: 'coupon_code', coupon_code: 'ABC123' }] }
    ])
  end

  it 'sends a single code for a copy_code button' do
    components = build(buttons: { 0 => { sub_type: 'copy_code', parameters: [12345, 'other'] } })
    expect(components.first['parameters']).to eq([{ type: 'coupon_code', coupon_code: '12345' }])
  end

  it 'ignores a button of an unknown sub_type' do
    expect(build(buttons: { 0 => { sub_type: 'flow', parameters: ['x'] } })).to eq([])
  end

  it 'serializes the copy_code button as the WhatsApp Cloud API expects' do
    json = JSON.parse(build(buttons: { 0 => { sub_type: 'copy_code', parameters: ['ABC123'] } }).to_json)
    expect(json).to eq([{ 'type' => 'button', 'sub_type' => 'copy_code', 'index' => 0,
                          'parameters' => [{ 'type' => 'coupon_code', 'coupon_code' => 'ABC123' }] }])
  end
end
