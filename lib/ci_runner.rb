# Adapted from Rails 8.1 ActiveSupport::ContinuousIntegration
# https://github.com/rails/rails/blob/8-1-stable/activesupport/lib/active_support/continuous_integration.rb
require "open3"

class CIRunner
  COLORS = {
    banner: "\e[1;32m",   # Bold green
    title: "\e[1;35m",    # Bold purple
    subtitle: "\e[1;90m", # Bold gray
    error: "\e[1;31m",    # Bold red
    success: "\e[1;32m",  # Bold green
    reset: "\e[0m"
  }.freeze

  attr_reader :results

  def initialize(output: $stdout, fail_fast: false)
    @output = output
    @fail_fast = fail_fast
    @results = []
  end

  def self.run(title = "Continuous Integration", subtitle = "Running checks...", output: $stdout, fail_fast: false, &block)
    new(output: output, fail_fast: fail_fast).tap do |ci|
      ci.heading(title, subtitle, type: :banner, padding: false)
      ci.report(title, &block)
    end
  end

  def step(title, *command)
    heading(title, command.join(" "), type: :title)

    started_at = Time.now
    stdout, stderr, status = run_with_timer(title, started_at) do
      Open3.capture3(*command)
    end
    elapsed = format_elapsed(Time.now - started_at)
    success = status.success?

    if success
      echo("\u2705 #{title} passed in #{elapsed}", type: :success)
    else
      echo("\u274C #{title} failed in #{elapsed}", type: :error)
      print_failure_output(stdout, stderr)
    end

    results << [ success, title, stdout, stderr ]
  end

  def success?
    results.all?(&:first)
  end

  def failure(title, subtitle = nil)
    heading(title, subtitle, type: :error)
  end

  def heading(text, subtitle = nil, type: :banner, padding: true)
    @output.puts if padding
    echo(text, type: type)
    echo(subtitle, type: :subtitle) if subtitle
    @output.puts if padding
  end

  def report(title, &block)
    Signal.trap("INT") { abort colorize("\n\u274C #{title} interrupted", :error) }

    ci = self.class.new(output: @output, fail_fast: @fail_fast)
    elapsed = timing { ci.instance_eval(&block) }

    if ci.success?
      echo("\u2705 #{title} passed in #{elapsed}", type: :success)
    else
      echo("\u274C #{title} failed in #{elapsed}", type: :error)
      abort if @fail_fast

      # List failed steps (output was already printed by each step)
      ci.results.reject(&:first).each do |_, step_title, _, _|
        echo("  \u21B3 #{step_title} failed", type: :error)
      end
    end

    results.concat(ci.results)
  ensure
    Signal.trap("INT", "DEFAULT")
  end

  private

  def run_with_timer(title, started_at)
    result = nil
    stop_timer = false

    # Only show timer if output is a TTY
    if @output.respond_to?(:tty?) && @output.tty?
      timer_thread = Thread.new do
        until stop_timer
          elapsed = format_elapsed(Time.now - started_at)
          @output.print colorize("\r⏱️  #{title} running... #{elapsed}", :subtitle)
          sleep 0.1
        end
      end

      result = yield

      stop_timer = true
      timer_thread.join
      @output.print "\r#{' ' * 60}\r" # Clear the timer line
    else
      result = yield
    end

    result
  end

  def print_failure_output(stdout, stderr)
    output_text = extract_relevant_output(stdout, stderr)
    @output.puts output_text unless output_text.empty?
  end

  def extract_relevant_output(stdout, stderr)
    combined = "#{stdout}#{stderr}"

    # For RSpec output, extract from "Failures:" onward
    if combined.include?("Failures:")
      combined.slice(/Failures:.*Failed examples:.*?(?=\n\n|\z)/m) ||
        combined.slice(/Failures:.*/m) ||
        combined
    else
      combined
    end
  end

  def echo(text, type:)
    @output.puts colorize(text, type)
  end

  def colorize(text, type)
    if @output.respond_to?(:tty?) && @output.tty?
      "#{COLORS[type]}#{text}#{COLORS[:reset]}"
    else
      text
    end
  end

  def timing
    started_at = Time.now
    yield
    format_elapsed(Time.now - started_at)
  end

  def format_elapsed(elapsed)
    if elapsed >= 60
      minutes = (elapsed / 60).to_i
      seconds = elapsed % 60
      "#{minutes}m#{format('%.2fs', seconds)}"
    else
      format("%.2fs", elapsed)
    end
  end
end
