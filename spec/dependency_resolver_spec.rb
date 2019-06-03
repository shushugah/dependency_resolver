# frozen_string_literal: true

require './dependency_resolver.rb'
require 'spec_helper.rb'

RSpec.describe DependencyResolver do
  def build_task(number, requires = nil)
    if requires.nil?
      { 'name' => "task-#{number}", 'command' => "command#{number}" }
    else
      {
        'name' => "task-#{number}",
        'command' => "command#{number}",
        'requires' => ["task-#{requires}"]
      }
    end
  end

  let(:dependency) { described_class.new('./tasks.json') }
  let(:bash_header) { "#!/usr/bin/env ruby\n\n" }

  describe '#initialize' do
    it 'raises error for missing json file' do
      expect { described_class.new }.to raise_error ArgumentError
    end

    it 'initializes "bash headers"' do
      @buffer = StringIO.new
      allow(File).to receive(:open).with('tasks.sh', 'w').and_return(@buffer)

      dependency
      expect(@buffer.string).to eq bash_header
    end
  end

  describe '#add' do
    let(:task_1) { build_task(1) }
    let(:task_2) { build_task(2) }
    let(:task_3) { build_task(3, 4) }
    let(:task_4) { build_task(4) }
    let(:task_5) { build_task(5, 6) }
    let(:task_6) { build_task(6, 5) }

    before(:each) do
      @buffer = StringIO.new
      allow(File).to receive(:open).with('tasks.sh', 'w').and_return(@buffer)
    end

    it 'adds a single task' do
      dependency.add(task_1)
      expect(@buffer.string.scan('command1').count).to eq 1
    end

    it 'does not add task twice' do
      2.times { dependency.add(task_2) }
      expect(@buffer.string.scan('command1').count).to eq 0
      expect(@buffer.string.scan('command2').count).to eq 1
    end

    it 'outputs tasks in dependent order' do
      expect(dependency).to receive(:find_task_by_name).with('task-4').and_return(task_4)
      dependency.add(task_3)
      expect(@buffer.string.split("\n").last(2)).to eq %w[command4 command3]
    end

    it 'raises error for circular task 5' do
      expect(dependency).to receive(:find_task_by_name).with('task-6').and_return(task_5)
      expect { dependency.add(task_5) }.to raise_error(CircularDependencyError)
      expect(@buffer.string).to eq bash_header
    end

    it 'raises error for circular task 6' do
      expect(dependency).to receive(:find_task_by_name).with('task-5').and_return(task_6)
      expect { dependency.add(task_6) }.to raise_error(CircularDependencyError)
      expect(@buffer.string).to eq bash_header
    end
  end
end
