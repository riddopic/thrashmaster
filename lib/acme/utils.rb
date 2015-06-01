# encoding: UTF-8
#
# Author:    Stefano Harding <riddopic@gmail.com>
# License:   Apache License, Version 2.0
# Copyright: (C) 2014-2015 Stefano Harding
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative 'os'
require 'ruby-progressbar'

module ACME
  # Some snazy utility methods for better Assignment Branch Condition
  # Cyclomatic complexity Perceived.
  #
  module Utils
    # Methods are also available as module-level methods as well as a mixin.
    extend self

    # Checks in PATH returns true if the command is found.
    #
    # @param [String] command
    #   The name of the command to look for.
    #
    # @return [Boolean]
    #   True if the command is found in the path.
    #
    def command_in_path?(command)
      found = ENV['PATH'].split(File::PATH_SEPARATOR).map do |p|
        File.exist?(File.join(p, command))
      end
      found.include?(true)
    end

    # Returns the columns and lines of the current tty.
    #
    # @return [Integer]
    #   Number of columns and lines of tty, returns [0, 0] if no tty is present.
    #
    def terminal_dimensions
      [0, 0] unless  STDOUT.tty?
      [80, 40] if OS.windows?

      if ENV['COLUMNS'] && ENV['LINES']
        [ENV['COLUMNS'].to_i, ENV['LINES'].to_i]
      elsif ENV['TERM'] && command_in_path?('tput')
        [`tput cols`.to_i, `tput lines`.to_i]
      elsif command_in_path?('stty')
        `stty size`.scan(/\d+/).map(&:to_i)
      else
        [0, 0]
      end
    rescue
      [0, 0]
    end

    # Prints a line across the length of the terminal to help divide text.
    #
    # @return [String]
    #
    def mark_line
      terminal_dimensions[0].times { print '-'.yellow }
      puts
    end

    def double_mark_line
      3.times { terminal_dimensions[0].times { print '~'.purple } }
      puts
    end

    # Displays a progress bar, incrementing each second.
    #
    # @param [Integer] amount
    #
    def progress_bar(wait)
      progressbar = ProgressBar.create(
        format:         '%a %bᗧ%i %p%% %t',
        progress_mark:  ' ',
        remainder_mark: '･',
        starting_at:     0,
        total:           wait)
      wait.times do
        progressbar.increment
        sleep 1
      end
    end
  end
end

# Slap a `#.contains?` class on String, like hiting the easy button.
#
class String
  # Search a text file for a matching string
  #
  # @return [Boolean]
  #   True if the file is present and a match was found, otherwise returns
  #   false if file does not exist and/or does not contain a match
  #
  # @api public
  def contains?(str)
    return false unless File.exist?(self)
    File.open(self, &:readlines).collect { |l| return true if l.match(str) }
    false
  end
end
