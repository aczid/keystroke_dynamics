# == Summary
# The Analysis class is used to:
# * gather keystroke data from attached GTK widgets
# * calculate character-specific statistics from the gathered keystroke data to base a metric on
# * calculate an average metric, consisting of min/max/mean seek/hold times per character, over several instances of keystroke data using these statistics
# * calculate the deviiation between these average metrics
# * calculate general statistics from the gathered keystroke data, to provide real time feedback to users

# Module housing Analysis class, Validation class and associated constants
module KeystrokeDynamics

# Number of milliseconds allowed to be slower or faster from measured profile.
# For example, setting this to 1000 means that there can be a total of 1 second deviation in keystroke min/max/mean seeks and holds combined. Having a 1 second deviation would then make the compare_metrics function return 0.
# This number needs to be increased as the number of compared metrics increases to allow for standard deviation.
MAX_ALLOWED_DEVIATION = 800

# == Summary
# The Analysis class is used to:
# * gather keystroke data from attached GTK widgets
# * calculate character-specific statistics from the gathered keystroke data to base a metric on
# * calculate an average metric, consisting of min/max/mean seek/hold times per character, over several instances of keystroke data using these statistics
# * calculate the deviiation between these average metrics
# * calculate general statistics from the gathered keystroke data, to provide real time feedback to users
#
# === Data structures
# First, a signal handler is attached to log key data. These are keystrokes with metadata such as time_pressed, time_released. These are elaborated on by calculating the hold time and the seek time since the last character interactively.
# These keystrokes are stored in an array which ensures they stay in an ordered position.
# The statistics and metric functions operate on an array of these keystroke arrays, which allows for test data from several widgets to be analyzed simultaneously. This metric is a hash of keystrokes with more explicit biometric information, namely min/max/mean seek/hold times.
# This metric can be tested for simmilarity to a refrence metric by counting the number of deviations in ms from the reference metric. The reference metric is actually calculated using the same metric function, because it is able to condense many instances of widgets (arrays of arrays) to a metric. Averaging over many widgets ensures any deviation gets more flattened out, and thus makes the metric more accurate.
#
# == Notes
# This class is instantiable as an Analysis, to capture input and do simple statistics on it.
# However, it also houses all the logic to calculate and compare the metric as class methods, which can be called from everywhere. (So it is partly like a static class would be in other languages.)
class Analysis
  # This array houses the analyzed keystrokes, with hashes like <tt>{:time_pressed, :time_released, :character, :seek_time, :hold_time}</tt>.
  # If the concept of hashes is unfamilliar to you, it might help to think of them like simple structs.
  attr_accessor :keystrokes

  def initialize
    # Using an array ensures the keystrokes are stored in the order they were inserted.
    # This is important because the release event handler needs to look through the list to find the last key which was pressed, but possibly not yet released.
    @keystrokes = []
  end

  # Attaches signal handlers to (an array of) widgets so that keystroke dynamics data can be collected from them.
  def analyze_keys(widget_array)
    widget_array = [widget_array] if !widget_array.is_a?(Array)
    widget_array.each do |widget|
      widget.add_events(Gdk::Event::KEY_PRESS)
      widget.add_events(Gdk::Event::KEY_RELEASE)
      widget.signal_connect("key-press-event") do |w, e|
        if(e.keyval)
          keystroke = {:time_pressed => e.time, :character => Gdk::Keyval.to_name(e.keyval).to_s}
          last = last_keystroke || {}
          # Calculates seek time.
          if(last[:time_pressed] != nil)
            keystroke[:seek_time] = (keystroke[:time_pressed] - last[:time_pressed]) if last[:time_pressed] != nil
          end
          @keystrokes << keystroke
        end
        # Lets the event propagate up to the original signal handler.
        false
      end
    
      widget.signal_connect("key-release-event") do |w, e|
        if(e.keyval)
          # Calculates hold time.
          # Iterates through the array in reverse to find the last pressed, but not yet released key.
          @keystrokes.reverse_each do |keystroke|
            if(keystroke[:time_released] == nil)
              keystroke[:time_released] = e.time
              keystroke[:hold_time] = (e.time - keystroke[:time_pressed]) if keystroke[:time_pressed] != nil
            end
          end
        end
        # Lets the event propagate up to the original signal handler.
        false
      end
    end 
  end

  # Returns last recorded keystroke hash.
  def last_keystroke
    # Looks if we are still in the middle of our last keystroke, and returns it if necessary.
    @keystrokes.reverse_each do |keystroke|
      if(keystroke[:time_released] == nil)
        return keystroke
      end
    end
    # If all the logged keystrokes were released, return the last one in the array.
    @keystrokes.last
  end

  # Returns mean seek time for all analyzed keystrokes.
  # Used to display realtime statistics in the application.
  def mean_seek
    mean = Analysis.metric([@keystrokes])
    mean_seek = 0 
    mean.each_pair do |idx, keystroke|
      mean_seek += keystroke[:mean_seek].to_i
    end
    if mean.size.to_i != 0
      return (mean_seek.to_i / mean.size.to_i).to_i
    else
      return 0
    end
  end

  # Returns mean hold time for all analyzed keystrokes.
  # Used to display realtime statistics in the application.
  def mean_hold
    mean = Analysis.metric([@keystrokes])
    mean_hold = 0 
    mean.each_pair do |idx, keystroke|
      mean_hold += keystroke[:mean_hold].to_i
    end
    if mean.size.to_i != 0
      return (mean_hold.to_i / mean.size.to_i).to_i
    else
      return 0
    end
  end

  # Returns mean number of keystrokes per second.
  # Used to display realtime statistics in the application.
  def mean_kps
    last = last_keystroke || {}
    first = @keystrokes.first || {}
    time_in_ms = (last[:time_pressed].to_i - first[:time_pressed].to_i).to_f
    if time_in_ms != 0
      return (@keystrokes.size.to_f / ((time_in_ms / 1000).to_f)).to_i
    else
      return 0
    end
  end

  # Returns deviation as an int betwoon 0 and 1.
  # Returns 0 if the max deviation is reached or exceeded.
  # Returns 0.5 if half of the max deviation is reached.
  # Returns 1 if the deviation is 0, ie the hashes of keystrokes match perfectly.
  def self.compare_metrics(metric_test, metric_ref)
    deviation = 0
    metric_test.each_pair do |idx,keystroke|
      if metric_test[idx.to_sym].is_a?(Hash) && metric_ref[idx.to_sym].is_a?(Hash)
        # Deviation will increase by the amount of ms seeks and holds differ from mean.
        mean_seek_diff = (metric_test[idx.to_sym][:mean_seek].to_i - metric_ref[idx.to_sym][:mean_seek].to_i)
        mean_hold_diff = (metric_test[idx.to_sym][:mean_hold].to_i - metric_ref[idx.to_sym][:mean_hold].to_i)
        if mean_seek_diff > 0
          deviation += mean_seek_diff
        else
          deviation -= mean_seek_diff
        end

        if mean_hold_diff > 0
          deviation += mean_hold_diff
        else
          deviation -= mean_hold_diff
        end

        # Deviation will increase by the amount of ms seeks and holds exceed min/max holds and seeks.
        if metric_test[idx.to_sym][:mean_hold] < metric_ref[idx.to_sym][:min_hold]
          deviation += (metric_ref[idx.to_sym][:min_hold] - metric_test[idx.to_sym][:mean_hold]).to_i
        end
        if metric_test[idx.to_sym][:mean_hold] > metric_ref[idx.to_sym][:max_hold]
          deviation += (metric_test[idx.to_sym][:mean_hold] - metric_ref[idx.to_sym][:max_hold]).to_i
        end
        if metric_test[idx.to_sym][:mean_seek] < metric_ref[idx.to_sym][:min_seek]
          deviation += (metric_ref[idx.to_sym][:min_seek] - metric_test[idx.to_sym][:mean_seek]).to_i
        end
        if metric_test[idx.to_sym][:mean_seek] > metric_ref[idx.to_sym][:max_seek]
          deviation += (metric_test[idx.to_sym][:mean_seek] - metric_ref[idx.to_sym][:max_seek]).to_i
        end
      end
    end
    if(deviation > MAX_ALLOWED_DEVIATION)
      return 0
    elsif((0 < deviation) && (deviation < MAX_ALLOWED_DEVIATION))
      return 1-(deviation.to_f/MAX_ALLOWED_DEVIATION)
    else
      return 1
    end
  end

  # Calculates mean, min and max seek/hold times per character from an array of keystroke arrays.
  # Returns a hash with <tt>{character.to_sym => {:mean_seek, :mean_hold, :min_seek, :max_seek, :min_hold, :max_hold}}</tt>.
  def self.metric(keystroke_array_array)
    stats = self.statistics(keystroke_array_array)
    metric = {}
    stats.each_pair do |idx, key|
      metric[idx] = {
        :mean_hold => (key[:hold_total] / key[:holds]),
        :mean_seek => (key[:seek_total] / key[:seeks]),
        :min_seek => key[:min_seek].to_i,
        :max_seek => key[:max_seek].to_i,
        :min_hold => key[:min_hold].to_i,
        :max_hold => key[:max_hold].to_i
      }
    end
    metric
  end

  # Calculates total seeks/holds, total seeks/holds time and min/max hold/seek values for each character analyzed.
  # Returns a hash with <tt>{character.to_sym => {:seek_total, :hold_total, :seeks, :holds, :character, :min_seek, :max_seek, :min_hold, :max_hold}}</tt>.
  def self.statistics(keystroke_array_array)
    stats = {}
    keystroke_array_array.each do |keystroke_array|
      keystroke_array.each do |keystroke|
        key = keystroke[:character].to_sym
        stats[key] = {:seek_total => 0, :hold_total => 0, :seeks => 0, :holds => 0, :character => keystroke[:character]} unless stats[key].is_a?(Hash)
        stats[key][:seek_total] += keystroke[:seek_time].to_i
        stats[key][:hold_total] += keystroke[:hold_time].to_i
        stats[key][:seeks] += 1
        stats[key][:holds] += 1
        stats[key][:min_seek] = keystroke[:seek_time].to_i if stats[key][:min_seek].to_i > keystroke[:seek_time].to_i
        stats[key][:max_seek] = keystroke[:seek_time].to_i if stats[key][:max_seek].to_i < keystroke[:seek_time].to_i
        stats[key][:min_hold] = keystroke[:hold_time].to_i if stats[key][:min_hold].to_i > keystroke[:hold_time].to_i
        stats[key][:max_hold] = keystroke[:hold_time].to_i if stats[key][:max_hold].to_i < keystroke[:hold_time].to_i
      end
    end
    stats
  end


end

end
