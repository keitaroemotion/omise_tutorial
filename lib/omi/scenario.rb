require "colorize"

module Lib
  class Scenario
    class << self 
      #
      # [ITERATION]
      # $schd: omi schedule delete schedule=$
      #
      
      def get_pkey
        key = ARGV.select{ |a| a.start_with?("pkey_") }.first 
        key
      end
      
      def get_skey
        key = ARGV.select{ |a| a.start_with?("skey_") }.first 
        key
      end
      
      def get_story_path
        path = ARGV.select{ |a| File.exist?(a) && a.end_with?(".story") }.first
        abort("story_path missing") unless path
        path
      end
      
      def process_echo(instruction)
        if instruction.start_with?("echo ")
          puts("\n---------------------------------------------------\n\n") 
          puts(instruction.gsub("echo ", "").chomp.blue)
          puts("\n---------------------------------------------------") 
        end
      end
      
      def process_loop_omi(instruction, hash, result)
        if /\$.+\:\s+omi\s+.+/ =~ instruction
          prefix = /\$[^\:]+/.match(instruction).to_s
          value = hash[prefix]
          instruction = instruction.gsub("#{prefix}:", "").strip
      
          if value.class == String
            value = [value]
          end
      
          value.each do |x|
            command = instruction.gsub("$", x)
            puts command
            system command
          end
        end
      end
      
      def process_omi(instruction, hash, result)
        if instruction.start_with?("omi ")
          hash.each do |k, v|
            return result if v.class == Array
            instruction = instruction.gsub(k, v)
          end  
          print(instruction.chomp)
          print(" [Y/n]: ")
          input = $stdin.gets.chomp.downcase
          abort if input == "n"
          result = `#{instruction}`.split("[Result]")
          command  = result[0]
          response = result[1]
          puts command
          print("[response]> "); $stdin.gets.chomp
          puts(response)
          result = response
        end
        result
      end
      
      def assign(instruction, result, hash)
        if /\$.+=.+/ =~ instruction
          isp      = instruction.split("=").map{ |x| x.strip.chomp }
          variable = isp[0] 
          regex    = Regexp.new(isp[1].gsub("_", "\\_") + "[^\"\/]+")
          if /{.+}/ =~ variable
            variable = variable.gsub("{", "").gsub("}", "")        
            match = result
              .split("\n")
              .select { |line| regex =~ line }
              .map    { |line| regex.match(line).to_s }
              .uniq
          else  
            match = regex.match(result).to_s
          end
          hash[variable] = match
          puts "ASSIGNED: #{variable} => #{match}"
        end
        hash
      end
      
      def execute
        result = ""
        hash   = {}
        
        File.open(get_story_path, "r").each do |instruction|
          if instruction.strip == "abort"
            abort
          end
          if !(instruction.start_with?("#") && instruction.strip.chomp)
            process_echo(instruction)
            result = process_omi(instruction, hash, result)
            hash   = assign(instruction, result, hash)
            process_loop_omi(instruction, hash, result)
          end
        end 
      end  
    end  
  end  
end
