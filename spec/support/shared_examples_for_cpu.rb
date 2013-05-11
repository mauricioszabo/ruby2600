CPU_FLAGS = %w'n v b d i z c'

shared_examples_for 'set A value' do |expected|
  it do
    cpu.step

    value = cpu.a
    value.should be(expected), "Expected: #{hex_byte(expected)}, found: #{hex_byte(value)}"
  end
end

shared_examples_for 'set X value' do |expected|
  it do
    cpu.step

    value = cpu.x
    value.should be(expected), "Expected: #{hex_byte(expected)}, found: #{hex_byte(value)}"
  end
end

shared_examples_for 'set Y value' do |expected|
  it do
    cpu.step

    value = cpu.y
    value.should be(expected), "Expected: #{hex_byte(expected)}, found: #{hex_byte(value)}"
  end
end

shared_examples_for 'set PC value' do |expected|
  it do
    cpu.step

    value = cpu.pc
    value.should be(expected), "Expected: #{hex_word(expected)}, found: #{hex_word(value)}"
  end
end

shared_examples_for 'set memory with value' do |position, expected|
  it do
    cpu.step

    value = cpu.memory[position]
    value.should be(expected), "Expected: #{hex_byte(expected)} at address #{hex_word(position)}, found: #{hex_byte(value)}"
  end
end

CPU_FLAGS.each do |flag|
  shared_examples_for "set #{flag.upcase} flag" do
    it do
      cpu.step

      cpu.send(flag).should be_true
    end
  end

  shared_examples_for "reset #{flag.upcase} flag" do
    it do
      cpu.step

      cpu.send(flag).should be_false
    end
  end
end

shared_examples_for "preserve flags" do
  CPU_FLAGS.each do |flag|
    it "keeps #{flag} reset" do
      cpu.send("#{flag}=", false)

      cpu.step

      cpu.send(flag).should be_false
    end

    it "keeps #{flag} set" do
      cpu.send("#{flag}=", true)

      cpu.step

      cpu.send(flag).should be_true
    end
  end
end

1.upto 3 do |number|
  shared_examples_for "advance PC by #{number.humanize}" do
    it { expect { cpu.step }.to change { cpu.pc }.by number }
  end
end

2.upto 7 do |number|
  puts "take #{number.humanize} cycles"
  shared_examples_for "take #{number.humanize} cycles" do
    it { cpu.step.should == number }
  end
end

shared_examples_for "a branch instruction" do
  before { cpu.pc = 0x0510 }

  context 'no branch' do
    before do
      cpu.memory[0x0510..0x0511] = opcode, 0x02  # B?? $0514
      cpu.send("#{flag}=", !branch_state)
    end

    it_should 'take two cycles'

    it_should 'advance PC by two'

    it_should 'preserve flags'
  end

  context 'branch' do
    before { cpu.send("#{flag}=", branch_state) }

    context 'forward on same page' do
      before { cpu.memory[0x0510..0x0511] = opcode, 0x02 }  # B?? $0514

      it_should 'take three cycles'

      it_should 'set PC value', 0x0514

      it_should 'preserve flags'
    end

    context 'backward on same page' do
      before { cpu.memory[0x0510..0x0511] = opcode, 0xFC }  # B?? $050E

      it_should 'take three cycles'

      it_should 'set PC value', 0x050E

      it_should 'preserve flags'
    end

    context 'forward on another page' do
      before do
        cpu.pc = 0x0590
        cpu.memory[0x0590..0x0591] = opcode, 0x7F # B?? $0611
      end

      it_should 'take four cycles'

      it_should 'set PC value', 0x0611

      it_should 'preserve flags'
    end

    context 'backward on another page' do
      before { cpu.memory[0x0510..0x0511] = opcode, 0x80 }  # B?? $0492

      it_should 'take four cycles'

      it_should 'set PC value', 0x0492

      it_should 'preserve flags'
    end
  end
end
