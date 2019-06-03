require 'json'
require_relative 'errors.rb'

class DependencyResolver
  attr_reader :json_data
  attr_accessor :bash_file


  def initialize(file_path)
    @json_data = JSON.parse(File.read(file_path))
    @bash_file = File.open('tasks.sh', 'w')
    @bash_file.puts "#!/usr/bin/env ruby\n\n"
  end

  def add(task)
    return if finished_tasks.include?(task['name'])
    raise CircularDependencyError if visited_tasks.include? task['name']
    visited_tasks << task['name']

    task['requires']&.each { |name| add(find_task_by_name(name)) }
    finished_tasks << task['name']
    bash_file.puts task['command']
  end

  def sort
    tasks.each(&method(:add))
  end

  private

  def tasks
    json_data['tasks']
  end

  def finished_tasks
    self.class.finished_tasks
  end

  def visited_tasks
    self.class.visited_tasks
  end

  def self.finished_tasks
    @finished_tasks ||= []
  end

  def self.visited_tasks
    @visited_tasks ||= []
  end

  def find_task_by_name(name)
    tasks.select {|h| h.values.include?(name) }.first
  end
end
