gem 'httparty'
require 'httparty'
require 'json'

module Geckoboard
  class Push
    class << self
      # API configuration
      attr_accessor :api_key
      attr_accessor :api_version
    end

    # Custom error type for handling API errors
    class Error < Exception; end

    include HTTParty
    base_uri 'https://push.geckoboard.com'

    # Initializes the push object for a specific widget
    def initialize(widget_key)
      @widget_key = widget_key
    end

    # Makes a call to Geckoboard to push data to the current widget
    def push(data)
      raise Geckoboard::Push::Error.new("Api key not configured.") if Geckoboard::Push.api_key.nil? || Geckoboard::Push.api_key.empty?
      result = JSON.parse(self.class.post("/#{Geckoboard::Push.api_version || 'v1'}/send/#{@widget_key}", {:body => {:api_key => Geckoboard::Push.api_key, :data => data}.to_json}))
      raise Geckoboard::Push::Error.new(result["error"]) unless result["success"]
      result["success"]
    end

    # Value and previous value should be numeric values
    def number_and_secondary_value(value, previous_value)
      self.push(:item => [{:text => "", :value => value}, {:text => "", :value => previous_value}])
    end

    # Items should be an array of hashes, each hash containing:
    # - text
    # - type (should be either :alert, or :info, optional)
    def text(items)
      data = items.collect do |item|
        type = case item[:type]
        when :alert
          1
        when :info
          2
        else
          0
        end
        {:text => item[:text], :type => type}
      end
      self.push(:item => data)
    end

    # Red, amber and green should be hash
    def rag(red, amber, green)
      self.push(:item => [{:value => red[:value], :text => red[:text]},
                          {:value => amber[:value], :text => amber[:text]},
                          {:value => green[:value], :text => green[:text]}])
    end

    # Values should be an array of numeric values
    # Colour, x_axis and y_axis are optional settings
    def line(values, colour = nil, x_axis = nil, y_axis = nil)
      self.push(:item => values, :settings => {:axisx => x_axis, :axisy => y_axis, :colour => colour})
    end

    # Items should be an array of hashes, each hash containing:
    # - value (numeric value)
    # - label (optional)
    # - colour (optional)
    def pie(items)
      data = items.collect do |item|
        {:value => item[:value], :label => item[:label], :colour => item[:colour]}
      end
      self.push(:item => data)
    end

    # Value is numeric, min and max should be hash
    def geckometer(value, min, max)
      min[:text] |= "Min value"
      max[:text] |= "Max value"
      self.push(:item => value,
                :min => {:text => min[:text], :value => min[:value]},
                :max => {:text => max[:text], :value => max[:value]}
                )
    end

    # Items should be an array of hashes, each hash containing:
    # - value (numeric value)
    # - label (optional)
    # Reverse defaults to false, and when true flips the colours on the widget
    # Hide percentage defaults to false, and when true hides the percentage value on the widget
    def funnel(items, reverse = false, hide_percentage = false)
      data = items.collect do |item|
        {:value => item[:value], :label => item[:label]}
      end
      opts = {:item => data}
      opts[:type] = "reverse" if reverse
      opts[:percentage] = "hide" if hide_percentage
      self.push(opts)
    end
  end
end
