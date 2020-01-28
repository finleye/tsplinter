module TSplit
  class Session
    attr_accessor :name

    def initialize
      @name = `tmux display-message -p '#S'`.gsub("\n","")
    end

    def target
      name
    end

    def windows
      @window ||= `tmux list-windows -F "\#{window_name}" -t #{@name}`.split("\n")
    end

    def next_split_window
      split_windows = windows.select { |window| window.include?("split") }

      if split_windows.empty?
        "split-0"
      else
        next_index = split_windows.map{|w| w.gsub("split-","").to_i}.max + 1
        "split-#{next_index}"
      end
    end
  end

  class Window
    attr_accessor :panes, :session
    def initialize(session)
      @session = session
      @panes = []
    end

    def name=(name)
      @name = name
    end

    def create
      `tmux new-window -d -n #{@name} -t #{@session.name}`
    end

    def target
      "#{@session.target}:#{@name}"
    end

    def split!(count)
      split_pattern(count).each do |direction, pane_num|
        `tmux split-window -d -#{direction} -t #{target}.#{pane_num}`
        sleep 0.3
      end
      populate_panes
    end

    def populate_panes
      number_of_panes = `tmux list-panes -t #{target} | wc -l`.to_i
      @panes = []
      (1..number_of_panes).each do |i|
        @panes << Pane.new(@session, self, i)
      end
    end

    def split_pattern(count)
      rtn = []
      direction = "h"
      i=0
      finished = false
      while !finished do
        (1..(2 ** i)).each do |j|
          next if (rtn.count == (count - 1))
          rtn << [direction, (j*2)-1]
        end
        finished = true if (rtn.count == (count - 1))
        direction = (direction == "h" ? "v" : "h")
        i+=1
      end
      rtn
    end
  end

  class Pane
    def initialize(session, window, index)
      @session = session
      @window = window
      @index = index
    end

    def target
      "#{@window.target}.#{@index}"
    end

    def send_keys(command)
      # `tmux send-keys -t #{target} C-c C-b '#{command}' Enter`
      `tmux send-keys -t #{target} '#{command}' Enter`
    end
  end
end
