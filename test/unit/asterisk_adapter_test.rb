require 'test_helper'

class AsteriskAdapterTest < ActiveSupport::TestCase
  setup do
    @context = mock('context')
    @adapter = AsteriskAdapter.new @context
    @seq = sequence('seq')
  end

  test 'answer' do
    @context.expects :answer
    @adapter.send :answer
  end

  test 'hangup' do
    @context.expects :hangup
    @context.expects :close_connection
    @adapter.send :hangup
  end

  test "play" do
    path = @adapter.sound_path_for 'something'

    @context.expects(:stream_file).with('verbo/something', nil).returns(line '1'.ord.to_s)
    value = @adapter.play path
    assert_equal '1', value
  end

  test "play with escape digits" do
    path = @adapter.sound_path_for 'something'

    @context.expects(:stream_file).with('verbo/something', '123').returns(line '0')
    value = @adapter.play path, '123'
    assert_nil value
  end

  {'48' => '0',
   '49' => '1',
   '57' => '9',
   '35' => '#',
   '42' => '*',
   '0' => nil}.each do |result, digit|
    test "capture one digit #{digit}" do
      expect_digit result
      value = @adapter.capture :min => 1, :max => 1, :finish_on_key => '', :timeout => 5
      assert_equal digit, value
    end
  end

  test "capture two digits" do
    seq = sequence('digits')

    expect_digits '42'
    value = @adapter.capture :min => 2, :max => 2, :finish_on_key => '#', :timeout => 5
    assert_equal '42', value
  end

  test "capture three digits timeout" do
    seq = sequence('digits')

    expect_digits ['4'.ord.to_s, '2'.ord.to_s, '0']
    value = @adapter.capture :min => 3, :max => 3, :finish_on_key => '#', :timeout => 5
    assert_equal nil, value
  end

  test "capture digits finishes on key" do
    seq = sequence('digits')

    expect_digits '42#'
    value = @adapter.capture :min => 1, :max => 5, :finish_on_key => '#', :timeout => 5
    assert_equal '42', value
  end

  test "capture digits while playing" do
    seq = sequence('digits')

    @adapter.expects(:play).with('some_file', '0123456789#*').returns('4').in_sequence(@seq)
    expect_digit '2'.ord.to_s
    value = @adapter.capture :min => 2, :max => 2, :finish_on_key => '#', :timeout => 5, :play => 'some_file'
    assert_equal '42', value
  end

  test "capture digits and play is finish key" do
    @adapter.expects(:play).with('some_file', '0123456789#*').returns('*').in_sequence(@seq)
    value = @adapter.capture :min => 2, :max => 2, :finish_on_key => '*', :timeout => 5, :play => 'some_file'
    assert_equal nil, value
  end

  def expect_digits(digits)
    if digits.is_a? Array
      digits.each { |digit| expect_digit digit }
    else
      digits.each_char { |c| expect_digit c.ord.to_s }
    end
  end

  def expect_digit(result)
    @context.expects(:wait_for_digit).with(5 * 1000).returns(line result).in_sequence(@seq)
  end

  def line(result)
    stub('line', :result => result)
  end
end